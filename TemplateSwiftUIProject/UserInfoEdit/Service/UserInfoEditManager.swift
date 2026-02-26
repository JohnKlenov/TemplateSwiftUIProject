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



// MARK: - пайплайн и таймаут

//func uploadAvatarAndTrack
/// 📌 Поведение при timeout и повторных вызовах:
/// - Если .timeout сработал, Combine-пайплайн завершается и Firestore update не вызовется,
///   даже если позже Firebase SDK вернёт promise(.success).
/// - Старый Future всё равно завершится внутри SDK, но результат будет проигнорирован,
///   так как подписчик уже отменён.
/// - Новый вызов uploadAvatarAndTrack создаёт независимый пайплайн и свой Future,
///   старый результат на него не повлияет.
/// - Единственный риск пересечения — если два аплоада пишут в один и тот же путь в Storage,
///   тогда последний аплоад перезапишет файл. В твоём случае пути генерируются рандомно,
///   поэтому гонки между аплоадами исключены.

//func handleError(_ error: Error, operationDescription:String)
///На продакшене действительно стараются централизовать обработку ошибок в одном месте
///Сервисы (StorageProfileService, FirestoreProfileService) должны быть максимально «чистыми» и возвращать только Publisher<Output, Error>.
///UserInfoEditManager — это уровень бизнес‑логики/оркестрации. Именно он решает, как реагировать на ошибки
///Если оставить вызовы handleError в сервисах, то при сложных сценариях (например, timeout + поздний ответ SDK) действительно может показаться пользователю, что «ошибка сыпется дважды».




// MARK: - comment methods

//func uploadAvatar

/// Загружает аватар в Storage и обновляет профиль в Firestore
/// нужно понимать что в нашем случае если при смене аватар дело дошло до firestoreService.updateProfile но подвисло от плохой сети то в addSnapshotListener сразу отрабаотает локальный кэш и видимо раз сеть плохая тоже не сможет получить картинку в SDWebimage сразу - но этот сценарий маловероятный так как firestoreService.updateProfile требует мало времени даже при млохой сети! а вот storageService.uploadImageData может при плохой сети зависнуть на долго если картинка большая но в нашем случае мы ее сжимае поэтому тут тоже скорость ответа должна быть бустрее!
/// Плюс Firestore применяет optimistic update: локальный кэш обновляется мгновенно, слушатели (addSnapshotListener) срабатывают сразу. Поэтому «подвиснуть» здесь почти нереально. Единственный случай — если сеть полностью отсутствует, тогда completion не вызовется до появления соединения.
///
///
/// ❗️Почему мы можем добавить `.timeout(...)` ПОКА ОСТАВЛЯЕМ КАК ЕСТЬ:
/// но методы Firebase SDK это не остановит а лишь прирвет пэйплайн Combine. (setData сразу обновляет локальный кэш, слушатели (addSnapshotListener) мгновенно видят изменения, даже если сервер ещё не подтвердил - по этому если мы прирываем пэйплайн нам нужно что бы addSnapshotListener не реагировал до тех пор пока не придет подтверждение от сервера.)
/// то есть если сработает timeout в combine и после это в адлистенер придет snapshot.metadata.hasPendingWrites == false выходит мы пользователю покажем ошибку что не получилось а потом он возьми и обновись? это ведь не нормально как такое решают на продакшене?
/// Да, твой сценарий возможен. На продакшене это решают либо жёсткой фильтрацией по hasPendingWrites (UI ждёт только подтверждённые данные), либо смягчением UX (ошибка = «не удалось подтвердить», но optimistic‑update остаётся).
/// По умолчанию Firebase SDK может ждать ответа от сервера очень долго (минуты),
/// если сеть нестабильна или соединение зависло. Это создаёт плохой UX — пользователь
/// видит «вечную загрузку» и не понимает, что происходит.
///
/// Используя `.timeout(.seconds(15))`, мы ограничиваем общее время ожидания операции
/// (Storage + Firestore). Если за 15 секунд ответ не пришёл, Combine прерывает цепочку
/// и возвращает контролируемую ошибку `FirebaseInternalError.timeout`.
/// Это позволяет:
/// - показать пользователю понятное сообщение («Сеть нестабильна, попробуйте ещё раз»);
/// - избежать бесконечного ожидания;
/// - сохранить предсказуемость поведения приложения.


//jpegData(compressionQuality:)

