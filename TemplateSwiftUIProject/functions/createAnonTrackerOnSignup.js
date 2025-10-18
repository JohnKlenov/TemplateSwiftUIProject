const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * Триггер: срабатывает при создании пользователя в Firebase Auth.
 * Если аккаунт анонимный — создаёт служебный документ
 * users/{uid}/anonAccountTracker/{uid}.
 */
exports.createAnonTrackerOnSignup = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const isAnonymous = user.providerData.length === 0;

  if (!isAnonymous) {
    console.log(`⏭️ Пропускаем ${uid}: не анонимный`);
    return;
  }

  const trackerRef = db.collection('users').doc(uid)
                       .collection('anonAccountTracker').doc(uid);

  try {
    await trackerRef.set({
      isAnonymous: true,
      lastActiveAt: admin.firestore.Timestamp.now(),
    });
    console.log(`✅ Создан anonAccountTracker для ${uid}`);
  } catch (error) {
    console.error(`❌ Ошибка при создании трекера для ${uid}`, error);
  }
});


