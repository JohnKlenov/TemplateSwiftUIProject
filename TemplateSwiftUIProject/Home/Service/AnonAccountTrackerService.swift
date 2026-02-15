//
//  AnonAccountTrackerService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.09.25.
//

/// Обновляет поле `lastActiveAt` в документе трекера анонимного аккаунта.
///
/// 🔎 Логика:
/// - Документ `users/{uid}/anonAccountTracker/{uid}` создаётся Cloud Function
///   `createAnonTrackerOnSignup` при первом создании анонимного пользователя.
/// - Однако на клиенте вызов может произойти раньше, чем Cloud Function успеет
///   создать документ (или при оффлайн‑режиме).
/// - Чтобы избежать ошибки `No document to update`в консоли, вместо `updateData`
///   используется `setData(merge: true)`.
///   - Если документ уже существует → обновляется только поле `lastActiveAt`.
///   - Если документа ещё нет → он будет создан с этим полем.
///   - Cloud Function перезапишет документ, если клиент успел создать его раньше.Это не страшно, потому что разница во времени будет считаться в миллисекундах. Лучший паттерн: использовать set(..., { merge: true }) и на клиенте тоже setData(merge: true).
/// - Таким образом метод становится идемпотентным и безопасным для повторных вызовов.

// Firestore и ошибки unavailable / deadlineExceeded:
//
// Эти ошибки НЕ означают, что запись потеряна или отменена.
// Firestore работает по модели "local‑first":
// 1) setData сначала записывает данные в локальный офлайн‑кэш
// 2) listener сразу отдаёт обновлённые данные
// 3) Firestore ставит операцию в очередь синхронизации
// 4) если сети нет — попытка отправки завершается ошибкой unavailable/deadlineExceeded
//
// ВАЖНО:
// - даже если в completion пришла ошибка unavailable/deadlineExceeded,
//   Firestore НЕ удаляет операцию из очереди
// - локальная запись остаётся в кэше
// - Firestore продолжает пытаться отправить её позже автоматически
// - при появлении сети запись будет доставлена на сервер
//
// Эти ошибки — нормальная часть офлайн‑режима Firestore,
// поэтому их обычно НЕ логируют как критические.
//
// Единственные ошибки, которые действительно означают,
// что запись НЕ будет отправлена — это ошибки безопасности:
// permissionDenied, unauthenticated, invalidArgument и т.п.
// Такие ошибки нужно логировать.
//
// Итог:
// Ошибки unavailable/deadlineExceeded НЕ приводят к тому,
// что анонимный пользователь будет удалён раньше времени.
// Запись lastActiveAt всё равно будет отправлена при следующей успешной синхронизации.



// Почему в AnonAccountTrackerService игнорируются только unavailable и deadlineExceeded:
//
// Хотя Firestore имеет много retryable‑ошибок, в этом сервисе мы фильтруем
// только две из них — unavailable и deadlineExceeded — и это сделано намеренно.
//
// Эти две ошибки возникают постоянно и являются нормальным офлайн‑поведением:
// - unavailable — нет сети или сервер временно недоступен
// - deadlineExceeded — слишком медленное соединение, запрос не успел выполниться
//
// Они НЕ означают, что запись не будет отправлена. Firestore продолжит
// синхронизацию автоматически, поэтому логировать такие ошибки бессмысленно:
// это создаёт шум и засоряет Crashlytics.
//
// Остальные retryable‑ошибки (internal, aborted, resource_exhausted,
// unknown, data_loss и др.) встречаются редко и могут указывать на реальные
// проблемы: сбои SDK, конфликты транзакций, превышение квот и т.п.
// Поэтому их важно логировать.
//
// Итог:
// - unavailable и deadlineExceeded — нормальные офлайн‑ошибки, их игнорируем
// - остальные retryable‑ошибки — редкие и потенциально важные, их логируем
// - fatal‑ошибки (permissionDenied, invalidArgument и др.) всегда логируем,
//   так как Firestore прекращает попытки и откатывает локальные изменения