///Эта функция может вернуть nil, если изображение не содержит данных или если базовый объект CGImageRef содержит данные в неподдерживаемом растровом формате.
///Преобразует UIImage в JPEG-формат. Сжимает изображение с заданным коэффициентом от 0.0 (максимальное сжатие, худшее качество) до 1.0 (минимальное сжатие, лучшее качество).
///снижение размера на 20–40%, но не в 2–3 раза, если исходник уже JPEG.


//func updateProfile

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






//func uploadAvatarAndTrack(for uid: String, image: UIImage)

/// Загружает аватар и отслеживает результат.
///
/// Поведение по шагам:
/// 1. Проверка `guard uid == currentUID` в начале метода:
///    - гарантирует, что мы не начнём загрузку для "устаревшего" пользователя,
///      если в момент вызова уже произошла смена аккаунта.
///    - если uid не совпадает с текущим авторизованным пользователем, метод сразу выходит.
///
/// 2. `.timeout(.seconds(15))`:
///    - если операция (Storage + Firestore) не завершится за 15 секунд,
///      пайплайн прервётся и в `.sink` придёт `.failure(FirebaseInternalError.delayedConfirmation)`.
///    - эта ошибка будет передана в `handleError(error, ...)`, и пользователь увидит мягкое сообщение
///      о задержке подтверждения.
///
/// 3. Проверка `guard uid == self.currentUID` внутри `.sink` (и в `receiveValue`):
///    - защищает от ситуации, когда один пользователь вышел, а другой вошёл,
///      но старый пайплайн всё ещё завершился и пытается обновить state.
///    - если uid не совпадает с текущим, результат игнорируется.
///
/// Таким образом, мы защищаемся от "протечек" событий между пользователями и
/// показываем корректные ошибки/статусы только для актуального пользователя.






// MARK: - Test



// 4. проверка работы observeUserChanges() - следим за print("🔄 User changed: \(String(describing: self.currentUID)) → \(String(describing: newUID))") при первом старте и когда мы сделаем сигнаут(перед тем как делать сигнаут вызовем func uploadAvatarAndTrack с реализацией в func uploadAvatar - когда отработает observeUserChanges() таймер уже будет не активен и мы не увидем алерт через 15 секунд) + отработает ошибка на profileListener так как нарушаться права на мгновение.

// 5. profileService.fetchProfile(uid: uid) не дергает алерт через хендлер в profileService. по хорошему создать отдельный менеджеор для этого. Подумать о том что при удалении будет отрабатывать ошибка в листенере так как правиола уже не позволяюьт чтение! Можно просто вернуть в profileService для этого метода хэндлер! 

// деплой тест + переходим к методу удаления аккаунта

// MARK: - UserInfoEditManager (централизованная обработка ошибок)


import Combine
import UIKit

/// Менеджер для операций редактирования информации о пользователе (аватар, профиль).
/// Использует Combine для реактивного управления состоянием и асинхронными операциями.
final class UserInfoEditManager {
    // MARK: - State
    enum State: Equatable {
        case idle
        case loading
        case avatarUploadSuccess(url: URL)
        case avatarDeleteSuccess
        case avatarUploadFailure
        case avatarDeleteFailure
    }
    
    @Published private(set) var state: State = .idle
    
    // MARK: - Dependencies
    private let firestoreService: ProfileServiceProtocol
    private let storageService: StorageProfileServiceProtocol
    private let errorHandler: ErrorHandlerProtocol
    private let alertManager: AlertManager
    private let userProvider: CurrentUserProvider
    
    // MARK: - Combine
    private var avatarUploadCancellable: AnyCancellable?
    private var avatarDeleteUrlCancellable: AnyCancellable?
    private var updateProfileCancellable: AnyCancellable?
    private var userListenerCancellable: AnyCancellable?
    
    private var currentUID: String?
    
    init(firestoreService: ProfileServiceProtocol,
         storageService: StorageProfileServiceProtocol,
         errorHandler: ErrorHandlerProtocol,
         userProvider: CurrentUserProvider,
         alertManager: AlertManager = .shared) {
        self.firestoreService = firestoreService
        self.storageService = storageService
        self.errorHandler = errorHandler
        self.alertManager = alertManager
        self.userProvider = userProvider
        
        observeUserChanges()
        
    }
    
    
    private func observeUserChanges() {
        userListenerCancellable = userProvider.currentUserPublisher
            .sink { [weak self] authUser in
                guard let self = self else { return }
                let newUID = authUser?.uid
                if self.currentUID != newUID {
                    print("🔄 UserInfoEditManager получил нового пользователя: \(String(describing: self.currentUID)) → \(String(describing: newUID))")
                    self.state = .idle
                    self.avatarUploadCancellable?.cancel()
                    self.updateProfileCancellable?.cancel()
                    self.avatarDeleteUrlCancellable?.cancel()
                    self.currentUID = newUID
                }
            }
    }
    
