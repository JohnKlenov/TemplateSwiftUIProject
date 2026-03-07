//
//  StorageProfileService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.25.
//

/*
 Сценарии:
 1) Успех:
    - putData(data) завершился без ошибок
    - downloadURL получен
    - Возвращаем URL через .success
    - Никаких алертов

 2) Ошибка во время putData:
    - handleStorageError(error, operationDescription) покажет глобальный алерт
    - Возвращаем .failure(error)

 3) Ошибка получения downloadURL:
    - handleStorageError(error, operationDescription) покажет глобальный алерт
    - Возвращаем .failure(error)

 4) downloadURL == nil (неконсистентное состояние):
    - handleStorageError(FirebaseInternalError.nilSnapshot, operationDescription) покажет глобальный алерт
    - Возвращаем .failure(FirebaseInternalError.nilSnapshot)
*/

// MARK: - comment methods

//func uploadImageData

///putData(data) — загрузка файла в Storage - Если интернет отсутствует:Firebase сразу вернёт ошибку в completion блоке
///Если интернет есть, но очень плохой: Загрузка может зависнуть, затем завершиться ошибкой по таймауту.
///downloadURL — получение ссылки после загрузки Если putData прошёл, но интернет пропал перед downloadURL: Получишь ошибку в блоке Не использует локальный кэш — всегда требует соединения с интернетом. Если интернет есть, но слабый или нестабильный: Запрос может «зависнуть» на некоторое время — Firebase SDK будет пытаться установить соединение.Запрос может «зависнуть» на некоторое время — Firebase SDK будет пытаться установить соединение.



// MARK: - UserInfoEditManager (централизованная обработка ошибок)

import FirebaseStorage
import Combine
import UIKit



protocol StorageProfileServiceProtocol {
    func uploadImageData(path: String, data: Data) -> AnyPublisher<URL, Error>
    func deleteImage(at url: URL)
}

final class StorageProfileService: StorageProfileServiceProtocol {
    
    private let storage = Storage.storage()
    
    func uploadImageData(path: String, data: Data) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { promise in
            let ref = self.storage.reference(withPath: path)
            
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("❌ Storage upload error: putData")
                    promise(.failure(error))
                    return
                }
                
