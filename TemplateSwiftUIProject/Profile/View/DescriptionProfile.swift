


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
/// необходимо логи которые мы получаем в терминал из index.js совместить с Crashlistics ? или как разработчику мониторить логи из index.js ?

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

// сценарии :





//1. Anon → SignIn (моментальное удаление анон)


// !!! Мы не будем реализовывать этот код что бы не усложнять логику (оставим только удаление протухших анон аккаунтов)

///Вот тут и появляется «сирота»: текущий анонимный uid остаётся в Firebase, но пользователь больше никогда не сможет им воспользоваться. Именно его и нужно удалять.
///Клиент (Swift, iOS) – после успешного signIn мы берём anonUid (старый анонимный пользователь) и отправляем его в Cloud Function.
/// if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous { anonUid = currentUser.uid }
/// Cloud Function (Node.js, Firebase Admin SDK) – принимает uid, проверяет что это анонимный пользователь, и удаляет его. Это вызовет твой onDelete‑триггер, который уже чистит Firestore и Storage.






//2. Анонимный аккаунт долго не используется (удаление анон по треккеру/таймеру)

///Firebase не удаляет анонимные аккаунты автоматически.
///При создании анонимного аккаунта сохраняют в Firestore метку createdAt и обновляют lastActiveAt при каждом запуске приложения.
///Запускают scheduled Cloud Function (cron, например раз в сутки).
///Функция ищет анонимные аккаунты, у которых lastActiveAt < now - 30d (или 90d, зависит от политики).
///Для таких аккаунтов вызывается admin.auth().deleteUser(uid).
///Это автоматически триггерит onDelete → очистку данных в Firestore и Storage.


// !!!! cleanupAnonTracker удален (в нашей реализации мы никогда не удаляем anonAccountTracker)
// мы когда все пользователи попадают в выборку для постоянных меням поле anonUser на true



// тесты с отсрочкой:

// ✅Тест1 update anonAccountTracker: Создаем Анонимного (SignOut) -> SignUp(link updatePermanentAccountTracker) -> в момент создание anonUser должен быть создан anonAccountTracker, через сутки anonAccountTracker должен быть изменен.
// SignOut на второй тест


// ✅Тест1.2 update anonAccountTracker: Создаем Анонимного (SignOut) -> SignUp(link deleteAnonUserAndData) -> Add profile + Avatar через сутки anonAccountTracker должен быть изменен.
// SignOut на второй тест


// ✅Тест2 удаление Anon: Создаем Анонимного () -> Создаем card -> SignIn -> на следующий день в это же время ждем удаления сиротского Anon и данных Firestore + Storage

// Тест3 удаление Anon: Создаем Анонимного (deleteAnonUser) ->  SignIn -> на следующий день в это же время ждем удаления сиротского Anon (без данных)

// Тест4 Проверка cleanupUnusedAvatars: добавить новые сиротские аватар в аккаунты klenovptz + klenovminsk (тут уже есть просроченные по времени которые удалятся в следующий понедельник) / для klenovKlon2411 создать новые сиротские аватар




// тест в реальном времени:

// Тест5 Проверка deleteUserData (удаление данных profile + storage): SignUp klenovDeleteUserData (Profile + Avatars + card) -> DeleteAccount








// если эти тесты отработали удаляем cleanupInactiveAnonUsersTest.js + создаем два аналогичных аккаунта для теста cleanupInactiveAnonUsers.js
// два аккаунта на мою почту проверяем в понедельник работу cleanupUnusedAvatars.js + удаляем их и проверяем работу deleteUserData.js

//ProfileView и дочерние View 









//Что такое Timestamp(date: Date()) ?

///В iOS SDK для Firestore есть тип Timestamp (FirebaseFirestore.Timestamp).
///Это обёртка вокруг даты/времени, которая хранит значение в формате «секунды + наносекунды с начала эпохи (Unix time)».
///Когда ты пишешь Timestamp(date: Date()), ты берёшь текущую Date из Swift и преобразуешь её в Firestore‑совместимый Timestamp.
///Firestore поддерживает собственный тип данных timestamp. То есть это не строка и не число, а именно отдельный тип, который можно: сортировать по времени, использовать в запросах (where("lastActiveAt", "<", cutoff)), сравнивать и фильтровать.
///В Firestore Console документ users/{uid} будет выглядеть примерно так:

//createdAt     September 28, 2025 at 14:35:12 UTC+3   (timestamp)
//lastActiveAt  September 28, 2025 at 14:35:12 UTC+3   (timestamp)
//isAnonymous   true                                    (boolean)




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














// На cartProduct если пользователь анонимный то при отсутствии товара в корзине мы сможем видить кнопку Create Account перейдя на которую мы попадаем на стек SignIn + SignUp (или SignUp + SignIn)







// old index.js

///**
// * Firebase Cloud Functions — TemplateSwiftUIProject
// * Реагирует на удаление аккаунта и очищает связанные данные
// */
//
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
//      await Promise.all(files.map((file) => file.delete()));
//      logger.info(`✅ Удалены все файлы в Storage для пользователя: ${uid}`, { uid });
//    } else {
//      logger.info(`ℹ️ Нет файлов в Storage для пользователя: ${uid}`, { uid });
//    }
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
//exports.cleanupInactiveAnonUsersTest =
// require('./cleanupInactiveAnonUsersTest').cleanupInactiveAnonUsersTest;
//
//exports.cleanupInactiveAnonUsers =
// require('./cleanupInactiveAnonUsers').cleanupInactiveAnonUsers;
