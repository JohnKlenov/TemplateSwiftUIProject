const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * TEST: Очистка анонимных аккаунтов, неактивных более 1 дня
 */
exports.cleanupInactiveAnonUsersTest = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 1);
    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);

    console.log(`🧪 [TEST] Ищем анонимные аккаунты, неактивные до ${cutoff.toDate().toISOString()}`);

// 🔎 Отладочный тестовый запрос
    try {
      const snapshot = await db.collectionGroup('anonAccountTracker').limit(1).get();
      console.log('Docs found (test):', snapshot.size);
    } catch (e) {
      console.error('Ошибка при простом запросе:', e);
      return null; // прерываем выполнение, если даже тестовый запрос падает
    }

// 🔎 Диагностика типов поля lastActiveAt
const testSnap2 = await db.collectionGroup('anonAccountTracker').limit(10).get();
testSnap2.forEach((doc) => {
  const data = doc.data();
  let type = 'undefined';
  if (data.lastActiveAt instanceof admin.firestore.Timestamp) {
    type = 'Timestamp';
  } else if (data.lastActiveAt !== undefined) {
    type = typeof data.lastActiveAt;
  }
  console.log(doc.id, 'lastActiveAt:', data.lastActiveAt, 'type:', type);
});


    // 🔎 Диагностика типов поля isAnonymous
    const testSnap = await db.collectionGroup('anonAccountTracker').limit(10).get();
    testSnap.forEach((doc) => {
      const data = doc.data();
      console.log(doc.id, 'isAnonymous:', data.isAnonymous, 'type:', typeof data.isAnonymous);
    });

    const snapshot = await db.collectionGroup('anonAccountTracker')
      .where('isAnonymous', '==', true)
.where('lastActiveAt', '<', cutoff)
      .get();

    if (snapshot.empty) {
      console.log('ℹ️ [TEST] Нет неактивных анонимных аккаунтов для удаления');
      return null;
    }

    const tasks = [];
    snapshot.forEach((doc) => {
      const uid = doc.id;
      tasks.push(handleCandidateUser(uid, doc.ref, '[TEST]'));
    });

    await Promise.all(tasks);
    console.log(`✅ [TEST] Завершена очистка. Обработано ${tasks.length} кандидатов.`);
    return null;
  });

async function handleCandidateUser(uid, trackerRef, tag) {
  try {
    const userRecord = await admin.auth().getUser(uid);
    const isStillAnonymous = userRecord.providerData.length === 0;

    if (!isStillAnonymous) {
      console.log(`⏭️ ${tag} Пропускаем ${uid}: пользователь уже не анонимный`);
      // Обновляем трекер, чтобы он больше не попадал в выборку
      await trackerRef.update({ isAnonymous: false });
      return;
    }

    await admin.auth().deleteUser(uid);
    console.log(`✅ ${tag} Удалён анонимный пользователь ${uid}`);
  } catch (err) {
    if (err.code === 'auth/user-not-found') {
      console.log(`ℹ️ ${tag} ${uid} уже удалён из Auth`);
      await trackerRef.update({ isAnonymous: false });
      return;
    }
    console.error(`❌ ${tag} Ошибка при обработке ${uid}:`, err);
  }
}


