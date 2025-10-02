


// MARK: - когда внутри Cloud Function что‑то пошло не так и ты залогировал logger.error


//Что делают профессионально в продакшене

//1. Логирование + алертинг

///logger.error сам по себе пишет в Google Cloud Logging (Stackdriver).
///На продакшене обычно настраивают алерты: если за последние N минут появилось M ошибок → отправить уведомление в Slack, Teams, Email, PagerDuty. это делается через Google Cloud Monitoring (Alerting Policies).
///Таким образом команда узнаёт о проблеме сразу, а не через неделю.


//2. Повторное выполнение (retry)

///Для background‑функций (например, Pub/Sub, Firestore triggers) можно включить автоматический retry. Если функция завершилась с ошибкой (бросила исключение), Cloud Functions сам попробует её выполнить снова. Это полезно для временных сбоев (например, сеть, таймаут).
///Для HTTP‑функций retry не включается автоматически — клиент сам должен повторить запрос.


//3. Dead Letter Queue (DLQ)

///Если функция всё равно падает после нескольких ретраев, сообщения можно складывать в Pub/Sub DLQ (отдельную очередь).
///Потом разработчики вручную или через отдельный воркер разбирают эти «проблемные события».
///Это защищает от потери данных.


//4. Идемпотентность

///Важно писать функции так, чтобы повторный запуск не ломал данные. Например, если удаление пользователя вызвалось дважды — это не должно привести к ошибке. Если запись в Firestore уже существует — setData(..., merge: true) или updateData должны корректно отработать.


//5. Оповещение команды


///В продакшене редко читают «сырые» логи.
///Обычно ошибки агрегируются в Sentry, Datadog, New Relic или хотя бы в Slack‑канал с алертами.
///Там сразу видно: какой сервис, какой стек‑трейс, сколько раз повторилось.



//Как это выглядит на практике

///Функция упала → logger.error → запись в Cloud Logging.
///Cloud Monitoring видит, что за 5 минут >10 ошибок → шлёт алерт в Slack.
///Если включён retry → функция сама попробует ещё раз.
///Если и после retry ошибка → событие уходит в DLQ.
///Команда утром видит алерт + DLQ и разбирает кейс.



// MARK: - Задачи для Profile


// path 1


// локализовать весь текст + inject AppColors

/// делаем signUp смотрим логи в консоли
/// подставляем signOut(активируем) вместо deleteAccount
/// снова делаем signUp смотрим логи в консоли + добавляем в корзину новую запись
/// теперь делаем SignIn на первый account смотрим логи в консоли
/// добавляем в deleteAccount реальное удаление пользователя
// deleteAccount смотрим логи в консоли (проверяем как работает function (удаление всех данных у перманентного юзера в users/${uid}) но нужно добавить удаление из Storage urlImage)
// добавить удаление анонимного пользователя и его данных в в users/${uid}) используя function (может можно инициировать удаление анонимного пользователя через function а тригер functions.auth.user().onDelete(async (user) сработает далбше сам и выполнит удаление данных?)
/// реализуем экран для ввода и сохранения личных данных пользователя в users/uid (текстовы поля name, email + iconImage)
/// тестируем экран ProfileEditView
// необходимо логи которые мы получаем в терминал из index.js совместить с Crashlistics ? или как разработчику мониторить логи из index.js ?

// сейчас мы анон у которого есть личные данные в users/id/document
// когда мы signUp данные anon станут permanent
/// когда мы удалим permanentUser то мы не можем сначала удалить личные данные пользователя а потом самого user, это не совсем логично!
/// по этому сначала нужно удалить user account и лиш потом на стороне сервера Firebase через Firebase Functions удалить уже и данные только что удаленного users по пути users/id/





// path 2


