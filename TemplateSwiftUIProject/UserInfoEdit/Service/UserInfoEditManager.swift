//
//  UserInfoEditManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.25.
//



// MARK: - Pipeline (Пайплайн) func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<Void, Error>

/*
 Сценарии uploadAvatar(for:image:):
 1) Успех:
    - jpegData → OK
    - Storage upload → URL
    - Firestore update → success
    - Паблишер завершится .finished, без алертов

 2) Ошибка jpegData (не удалось сконвертировать UIImage в JPEG):
    - Паблишер сразу вернёт .failure(ProfileServiceError.imageEncodingFailed)
    - Alert НЕ показывается (ошибка до сервисов)

 3) Ошибка в Storage (putData или downloadURL):
    - StorageProfileService покажет алерт внутри handleStorageError(...)
    - Паблишер вернёт .failure(...)
    - Менеджер алерты не показывает

 4) Ошибка в Firestore (кодирование/запись):
    - FirestoreProfileService покажет алерт внутри handleFirestoreError(...)
    - Паблишер вернёт .failure(...)
    - Менеджер алерты не показывает
*/


/*
 Пошаговое выполнение uploadAvatar(for:image:) в текущей кодовой базе:

 1) storageService.uploadImageData(path:data:operationDescription:)
    - Запускает загрузку изображения в Firebase Storage.
    - При успехе:
         • Отправляет одно значение (URL) и завершает .finished.
         • → Во ViewModel: НЕ сработает receiveValue (у нас Void), пойдёт дальше в flatMap.
    - При ошибке:
         • Показывает глобальный алерт через handleStorageError(...) внутри StorageProfileService.
         • Отправляет .failure(...) в Combine-цепочку.
         • Цепочка завершается, flatMap не вызывается.
         • → Во ViewModel: сразу completion == .failure(error), receiveValue не вызывается.

 2) handleEvents(receiveOutput:)
    - Вызывается только при успешном URL от Storage.
    - Не изменяет поток, делает побочный эффект (лог "Avatar uploaded to Storage: ...").
    - → Во ViewModel: на этом шаге ещё нет событий, так как это не terminal-оператор.

 3) flatMap { url in ... }
    - Вызывается только если Storage прислал URL (ошибки не было).
    - Превращает URL в новый паблишер, который вызывает firestoreService.updateProfilePublisher(...).
    - → Во ViewModel: пока без изменений, ждём результат Firestore.

 4) firestoreService.updateProfilePublisher(...)
    - Пытается обновить профиль пользователя в Firestore с новым photoURL.
    - При успехе:
         • Возвращает .success(()).
         • → Во ViewModel: completion == .finished, receiveValue == Void.
    - При ошибке (кодирование или setData):
         • Показывает глобальный алерт через handleFirestoreError(...) внутри FirestoreProfileService.
         • Отправляет .failure(...) в Combine-цепочку.
         • → Во ViewModel: completion == .failure(error), receiveValue не вызывается.

 5) Итог для подписчика (ViewModel) по сценариям:
    - Успех Storage + успех Firestore:
         • completion == .finished
         • receiveValue == Void
    - Ошибка в Storage:
         • completion == .failure(error)
         • receiveValue не вызывается
    - Ошибка в Firestore:
         • completion == .failure(error)
         • receiveValue не вызывается
    - Ошибка jpegData (nil при конвертации UIImage → JPEG):
         • completion == .failure(ProfileServiceError.imageEncodingFailed)
         • receiveValue не вызывается
         • Алерта нет (ошибка до сервисов)

 6) Важное:
    - Даже если ViewModel будет деинициализирована (умрёт) раньше,
      StorageProfileService и FirestoreProfileService всё равно покажут алерты,
      т.к. handleError вызывается внутри них и они живут весь жизненный цикл приложения.
    - Менеджер UserInfoEditManager не вызывает handleError — он только связывает сервисы.
 */




// MARK: - Поведение Firebase SDK при плохом или отсутствующем интернете


/// 1. putData(data) — загрузка файла в Storage Если интернет отсутствует Firebase сразу вернёт ошибку в completion блоке.(NSURLErrorNotConnectedToInternet+ NSURLErrorTimedOut + NSURLErrorNetworkConnectionLost ) 
/// Если интернет есть, но очень плохой Загрузка может зависнуть, затем завершиться ошибкой по таймауту.

/// 2. downloadURL — получение ссылки после загрузки. если интернет пропал Получишь ошибку в блоке ref.downloadURL Работает ли downloadURL в оффлайне - нет!

