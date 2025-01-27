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

///тестируем рабуту кэша при удалении document по path за которым идет наблюдение addSnapshotListener
///Set rules - запрет на запись всем пользователям.
///Отключаем инет, удаляем документ - отрабатывает addSnapshotListener без удаленным элементом, блок для delete не отработал не разу.
///Подключаем инет, срабатывает блок для delete и возвращает ошибку + отрабатывает addSnapshotListener с удаленным элементом - локальная кэшированная операция откатывается (rollback).
///
///если удалить без интернета и прав доступа не дождаться подключения кансельнуть приложения из памяти затем снова его загрузить но уже с инетом
///сначало addSnapshotListener отработает без  удаленного элемента(видимо всегда сначало работает с локальным кэшом) затем эта отложенная операция перешла в реализации и была отклонена из за отсутствия прав на запись что привело к повторному вызову addSnapshotListener
///
///Теперь удаляем с правами на запись для всех users с отключеным инет - отрабатывает addSnapshotListener без удаленного документа
///включаем инет - отрабатывает только блок delete с success. addSnapshotListener не отрабатывает больше.




import Combine
import FirebaseDatabase
import FirebaseFirestore

protocol DatabaseCRUDServiceProtocol:ObservableObject {
    func addBook(path:String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
}


class RealtimeDatabaseCRUDService: DatabaseCRUDServiceProtocol {
    
    private let db:DatabaseReference
    
    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
    init(db: DatabaseReference = Database.database().reference()) {
        self.db = db
    }
    
    func addBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
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
    
    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
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
    
    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
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
    
    deinit {
        print("deinit RealtimeDatabaseCRUDService")
    }
}


class FirestoreDatabaseCRUDService: DatabaseCRUDServiceProtocol {
    
    private var db:Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func addBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future {  promise in
            
            do {
                print("func addBook(path")
                let _ = try self.db.collection(path).addDocument(from: book) { error in
                    print("addDocument - \(String(describing: error))")
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
    
    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let bookID = book.id else {
                promise(.success(.failure(FirebaseEnternalAppError.failedDeployOptionalID)))
                return
            }
            do {
                let encodableBook = EncodableBook(from: book)
                let bookData = try JSONEncoder().encode(encodableBook)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String: Any]
                
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
    
    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
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
    
    deinit {
        print("deinit FirestoreDatabaseCRUDService")
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