/*
1. ProfileView и дочерние View:
   - [ ] Добавить локализацию текста (использовать Localizable.strings).
   - [ ] Адаптировать UI под разные устройства (Auto Layout, Dynamic Type).
   - [ ] Локализовать Color (через Asset Catalog с поддержкой локализаций).

2. Cloud Function: удаление avatarImage
   - [ ] Протестировать удаление аватаров при наличии нескольких аккаунтов:
         • Добавить аватары во второй аккаунт и проверить корректность очистки.
   - [ ] Убедиться, что в "keep" остаются N последних аватаров по дате создания (сейчас N = 2).
   - [ ] Проверить, что эти N аватаров навсегда остаются в Storage.

3. Cloud Function: удаление аккаунта пользователя
   - [ ] Уже реализовано: удаление личных данных из CloudFirestore.
   - [ ] Реализовать удаление личных данных из Storage (путь avatars/uid).
   - [ ] Протестировать полный цикл: удаление аккаунта → триггер удаления данных.

4. Cloud Function: удаление анонимных аккаунтов
   - [ ] Реализовать удаление анонимного аккаунта и связанных данных (Firestore + Storage).
   - [ ] Определить условие удаления:
         • Пользователь сделал SignIn → удалить старый анонимный аккаунт.
         • Пользователь долго не заходит → считать аккаунт устаревшим и удалить.
   - [ ] При удалении анонимного аккаунта триггерить уже существующую функцию удаления личных данных.
*/





// MARK:  Cloud Function: удаление анонимных аккаунтов

// сценарии:

//1. Anon → SignIn (вход в уже существующий аккаунт)


// !!! Мы не будем реализовывать этот код что бы не усложнять логику (оставим только удаление протухших анон аккаунтов)

///Вот тут и появляется «сирота»: текущий анонимный uid остаётся в Firebase, но пользователь больше никогда не сможет им воспользоваться. Именно его и нужно удалять.
///Клиент (Swift, iOS) – после успешного signIn мы берём anonUid (старый анонимный пользователь) и отправляем его в Cloud Function.
/// if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous { anonUid = currentUser.uid }
/// Cloud Function (Node.js, Firebase Admin SDK) – принимает uid, проверяет что это анонимный пользователь, и удаляет его. Это вызовет твой onDelete‑триггер, который уже чистит Firestore и Storage.


//import FirebaseAuth
//import FirebaseFunctions
//
//class AuthManager {
//    private lazy var functions = Functions.functions()
//    
//    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
//        // Сохраняем UID только если текущий пользователь анонимный
//        var anonUid: String?
//        if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
//            anonUid = currentUser.uid
//        }
//        
//        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            guard let user = result?.user else {
//                completion(.failure(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user"])))
//                return
//            }
//            
//            // Если был анонимный аккаунт → отправляем его UID на Cloud Function
//            if let anonUid = anonUid {
//                self?.functions.httpsCallable("deleteAnonUser")
//                    .call(["uid": anonUid]) { response, error in
//                        if let error = error {
//                            print("⚠️ Ошибка при удалении анонима: \(error)")
//                        } else {
//                            print("✅ Анонимный аккаунт \(anonUid) отправлен на удаление")
//                        }
//                    }
//            }
//            
//            completion(.success(user))
//        }
//    }
//}




//functions/index.js

//const functions = require("firebase-functions");
//const admin = require("firebase-admin");
//
//admin.initializeApp();
//
//// HTTPS Callable Function
//exports.deleteAnonUser = functions.https.onCall(async (data, context) => {
//  const uid = data.uid;
//
//  if (!uid) {
//    throw new functions.https.HttpsError("invalid-argument", "UID is required");
//  }
//
//  try {
//    const userRecord = await admin.auth().getUser(uid);
//
//    if (userRecord.providerData.length === 0) {
//      // Это анонимный аккаунт → удаляем
//      await admin.auth().deleteUser(uid);
//      return { success: true, message: `Anonymous user ${uid} deleted` };
//    } else {
//      // Не анонимный → не трогаем
//      return { success: false, message: `User ${uid} is not anonymous` };
//    }
//  } catch (error) {
//    console.error("Error deleting user:", error);
//    throw new functions.https.HttpsError("internal", error.message);
//  }
//});