/// 3. docRef.setData(data, merge: true) { ... } - Firestore сразу пишет эти данные в свой локальный оффлайн‑кэш. 
/// Если у тебя есть addSnapshotListener на этот же docRef: Он мгновенно получит новый DocumentSnapshot с обновлёнными данными. (snapshot.metadata будут флаги: hasPendingWrites == true — изменения ещё не подтверждены сервером. isFromCache == true — данные из локального кэша.)  Если сервер примет данные — hasPendingWrites станет false, listener снова сработает (но данные останутся те же). Если сервер отвергнет (например, из‑за правил безопасности) — тогда listener получит откат на предыдущие данные.
/// Completion блок setData вызывается только после попытки синхронизации с сервером. Если соединение есть и сервер подтвердил запись → error == nil. Если соединения нет или оно рвётся → error будет не nil (например, unavailable, NSURLErrorNotConnectedToInternet, timedOut).
///
///Если сети нет и SDK ещё не успел сделать попытку → блок просто не вызывается, пока не появится соединение.
///Это значит, что ловить внутри completion ошибки вида NSURLErrorNotConnectedToInternet, timedOut и т.п. обычно бесполезно,
///
/// мы решили что такой сценарий маловероятен так как при отсутствии сети блок не вызывается (тестировал на updateData)
/// блок вызывается только после получении данных из сети
/// Ошибка в completion setData в оффлайне — это не всегда «фатал», а просто «на момент вызова сервер не ответил».
/// Если ошибка явно «нет сети» или «таймаут» — не показывают алерт, а просто логируют/ставят флаг «синхронизация в ожидании».
/// Если ошибка — «permission denied» или «invalid argument» — показывают алерт и откатывают UI (потому что сервер точно не примет).

///
/// при вызове  docRef.setData в оффлайн:
/// блок не будет вызван до тех пор пока не появится сеть
/// handleFirestoreError не отработает
/// addSnapshotListener получит photoURL (локально).
/// SDWebImage попытается загрузить картинку — если сети нет, она не загрузится, но останется в кэше, и при появлении сети подгрузится(тут если у нас раньше была картинка до новой она пропадет и будет заполнена плэйсхолдером !!!!!  нужно отработать что бы в плэйсхолдере обозначалось что не удалось подгрузить из сети ).
///
/// Когда сеть появится и запись прошла успешно:
/// addSnapshotListener вернет новый snapshot и hasPendingWrites == false
/// SDWebImage загрузит картинку по новому URL.
///
///Когда сеть появится и запись не прошла:
///addSnapshotListener вернет новый snapshot с старым photoURL
///SDWebImage загрузит картинку по старом URL.
/// в этот момент отработает наш блок в docRef.setData(data, merge: true) { [weak self] error in .. } и мы увидим handleFirestoreError





// MARK: - В UI сразу обновляют данные (оптимистичный апдейт)

import Combine
import UIKit

final class UserInfoEditManager {

