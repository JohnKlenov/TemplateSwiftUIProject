const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Триггер: срабатывает при удалении пользователя из Firebase Auth.
 * Удаляет все связанные данные: Firestore-документы и Storage-файлы.
 */
exports.deleteUserData = functions.auth.user().onDelete(async (user) => {
  const uid = user.uid;
  const userRef = db.doc(`users/${uid}`);

  try {
    // Удаляем все Firestore-данные пользователя (включая вложенные коллекции)
    await admin.firestore().recursiveDelete(userRef);
    console.log(`✅ Firestore-данные удалены: ${uid}`);

    // Удаляем все файлы пользователя в Storage по пути avatars/${uid}/
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: `avatars/${uid}/` });

    if (files.length > 0) {
      await Promise.all(files.map((file) => file.delete()));
      console.log(`✅ Storage-файлы удалены: ${uid}`);
    } else {
      console.log(`ℹ️ Нет файлов в Storage для: ${uid}`);
    }
  } catch (error) {
    console.error(`❌ Ошибка при удалении данных пользователя: ${uid}`, error);
  }
});

