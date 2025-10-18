/**
 * Cloud Function: cleanupUnusedAvatars
 *
 * 🧹 Задача:
 *   Автоматическая уборка «сиротских» аватаров в Firebase Storage, которые
 *   больше не используются в профиле пользователя.
 *
 * 🔄 Логика работы:
 * 1. Функция запускается по расписанию (каждый понедельник в 03:00).
 * 2. Из Firestore через collectionGroup("userProfileData") выбираются все документы профилей.
 *    - Ожидается структура: users/{uid}/userProfileData/{uid}.
 *    - Из документа берётся поле photoURL (текущий используемый аватар).
 * 3. Из photoURL извлекается имя файла (например, avatar_1693648123.jpg).
 * 4. В Storage листятся все файлы по пути avatars/{uid}/.
 * 5. Для каждого файла получаем метаданные (updated/timeCreated).
 * 6. Сортируем файлы по дате обновления (сначала новые).
 * 7. Формируем список «не трогать» (keep).
 * 8. Определяем кандидатов на удаление.
 * 9. Удаляем такие файлы из Storage.
 *
 * ⚙️ Настройки:
 *   - GRACE_DAYS: сколько дней хранить «свежие» файлы (по умолчанию 7).
 *   - KEEP_RECENT: сколько последних версий хранить сверх текущей (по умолчанию 2).
 *   - PROFILE_COLLECTION_GROUP: имя коллекции профилей (userProfileData).
 *
 * 🛡️ Защита от ошибок:
 *   - Если у пользователя нет photoURL → просто не добавляем «текущий» файл в keep.
 *   - Если в Storage нет файлов по пути avatars/{uid}/ → пропускаем пользователя.
 *   - Если нет документов userProfileData → функция завершится без ошибок.
 *   - Ошибки удаления конкретного файла логируются, но не прерывают выполнение.
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

const db = admin.firestore();
const storage = admin.storage().bucket(process.env.FIREBASE_STORAGE_BUCKET);

// Настройки
const GRACE_DAYS = parseInt(process.env.AVATAR_GRACE_DAYS || '7', 10);
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

// Основная функция очистки (v1 API)
const cleanupUnusedAvatars = functions.pubsub
  .schedule('every monday 03:00')
  .onRun(async () => {
    const now = Date.now();
    const graceMs = GRACE_DAYS * 24 * 60 * 60 * 1000;

    // Получаем все профили пользователей
    const profilesSnap = await db.collectionGroup(PROFILE_COLLECTION_GROUP).get();

    for (const doc of profilesSnap.docs) {
      const data = doc.data();
      const uid = doc.id;
      const photoURL = data.photoURL || null;
      const usedFileName = photoURL ? extractFileNameFromUrl(photoURL) : null;

      // Папка с аватарами конкретного пользователя
      const prefix = `avatars/${uid}/`;

      const [files] = await storage.getFiles({ prefix });
      if (!files.length) continue;

      // Получаем метаданные и сортируем по дате обновления
      const withMeta = await Promise.all(
        files.map(async (file) => {
          const [meta] = await file.getMetadata();
          const updated = new Date(meta.updated || meta.timeCreated || Date.now()).getTime();
          const name = file.name.replace(prefix, '');
          return { file, name, updated };
        })
      );

      withMeta.sort((a, b) => b.updated - a.updated);

      // Формируем список "не трогать"
      const keep = new Set();
      if (usedFileName) keep.add(usedFileName);

      for (const { name } of withMeta) {
        if (keep.size >= (usedFileName ? 1 + KEEP_RECENT : KEEP_RECENT)) break;
        if (!keep.has(name)) keep.add(name);
      }

      // Определяем кандидатов на удаление
      const toDelete = withMeta.filter(({ name, updated }) => {
        const isOld = now - updated > graceMs;
        return isOld && !keep.has(name);
      });

      // Удаляем старые и неиспользуемые
      for (const item of toDelete) {
        try {
          await item.file.delete();
          console.log(`Deleted ${item.file.name}`);
        } catch (e) {
          console.warn(`Failed to delete ${item.file.name}:`, e);
        }
      }
    }
  });

module.exports = { cleanupUnusedAvatars };
