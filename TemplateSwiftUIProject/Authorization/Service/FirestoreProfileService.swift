//
//  FirestoreProfileService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.07.25.
//

// что мы ловим в блоке catch?

/// Ошибку DecodingError — результат того, что snapshot.data(as:) не смог преобразовать данные Firestore в тип UserProfile. Это может быть:
/// DecodingError.dataCorrupted
/// DecodingError.keyNotFound
/// DecodingError.typeMismatch
/// DecodingError.valueNotFound
/// DecodingError — это не NSError, но если ты приведёшь его к NSError, то получишь - NSCocoaErrorDomain
// let nsError = error as NSError
//print(nsError.domain)
///Ошибка в catch — это DecodingError, с NSError.domain == NSCocoaErrorDomain


/*
 Сценарии fetchProfile(uid:):
 1) Успех:
    - Есть snapshot.exists == true → декодируем -> отправляем UserProfile
    - Нет документа → отправляем пустую модель UserProfile(uid: uid)
    - Поток не завершается, слушатель продолжает присылать обновления

 2) Ошибка в listener (например, permission error):
    - subject.send(completion: .failure(error))
    - handleFirestoreError(error, "Error fetch profile") покажет алерт

 3) snapshot == nil при error == nil (редкий SDK-сбой/невалидный путь):
    - subject.send(completion: .failure(FirebaseInternalError.nilSnapshot))
    - handleFirestoreError(...) покажет алерт

 4) Ошибка декодирования:
    - subject.send(completion: .failure(error))
    - handleFirestoreError(...) покажет алерт

 Примечания по includeMetadataChanges:
 - true: получите локальный снапшот (кэш/пенд. записи), затем подтверждённый сервером
 - snapshot.metadata.hasPendingWrites и isFromCache помогают отобразить состояние синхронизации в UI

 Сценарии updateProfilePublisher(_:, operationDescription:):
 1) Успех:
    - setData merge: true завершился без ошибок → promise(.success)

 2) Ошибка кодирования:
    - handleFirestoreError(error, operationDescription) → алерт, .failure(error)

 3) Ошибка setData:
    - handleFirestoreError(error, operationDescription) → алерт, .failure(error)
*/


import FirebaseFirestore
import Combine

struct UserProfile: Codable, Equatable, Hashable {
    let uid: String
    var name: String?
    var lastName: String?
    var photoURL: URL?

    init(uid: String, name: String? = nil, lastName: String? = nil, photoURL: URL? = nil) {
        self.uid = uid
        self.name = name
        self.lastName = lastName
        self.photoURL = photoURL
    }
}


protocol ProfileServiceProtocol {
    func fetchProfile(uid: String) -> AnyPublisher<UserProfile, Error>
    func updateProfile(_ profile: UserProfile, operationDescription:String, shouldDeletePhotoURL: Bool) -> AnyPublisher<Void, Error>
//    func updateProfile(_ profile: UserProfile)
}

class FirestoreProfileService: ProfileServiceProtocol {
    
    private let db = Firestore.firestore()
    private var profileListener: ListenerRegistration?
    private let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
    private let alertManager: AlertManager = AlertManager.shared
    
    func fetchProfile(uid: String) -> AnyPublisher<UserProfile, Error> {
        
        profileListener?.remove()
        profileListener = nil
        
        let subject = PassthroughSubject<UserProfile, Error>()
        
        let docRef = db
            .collection("users")
            .document(uid)
            .collection("userProfileData")
            .document(uid)
        
        //docRef.addSnapshotListener(includeMetadataChanges: true)
        /// с includeMetadataChanges: true ты получишь два снапшота: один сразу (локальный), второй — когда сервер подтвердит. Без него — только первый, и ты не узнаешь, что данные дошли до сервера.
        /// snapshot.metadata.hasPendingWrites == true + snapshot.metadata.isFromCache == true - Локальная запись, оффлайн или ещё не синхронизирована
        /// snapshot.metadata.hasPendingWrites - В документе есть локальные изменения, которые ещё не подтверждены сервером.
        /// snapshot.metadata.isFromCache - Снапшот пришёл из локального кэша, а не напрямую с сервера
        /// docRef.addSnapshotListener(includeMetadataChanges: false) - я протестировал и с false при ошибки Missing or insufficient permissions. приходит откатной snapshot
        profileListener = docRef.addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                ///  когда мы будем удалять users/{uid} через cloud function
                ///  может отработать error ошибка прав доступа до того как будет вызван новый fetchProfile(uid: String) и profileListener?.remove()
                ///  !!! можно не отображать алерт в случае ошибки получения данных о пользователе так как у нас всегда есть retry
                ///  но отправлять данные в краш листикс
                self?.handleFirestoreError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
                return
            }
            