    enum State: Equatable {
        case idle
        case loading
        case avatarUploadSuccess(url: URL)
        case avatarDeleteSuccess
        case avatarUploadFailure
        case avatarDeleteFailure

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle),
                 (.loading, .loading),
                 (.avatarDeleteSuccess, .avatarDeleteSuccess),
                 (.avatarUploadFailure, .avatarUploadFailure),
                 (.avatarDeleteFailure, .avatarDeleteFailure):
                return true
            case (.avatarUploadSuccess(let lURL), .avatarUploadSuccess(let rURL)):
                return lURL == rURL
            default:
                return false
            }
        }
    }

    
    private let firestoreService: ProfileServiceProtocol
    private let storageService: StorageProfileServiceProtocol
    private let alertManager:AlertManager
    private let errorHandler: ErrorHandlerProtocol
    
    private var avatarUploadCancellable: AnyCancellable?
    private var avatarDeleteCancellable: AnyCancellable?
    
    @Published var state: State = .idle
    
    init(firestoreService: ProfileServiceProtocol,
         storageService: StorageProfileServiceProtocol, errorHandler: ErrorHandlerProtocol, alertManager: AlertManager = AlertManager.shared) {
        self.firestoreService = firestoreService
        self.storageService = storageService
        self.errorHandler = errorHandler
        self.alertManager = alertManager
    }
    
    // Загружает аватар в Storage и обновляет профиль в Firestore
    private func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<URL, Error> {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            handleError(FirebaseInternalError.imageEncodingFailed, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
            return Fail(error: FirebaseInternalError.imageEncodingFailed)
                .eraseToAnyPublisher()
        }
        
        // Генерируем уникальное имя файла с timestamp
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "avatar_\(timestamp).jpg"
        let path = "avatars/\(uid)/\(fileName)"
        
        return storageService.uploadImageData(path: path, data: data, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
            .flatMap { [weak self] url -> AnyPublisher<URL, Error> in
                guard let self = self else {
                    return Fail(error: FirebaseInternalError.nilSnapshot).eraseToAnyPublisher()
                }
                let profile = UserProfile(uid: uid, photoURL: url)
                return self.firestoreService.updateProfile(profile, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage, shouldDeletePhotoURL: false)
                    .map { url } // возвращаем URL после успешного обновления
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func uploadAvatarAndTrack(for uid: String, image: UIImage) {
        state = .loading
        avatarUploadCancellable?.cancel() // отменяем предыдущую загрузку
        
        avatarUploadCancellable = uploadAvatar(for: uid, image: image)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                
                if case .failure(_) = completion {
                    self?.state = .avatarUploadFailure
                }
            } receiveValue: { [weak self] newURL in
                self?.state = .avatarUploadSuccess(url: newURL)// сохраняем новый URL
            }
    }


    private func deleteAvatar(for uid: String, photoURL: URL, operationDescription: String) -> AnyPublisher<Void, Error> {
        return storageService.deleteImage(at: photoURL, operationDescription: operationDescription)
            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
                guard let self else {
                    return Empty(completeImmediately: true).eraseToAnyPublisher()
                }
                let profile = UserProfile(uid: uid, photoURL: nil)
                return self.firestoreService.updateProfile(profile, operationDescription: operationDescription, shouldDeletePhotoURL: true)
            }
            .eraseToAnyPublisher()
    }

    func deleteAvatarAndTrack(for uid: String, photoURL: URL, operationDescription: String) {
        state = .loading
        avatarDeleteCancellable?.cancel()
        
        avatarDeleteCancellable = deleteAvatar(for: uid, photoURL: photoURL, operationDescription: operationDescription)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(_) = completion {
                    self?.state = .avatarDeleteFailure
                }
            } receiveValue: { [weak self] in
                self?.state = .avatarDeleteSuccess
            }
    }


    
    /*
     🔍 Почему утечки памяти не будет при вызове без .store(in:)

    Future в методе updateProfile — однократный Combine-паблишер, который начинает выполнение сразу при подписке.
    sink создаёт объект AnyCancellable, но мы его не сохраняем (используем _ =), значит он живёт только в текущем стеке вызова.
    Когда AnyCancellable уничтожается (почти сразу после выхода из этого места), Combine вызывает у него .cancel().

    ⚠️ Важный момент: отмена Combine-подписки НЕ отменяет сам вызов setData во Firebase SDK.
    Firebase продолжит выполнение операции до конца, независимо от Combine.
    После завершения setData, Promise внутри Future выполнится, но результат просто никуда не отправится (подписчик уже уничтожен).

    🧠 Объекты не удерживаются циклически — self используется с [weak self], поэтому retain cycle невозможен.

    ✅ Резюме: выполняется «fire-and-forget», памяти не течёт, операция в Firebase гарантированно завершится.

    📌 Что делает .store(in: &cancellables)
    .store(in:) сохраняет AnyCancellable в коллекцию (Set<AnyCancellable>), чтобы подписка жила ровно столько, сколько живёт владелец коллекции.
    Пока подписка хранится в cancellables — Combine не вызовет .cancel(), и Publisher продолжит выдавать события.
    Как только владелец (например, ViewModel) деинициализируется, Set уничтожается, и все подписки в нём автоматически отменяются.
    */
    func updateProfile(_ profile: UserProfile, operationDescription: String, shouldDeletePhotoURL:Bool) {
        _ = firestoreService.updateProfile(profile, operationDescription: operationDescription, shouldDeletePhotoURL: shouldDeletePhotoURL)
            .sink(receiveCompletion: { _ in }, receiveValue: { })
    }
    
    func handleError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }
}







//enum ProfileServiceError: Error {
//    case imageEncodingFailed
//}



//    enum State: Equatable {
//        case idle
//        case loading
//        case success(url: URL)
//        case failure
//
//        static func == (lhs: State, rhs: State) -> Bool {
//            switch (lhs, rhs) {
//            case (.idle, .idle),
//                 (.loading, .loading),
//                 (.failure, .failure):
//                return true
//            case (.success(let lURL), .success(let rURL)):
//                return lURL == rURL
//            default:
//                return false
//            }
//        }
//    }

///полезен в отладке, но в продакшене лучше заменить на логгер или удалить.
//            .handleEvents(receiveOutput: { url in
//                print("✅ Avatar uploaded to Storage: \(url)")
//            })


//        let path = "avatars/\(uid)/\(uid).jpg"

//    func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<Void, Error> {
//        // 1. Сжатие изображения
//        guard let data = image.jpegData(compressionQuality: 0.8) else {
//            handleError(FirebaseInternalError.imageEncodingFailed, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//            return Fail(error: FirebaseInternalError.imageEncodingFailed)
//                .eraseToAnyPublisher()
//        }
//
//        // 2. Путь и заголовки операций (ключи/тексты для алертов в сервисах)
//        let path = "avatars/\(uid)/\(uid).jpg"
//
//        // 3. Цепочка: Storage → Firestore
//        return storageService.uploadImageData(path: path, data: data, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//        ///полезен в отладке, но в продакшене лучше заменить на логгер или удалить.
//            .handleEvents(receiveOutput: { url in
//                print("✅ Avatar uploaded to Storage: \(url)")
//            })
//            .flatMap { [weak self] url -> AnyPublisher<Void, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseInternalError.nilSnapshot).eraseToAnyPublisher()
//                }
//                let profile = UserProfile(uid: uid, photoURL: url)
//                return self.firestoreService.updateProfile(profile, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage, shouldDeletePhotoURL: false)
//            }
//            .eraseToAnyPublisher()
//    }
    
