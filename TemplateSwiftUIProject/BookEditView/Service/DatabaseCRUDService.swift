//
//  DatabaseCRUDService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.11.24.
//
///Паблишер Future в Combine используется для представления асинхронной операции, которая завершится единственным значением или ошибкой.
///Идеальный для одноразовых асинхронных операций.


///childByAutoId() предпочтителен, если вам важен хронологический порядок и упрощенный доступ к данным на основе времени их создания.
///UUID().uuidString идеален для систем, требующих глобальной уникальности идентификаторов без привязки к времени создания.


import Combine
import FirebaseDatabase
import FirebaseFirestore

protocol DatabaseCRUDServiceProtocol {
    func addBook(path:String, _ book: BookRealtime) -> AnyPublisher<Result<Void,Error>, Never>
    func updateBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void,Error>, Never>
    func removeBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void,Error>, Never>
}


class RealtimeDatabaseCRUDService: DatabaseCRUDServiceProtocol {
    
    private let db:DatabaseReference
    
    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
    init(db: DatabaseReference = Database.database().reference()) {
        self.db = db
    }
    
    func addBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            ///UUID().uuidString
            let bookID = self?.db.child(path).childByAutoId().key
            var bookWithID = book
            bookWithID.id = bookID
            
            guard let childId = bookWithID.id else {
                let error = FirebaseEnternalAppError.failedDeployOptionalID
                promise(.success(.failure(error)))
                return
            }
            
            do {
                let bookData = try JSONEncoder().encode(bookWithID)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String:Any]
                
                guard let bookDict = bookDict else {
                    promise(.success(.failure(FirebaseEnternalAppError.jsonConversionFailed)))
                    return
                }
                /// ошибки которые приходят от сервера все кроме отсутствия сети мы не можем на них повлиять со стороны user.
                self?.db.child(path).child(childId).setValue(bookDict) { error, _ in
                    if let error = error {
                        promise(.success(.failure(error)))
                    } else {
                        promise(.success(.success(())))
                    }
                }
            } catch {
                promise(.success(.failure(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let childId = book.id else {
                let error = FirebaseEnternalAppError.failedDeployOptionalID
                promise(.success(.failure(error)))
                return
            }
            
            do {
                let bookData = try JSONEncoder().encode(book)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String:Any]
                guard let bookDict = bookDict else {
                    promise(.success(.failure(FirebaseEnternalAppError.jsonConversionFailed)))
                    return
                }
                self?.db.child(path).child(childId).updateChildValues(bookDict) { error, _ in
                    if let error = error {
                        promise(.success(.failure(error)))
                    } else {
                        promise(.success(.success(())))
                    }
                }
            } catch {
                promise(.success(.failure(error)))
            }
            
        }
        .eraseToAnyPublisher()
    }
    
    func removeBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let childId = book.id else {
                promise(.success(.failure(FirebaseEnternalAppError.failedDeployOptionalID)))
                return
            }
            
            self?.db.child(path).child(childId).removeValue { error, _ in
                if let error = error {
                    promise(.success(.failure(error)))
                } else {
                    promise(.success(.success(())))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}


class FirestoreDatabaseCRUDService: DatabaseCRUDServiceProtocol {
    
    private var db:Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func addBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future {  promise in
            
            do {
                let _ = try self.db.collection(path).addDocument(from: book) { error in
                    if let error = error {
                        promise(.success(.failure(error)))
                    } else {
                        promise(.success(.success(())))
                    }
                }
            }
            catch {
                promise(.success(.failure(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let bookID = book.id else {
                promise(.success(.failure(FirebaseEnternalAppError.failedDeployOptionalID)))
                return
            }
            do {
                let bookData = try JSONEncoder().encode(book)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String:Any]
                
                guard let bookDict = bookDict else {
                    promise(.success(.failure(FirebaseEnternalAppError.jsonConversionFailed)))
                    return
                }
                
                self?.db.collection(path).document(bookID).updateData(bookDict) { error in
                    if let error = error {
                        promise(.success(.failure(error)))
                    } else {
                        promise(.success(.success(())))
                    }
                }
            } catch {
                promise(.success(.failure(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeBook(path: String, _ book: BookRealtime) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let bookID = book.id else {
                promise(.success(.failure(FirebaseEnternalAppError.failedDeployOptionalID)))
                return
            }
            
            self?.db.collection(path).document(bookID).delete { error in
                if let error = error {
                    promise(.success(.failure(error)))
                } else {
                    promise(.success(.success(())))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}



//            { error in
//                if let error = error {
//                    promise(.success(.failure(error)))
//                } else {
//                    promise(.success(.success(())))
//                }
//            do {
//                let bookData = try JSONEncoder().encode(book)
//                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String:Any]
//                // Использование FirestoreEncoder для кодирования данных
//                guard let bookDict = bookDict else {
//                    promise(.success(.failure(FirebaseEnternalAppError.jsonConversionFailed)))
//                    return
//                }
//
//                self?.db.collection(path).document().setData(bookDict) { error in
//                    if let error = error {
//                        promise(.success(.failure(error)))
//                    } else {
//                        promise(.success(.success(())))
//                    }
//                }
//            } catch {
//                promise(.success(.failure(error)))
//            }