//2. Анонимный аккаунт долго не используется

///Firebase не удаляет анонимные аккаунты автоматически.
///При создании анонимного аккаунта сохраняют в Firestore метку createdAt и обновляют lastActiveAt при каждом запуске приложения.
///Запускают scheduled Cloud Function (cron, например раз в сутки).
///Функция ищет анонимные аккаунты, у которых lastActiveAt < now - 30d (или 90d, зависит от политики).
///Для таких аккаунтов вызывается admin.auth().deleteUser(uid).
///Это автоматически триггерит onDelete → очистку данных в Firestore и Storage.


// Тест cleanupAnonTracker (удаляем cleanupAnonTracker в Firestore как только user перестал быть анон) -> Создаем Анонимного (SignOut) -> SignUp -> данные по пути users/{uid}/anonAccountTracker/{uid} должны быть удалены.

// Тест удаление Anon : Создаем Анонимного (SignOut) -> Создаем Profile + Avatars -> SignIn -> на следующий день в это же время ждем удаления сиротского Anon и данных Firestore + Storage


// клиент

//import FirebaseAuth
//import FirebaseFirestore
//
//class AnonAccountTracker {
//    private let db = Firestore.firestore()
//    
//    func signInAnonymously(completion: @escaping (Result<User, Error>) -> Void) {
//        Auth.auth().signInAnonymously { [weak self] result, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            guard let user = result?.user else {
//                completion(.failure(NSError(domain: "Auth", code: -1,
//                    userInfo: [NSLocalizedDescriptionKey: "No user"])))
//                return
//            }
//            
//            let uid = user.uid
//            let now = Timestamp(date: Date())
//            
//            // сохраняем во вложенную коллекцию users/{uid}/anonAccountTracker/{uid}
//            self?.db.collection("users").document(uid)
//                .collection("anonAccountTracker").document(uid)
//                .setData([
//                    "createdAt": now,
//                    "lastActiveAt": now,
//                    "isAnonymous": true
//                ], merge: true)
//            
//            completion(.success(user))
//        }
//    }
//    
//    func updateLastActive() {
//        if let uid = Auth.auth().currentUser?.uid {
//            db.collection("users").document(uid)
//                .collection("anonAccountTracker").document(uid)
//                .updateData([
//                    "lastActiveAt": Timestamp(date: Date())
//                ])
//        }
//    }
//}




//Что такое Timestamp(date: Date()) ?

///В iOS SDK для Firestore есть тип Timestamp (FirebaseFirestore.Timestamp).
///Это обёртка вокруг даты/времени, которая хранит значение в формате «секунды + наносекунды с начала эпохи (Unix time)».
///Когда ты пишешь Timestamp(date: Date()), ты берёшь текущую Date из Swift и преобразуешь её в Firestore‑совместимый Timestamp.
///Firestore поддерживает собственный тип данных timestamp. То есть это не строка и не число, а именно отдельный тип, который можно: сортировать по времени, использовать в запросах (where("lastActiveAt", "<", cutoff)), сравнивать и фильтровать.
///В Firestore Console документ users/{uid} будет выглядеть примерно так:

//createdAt     September 28, 2025 at 14:35:12 UTC+3   (timestamp)
//lastActiveAt  September 28, 2025 at 14:35:12 UTC+3   (timestamp)
//isAnonymous   true                                    (boolean)









//# 1 version

//Cloud Function (Node.js) - Scheduled cleanup of inactive anonymous users


