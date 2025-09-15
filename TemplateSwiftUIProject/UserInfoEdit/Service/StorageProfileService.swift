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

import FirebaseStorage
import Combine
import UIKit

protocol StorageProfileServiceProtocol {
    func uploadImageData(path: String, data: Data, operationDescription: String) -> AnyPublisher<URL, Error>
    func deleteImage(at url: URL, operationDescription: String) -> AnyPublisher<Void, Error>

}

final class StorageProfileService: StorageProfileServiceProtocol {
    
    private let storage = Storage.storage()
    private let errorHandler: ErrorHandlerProtocol = SharedErrorHandler()
    private let alertManager: AlertManager = .shared
    
    ///putData(data) — загрузка файла в Storage - Если интернет отсутствует:Firebase сразу вернёт ошибку в completion блоке
    ///Если интернет есть, но очень плохой: Загрузка может зависнуть, затем завершиться ошибкой по таймауту.
    ///downloadURL — получение ссылки после загрузки Если putData прошёл, но интернет пропал перед downloadURL: Получишь ошибку в блоке Не использует локальный кэш — всегда требует соединения с интернетом. Если интернет есть, но слабый или нестабильный: Запрос может «зависнуть» на некоторое время — Firebase SDK будет пытаться установить соединение.Запрос может «зависнуть» на некоторое время — Firebase SDK будет пытаться установить соединение.
    func uploadImageData(path: String, data: Data, operationDescription: String) -> AnyPublisher<URL, Error> {
        Future<URL, Error> { [weak self] promise in
            guard let self = self else { return }
            
            let ref = storage.reference(withPath: path)
            
            ref.putData(data, metadata: nil) { _, error in
                if let error = error {
                    print("error uploadImageData ref.putData")
                    self.handleStorageError(error, operationDescription: operationDescription)
                    promise(.failure(error))
                    return
                }
                
                ref.downloadURL { url, error in
                    if let error = error {
                        print("error uploadImageData ref.downloadURL")
                        self.handleStorageError(error, operationDescription: operationDescription)
                        promise(.failure(error))
                        return
                    }
                    guard let url = url else {
                        print("error uploadImageData guard let url = url")
                        let err = FirebaseInternalError.nilSnapshot
                        self.handleStorageError(err, operationDescription: operationDescription)
                        promise(.failure(err))
                        return
                    }
                    promise(.success(url))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteImage(at url: URL, operationDescription: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self else { return }

            let ref = storage.reference(forURL: url.absoluteString)
            ref.delete { error in
                if let error = error {
                    self.handleStorageError(error, operationDescription: operationDescription)
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    
    private func handleStorageError(_ error: Error, operationDescription: String) {
        let message = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: message, operationDescription: operationDescription, alertType: .ok)
    }
}

///всегда в users/{userID}/userid.jpg хранить всего один файл с аватар . Но меня беспокоят две возможные проблемы - первая это что если в момент записи новой картинки в Storage все пройдет хорошо но получения url пройдет с ошибкой , тогда мы затрем наш старую картинку в storage и прервем получения новой? И второй момент я думаю о том что мы кэшируем картинку в SDWebImage по url , но не будет ли url всегда одинаковый вне зависимости от того какую картинку мы загрузим в Storage ведь путь всегда один и тот же - users/{userID}/userid.jpg ? Как подобные проблемы решают старшие iOS разработчики на боевых приложениях учитывая мою кодовую базу?
///
///
// Генерируем уникальное имя файла с timestamp
//        let timestamp = Int(Date().timeIntervalSince1970)
//        let fileName = "avatar_\(timestamp).jpg"
//        let path = "users/\(uid)/\(fileName)"
//        let ref = self.storage.reference(withPath: path)


//Раз в неделю обходит все профили пользователей.
//Берёт из Firestore photoURL (текущий используемый аватар).
//Листит все файлы в Storage по пути users/{uid}/.
//Никогда не удаляет файл, который сейчас в photoURL.
//Не трогает N последних файлов (по дате) и все файлы моложе grace‑периода (например, 7 дней) — чтобы защитить свежие «сироты» при оффлайне или сбое получения URL.
//Удаляет всё остальное.


//📄 Код Cloud Function (Node.js, Firebase Admin SDK)

// functions/cleanupUnusedAvatars.js
//import { onSchedule } from "firebase-functions/v2/scheduler";
//import * as admin from "firebase-admin";
//
//if (!admin.apps.length) {
//  admin.initializeApp();
//}
//
//const db = admin.firestore();
//const storage = admin.storage().bucket(process.env.FIREBASE_STORAGE_BUCKET);
//
//// Настройки
//const GRACE_DAYS = parseInt(process.env.AVATAR_GRACE_DAYS ?? "7", 10); // карантин по возрасту
//const KEEP_RECENT = parseInt(process.env.AVATAR_KEEP_RECENT ?? "2", 10); // сколько последних версий хранить сверх текущей
//const PROFILE_COLLECTION_GROUP = "userProfileData"; // твой путь под коллекцией
//
//function extractFileNameFromUrl(url) {
//  try {
//    const u = new URL(url);
//    const decodedPath = decodeURIComponent(
//      u.pathname.replace(/^\/v0\/b\/[^/]+\/o\//, "")
//    );
//    const parts = decodedPath.split("/");
//    return parts[parts.length - 1]; // avatar_123.jpg
//  } catch {
//    return null;
//  }
//}
//
//export const cleanupUnusedAvatars = onSchedule("every monday 03:00", async () => {
//  const now = Date.now();
//  const graceMs = GRACE_DAYS * 24 * 60 * 60 * 1000;
//
//  const profilesSnap = await db.collectionGroup(PROFILE_COLLECTION_GROUP).get();
//
//  for (const doc of profilesSnap.docs) {
//    const data = doc.data();
//    const uid = doc.id;
//    const photoURL = data.photoURL || null;
//    const usedFileName = photoURL ? extractFileNameFromUrl(photoURL) : null;
//    const prefix = `users/${uid}/`;
//
//    const [files] = await storage.getFiles({ prefix });
//    if (!files.length) continue;
//
//    // Получаем метаданные и сортируем по дате обновления
//    const withMeta = await Promise.all(
//      files.map(async (file) => {
//        const [meta] = await file.getMetadata();
//        const updated = new Date(meta.updated || meta.timeCreated || Date.now()).getTime();
//        const name = file.name.replace(prefix, "");
//        return { file, name, updated };
//      })
//    );
//
//    withMeta.sort((a, b) => b.updated - a.updated);
//
//    // Формируем список "не трогать"
//    const keep = new Set();
//    if (usedFileName) keep.add(usedFileName);
//
//    for (const { name } of withMeta) {
//      if (keep.size >= (usedFileName ? 1 + KEEP_RECENT : KEEP_RECENT)) break;
//      if (!keep.has(name)) keep.add(name);
//    }
//
//    // Удаляем старые и неиспользуемые
//    const toDelete = withMeta.filter(({ name, updated }) => {
//      const isOld = now - updated > graceMs;
//      return isOld && !keep.has(name);
//    });
//
//    for (const item of toDelete) {
//      try {
//        await item.file.delete();
//        console.log(`Deleted ${item.file.name}`);
//      } catch (e) {
//        console.warn(`Failed to delete ${item.file.name}:`, e);
//      }
//    }
//  }
//});


//GRACE_DAYS — «карантин» для свежих файлов (по умолчанию 7 дней).
//KEEP_RECENT — сколько последних версий (по дате) хранить сверх текущей.
//usedFileName — имя файла из photoURL в Firestore, всегда сохраняем.
//keep — набор файлов, которые не удаляем.
//toDelete — всё, что старше grace‑периода и не в keep.


//Евгений, твой вопрос абсолютно в точку — Cloud Function с обходом всех пользователей и умной логикой чистки — это действительно «тяжёлая артиллерия». Она даёт максимальный контроль, но требует поддержки и инфраструктуры.
//В продакшене у крупных команд это действительно довольно частый подход, потому что:
//он гарантирует, что Storage не зарастёт мусором,
//и защищает от случайного удаления актуальных файлов.
