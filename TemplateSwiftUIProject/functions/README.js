/**
 * 🔧 Firebase Cloud Functions — Архитектура проекта
 *
 * ✅ Используется v1 API (1st Gen):
 *   - functions.auth.user().onCreate / onDelete
 *   - functions.pubsub.schedule(...).onRun
 *   - Все функции работают на Node.js 20
 *   - Нет управления ресурсами (CPU, memory, concurrency)
 *   - Быстрый cold start, стабильный деплой
 *
 * ❌ v2 API (2nd Gen) не используется:
 *   - Не подключены onSchedule из firebase-functions/v2
 *   - Нет setGlobalOptions, App Check, Eventarc
 *   - Удалены все старые v2-функции (например, cleanupUnusedAvatars v2 HTTP)
 *
 * 📦 Стек проекта:
 *   - Язык: JavaScript
 *   - Среда выполнения: Node.js 20
 *   - Фреймворк: firebase-functions v1
 *   - SDK: firebase-admin (Firestore, Auth, Storage)
 *   - Инфраструктура: Firebase Hosting, Firestore, Storage
 *   - Инструменты: ESLint, npm, Git, Firebase CLI
 *
 * 📁 Структура функций:
 *   - createAnonTrackerOnSignup → Auth trigger (onCreate)
 *   - deleteUserData → Auth trigger (onDelete)
 *   - cleanupInactiveAnonUsers → Cron (каждые 24 часа)
 *   - cleanupInactiveAnonUsersTest → Cron (тестовая, 1 день)
 *   - cleanupUnusedAvatars → Cron (каждый понедельник 03:00)
 *
 * 🛡️ Причины выбора v1:
 *   - Простота и стабильность
 *   - Быстрая отладка и логирование
 *   - Нет необходимости в ресурсной настройке
 *   - Полная совместимость с Firebase tooling
 *
 * 📌 Вывод:
 *   - Проект стабилизирован на v1 API
 *   - Все функции работают корректно и задеплоены как Gen 1
 *   - В продакшене v1 — надёжный выбор для текущих задач
 */
