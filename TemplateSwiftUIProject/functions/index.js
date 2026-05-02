/**
 * Firebase Cloud Functions — TemplateSwiftUIProject
 * Централизованная точка входа для всех триггеров и задач
 */

const admin = require('firebase-admin');

// Инициализация Admin SDK один раз
admin.initializeApp();

// 🔹 Триггеры Auth
exports.createAnonTrackerOnSignup =
  require('./createAnonTrackerOnSignup').createAnonTrackerOnSignup;

exports.deleteUserData =
  require('./deleteUserData').deleteUserData;

// 🔹 Плановые задачи (cron)
exports.cleanupInactiveAnonUsers =
  require('./cleanupInactiveAnonUsers').cleanupInactiveAnonUsers;

// 🔹 Дополнительные задачи
exports.cleanupUnusedAvatars =
  require('./cleanupUnusedAvatars').cleanupUnusedAvatars;

// 🔹 Playlist cover generator
exports.generatePlaylistCover =
  require('./generatePlaylistCover').generatePlaylistCover;