//// Подключаем Firebase Functions (для триггеров) и Admin SDK (для админ-доступа к Auth/Firestore/Storage)
//const functions = require("firebase-functions");
//const admin = require("firebase-admin");
//
//// Инициализируем Admin SDK (использует служебные креды проекта)
//admin.initializeApp();
//
//// Получаем ссылку на Firestore (через Admin SDK)
//const db = admin.firestore();
//
///**
// * Плановая (cron) функция: запускается каждые 24 часа.
// * Цель: найти анонимные аккаунты, которые давно не были активны,
// * и удалить их из Firebase Auth. Удаление пользователя автоматически
// * вызовет триггер onDelete (если он реализован), который очистит данные в Firestore/Storage.
// */
//exports.cleanupInactiveAnonUsers = functions.pubsub
//  .schedule("every 24 hours")
//  .onRun(async (context) => {
//    // Вычисляем "крайний срок": все, кто неактивен дольше 30 дней, подлежат удалению
//    const cutoff = new Date();
//    cutoff.setDate(cutoff.getDate() - 30); // 30 дней неактивности
//
//    console.log(`🧹 Чистим анонимные аккаунты неактивные до ${cutoff.toISOString()}`);
//
//    /**
//     * Ищем в коллекции users документы, помеченные как анонимные (isAnonymous == true),
//     * у которых поле lastActiveAt < cutoff.
//     * Важно: lastActiveAt должен быть совместим с сравнимым типом (Date/Timestamp).
//     * Если сохраняете Timestamp, приводите сравнение корректно (например, используйте admin.firestore.Timestamp).
//     */
//      const snapshot = await db.collectionGroup("anonAccountTracker")
//          .where("isAnonymous", "==", true)
//          .where("lastActiveAt", "<", cutoff)
//          .get();
//
//
//    // Если никого не нашли — логируем и завершаем
//    if (snapshot.empty) {
//      console.log("ℹ️ Нет неактивных анонимных аккаунтов для удаления");
//      return null;
//    }
//
//    // Готовим параллельные операции удаления в Auth для каждого найденного uid
//    const batch = [];
//    snapshot.forEach(doc => {
//      const uid = doc.id; // Предполагаем, что doc.id == uid пользователя
//      batch.push(deleteUser(uid));
//    });
//
//    // Запускаем все удаления параллельно и дожидаемся завершения
//    await Promise.all(batch);
//    console.log(`✅ Удалено ${batch.length} анонимных аккаунтов`);
//    return null;
//  });
//
///**
// * Вспомогательная функция: удаляет пользователя из Firebase Auth по uid.
// * Если включен триггер functions.auth.user().onDelete, он запустится автоматически,
// * и там нужно чистить Firestore/Storage данные этого пользователя.
// */
//async function deleteUser(uid) {
//  try {
//    await admin.auth().deleteUser(uid);
//    console.log(`✅ Пользователь ${uid} удалён`);
//  } catch (error) {
//    // Не прерываем общий процесс из-за одного сбоя — просто логируем ошибку
//    console.error(`❌ Ошибка при удалении ${uid}:`, error);
//  }
//}


//А в index.js просто подключаешь:

//exports.cleanupInactiveAnonUsers =
//  require('./cleanupInactiveAnonUsers').cleanupInactiveAnonUsers;






//# 2 version prod + test




//admin.initializeApp() должен быть вызван только один раз во всём проекте функций. Обычно это делают в functions/index.js (или в отдельном общем модуле, который импортируется везде).
//Если ты вызываешь admin.initializeApp() в каждом файле (cleanupInactiveAnonUsers.js, cleanupInactiveAnonUsersTest.js, cleanupAnonTracker.js), Firebase не упадёт, но в логах будут предупреждения вида: Error: The default Firebase app already exists.





//🔹 Как работает этот код (по шагам)
//Раз в сутки запускается функция (отдельно для продакшена и теста).
//Вычисляется дедлайн:
//30 дней назад (продакшен)
//1 день назад (тест)
//Запрос к Firestore: ищем все anonAccountTracker, где isAnonymous == true и lastActiveAt < cutoff.
//Для каждого кандидата:
//Получаем UserRecord из Firebase Auth.
//Если у пользователя есть провайдеры (providerData.length > 0) → значит, он уже постоянный → пропускаем.
//Если провайдеров нет → это всё ещё анонимный → удаляем через admin.auth().deleteUser(uid).
//У постоянного пользователя всегда есть хотя бы один провайдер (email, Google, Apple и т. д.).
//Если пользователя уже нет в Auth → просто логируем, а трекер подчистит onDelete.
//Удаление трекеров вручную не выполняется — этим занимается functions.auth.user().onDelete.






