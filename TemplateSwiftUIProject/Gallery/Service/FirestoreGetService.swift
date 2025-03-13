//
//  FirestoreGetService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//


import FirebaseFirestore
import Foundation

//enum DataFetchError: Error {
//    case mallsError(Error)
//    case shopsError(Error)
//    case popularProductsError(Error)
//    case decodingError
//}

final class FirestoreGetService {
    private let db = Firestore.firestore()
    
    func fetchMalls() async throws -> [Item] {
        ///withCheckedThrowingContinuation: – Это механизм, позволяющий «обернуть» callback-функцию (здесь, Firestore getDocuments с closure) в асинхронную функцию, работающую с async/await.
        ///continuation.resume(returning:) для возврата значений
        ///continuation.resume(throwing:) для выбрасывания ошибки.
        try await withCheckedThrowingContinuation { continuation in
            db.collection("malls").getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    do {
                        let items = try snapshot.documents.compactMap { doc -> Item? in
                            guard let title = doc.data()["title"] as? String else { throw FirebaseEnternalError.jsonConversionFailed }
                            return Item(id: doc.documentID, title: title)
                        }
                        continuation.resume(returning: items)
                    } catch {
                        ///decodingError?
                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
                    }
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func fetchShops() async throws -> [Item] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("shops").getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    do {
                        let items = try snapshot.documents.compactMap { doc -> Item? in
                            guard let title = doc.data()["title"] as? String else { throw FirebaseEnternalError.jsonConversionFailed }
                            return Item(id: doc.documentID, title: title)
                        }
                        continuation.resume(returning: items)
                    } catch {
                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
                    }
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func fetchPopularProducts() async throws -> [Item] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("popularProducts").getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    do {
                        let items = try snapshot.documents.compactMap { doc -> Item? in
                            guard let title = doc.data()["title"] as? String else { throw FirebaseEnternalError.jsonConversionFailed }
                            return Item(id: doc.documentID, title: title)
                        }
                        continuation.resume(returning: items)
                    } catch {
                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
                    }
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}


//final class FirestoreGetService {
//    private let db = Firestore.firestore()
//    
//    func fetchMalls() async throws -> [Item] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("malls").getDocuments { snapshot, error in
//                if let error = error {
//                    continuation.resume(throwing: DataFetchError.mallsError(error))
//                } else if let snapshot = snapshot {
//                    let items = snapshot.documents.compactMap { doc -> Item? in
//                        guard let title = doc.data()["title"] as? String else { return nil }
//                        return Item(id: doc.documentID, title: title)
//                    }
//                    continuation.resume(returning: items)
//                } else {
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//    }
//
//    
//    func fetchShops() async throws -> [Item] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("shops").getDocuments { snapshot, error in
//                if let error = error {
//                    continuation.resume(throwing: DataFetchError.shopsError(error))
//                } else if let snapshot = snapshot {
//                    let items = snapshot.documents.compactMap { doc -> Item? in
//                        guard let title = doc.data()["title"] as? String else { return nil }
//                        return Item(id: doc.documentID, title: title)
//                    }
//                    continuation.resume(returning: items)
//                } else {
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//    }
//    
//    func fetchPopularProducts() async throws -> [Item] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("popularProducts").getDocuments { snapshot, error in
//                if let error = error {
//                    continuation.resume(throwing: DataFetchError.popularProductsError(error))
//                } else if let snapshot = snapshot {
//                    let items = snapshot.documents.compactMap { doc -> Item? in
//                        guard let title = doc.data()["title"] as? String else { return nil }
//                        return Item(id: doc.documentID, title: title)
//                    }
//                    continuation.resume(returning: items)
//                } else {
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//    }
//}
