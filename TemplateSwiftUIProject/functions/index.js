/**
 * Firebase Cloud Functions — TemplateSwiftUIProject
 * Реагирует на удаление аккаунта и очищает связанные данные
 */

const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
const {setGlobalOptions, logger} = require("firebase-functions");

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const userRef = admin.firestore().doc(`users/${uid}`);

  try {
    const snapshot = await userRef.get();

    if (!snapshot.exists) {
      logger.info(
          `ℹ️ У пользователя ${uid} не найдено данных в Firestore`,
          {uid},
      );
      return;
    }

    await admin.firestore().recursiveDelete(userRef);
    logger.info(
        `✅ Удалены данные пользователя: ${uid}`,
        {uid},
    );
  } catch (error) {
    logger.error(
        `❌ Ошибка при удалении данных пользователя: ${uid}`,
        {uid, error},
    );
  }
});