//🔹 cleanupInactiveAnonUsers.js  (продакшен, 30 дней)


//const functions = require("firebase-functions");
//const admin = require("firebase-admin");
//const db = admin.firestore();
//
///**
// * PROD: Очистка анонимных аккаунтов, неактивных более 30 дней
// */
//exports.cleanupInactiveAnonUsers = functions.pubsub
//  .schedule("every 24 hours")
//  .onRun(async () => {
//    const cutoffDate = new Date();
//    cutoffDate.setDate(cutoffDate.getDate() - 30);
//    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);
//
//    console.log(`🧹 [PROD] Ищем анонимные аккаунты, неактивные до ${cutoff.toDate().toISOString()}`);
//
//    const snapshot = await db.collectionGroup("anonAccountTracker")
//      .where("isAnonymous", "==", true)
//      .where("lastActiveAt", "<", cutoff)
//      .get();
//
//    if (snapshot.empty) {
//      console.log("ℹ️ [PROD] Нет неактивных анонимных аккаунтов для удаления");
//      return null;
//    }
//
//    const tasks = [];
//    snapshot.forEach((doc) => {
//      const uid = doc.id;
//      tasks.push(handleCandidateUser(uid, doc.ref, "[PROD]"));
//    });
//
//    await Promise.all(tasks);
//    console.log(`✅ [PROD] Завершена очистка. Обработано ${tasks.length} кандидатов.`);
//    return null;
//  });
//
//async function handleCandidateUser(uid, trackerRef, tag) {
//  try {
//    const userRecord = await admin.auth().getUser(uid);
//    const isStillAnonymous = userRecord.providerData.length === 0;
//
//    if (!isStillAnonymous) {
//      console.log(`⏭️ ${tag} Пропускаем ${uid}: пользователь уже не анонимный`);
//      // Обновляем трекер, чтобы он больше не попадал в выборку
//      await trackerRef.update({ isAnonymous: false });
//      return;
//    }
//
//    await admin.auth().deleteUser(uid);
//    console.log(`✅ ${tag} Удалён анонимный пользователь ${uid}`);
//  } catch (err) {
//    if (err.code === "auth/user-not-found") {
//      console.log(`ℹ️ ${tag} ${uid} уже удалён из Auth`);
//      await trackerRef.update({ isAnonymous: false });
//      return;
//    }
//    console.error(`❌ ${tag} Ошибка при обработке ${uid}:`, err);
//  }
//}
//



//🔹 index.js
//exports.cleanupInactiveAnonUsers = require("./cleanupInactiveAnonUsers").cleanupInactiveAnonUsers;





//🔹 cleanupInactiveAnonUsersTest.js  (тест, 1 день)



//const functions = require("firebase-functions");
//const admin = require("firebase-admin");
//const db = admin.firestore();
//
///**
// * TEST: Очистка анонимных аккаунтов, неактивных более 1 дня
// */
//exports.cleanupInactiveAnonUsersTest = functions.pubsub
//  .schedule("every 24 hours")
//  .onRun(async () => {
//    const cutoffDate = new Date();
//    cutoffDate.setDate(cutoffDate.getDate() - 1);
//    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);
//
//    console.log(`🧪 [TEST] Ищем анонимные аккаунты, неактивные до ${cutoff.toDate().toISOString()}`);
//
//    const snapshot = await db.collectionGroup("anonAccountTracker")
//      .where("isAnonymous", "==", true)
//      .where("lastActiveAt", "<", cutoff)
//      .get();
//
//    if (snapshot.empty) {
//      console.log("ℹ️ [TEST] Нет неактивных анонимных аккаунтов для удаления");
//      return null;
//    }
//
//    const tasks = [];
//    snapshot.forEach((doc) => {
//      const uid = doc.id;
//      tasks.push(handleCandidateUser(uid, doc.ref, "[TEST]"));
//    });
//
//    await Promise.all(tasks);
//    console.log(`✅ [TEST] Завершена очистка. Обработано ${tasks.length} кандидатов.`);
//    return null;
//  });
//
//async function handleCandidateUser(uid, trackerRef, tag) {
//  try {
//    const userRecord = await admin.auth().getUser(uid);
//    const isStillAnonymous = userRecord.providerData.length === 0;
//
//    if (!isStillAnonymous) {
//      console.log(`⏭️ ${tag} Пропускаем ${uid}: пользователь уже не анонимный`);
//      // Обновляем трекер, чтобы он больше не попадал в выборку
//      await trackerRef.update({ isAnonymous: false });
//      return;
//    }
//
//    await admin.auth().deleteUser(uid);
//    console.log(`✅ ${tag} Удалён анонимный пользователь ${uid}`);
//  } catch (err) {
//    if (err.code === "auth/user-not-found") {
//      console.log(`ℹ️ ${tag} ${uid} уже удалён из Auth`);
//      await trackerRef.update({ isAnonymous: false });
//      return;
//    }
//    console.error(`❌ ${tag} Ошибка при обработке ${uid}:`, err);
//  }
//}
//