            ///В корректной работе Firestore snapshot == nil && error == nil — не должно быть(редко).
            ///Внутренние сбои SDK + Неверный путь (например, пустой uid)
            guard let snapshot = snapshot else {
                subject.send(completion: .failure(FirebaseInternalError.nilSnapshot))
                self?.handleFirestoreError(FirebaseInternalError.nilSnapshot, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
                return
            }
            
            do {
                if snapshot.exists {
                    let profile = try snapshot.data(as: UserProfile.self)
                    print("FirestoreProfileService Received objects: \(profile)")
                    subject.send(profile)
                } else {
                    // Документ отсутствует — отдаем пустую модель
                    subject.send(UserProfile(uid: uid))
                }
            } catch {
                subject.send(completion: .failure(error))
                self?.handleFirestoreError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
            }
            
        }
        
        return subject
            .eraseToAnyPublisher()
    }



    func updateProfile(_ profile: UserProfile, operationDescription: String, shouldDeletePhotoURL: Bool) -> AnyPublisher<Void, Error> {
            Future<Void, Error> { [weak self] promise in
                guard let self = self else { return }
                
                let docRef = self.db
                    .collection("users")
                    .document(profile.uid)
                    .collection("userProfileData")
                    .document(profile.uid)
                
                do {
                    var data = try Firestore.Encoder().encode(profile)
                    
                    // Нормализация: пустые строки → удаление полей в Firestore
                    if let name = profile.name, name.isEmpty {
                        data["name"] = FieldValue.delete()
                    }
                    if let lastName = profile.lastName, lastName.isEmpty {
                        data["lastName"] = FieldValue.delete()
                    }
                    // Явное удаление photoURL, если требуется
                    if shouldDeletePhotoURL {
                        data["photoURL"] = FieldValue.delete()
                    }
                    // Completion‑блок вызывается только после попытки синхронизации с сервером:
                    ///Если сеть появилась и сервер принял изменения → error == nil.
                    ///Если сервер отверг (например, из‑за security rules) → error будет с причиной отказа.
                    ///Если сети нет и SDK ещё не успел сделать попытку → блок просто не вызывается, пока не появится соединение.
                    ///Firestore не вызовет твой completion-блок до тех пор, пока не попробует (и фактически не завершит) синхронизацию с сервером.
                    ///Это значит, что ловить внутри completion ошибки вида NSURLErrorNotConnectedToInternet, timedOut и т.п. обычно бесполезно,
                    docRef.setData(data, merge: true) { [weak self] error in
                        if let error = error {
                            ///DispatchQueue.main.async { [weak self] in ???
                            self?.handleFirestoreError(error, operationDescription: operationDescription)
                            promise(.failure(error))
                        } else {
                            promise(.success(()))
                        }
                    }
                } catch {
                    ///DispatchQueue.main.async { [weak self] in ???
                    self.handleFirestoreError(error, operationDescription: operationDescription)
                    promise(.failure(error))
                }
            }
            .eraseToAnyPublisher()
        }
    
    private func handleFirestoreError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }
}