                ref.downloadURL { url, error in
                    //                                        promise(.failure(FirebaseInternalError.imageEncodingFailed))
                    if let error = error {
                        print("❌ Storage upload error: downloadURL")
                        promise(.failure(error))
                        return
                    }
                    guard let url = url else {
                        print("❌ Storage upload error: nil URL")
                        promise(.failure(AppInternalError.storageReturnedNilURL))
                        return
                    }
                    promise(.success(url))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteImage(at url: URL) {
        let ref = storage.reference(forURL: url.absoluteString)
        ref.delete { error in
            if let error = error {
                // Логируем, но не пробрасываем наружу
                print("⚠️ Storage delete error: \(error.localizedDescription)")
            }
        }
    }
}



// MARK: - before центрозовынной обработки ошибок в UserInfoEditManager


//import FirebaseStorage
//import Combine
//import UIKit
//
//protocol StorageProfileServiceProtocol {
//    func uploadImageData(path: String, data: Data, operationDescription: String) -> AnyPublisher<URL, Error>
//    func deleteImage(at url: URL)
//
//}
//
//final class StorageProfileService: StorageProfileServiceProtocol {
//    
//    private let storage = Storage.storage()
//    private let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
//    private let alertManager: AlertManager = .shared
//    
//    func uploadImageData(path: String, data: Data, operationDescription: String) -> AnyPublisher<URL, Error> {
//        Future<URL, Error> { [weak self] promise in
//            guard let self = self else { return }
//            
//            let ref = storage.reference(withPath: path)
//            
//            ref.putData(data, metadata: nil) { _, error in
//                if let error = error {
//                    print("error uploadImageData ref.putData")
//                    self.handleStorageError(error, operationDescription: operationDescription)
//                    promise(.failure(error))
//                    return
//                }
//                
//                ref.downloadURL { url, error in
////                    promise(.failure(FirebaseInternalError.imageEncodingFailed))
//                    if let error = error {
//                        print("error uploadImageData ref.downloadURL")
//                        self.handleStorageError(error, operationDescription: operationDescription)
//                        promise(.failure(error))
//                        return
//                    }
//                    guard let url = url else {
//                        print("error uploadImageData guard let url = url")
//                        let err = FirebaseInternalError.nilSnapshot
//                        self.handleStorageError(err, operationDescription: operationDescription)
//                        promise(.failure(err))
//                        return
//                    }
//                    promise(.success(url))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    func deleteImage(at url: URL) {
//        let ref = storage.reference(forURL: url.absoluteString)
//        ref.delete { [weak self] error in
//            if let error = error {
//                // Логируем, но не пробрасываем наружу
//                let _ = self?.errorHandler.handle(error: error)
//            }
//        }
//    }
//
//    
//    private func handleStorageError(_ error: Error, operationDescription: String) {
//        let message = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: message, operationDescription: operationDescription, alertType: .ok)
//    }
//}


// MARK: по какой логике чистим картинки "сироты" в Storage  (у которых при update не удалось получить url но картинка была сохранена в Storage или при удалении аватара не удалось по каким то причинам это сделать, то есть url с СloudFirestore удалили а удаление картинки в storage по каким то причинам провалилась)



///Вместо «оставляем самую свежую» — оставляем ту, что реально используется в Firestore (и, возможно, ещё несколько предыдущих на всякий случай).
///Алгоритм Cloud Function:
///Пройтись по всем пользователям в Firestore. - users/{uid}/userProfileData/{uid}. - тут в поле photoURL лежит URL или такого поля может не быть если аватар отсутствует.
///Для каждого взять photoURL из профиля.
///В Storage в папке avatars/{uid}/ удалить все файлы, кроме:   Удаляем только те файлы, которые: не совпадают с «текущим» именем из photoURL(или его basename) , не входят в список допустимых «резервных» последних версий, старше grace-периода (например, 7 дней).
///Так мы никогда не удалим файл, на который сейчас ссылается Firestore, даже если он «старый» по дате.


// Идея целиком

///Мы всегда грузим аватар в Storage под уникальным именем: users/{uid}/avatar_{timestamp}.jpg.
///В Firestore храним ровно один «истинный» URL (photoURL), на который смотрит профиль и который подхватывает SDWebImage.
///Все прочие файлы в папке avatars/{uid}/ считаем «кандидатами на уборку».
///Удаляем только те файлы, которые: не совпадают с «текущим» именем из photoURL(или его basename) , не входят в список допустимых «резервных» последних версий, старше grace-периода (например, 7 дней).


//Логика Cloud Function

///Обходим всех пользователей(Раз в неделю ) Через collectionGroup("userProfileData") или прямой обход users/{uid}/userProfileData/{uid}.
///Берём из Firestore текущее значение photoURL(такого поля может не быть если аватара еще нет ) Это URL, который сейчас реально используется в приложении (и который SDWebImage кэширует). Из него извлекаем имя файла (basename), например avatar_1693648123.jpg.
///Листим все файлы в Storage по пути avatars/{uid}/  Получаем список всех версий аватара, включая старые.
///Формируем список «не трогать»:  Текущий файл из photoURL — всегда оставляем.
///N последних по дате (например, 1–2) — оставляем на случай, если:
///Загрузка прошла, но downloadURL не успели записать в Firestore (слабый интернет, оффлайн).
///Эти файлы ещё могут «досинхронизироваться» при восстановлении сети.
///Файлы моложе grace‑периода (например, 7 дней) — оставляем, чтобы дать время на повторную попытку.
///Удаляем всё остальное  - То есть старые, неиспользуемые, незащищённые файлы.







// MARK: - исправленный Код Cloud Function (Node.js, Firebase Admin SDK)


// в данной реализации 2 сироткских аватар при отсутствии url будут жить всегда в хранилище, все остальные будут удалены.


/**
 * Cloud Function: cleanupUnusedAvatars
 *
 * 🧹 Задача:
 *   Автоматическая уборка «сиротских» аватаров в Firebase Storage, которые
 *   больше не используются в профиле пользователя.
 *
 * 🔄 Логика работы:
 * 1. Функция запускается по расписанию (каждый понедельник в 03:00).
 * 2. Из Firestore через collectionGroup("userProfileData") выбираются все документы профилей.
 *    - Ожидается структура: users/{uid}/userProfileData/{uid}.
 *    - Из документа берётся поле photoURL (текущий используемый аватар).
 * 3. Из photoURL извлекается имя файла (например, avatar_1693648123.jpg).
 * 4. В Storage листятся все файлы по пути avatars/{uid}/.
 * 5. Для каждого файла получаем метаданные (updated/timeCreated).
 * 6. Сортируем файлы по дате обновления (сначала новые).
 * 7. Формируем список «не трогать» (keep):
 *    - Текущий файл из photoURL (если есть).
 *    - N последних файлов (KEEP_RECENT), чтобы защитить свежие загрузки,
 *      даже если они ещё не успели попасть в Firestore.
 * 8. Определяем кандидатов на удаление:
 *    - Файлы старше grace-периода (GRACE_DAYS, например 7 дней).
 *    - Файлы, которые не входят в список keep.
 * 9. Удаляем такие файлы из Storage.
 *
 * ⚙️ Настройки:
 *   - GRACE_DAYS: сколько дней хранить «свежие» файлы (по умолчанию 7).
 *   - KEEP_RECENT: сколько последних версий хранить сверх текущей (по умолчанию 2).
 *   - PROFILE_COLLECTION_GROUP: имя коллекции профилей (userProfileData).
 *
 * 🛡️ Защита от ошибок:
 *   - Если у пользователя нет photoURL → просто не добавляем «текущий» файл в keep.
 *   - Если в Storage нет файлов по пути avatars/{uid}/ → пропускаем пользователя.
 *   - Если нет документов userProfileData → функция завершится без ошибок.
 *   - Ошибки удаления конкретного файла логируются, но не прерывают выполнение.
 */

//Почему мы меняем export const ... на module.exports:
// У тебя в проекте уже используется require(...) в index.js, значит, проект работает в режиме CommonJS.
// Поэтому, чтобы всё было совместимо, мы экспортируем функции через module.exports.



// MARK: Деплой

//Вынеси функции в отдельные файлы:

//functions/
// ├─ index.js
// ├─ cleanupUnusedAvatars.js
// ├─ cleanupUnusedAvatarsTest.js
// ├─ package.json
// └─ ...



//Экспортируй их в index.js:

//// index.js
//const functions = require("firebase-functions/v1");
//const admin = require("firebase-admin");
//const { setGlobalOptions, logger } = require("firebase-functions");
//
//setGlobalOptions({ maxInstances: 10 });
//admin.initializeApp();
//
//// Существующая функция
//exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
//  const uid = user.uid;
//  const userRef = admin.firestore().doc(`users/${uid}`);
//
//  try {
//    await admin.firestore().recursiveDelete(userRef);
//    logger.info(`✅ Удалены все данные пользователя: ${uid}`, { uid });
//  } catch (error) {
//    logger.error(`❌ Ошибка при удалении данных пользователя: ${uid}`, {
//      uid,
//      error,
//    });
//  }
//});
//
//// Подключаем новые функции
//exports.cleanupUnusedAvatars = require("./cleanupUnusedAvatars").cleanupUnusedAvatars;
//exports.cleanupUnusedAvatarsTest = require("./cleanupUnusedAvatarsTest").cleanupUnusedAvatarsTest;


//Теперь просто запускаешь из корня проекта:

//cd functions
//npm install   # если нужно подтянуть зависимости
//npm run deploy

//или напрямую:

//firebase deploy --only functions



//После деплоя в консоли Firebase → Functions ты увидишь три функции:

///deleteUserData (auth trigger)
///cleanupUnusedAvatars (scheduler, раз в неделю)
///cleanupUnusedAvatarsTest (scheduler, каждые 30 минут)


//после деплоя обе функции будут существовать и работать параллельно (cleanupUnusedAvatars + cleanupUnusedAvatarsTest)

//Как удалить тестовую функцию после проверки?

///1. Удалить экспорт из index.js
///Просто убираешь строку: exports.cleanupUnusedAvatarsTest = require("./cleanupUnusedAvatarsTest").cleanupUnusedAvatarsTest;
///и удаляешь сам файл cleanupUnusedAvatarsTest.js (или оставляешь, но не подключаешь).
///Затем выполняешь: firebase deploy --only functions
/// Firebase увидит, что функция больше не экспортируется, и удалит её из проекта.

