//
//  AnonAccountTrackerService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.09.25.
//

import FirebaseFirestore
import FirebaseAuth
import Combine

protocol AnonAccountTrackerServiceProtocol {
    func createOrUpdateTracker(for uid: String)
    func updateLastActive(for uid: String)
}

class AnonAccountTrackerService: AnonAccountTrackerServiceProtocol {
    private let db = Firestore.firestore()
    
    func createOrUpdateTracker(for uid: String) {
        let now = Timestamp(date: Date())
        db.collection("users").document(uid)
            .collection("anonAccountTracker").document(uid)
            .setData([
                "createdAt": now,
                "lastActiveAt": now,
                "isAnonymous": true
            ], merge: true)
    }
    
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
    func updateLastActive(for uid: String) {
        db.collection("users").document(uid)
            .collection("anonAccountTracker").document(uid)
            .setData([
                "lastActiveAt": Timestamp(date: Date())
            ], merge: true)
    }
}






// MARK: - Tresh



//    func updateLastActive(for uid: String) {
//        db.collection("users").document(uid)
//            .collection("anonAccountTracker").document(uid)
//            .updateData([
//                "lastActiveAt": Timestamp(date: Date())
//            ])
//    }
