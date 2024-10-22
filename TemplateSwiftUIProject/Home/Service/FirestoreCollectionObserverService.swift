//
//  FirestoreCollectionObserverService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//

//import Foundation
import Combine
import FirebaseFirestore


protocol FirestoreCollectionObserverProtocol {
    func observeCollection(at path: String) -> AnyPublisher<Result<[String], Error>, Never>
}


//class FirestoreCollectionObserverService: FirestoreCollectionObserverProtocol {
//    
//    private let db:Firestore
//    private var listener: ListenerRegistration?
//    private let subject = PassthroughSubject<Result<[String], Error>, Never>()
//    
//    init(db:Firestore = Firestore.firestore()) {
//        self.db = db
//    }
//    
//    func observeCollection(at path: String) -> AnyPublisher<Result<[String], Error>, Never> {
//        guard  PathValidator.validateCollectionPath(path) else {
////            return Fail(error: PathFirestoreError.invalidCollectionPath).eraseToAnyPublisher()
//            return Just(.failure(PathFirestoreError.invalidCollectionPath)).eraseToAnyPublisher()
//        }
//    }
//}

import Combine
import FirebaseFirestore

class FirestoreCollectionObserverService: FirestoreCollectionObserverProtocol {
    private let db: Firestore
    private var listener: ListenerRegistration?
    

    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func observeCollection(at path: String) -> AnyPublisher<Result<[String], Error>, Never> {
        guard PathValidator.validateCollectionPath(path) else {
            return Just(.failure(PathFirestoreError.invalidCollectionPath)).eraseToAnyPublisher()
        }
        let subject = PassthroughSubject<Result<[String], Error>, Never>()
        listener?.remove()
        listener = db.collection(path)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    subject.send(.failure(error))
                } else {
                    let data = querySnapshot?.documents.compactMap { $0.get("value") as? String } ?? []
                    subject.send(.success(data))
                }
            }

        return subject.eraseToAnyPublisher()
    }
}
