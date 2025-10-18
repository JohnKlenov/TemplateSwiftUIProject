const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();

/**
 * PROD: Очистка анонимных аккаунтов, неактивных более 30 дней
 */
exports.cleanupInactiveAnonUsers = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 30);
    const cutoff = admin.firestore.Timestamp.fromDate(cutoffDate);

    console.log(`🧹 [PROD] Ищем анонимные аккаунты, неактивные до ${cutoff.toDate().toISOString()}`);

    const snapshot = await db.collectionGroup('anonAccountTracker')
      .where('isAnonymous', '==', true)
      .where('lastActiveAt', '<', cutoff)
      .get();

    if (snapshot.empty) {
      console.log('ℹ️ [PROD] Нет неактивных анонимных аккаунтов для удаления');
      return null;
    }

    const tasks = [];
    snapshot.forEach((doc) => {
      const uid = doc.id;
      tasks.push(handleCandidateUser(uid, doc.ref, '[PROD]'));
    });

    await Promise.all(tasks);
    console.log(`✅ [PROD] Завершена очистка. Обработано ${tasks.length} кандидатов.`);
    return null;
  });

async function handleCandidateUser(uid, trackerRef, tag) {
  try {
    const userRecord = await admin.auth().getUser(uid);
    const isStillAnonymous = userRecord.providerData.length === 0;

    if (!isStillAnonymous) {
      console.log(`⏭️ ${tag} Пропускаем ${uid}: пользователь уже не анонимный`);
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