//    func updateProfile(_ profile: UserProfile) -> AnyPublisher<Void, Error> {
//        Future<Void, Error> { [weak self] promise in
//            guard let self = self else { return }
//
//            let docRef = self.db
//                .collection("users")
//                .document(profile.uid)
//                .collection("userProfileData")
//                .document(profile.uid)
//
//            do {
//                var data = try Firestore.Encoder().encode(profile)
//
//                // Нормализация: пустые строки → удаление полей в Firestore
//                if let name = profile.name, name.isEmpty {
//                    data["name"] = FieldValue.delete()
//                }
//                if let lastName = profile.lastName, lastName.isEmpty {
//                    data["lastName"] = FieldValue.delete()
//                }
//
//                docRef.setData(data, merge: true) { [weak self] error in
//                    if let error = error {
//                        // Определяем тип ошибки
//                        let nsError = error as NSError
//                        let code = nsError.code
//                        let domain = nsError.domain
//
//                        // Сетевые ошибки — не показываем алерт, просто логируем (нет сети setData работает в оффлайн )
//                        ///Ошибка в completion setData в оффлайне — это не всегда «фатал», а просто «на момент вызова сервер не ответил».
//                        ///в большинстве случаев при работе с docRef.setData Firestore вернёт ошибку с доменом FIRFirestoreErrorDomain
//                        ///Если проблема не в логике Firestore, а в транспортном уровне (нет интернета, таймаут, потеря соединения) то domain = NSURLErrorDomain
//                        ///.contains(code) — быстрый способ проверить, относится ли код к этим "мягким" ошибкам
//                        if domain == NSURLErrorDomain,
//                           [NSURLErrorNotConnectedToInternet,
//                            NSURLErrorTimedOut,
//                            NSURLErrorNetworkConnectionLost].contains(code) {
//                            print("⚠️ Firestore: нет сети или слабое соединение, изменения будут синхронизированы позже")
//                            promise(.success(()))
////                            promise(.failure(error)) // Можно вернуть failure, чтобы цепочка знала, что сервер не подтвердил
//                            return
//                        }
//
//                        // Остальные ошибки — показываем алерт
//                        ///DispatchQueue.main.async { [weak self] in ???
//                        self?.handleFirestoreError(error, operationDescription: "Error update profile")
//                        promise(.failure(error))
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//            } catch {
//                self.handleFirestoreError(error, operationDescription: "Encoding error update profile")
//                promise(.failure(error))
//            }
//        }
//        .eraseToAnyPublisher()
//    }

// btfore UserInfoEditManager
//    func updateProfile(_ profile: UserProfile) {
//        let docRef = db
//            .collection("users")
//            .document(profile.uid)
//            .collection("userProfileData")
//            .document(profile.uid)
//
//        do {
//            var data = try Firestore.Encoder().encode(profile)
//
//            if let name = profile.name, name.isEmpty {
//                data["name"] = FieldValue.delete()
//            }
//            if let lastName = profile.lastName, lastName.isEmpty {
//                data["lastName"] = FieldValue.delete()
//            }
//
//            docRef.setData(data, merge: true) { [weak self] error in
//                if let error {
//                    DispatchQueue.main.async {
//                        self?.handleFirestoreError(error, operationDescription: "Error update profile")
//                    }
//                }
//            }
//        } catch {
//            DispatchQueue.main.async { [weak self] in
//                self?.handleFirestoreError(error, operationDescription: "Encoding error update profile")
//            }
//        }
//    }




//    func updateProfile(_ profile: UserProfile) {
//        let docRef = db
//            .collection("users")
//            .document(profile.uid)
//            .collection("userProfileData")
//            .document(profile.uid)
//
//        do {
//            ///Если merge == false (по умолчанию), он перезаписывает весь документ
//            ///Когда ты указываешь merge: true, Firestore: Обновляет только те поля, которые есть в сериализованной модели
//            ///Сохраняет все остальные поля, которые уже были в документе + Не удаляет поля, которых нет в модели
//            ///merge: true = «обнови только указанные поля» → существующие данные не трогаются, а для удаления нужно явно поставить FieldValue.delete().
//            try docRef.setData(from: profile, merge: true) { [weak self] error in
//                guard let self else { return }
//                if let error = error {
//                    DispatchQueue.main.async {
//                        self.handleFirestoreError(error, operationDescription: "Error update profile")
//                    }
//                }
//                print("docRef.setData - \(String(describing: error))")
//                // Успех обрабатывать не требуется: Root-listener сам обновит UI.
//                // При оффлайне completion придёт позже, когда будет подтверждение сервера или ошибка.
//            }
//        } catch {
//            // Синхронная ошибка кодирования модели
//            DispatchQueue.main.async { [weak self] in
//                self?.handleFirestoreError(error, operationDescription: "Encoding error update profile")
//            }
//        }
//    }


// docRef.setData(from: profile, merge: true)


