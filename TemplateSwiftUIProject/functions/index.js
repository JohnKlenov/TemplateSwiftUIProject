/**
 * Firebase Cloud Functions — TemplateSwiftUIProject
 * Реагирует на удаление аккаунта и очищает связанные данные
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const {setGlobalOptions, logger} = require('firebase-functions');

setGlobalOptions({maxInstances: 10});
admin.initializeApp();

exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const userRef = admin.firestore().doc(`users/${uid}`);

  try {
    // Удаляем все данные пользователя, включая вложенные коллекции
    await admin.firestore().recursiveDelete(userRef);

    logger.info(`✅ Удалены все данные пользователя: ${uid}`, {uid});
  } catch (error) {
    logger.error(`❌ Ошибка при удалении данных пользователя: ${uid}`, {
      uid,
      error,
    });
  }
});

exports.cleanupUnusedAvatars =
  require('./cleanupUnusedAvatars').cleanupUnusedAvatars;

exports.cleanupUnusedAvatarsTest =
  require('./cleanupUnusedAvatarsTest').cleanupUnusedAvatarsTest;

