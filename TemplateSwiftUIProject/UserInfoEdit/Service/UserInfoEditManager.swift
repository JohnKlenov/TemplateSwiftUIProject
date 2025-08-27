//
//  UserInfoEditManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.25.
//

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

import Combine
import UIKit

final class UserInfoEditManager {
    
    private let firestoreService: ProfileServiceProtocol
    private let storageService: StorageProfileServiceProtocol
    
    init(firestoreService: ProfileServiceProtocol,
         storageService: StorageProfileServiceProtocol) {
        self.firestoreService = firestoreService
        self.storageService = storageService
    }
    
    /// Загружает аватар в Storage и обновляет профиль в Firestore
    /// Все алерты показывают СЕРВИСЫ. Менеджер не вызывает handleError.
    func uploadAvatar(for uid: String, image: UIImage) -> AnyPublisher<Void, Error> {
        // 1. Сжатие изображения
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            return Fail(error: ProfileServiceError.imageEncodingFailed)
                .eraseToAnyPublisher()
        }
        
        // 2. Путь и заголовки операций (ключи/тексты для алертов в сервисах)
        let path = "avatars/\(uid).jpg"
//        let storageOperationTitle = TitleOfFailedOperationFirebase.pickingImage      // "error.picking_image"
//        let firestoreOperationTitle = TitleOfFailedOperationFirebase.database        // "error.database" (или свой ключ)
        
        // 3. Цепочка: Storage → Firestore
        return storageService.uploadImageData(path: path, data: data, operationDescription: "storageOperationTitle")
            .handleEvents(receiveOutput: { url in
                print("✅ Avatar uploaded to Storage: \(url)")
            })
            .flatMap { [weak self] url -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: FirebaseInternalError.nilSnapshot).eraseToAnyPublisher()
                }
                let profile = UserProfile(uid: uid, photoURL: url)
                return self.firestoreService.updateProfile(profile)
            }
            .eraseToAnyPublisher()
    }
}

enum ProfileServiceError: Error {
    case imageEncodingFailed
}

