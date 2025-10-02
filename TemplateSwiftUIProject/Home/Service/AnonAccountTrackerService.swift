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
    
    func updateLastActive(for uid: String) {
        db.collection("users").document(uid)
            .collection("anonAccountTracker").document(uid)
            .updateData([
                "lastActiveAt": Timestamp(date: Date())
            ])
    }
}

