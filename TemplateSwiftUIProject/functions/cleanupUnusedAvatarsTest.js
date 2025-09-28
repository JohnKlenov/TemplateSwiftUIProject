/**
 * Cloud Function: cleanupUnusedAvatarsTest
 *
 * 🧪 Задача:
 *   Тестовая версия функции очистки аватаров. Работает чаще и с меньшим grace‑периодом,
 *   чтобы быстрее проверять корректность логики.
 *
 * 🔄 Логика работы:
 * 1. Функция запускается по расписанию (каждые 30 минут).
 * 2. Из Firestore через collectionGroup("userProfileData") выбираются все документы профилей.
 * 3. Из photoURL извлекается имя файла (если есть).
 * 4. В Storage листятся все файлы по пути avatars/{uid}/.
 * 5. Для каждого файла получаем метаданные (updated/timeCreated).
 * 6. Сортируем файлы по дате обновления (сначала новые).
 * 7. Формируем список «не трогать» (keep).
 * 8. Определяем кандидатов на удаление:
 *    - Файлы старше grace‑периода (30 минут).
 *    - Файлы, которые не входят в список keep.
 * 9. Удаляем такие файлы из Storage.
 *
 * ⚙️ Настройки:
 *   - GRACE_MINUTES: 30 минут.
 *   - KEEP_RECENT: сколько последних версий хранить сверх текущей (по умолчанию 2).
 *   - PROFILE_COLLECTION_GROUP: имя коллекции профилей (userProfileData).
 *
 * 🛡️ Защита от ошибок:
 *   - Если у пользователя нет photoURL → просто не добавляем «текущий» файл в keep.
 *   - Если в Storage нет файлов по пути avatars/{uid}/ → пропускаем пользователя.
 *   - Если нет документов userProfileData → функция завершится без ошибок.
 *   - Ошибки удаления конкретного файла логируются, но не прерывают выполнение.
 */

const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const storage = admin.storage().bucket(process.env.FIREBASE_STORAGE_BUCKET);

// Настройки для теста
const GRACE_MINUTES = 30;
const KEEP_RECENT = parseInt(process.env.AVATAR_KEEP_RECENT || '2', 10);
const PROFILE_COLLECTION_GROUP = 'userProfileData';

// Вспомогательная функция: извлекает имя файла из URL
function extractFileNameFromUrl(url) {
  try {
    const u = new URL(url);
    const decodedPath = decodeURIComponent(
      u.pathname.replace(/^\/v0\/b\/[^/]+\/o\//, '')
    );
    const parts = decodedPath.split('/');
    return parts[parts.length - 1];
  } catch {
    return null;
  }
}

// Основная функция очистки (тестовый режим)
const cleanupUnusedAvatarsTest = onSchedule('every 30 minutes', async () => {
  const now = Date.now();
  const graceMs = GRACE_MINUTES * 60 * 1000;

  const profilesSnap = await db.collectionGroup(PROFILE_COLLECTION_GROUP).get();

  for (const doc of profilesSnap.docs) {
    const data = doc.data();
    const uid = doc.id;
    const photoURL = data.photoURL || null;
    const usedFileName = photoURL ? extractFileNameFromUrl(photoURL) : null;

    const prefix = `avatars/${uid}/`;

    const [files] = await storage.getFiles({ prefix });
    if (!files.length) continue;

    const withMeta = await Promise.all(
      files.map(async (file) => {
        const [meta] = await file.getMetadata();
        const updated = new Date(meta.updated || meta.timeCreated || Date.now()).getTime();
        const name = file.name.replace(prefix, '');
        return { file, name, updated };
      })
    );

    withMeta.sort((a, b) => b.updated - a.updated);

    const keep = new Set();
    if (usedFileName) keep.add(usedFileName);

    for (const { name } of withMeta) {
      if (keep.size >= (usedFileName ? 1 + KEEP_RECENT : KEEP_RECENT)) break;
      if (!keep.has(name)) keep.add(name);
    }

    const toDelete = withMeta.filter(({ name, updated }) => {
      const isOld = now - updated > graceMs;
      return isOld && !keep.has(name);
    });

    for (const item of toDelete) {
      try {
        await item.file.delete();
        console.log(`[TEST] Deleted ${item.file.name}`);
      } catch (e) {
        console.warn(`[TEST] Failed to delete ${item.file.name}:`, e);
      }
    }
  }
});

module.exports = { cleanupUnusedAvatarsTest };
