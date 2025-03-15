//
//  FirestoreGetService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

///Если путь db.collection("shops") в вашей базе данных Firestore не существует (то есть коллекция "shops" не была создана в Firestore), Firestore вернёт результат без ошибки. В этом случае массив snapshot.documents будет пустым.

///async throws — это комбинация для функций, которые выполняют асинхронные операции (требующие ожидания await) и могут выбрасывать ошибки (требующие обработки через try или catch).
///withCheckedThrowingContinuation: – Это механизм, позволяющий «обернуть» callback-функцию (здесь, Firestore getDocuments с closure) в асинхронную функцию, работающую с async/await.
///continuation.resume(returning:) для возврата значений
///continuation.resume(throwing:) для выбрасывания ошибки.



import FirebaseFirestore
import Foundation

final class FirestoreGetService {
    private let db = Firestore.firestore()
    
    func fetchMalls() async throws -> [Item] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("mall").getDocuments { snapshot, error in
                if let error = error {
                    print("malls error = \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    // Если коллекция существует, но документов нет
                    if snapshot.documents.isEmpty {
                        print("malls: empty snapshot")
                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                        return
                    }
                    do {
                        let items = try snapshot.documents.compactMap { doc -> Item? in
                            guard let title = doc.data()["title"] as? String else {
                                throw FirebaseEnternalError.jsonConversionFailed
                            }
                            return Item(id: doc.documentID, title: title)
                        }
                        // Если после преобразования получился пустой массив, выбрасываем ошибку
                        if items.isEmpty {
                            print("malls: conversion yielded empty")
                            continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                        } else {
                            print("malls snapshot != nil - \(items)")
                            continuation.resume(returning: items)
                        }
                    } catch {
                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
                    }
                } else {
                    print("malls snapshot == nil")
                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                }
            }
        }
    }
    
    func fetchShops() async throws -> [Item] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("shop").getDocuments { snapshot, error in
                if let error = error {
                    print("shops error = \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    if snapshot.documents.isEmpty {
                        print("shops: empty snapshot")
                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                        return
                    }
                    do {
                        let items = try snapshot.documents.compactMap { doc -> Item? in
                            guard let title = doc.data()["title"] as? String else {
                                throw FirebaseEnternalError.jsonConversionFailed
                            }
                            return Item(id: doc.documentID, title: title)
                        }
                        if items.isEmpty {
                            print("shops: conversion yielded empty")
                            continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                        } else {
                            print("shops snapshot != nil - \(items)")
                            continuation.resume(returning: items)
                        }
                    } catch {
                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
                    }
                } else {
                    print("shops snapshot == nil")
                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                }
            }
        }
    }
    
    func fetchPopularProducts() async throws -> [Item] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("popularProduct").getDocuments { snapshot, error in
                if let error = error {
                    print("popularProducts error = \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    if snapshot.documents.isEmpty {
                        print("popularProducts: empty snapshot")
                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                        return
                    }
                    do {
                        let items = try snapshot.documents.compactMap { doc -> Item? in
                            guard let title = doc.data()["title"] as? String else {
                                throw FirebaseEnternalError.jsonConversionFailed
                            }
                            return Item(id: doc.documentID, title: title)
                        }
                        if items.isEmpty {
                            print("popularProducts: conversion yielded empty")
                            continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                        } else {
                            print("popularProducts snapshot != nil - \(items)")
                            continuation.resume(returning: items)
                        }
                    } catch {
                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
                    }
                } else {
                    print("popularProducts snapshot == nil")
                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
                }
            }
        }
    }
}

//import FirebaseFirestore
//import Foundation
//
//final class FirestoreGetService {
//    private let db = Firestore.firestore()
//    
//    func fetchMalls() async throws -> [Item] {
//        ///async throws — это комбинация для функций, которые выполняют асинхронные операции (требующие ожидания await) и могут выбрасывать ошибки (требующие обработки через try или catch).
//        ///withCheckedThrowingContinuation: – Это механизм, позволяющий «обернуть» callback-функцию (здесь, Firestore getDocuments с closure) в асинхронную функцию, работающую с async/await.
//        ///continuation.resume(returning:) для возврата значений
//        ///continuation.resume(throwing:) для выбрасывания ошибки.
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("mall").getDocuments { snapshot, error in
//                if let error = error {
//                    print("malls error = \(error.localizedDescription)")
//                    continuation.resume(throwing: error)
//                } else if let snapshot = snapshot {
//                    do {
//                        let items = try snapshot.documents.compactMap { doc -> Item? in
//                            guard let title = doc.data()["title"] as? String else { throw FirebaseEnternalError.jsonConversionFailed }
//                            return Item(id: doc.documentID, title: title)
//                        }
//                        print("malls snapshot != nil - \(items)")
//                        continuation.resume(returning: items)
//                    } catch {
//                        ///decodingError?
//                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
//                    }
//                } else {
//                    print("malls snapshot == nil = \(String(describing: snapshot))")
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//    }
//    
//    func fetchShops() async throws -> [Item] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("shop").getDocuments { snapshot, error in
//                if let error = error {
//                    print("shops error = \(error.localizedDescription)")
//                    continuation.resume(throwing: error)
//                } else if let snapshot = snapshot {
//                    do {
//                        let items = try snapshot.documents.compactMap { doc -> Item? in
//                            guard let title = doc.data()["title"] as? String else { throw FirebaseEnternalError.jsonConversionFailed }
//                            return Item(id: doc.documentID, title: title)
//                        }
//                        print("shops snapshot != nil - \(items)")
//                        continuation.resume(returning: items)
//                    } catch {
//                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
//                    }
//                } else {
//                    print("shops snapshot == nil = \(String(describing: snapshot))")
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//    }
//    
//    func fetchPopularProducts() async throws -> [Item] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("popularProduct").getDocuments { snapshot, error in
//                if let error = error {
//                    print("popularProducts error = \(error.localizedDescription)")
//                    continuation.resume(throwing: error)
//                } else if let snapshot = snapshot {
//                    do {
//                        let items = try snapshot.documents.compactMap { doc -> Item? in
//                            guard let title = doc.data()["title"] as? String else { throw FirebaseEnternalError.jsonConversionFailed }
//                            return Item(id: doc.documentID, title: title)
//                        }
//                        print("popularProducts snapshot != nil - \(items)")
//                        continuation.resume(returning: items)
//                    } catch {
//                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
//                    }
//                } else {
//                    print("popularProducts snapshot == nil = \(String(describing: snapshot))")
//                    continuation.resume(returning: [])
//                }
//            }
//        }
//    }
//}


///Если для документа поле "title" отсутствует или его значение не является строкой (String): - Выполняется throw FirebaseEnternalError.jsonConversionFailed. + Ошибка выбрасывается, и дальнейшее выполнение замыкания compactMap для текущего документа прерывается.
///Если вы хотите, чтобы "проблемные" документы (без корректного "title") пропускались, вместо того чтобы выбрасывать ошибку, можно изменить логику compactMap:
//let items = snapshot.documents.compactMap { doc -> Item? in
//    guard let title = doc.data()["title"] as? String else {
//        // Пропускаем документ, возвращаем nil
//        print("Ошибка преобразования документа \(doc.documentID)")
//        return nil
//    }
//    return Item(id: doc.documentID, title: title)
//}
//continuation.resume(returning: items)






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
