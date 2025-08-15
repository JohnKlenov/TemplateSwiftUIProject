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





import FirebaseFirestore
import Combine

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

struct UserProfile: Codable, Equatable, Hashable {
    let uid: String
    var name: String?
    var lastName: String?
    var photoURL: URL?

    init(uid: String, name: String? = nil, email: String? = nil, photoURL: URL? = nil) {
        self.uid = uid
        self.name = name
        self.lastName = email
        self.photoURL = photoURL
    }
}


protocol ProfileServiceProtocol {
    func fetchProfile(uid: String) -> AnyPublisher<UserProfile, Error>
    func updateProfile(_ profile: UserProfile) -> AnyPublisher<Void, Error>
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
            profileListener = docRef.addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    self.handleFirestoreError(error, operationDescription: "Error fetch profile")
                    return
                }

                ///В корректной работе Firestore snapshot == nil && error == nil — не должно быть(редко).
                ///Внутренние сбои SDK + Неверный путь (например, пустой uid)
                guard let snapshot = snapshot else {
                    subject.send(completion: .failure(FirebaseInternalError.nilSnapshot))
                    self.handleFirestoreError(FirebaseInternalError.nilSnapshot, operationDescription: "Error fetch profile")
                    return
                }

                do {
                    if snapshot.exists {
                        let profile = try snapshot.data(as: UserProfile.self)
                        subject.send(profile)
                    } else {
                        // Документ отсутствует — отдаем пустую модель
                        subject.send(UserProfile(uid: uid))
                    }
                } catch {
                    subject.send(completion: .failure(error))
                    self.handleFirestoreError(error, operationDescription: "Error fetch profile")
                }
                
            }

            return subject
                .eraseToAnyPublisher()
        }

    
    func updateProfile(_ profile: UserProfile) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            do {
                try self?.db.collection("users").document(profile.uid).setData(from: profile) { error in
                    if let error = error {
                        promise(.failure(error))
                        self?.handleFirestoreError(error, operationDescription: "Error update profile")
                    } else {
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
                self?.handleFirestoreError(error, operationDescription: "Error update profile")
            }
        }.eraseToAnyPublisher()
    }
    
    private func handleFirestoreError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }
}



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