import FirebaseFirestore
import Combine

protocol AnonAccountTrackerServiceProtocol {
    func updateLastActive(for uid: String)
}

final class AnonAccountTrackerService: AnonAccountTrackerServiceProtocol {

    private let db: Firestore
    private let errorCenter: ErrorDiagnosticsProtocol

    init(
        db: Firestore = Firestore.firestore(),
        errorCenter: ErrorDiagnosticsProtocol
    ) {
        self.db = db
        self.errorCenter = errorCenter
    }

    func updateLastActive(for uid: String) {
        let data: [String: Any] = [
            "lastActiveAt": Timestamp(date: Date())
        ]

        db.collection("users")
            .document(uid)
            .collection("anonAccountTracker")
            .document(uid)
            .setData(data, merge: true) { [weak self] error in

                guard let self = self else { return }

                if let error = error {
                    if self.shouldLog(error: error) {
                        self.handleError(error, uid: uid)
                    }
                }
            }
    }

    /// Фильтрация ошибок Firestore, чтобы не логировать "нормальные" офлайн‑ошибки
    private func shouldLog(error: Error) -> Bool {
        let nsError = error as NSError
        
        // Логируем всё, что не Firestore
        guard nsError.domain == FirestoreErrorDomain else {
            return true
        }
        
        switch nsError.code {
        case FirestoreErrorCode.unavailable.rawValue,
             FirestoreErrorCode.deadlineExceeded.rawValue:
            // Нормальные офлайн‑ошибки — не логируем
            return false
        default:
            return true
        }
    }
    
    private func handleError(_ error: Error, uid: String) {
        let fullContext = "\(ErrorContext.AnonAccountTrackerService_updateLastActive.rawValue) | uid: \(uid)"
        let _ = errorCenter.handle(error: error, context: fullContext)
    }
}







// MARK: - before inject ErrorDiagnosticsCenterProtocol

//import FirebaseFirestore
//import FirebaseAuth
//import Combine

//protocol AnonAccountTrackerServiceProtocol {
//    func createOrUpdateTracker(for uid: String)
//    func updateLastActive(for uid: String)
//}
//
//class AnonAccountTrackerService: AnonAccountTrackerServiceProtocol {
//    private let db = Firestore.firestore()
//    
//    func createOrUpdateTracker(for uid: String) {
//        let now = Timestamp(date: Date())
//        db.collection("users").document(uid)
//            .collection("anonAccountTracker").document(uid)
//            .setData([
//                "createdAt": now,
//                "lastActiveAt": now,
//                "isAnonymous": true
//            ], merge: true)
//    }
//    
//    /// Обновляет поле `lastActiveAt` в документе трекера анонимного аккаунта.
//    ///
//    /// 🔎 Логика:
//    /// - Документ `users/{uid}/anonAccountTracker/{uid}` создаётся Cloud Function
//    ///   `createAnonTrackerOnSignup` при первом создании анонимного пользователя.
//    /// - Однако на клиенте вызов может произойти раньше, чем Cloud Function успеет
//    ///   создать документ (или при оффлайн‑режиме).
//    /// - Чтобы избежать ошибки `No document to update`в консоли, вместо `updateData`
//    ///   используется `setData(merge: true)`.
//    ///   - Если документ уже существует → обновляется только поле `lastActiveAt`.
//    ///   - Если документа ещё нет → он будет создан с этим полем.
//    ///   - Cloud Function перезапишет документ, если клиент успел создать его раньше.Это не страшно, потому что разница во времени будет считаться в миллисекундах. Лучший паттерн: использовать set(..., { merge: true }) и на клиенте тоже setData(merge: true).
//    /// - Таким образом метод становится идемпотентным и безопасным для повторных вызовов.
//    func updateLastActive(for uid: String) {
//        db.collection("users").document(uid)
//            .collection("anonAccountTracker").document(uid)
//            .setData([
//                "lastActiveAt": Timestamp(date: Date())
//            ], merge: true)
//    }
//}