    // MARK: - Upload Avatar
    
    func uploadAvatarAndTrack(for uid: String, image: UIImage) {
        guard uid == currentUID else {
            self.handleError(FirebaseInternalError.staleUserSession, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
            return
        }
        transition(to: .loading, autoReset: false)
        avatarUploadCancellable?.cancel()
        
        avatarUploadCancellable = uploadAvatar(for: uid, image: image)
            .timeout(.seconds(15), scheduler: DispatchQueue.main, customError: {
                FirebaseInternalError.delayedConfirmation
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self, uid == self.currentUID else { return }
                if case .failure(let error) = completion {
                    self.handleError(error,
                                     operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
                    self.transition(to: .avatarUploadFailure)
                }
            } receiveValue: { [weak self] newURL in
                guard let self = self, uid == self.currentUID else { return }
                self.transition(to: .avatarUploadSuccess(url: newURL))
            }
    }

    
    private func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<URL, Error> {
//        return Fail<URL, Error>(error: FirebaseInternalError.imageEncodingFailed)
//            .delay(for: .seconds(16), scheduler: DispatchQueue.main)
//            .eraseToAnyPublisher()
        guard let resizedImage = image.resizedMaintainingAspectRatio(toFit: 600),
              let data = resizedImage.jpegData(compressionQuality: 0.8) else {
            return Fail(error: FirebaseInternalError.imageEncodingFailed)
                .eraseToAnyPublisher()
        }
        
        // Генерируем уникальное имя файла с timestamp
        let path = String.avatarPath(for: uid)
        
        return storageService.uploadImageData(path: path,
                                              data: data)
        .flatMap { [weak self] url -> AnyPublisher<URL, Error> in
            guard let self = self else {
                return Fail(error: FirebaseInternalError.nilSnapshot).eraseToAnyPublisher()
            }
            let profile = UserProfile(uid: uid, photoURL: url)
            return self.firestoreService.updateProfile(profile,
                                                       shouldDeletePhotoURL: false)
            .map { url }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Delete Avatar
    
    // сначало удаляем url а потом image в Storage (если удаление в Storage не прошло чистим через Cloud Function)
    func deleteAvatarAndTrack(for uid: String, photoURL: URL) {
        
        guard uid == currentUID else {
            self.handleError(FirebaseInternalError.staleUserSession, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
            return
        }
        transition(to: .loading, autoReset: false)
        avatarDeleteUrlCancellable?.cancel()
        
        let profile = UserProfile(uid: uid, photoURL: nil)
        
        avatarDeleteUrlCancellable = firestoreService
            .updateProfile(profile,
                           shouldDeletePhotoURL: true)
            .handleEvents(receiveOutput: { [weak self] _ in
                // Fire‑and‑forget удаление из Storage
                self?.storageService.deleteImage(at: photoURL)
            })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self, uid == self.currentUID else { return }
                if case .failure(let error) = completion {
                    self.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.deletingProfileAvatar)
                    self.transition(to: .avatarDeleteFailure)
                }
            } receiveValue: { [weak self] in
                guard let self = self, uid == self.currentUID else { return }
                self.transition(to: .avatarDeleteSuccess)
            }
    }
    
    func updateProfile(for uid: String, profile: UserProfile) {
        
        guard uid == currentUID else {
            self.handleError(FirebaseInternalError.staleUserSession, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
            return
        }
        updateProfileCancellable?.cancel()
        
        updateProfileCancellable = firestoreService
            .updateProfile(profile, shouldDeletePhotoURL: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self, uid == self.currentUID else { return }
                if case .failure(let error) = completion {
                    self.handleError(error,
                                     operationDescription: Localized.TitleOfFailedOperationFirebase.editingProfileFields)
                }
            } receiveValue: { _ in
                // Пока ничего не делаем при успехе
            }
    }

    
    // MARK: - Helpers
    
    private func transition(to newState: State, autoReset: Bool = true) {
        state = newState
        if autoReset, newState != .idle, newState != .loading {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.state = .idle
            }
        }
    }
    
    func handleError(_ error: Error, operationDescription: String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage,
                                     operationDescription: operationDescription,
                                     alertType: .ok)
    }
}



// MARK: - Before refactoring AuthorizationService (DI FirebaseAuthUserProvider)



//private func observeUserChanges() {
//    userListenerCancellable = userProvider.currentUserPublisher
//        .sink { [weak self] newUID in
//            guard let self = self else { return }
//            if self.currentUID != newUID {
//                print("🔄 User changed: \(String(describing: self.currentUID)) → \(String(describing: newUID))")
//                self.state = .idle
//                self.avatarUploadCancellable?.cancel()
//                self.updateProfileCancellable?.cancel()
//                self.avatarDeleteUrlCancellable?.cancel()
//                self.currentUID = newUID
//            }
//        }
//}




//    func uploadAvatarAndTrack(for uid: String, image: UIImage) {
//        guard uid == currentUID else {
//            print("⚠️ Игнорируем uploadAvatar: uid не совпадает с текущим пользователем")
//            return
//        }
//        transition(to: .loading, autoReset: false)
//        avatarUploadCancellable?.cancel()
//
//        avatarUploadCancellable = uploadAvatar(for: uid, image: image)
//            // ⏱ Ограничиваем общее время ожидания
//            .timeout(.seconds(15), scheduler: DispatchQueue.main, customError: {
//                FirebaseInternalError.delayedConfirmation
//            })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                guard let self = self, uid == self.currentUID else { return }
//                switch completion {
//                case .failure(let error):
//                    self.handleError(error,
//                                     operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//                    self.transition(to: .avatarUploadFailure)
//                    if let internalError = error as? FirebaseInternalError,
//                       internalError == .delayedConfirmation {
//                        // Мягкий статус: загрузка ушла, но подтверждение задерживается
//                        self.transition(to: .avatarUploadDelayedConfirmation)
//                    } else {
//                        self.handleError(error,
//                                         operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//                        self.transition(to: .avatarUploadFailure)
//                    }
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] newURL in
//                guard let self = self, uid == self.currentUID else { return }
//                self.transition(to: .avatarUploadSuccess(url: newURL))
//            }
//    }

// MARK: - before центрозовынной обработки ошибок в UserInfoEditManager


//import Combine
//import UIKit
//
//final class UserInfoEditManager {
//
//    enum State: Equatable {
//        case idle
//        case loading
//        case avatarUploadSuccess(url: URL)
//        case avatarDeleteSuccess
//        case avatarUploadFailure
//        case avatarDeleteFailure
//
//        static func == (lhs: State, rhs: State) -> Bool {
//            switch (lhs, rhs) {
//            case (.idle, .idle),
//                 (.loading, .loading),
//                 (.avatarDeleteSuccess, .avatarDeleteSuccess),
//                 (.avatarUploadFailure, .avatarUploadFailure),
//                 (.avatarDeleteFailure, .avatarDeleteFailure):
//                return true
//            case (.avatarUploadSuccess(let lURL), .avatarUploadSuccess(let rURL)):
//                return lURL == rURL
//            default:
//                return false
//            }
//        }
//    }
//
//    
//    private let firestoreService: ProfileServiceProtocol
//    private let storageService: StorageProfileServiceProtocol
//    private let alertManager:AlertManager
//    private let errorHandler: ErrorHandlerProtocol
//    
//    private var avatarUploadCancellable: AnyCancellable?
//    private var avatarDeleteUrlCancellable: AnyCancellable?
//    
//    @Published var state: State = .idle
//    
//    init(firestoreService: ProfileServiceProtocol,
//         storageService: StorageProfileServiceProtocol, errorHandler: ErrorHandlerProtocol, alertManager: AlertManager = AlertManager.shared) {
//        self.firestoreService = firestoreService
//        self.storageService = storageService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//    }
//    
//    
//    private func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<URL, Error> {
//        
//        guard let resizedImage = image.resizedMaintainingAspectRatio(toFit: 600), let data = resizedImage.jpegData(compressionQuality: 0.8) else {
//            handleError(FirebaseInternalError.imageEncodingFailed, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//            return Fail(error: FirebaseInternalError.imageEncodingFailed)
//                .eraseToAnyPublisher()
//        }
//        
//        // Генерируем уникальное имя файла с timestamp
//        let path = String.avatarPath(for: uid)
//        
//        return storageService.uploadImageData(path: path, data: data, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//            .flatMap { [weak self] url -> AnyPublisher<URL, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseInternalError.nilSnapshot).eraseToAnyPublisher()
//                }
//                // может есть смысл ставить тайм аут если сеть очень плохая?
//                let profile = UserProfile(uid: uid, photoURL: url)
//                return self.firestoreService.updateProfile(profile, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage, shouldDeletePhotoURL: false)
//                    .map { url } // возвращаем URL после успешного обновления
//                    .eraseToAnyPublisher()
//            }
//            .eraseToAnyPublisher()
//    }
//
//    
//    func uploadAvatarAndTrack(for uid: String, image: UIImage) {
//        state = .loading
//        avatarUploadCancellable?.cancel() // отменяем предыдущую загрузку
//        
//        avatarUploadCancellable = uploadAvatar(for: uid, image: image)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                
//                if case .failure(_) = completion {
//                    self?.state = .avatarUploadFailure
//                }
//            } receiveValue: { [weak self] newURL in
//                self?.state = .avatarUploadSuccess(url: newURL)// сохраняем новый URL
//            }
//    }
//
//    // сначало удаляем url а потом image в Storage (если удаление в Storage не прошло чистим через Cloud Function)
//    func deleteAvatarAndTrack(for uid: String, photoURL: URL, operationDescription: String) {
//        state = .loading
//        avatarDeleteUrlCancellable?.cancel()
//        
//        let profile = UserProfile(uid: uid, photoURL: nil)
//        
//        avatarDeleteUrlCancellable = firestoreService
//            .updateProfile(profile,
//                           operationDescription: operationDescription,
//                           shouldDeletePhotoURL: true)
//            .handleEvents(receiveOutput: { [weak self] _ in
//                // Fire‑and‑forget удаление из Storage
//                self?.storageService.deleteImage(at: photoURL)
//            })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                if case .failure = completion {
//                    self?.state = .avatarDeleteFailure
//                }
//            } receiveValue: { [weak self] in
//                self?.state = .avatarDeleteSuccess
//            }
//    }
//
//    func updateProfile(_ profile: UserProfile, operationDescription: String, shouldDeletePhotoURL:Bool) {
//        _ = firestoreService.updateProfile(profile, operationDescription: operationDescription, shouldDeletePhotoURL: shouldDeletePhotoURL)
//            .sink(receiveCompletion: { _ in }, receiveValue: { })
//    }
//    
//    func handleError(_ error: Error, operationDescription:String) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
//    }
//}






// MARK: - Test




//import FirebaseAuth
//import Combine
//
//final class FirebaseAuthUserProvider: CurrentUserProvider {
//    private let subject = CurrentValueSubject<String?, Never>(nil)
//    private var handle: AuthStateDidChangeListenerHandle?
//    
//    init() {
//        handle = Auth.auth().addStateDidChangeListener { _, user in
//            self.subject.send(user?.uid)
//        }
//    }
//    
//    deinit {
//        if let handle = handle {
//            Auth.auth().removeStateDidChangeListener(handle)
//        }
//    }
//    
//    var currentUserPublisher: AnyPublisher<String?, Never> {
//        subject.eraseToAnyPublisher()
//    }
//}



//import Combine
//import UIKit
//
///// Менеджер для операций редактирования информации о пользователе (аватар, профиль).
///// Использует Combine для реактивного управления состоянием и асинхронными операциями.
//final class UserInfoEditManager {
//    // MARK: - State
//    enum State: Equatable {
//        case idle
//        case loading
//        case avatarUploadSuccess(url: URL)
//        case avatarDeleteSuccess
//        case avatarUploadFailure
//        case avatarDeleteFailure
//        case avatarUploadDelayedConfirmation   // мягкий статус при таймауте
//    }
//    
//    @Published private(set) var state: State = .idle
//    
//    // MARK: - Dependencies
//    private let firestoreService: ProfileServiceProtocol
//    private let storageService: StorageProfileServiceProtocol
//    private let errorHandler: ErrorHandlerProtocol
//    private let alertManager: AlertManager
//    private let userProvider: CurrentUserProvider
//    
//    // MARK: - Combine
//    private var avatarUploadCancellable: AnyCancellable?
//    private var avatarDeleteUrlCancellable: AnyCancellable?
//    private var userListenerCancellable: AnyCancellable?
//    
//    private var currentUID: String?
//    
//    init(firestoreService: ProfileServiceProtocol,
//         storageService: StorageProfileServiceProtocol,
//         errorHandler: ErrorHandlerProtocol,
//         userProvider: CurrentUserProvider,
//         alertManager: AlertManager = .shared) {
//        self.firestoreService = firestoreService
//        self.storageService = storageService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        self.userProvider = userProvider
//        
//        observeUserChanges()
//    }
//    
//    private func observeUserChanges() {
//        userListenerCancellable = userProvider.currentUserPublisher
//            .sink { [weak self] newUID in
//                guard let self = self else { return }
//                if self.currentUID != newUID {
//                    print("🔄 User changed: \(String(describing: self.currentUID)) → \(String(describing: newUID))")
//                    self.state = .idle
//                    self.avatarUploadCancellable?.cancel()
//                    self.avatarDeleteUrlCancellable?.cancel()
//                    self.currentUID = newUID
//                }
//            }
//    }
//    
//    // MARK: - Upload Avatar
//    
//    func uploadAvatarAndTrack(for uid: String, image: UIImage) {
//        guard uid == currentUID else {
//            print("⚠️ Игнорируем uploadAvatar: uid не совпадает с текущим пользователем")
//            return
//        }
//        transition(to: .loading, autoReset: false)
//        avatarUploadCancellable?.cancel()
//        
//        avatarUploadCancellable = uploadAvatar(for: uid, image: image)
//            // ⏱ Ограничиваем общее время ожидания
//            .timeout(.seconds(15), scheduler: DispatchQueue.main, customError: {
//                FirebaseInternalError.delayedConfirmation
//            })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                guard let self = self, uid == self.currentUID else { return }
//                switch completion {
//                case .failure(let error):
//                    if let internalError = error as? FirebaseInternalError,
//                       internalError == .delayedConfirmation {
//                        // Мягкий статус: загрузка ушла, но подтверждение задерживается
//                        self.transition(to: .avatarUploadDelayedConfirmation)
//                    } else {
//                        self.transition(to: .avatarUploadFailure)
//                    }
//                case .finished:
//                    break
//                }
//            } receiveValue: { [weak self] newURL in
//                guard let self = self, uid == self.currentUID else { return }
//                self.transition(to: .avatarUploadSuccess(url: newURL))
//            }
//    }
//    
//    private func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<URL, Error> {
//        guard let resizedImage = image.resizedMaintainingAspectRatio(toFit: 600),
//              let data = resizedImage.jpegData(compressionQuality: 0.8) else {
//            handleError(FirebaseInternalError.imageEncodingFailed,
//                        operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//            return Fail(error: FirebaseInternalError.imageEncodingFailed)
//                .eraseToAnyPublisher()
//        }
//        
//        let path = String.avatarPath(for: uid)
//        
//        return storageService.uploadImageData(path: path,
//                                              data: data,
//                                              operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//            .flatMap { [weak self] url -> AnyPublisher<URL, Error> in
//                guard let self = self else {
//                    return Fail(error: FirebaseInternalError.nilSnapshot).eraseToAnyPublisher()
//                }
//                let profile = UserProfile(uid: uid, photoURL: url)
//                return self.firestoreService.updateProfile(profile,
//                                                           operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage,
//                                                           shouldDeletePhotoURL: false)
//                    .map { url }
//                    .eraseToAnyPublisher()
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    // MARK: - Delete Avatar
//    
//    func deleteAvatarAndTrack(for uid: String, photoURL: URL, operationDescription: String) {
//        guard uid == currentUID else {
//            print("⚠️ Игнорируем deleteAvatar: uid не совпадает с текущим пользователем")
//            return
//        }
//        transition(to: .loading, autoReset: false)
//        avatarDeleteUrlCancellable?.cancel()
//        
//        let profile = UserProfile(uid: uid, photoURL: nil)
//        
//        avatarDeleteUrlCancellable = firestoreService
//            .updateProfile(profile,
//                           operationDescription: operationDescription,
//                           shouldDeletePhotoURL: true)
//            .handleEvents(receiveOutput: { [weak self] _ in
//                self?.storageService.deleteImage(at: photoURL)
//            })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                guard let self = self, uid == self.currentUID else { return }
//                if case .failure = completion {
//                    self.transition(to: .avatarDeleteFailure)
//                }
//            } receiveValue: { [weak self] in
//                guard let self = self, uid == self.currentUID else { return }
//                self.transition(to: .avatarDeleteSuccess)
//            }
//    }
//    
//    // MARK: - Helpers
//    
//    private func transition(to newState: State, autoReset: Bool = true) {
//        state = newState
//        if autoReset, newState != .idle, newState != .loading {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//                self?.state = .idle
//            }
//        }
//    }
//    
//    private func handleError(_ error: Error, operationDescription: String) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage,
//                                     operationDescription: operationDescription,
//                                     alertType: .ok)
//    }
//}
//














//        let timestamp = Int(Date().timeIntervalSince1970)
//        let fileName = "avatar_\(timestamp).jpg"
//        let path = "avatars/\(uid)/\(fileName)"

//    func deleteAvatarAndTrack(for uid: String, photoURL: URL, operationDescription: String) {
//        state = .loading
//        avatarDeleteUrlCancellable?.cancel()
//        avatarDeleteStorageCancellable?.cancel()
//
//        let profile = UserProfile(uid: uid, photoURL: nil)
//
//        avatarDeleteUrlCancellable = firestoreService.updateProfile(profile, operationDescription: operationDescription, shouldDeletePhotoURL: true)
//            .handleEvents(receiveOutput: { [weak self] _ in
//                guard let self else { return }
//
//                self.avatarDeleteStorageCancellable = self.storageService.deleteImage(at: photoURL, operationDescription: operationDescription)
//                    .sink(receiveCompletion: { completion in
//                        if case .failure(let error) = completion {
//                            print("⚠️ Ошибка удаления из Storage: \(error.localizedDescription)")
//                        }
//                    }, receiveValue: {
//                        print("✅ Аватар удалён из Storage")
//                    })
//            })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                if case .failure = completion {
//                    self?.state = .avatarDeleteFailure
//                }
//            } receiveValue: { [weak self] in
//                self?.state = .avatarDeleteSuccess
//            }
//    }

    
//    func deleteAvatarAndTrack(for uid: String, photoURL: URL, operationDescription: String) {
//        state = .loading
//        avatarDeleteCancellable?.cancel()
//
//        let profile = UserProfile(uid: uid, photoURL: nil)
//
//        avatarDeleteCancellable = firestoreService.updateProfile(profile, operationDescription: operationDescription, shouldDeletePhotoURL: true)
//            .handleEvents(receiveOutput: { [weak self] _ in
//                // Удаляем из Storage в фоне, не влияя на состояние
//                _ = self?.storageService.deleteImage(at: photoURL, operationDescription: operationDescription)
//                    .sink(receiveCompletion: { completion in
//                        if case .failure(let error) = completion {
//                            print("⚠️ Ошибка удаления из Storage: \(error.localizedDescription)")
//                        }
//                    }, receiveValue: {
//                        print("✅ Аватар удалён из Storage")
//                    })
//            })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                if case .failure = completion {
//                    self?.state = .avatarDeleteFailure
//                }
//            } receiveValue: { [weak self] in
//                self?.state = .avatarDeleteSuccess
//            }
//    }

//    private func deleteAvatar(for uid: String, photoURL: URL, operationDescription: String) -> AnyPublisher<Void, Error> {
//        return storageService.deleteImage(at: photoURL, operationDescription: operationDescription)
//            .flatMap { [weak self] _ -> AnyPublisher<Void, Error> in
//                guard let self else {
//                    return Empty(completeImmediately: true).eraseToAnyPublisher()
//                }
//                let profile = UserProfile(uid: uid, photoURL: nil)
//                return self.firestoreService.updateProfile(profile, operationDescription: operationDescription, shouldDeletePhotoURL: true)
//            }
//            .eraseToAnyPublisher()
//    }
//
//    func deleteAvatarAndTrack(for uid: String, photoURL: URL, operationDescription: String) {
//        state = .loading
//        avatarDeleteCancellable?.cancel()
//
//        avatarDeleteCancellable = deleteAvatar(for: uid, photoURL: photoURL, operationDescription: operationDescription)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                if case .failure(_) = completion {
//                    self?.state = .avatarDeleteFailure
//                }
//            } receiveValue: { [weak self] in
//                self?.state = .avatarDeleteSuccess
//            }
//    }


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
    
