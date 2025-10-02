/**
 * Firebase Cloud Functions — TemplateSwiftUIProject
 * Реагирует на удаление аккаунта и очищает связанные данные
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
const { setGlobalOptions, logger } = require('firebase-functions');

setGlobalOptions({ maxInstances: 10 });
admin.initializeApp();

exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const userRef = admin.firestore().doc(`users/${uid}`);

  try {
    // 1. Удаляем все данные пользователя в Firestore (включая вложенные коллекции)
    await admin.firestore().recursiveDelete(userRef);
    logger.info(`✅ Удалены все Firestore-данные пользователя: ${uid}`, { uid });

    // 2. Удаляем все файлы пользователя в Storage по пути avatars/${uid}/
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: `avatars/${uid}/` });

    if (files.length > 0) {
      await Promise.all(files.map((file) => file.delete()));
      logger.info(`✅ Удалены все файлы в Storage для пользователя: ${uid}`, { uid });
    } else {
      logger.info(`ℹ️ Нет файлов в Storage для пользователя: ${uid}`, { uid });
    }
  } catch (error) {
    logger.error(`❌ Ошибка при удалении данных пользователя: ${uid}`, {
      uid,
      error,
    });
  }
});

exports.cleanupUnusedAvatars =
  require('./cleanupUnusedAvatars').cleanupUnusedAvatars;