//🔹 index.js
//exports.cleanupInactiveAnonUsersTest = require("./cleanupInactiveAnonUsersTest").cleanupInactiveAnonUsersTest;





//Cloud Function (Node.js) -  cleanupAnonTracker (удаляем cleanupAnonTracker в Firestore как только user перестал быть анон)

//Как это делают на продакшене

///Когда анонимный пользователь «апгрейдится» до постоянного (через linkWithCredential), в Firebase Auth у него меняется флаг isAnonymous → false.
///UID остаётся тем же.
///На стороне Cloud Functions можно повесить Auth trigger functions.auth.user().onCreate или onUpdate и проверять: если пользователь больше не анонимный, то удалить его служебный документ users/{uid}/anonAccountTracker/{uid}.


//Создаём отдельный файл, например cleanupAnonTracker.js:
//const functions = require("firebase-functions/v1");
//const admin = require("firebase-admin");
//const db = admin.firestore();
//
///**
// * Триггер: срабатывает при изменении пользователя в Firebase Auth.
// * Если аккаунт перестал быть анонимным — удаляем служебный документ
// * users/{uid}/anonAccountTracker/{uid}.
// */
//exports.cleanupAnonTrackerOnUpgrade = functions.auth.user().onUpdate(async (change) => {
//  const before = change.before;
//  const after = change.after;
//
//  // Если раньше был анонимным, а теперь нет
//  if (before.isAnonymous && !after.isAnonymous) {
//    const uid = after.uid;
//    const trackerRef = db.collection("users").doc(uid)
//                         .collection("anonAccountTracker").doc(uid);
//
//    try {
//      await trackerRef.delete();
//      functions.logger.info(`✅ Удалён anonAccountTracker для апгрейднутого пользователя: ${uid}`);
//    } catch (error) {
//      functions.logger.error(`❌ Ошибка при удалении anonAccountTracker для ${uid}`, { error });
//    }
//  }
//});





//А в index.js просто подключаешь:

//exports.cleanupAnonTrackerOnUpgrade =
//  require("./cleanupAnonTracker").cleanupAnonTrackerOnUpgrade;





// MARK: - удаление личных данных из Storage (путь avatars/uid).


// before

/**
 * Firebase Cloud Functions — TemplateSwiftUIProject
 * Реагирует на удаление аккаунта и очищает связанные данные
 */