//func updateProfile(_ profile: UserProfile) {
//    let docRef = db
//        .collection("users")
//        .document(profile.uid)
//        .collection("userProfileData")
//        .document(profile.uid)
//    
//    do {
//        ///Если merge == false (по умолчанию), он перезаписывает весь документ
//        ///Когда ты указываешь merge: true, Firestore: Обновляет только те поля, которые есть в сериализованной модели
//        ///Сохраняет все остальные поля, которые уже были в документе + Не удаляет поля, которых нет в модели
//        ///merge: true = «обнови только указанные поля» → существующие данные не трогаются, а для удаления нужно явно поставить FieldValue.delete().
//        try docRef.setData(from: profile, merge: true) { [weak self] error in
//            guard let self else { return }
//            if let error = error {
//                DispatchQueue.main.async {
//                    self.handleFirestoreError(error, operationDescription: "Error update profile")
//                }
//            }
//            print("docRef.setData - \(String(describing: error))")
//            // Успех обрабатывать не требуется: Root-listener сам обновит UI.
//            // При оффлайне completion придёт позже, когда будет подтверждение сервера или ошибка.
//        }
//    } catch {
//        // Синхронная ошибка кодирования модели
//        DispatchQueue.main.async { [weak self] in
//            self?.handleFirestoreError(error, operationDescription: "Encoding error update profile")
//        }
//    }
//}



// MARK: - getDocument

//поведение getDocument в оффлайне
/// document(uid).getDocument(source: .cache) { ... }
/// getDocument ведёт себя по-разному в зависимости от source:
/// source: .cache — вернёт локальное состояние, включая незасинхроненные изменения.
/// source: .server — попытается получить с сервера; офлайн → ошибка, онлайн до синка → старые серверные данные.
/// source: .default — попробует сервер, при недоступности упадёт в кэш и вернёт локальные данные.
/// Firestore не “откатывает” локальный кэш, даже если синхронизация с сервером впоследствии провалилась.
//    func fetchProfile(uid: String) -> AnyPublisher<UserProfile, Error> {
//        Future { [weak self] promise in
//            self?.db
//                .collection("users")
//                .document(uid)
//                .collection("userProfileData")
//                .document(uid).getDocument { snapshot, error in
//                    if let error = error {
//                        promise(.failure(error))
//                        self?.handleFirestoreError(error, operationDescription: "Error fetch profile")
//                        return
//                    }
//
//                    do {
//                        if let snapshot = snapshot, snapshot.exists {
//                            let profile = try snapshot.data(as: UserProfile.self)
//                            promise(.success(profile))
//                        } else {
//                            // Чёткое разделение: документ есть, но пустой vs документ отсутствует
//                            promise(.success(UserProfile(uid: uid)))
//                        }
//                    } catch {
//                        promise(.failure(error)) // Чёткая ошибка декодирования
//                        self?.handleFirestoreError(error, operationDescription: "Error fetch profile")
//                    }
//                }
//        }.eraseToAnyPublisher()
//    }

//    private func loadUserProfile(uid: String) {
//
//        // 1. Отменяем предыдущую загрузку профиля
//        profileLoadCancellable?.cancel()
//        profileLoadingState = .loading
//
//        // 2. Создаем новую подписку
//        profileLoadCancellable = profileService.fetchProfile(uid: uid)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    switch completion {
//                    case .finished:
//                        self?.profileLoadingState = .idle
//                    case .failure(_):
//                        self?.profileLoadingState = .failure
//                    }
//                },
//                receiveValue: { [weak self] profile in
//                    print("loadUserProfile/receiveValue -  \(profile)")
//                    self?.userProfile = profile
//                }
//            )
//    }






// MARK: - trush

//    func updateProfile(_ profile: UserProfile) -> AnyPublisher<Void, Error> {
//        Future { [weak self] promise in
//            do {
//                try self?.db.collection("users").document(profile.uid).setData(from: profile) { error in
//                    if let error = error {
//                        promise(.failure(error))
//                        self?.handleFirestoreError(error, operationDescription: "Error update profile")
//                    } else {
//                        promise(.success(()))
//                    }
//                }
//            } catch {
//                promise(.failure(error))
//                self?.handleFirestoreError(error, operationDescription: "Error update profile")
//            }
//        }.eraseToAnyPublisher()
//    }


// before case .userInfoEdit(let profile):

//struct UserProfile: Codable {
//    let uid: String
//    var name: String?
//    var email: String?
//    var photoURL: URL?
//
//    init(uid: String, name: String? = nil, email: String? = nil, photoURL: URL? = nil) {
//        self.uid = uid
//        self.name = name
//        self.email = email
//        self.photoURL = photoURL
//    }
//}