//const functions = require('firebase-functions/v1');
//const admin = require('firebase-admin');
//const {setGlobalOptions, logger} = require('firebase-functions');
//
//setGlobalOptions({maxInstances: 10});
//admin.initializeApp();
//
//exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
//  const uid = user.uid;
//  const userRef = admin.firestore().doc(`users/${uid}`);
//
//  try {
//    // Удаляем все данные пользователя, включая вложенные коллекции
//    await admin.firestore().recursiveDelete(userRef);
//
//    logger.info(`✅ Удалены все данные пользователя: ${uid}`, {uid});
//  } catch (error) {
//    logger.error(`❌ Ошибка при удалении данных пользователя: ${uid}`, {
//      uid,
//      error,
//    });
//  }
//});
//
//exports.cleanupUnusedAvatars =
//  require('./cleanupUnusedAvatars').cleanupUnusedAvatars;
//
//exports.cleanupUnusedAvatarsTest =
//  require('./cleanupUnusedAvatarsTest').cleanupUnusedAvatarsTest;


// after


/**
 * Firebase Cloud Functions — TemplateSwiftUIProject
 * Реагирует на удаление аккаунта и очищает связанные данные
 */

//const functions = require('firebase-functions/v1');
//const admin = require('firebase-admin');
//const { setGlobalOptions, logger } = require('firebase-functions');
//
//setGlobalOptions({ maxInstances: 10 });
//admin.initializeApp();
//
//exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
//  const uid = user.uid;
//  const userRef = admin.firestore().doc(`users/${uid}`);
//
//  try {
//    // 1. Удаляем все данные пользователя в Firestore (включая вложенные коллекции)
//    await admin.firestore().recursiveDelete(userRef);
//    logger.info(`✅ Удалены все Firestore-данные пользователя: ${uid}`, { uid });
//
//    // 2. Удаляем все файлы пользователя в Storage по пути avatars/${uid}/
//    const bucket = admin.storage().bucket();
//    const [files] = await bucket.getFiles({ prefix: `avatars/${uid}/` });
//
//    if (files.length > 0) {
//      await Promise.all(files.map(file => file.delete()));
//      logger.info(`✅ Удалены все файлы в Storage для пользователя: ${uid}`, { uid });
//    } else {
//      logger.info(`ℹ️ Нет файлов в Storage для пользователя: ${uid}`, { uid });
//    }
//
//  } catch (error) {
//    logger.error(`❌ Ошибка при удалении данных пользователя: ${uid}`, {
//      uid,
//      error,
//    });
//  }
//});
//
//exports.cleanupUnusedAvatars =
//  require('./cleanupUnusedAvatars').cleanupUnusedAvatars;
//
//exports.cleanupUnusedAvatarsTest =
//  require('./cleanupUnusedAvatarsTest').cleanupUnusedAvatarsTest;


//чтобы админ имел такие же полномочия в Storage, как и в Firestore, нужно добавить правило:

//rules_version = '2';
//
//service firebase.storage {
//  match /b/{bucket}/o {
//
//    // ✅ Чтение доступно только авторизованным пользователям (не для продакшена)
//    match /{allPaths=**} {
//      allow read: if request.auth != null;
//    }
//
//    // 👤 Доступ к аватарам: владелец или админ
//    match /avatars/{userId}/{allPaths=**} {
//      allow read, write: if request.auth != null
//        && (request.auth.uid == userId || request.auth.token.role == "admin");
//    }
//
//    // 👑 Администратор может писать в любые пути (например, для служебных задач)
//    match /{allPaths=**} {
//      allow write: if request.auth != null && request.auth.token.role == "admin";
//    }
//  }
//}




//тут пользователь не может читать ничего кроме своих аватар

//rules_version = '2';
//
//service firebase.storage {
//  match /b/{bucket}/o {
//
//    // 👤 Доступ к аватарам: только владелец или админ
//    match /avatars/{userId}/{allPaths=**} {
//      allow read, write: if request.auth != null
//        && (request.auth.uid == userId || request.auth.token.role == "admin");
//    }
//
//    // 👑 Администратор может читать/писать в любые пути (например, для служебных задач)
//    match /{allPaths=**} {
//      allow read, write: if request.auth != null && request.auth.token.role == "admin";
//    }
//  }
//}












// На cartProduct если пользователь анонимный то при отсутствии товара в корзине мы сможем видить кнопку Create Account перейдя на которую мы попадаем на стек SignIn + SignUp (или SignUp + SignIn)
