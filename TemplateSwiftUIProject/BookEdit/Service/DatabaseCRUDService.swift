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




// Firestore работает по модели "local‑first":
// - операции add/update/delete сначала записываются в локальный офлайн‑кэш
// - listener мгновенно возвращает обновлённые данные
// - Firestore пытается синхронизировать изменения с сервером в фоне
//
// Если сети нет:
// - Firestore НЕ возвращает ошибку сразу
// - локальные данные считаются успешными
// - listener НЕ откатывает изменения
//
// Ошибка может прийти позже (unavailable, deadlineExceeded), если Firestore
// долго не может достучаться до сервера. Это НЕ отменяет локальные изменения.
//
// Listener откатывает данные ТОЛЬКО если сервер принял запрос,
// но затем вернул ошибку безопасности (например, permission denied).

// Чтобы пользователь не видел ошибку при офлайн‑режиме Firestore:
//
// Firestore сначала записывает изменения в локальный офлайн‑кэш,
// listener мгновенно отдаёт обновлённые данные,
// а синхронизация с сервером происходит позже в фоне.
//
// Ошибки unavailable / deadlineExceeded приходят только тогда,
// когда Firestore долго не может достучаться до сервера.
// Эти ошибки НЕ означают, что локальная операция не выполнена.
//
// Чтобы не показывать пользователю лишний Alert:
// - фильтруйте ошибки Firestore по кодам unavailable и deadlineExceeded
// - такие ошибки можно тихо логировать, но не отображать в UI
// - UI остаётся корректным, так как локальные данные уже применены
//
// Listener НЕ откатывает локальные изменения при ошибках сети,
// поэтому скрытие этих ошибок безопасно для UX.


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


import Combine
import FirebaseDatabase
import FirebaseFirestore

protocol DatabaseCRUDServiceProtocol:ObservableObject {
    func addBook(path:String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
}



class FirestoreDatabaseCRUDService: DatabaseCRUDServiceProtocol {
    
    private var db:Firestore
    
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func addBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future {  promise in
            
            do {
                let _ = try self.db.collection(path).addDocument(from: book) { error in
                    print("func addBook addDocument - \(String(describing: error))")
                    if let error = error {
                        promise(.success(.failure(error)))
                    } else {
                        promise(.success(.success(())))
                    }
                }
            }
            catch {
                // В блок catch попадают только ошибки кодирования модели (EncodingError).
                // Это происходит, когда JSONEncoder не может преобразовать BookCloud в JSON.
                // Возможные причины:
                // - модель содержит несериализуемые типы (например, Date без стратегии, URL и т.п.)
                // - неверно указаны CodingKeys
                // - обязательное поле имеет значение nil
                // - вложенные структуры не соответствуют протоколу Codable
                // - кастомная реализация encode(to:) вручную выбрасывает ошибку
                promise(.success(.failure(error)))
            }
        }
        .eraseToAnyPublisher()
    }

    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let bookID = book.id else {
                promise(.success(.failure(AppInternalError.failedDeployOptionalID)))
                return
            }
            do {
                let encodableBook = EncodableBook(from: book)
                let bookData = try JSONEncoder().encode(encodableBook)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String: Any]
                
                guard let bookDict = bookDict else {
                    // Эта ошибка возникает, когда JSON валиден и успешно распарсен JSONSerialization,
                    // но его структура НЕ является словарём верхнего уровня ([String: Any]).
                    //
                    // Примеры валидного, но неподходящего JSON:
                    // - массив: [1, 2, 3]
                    // - строка: "hello"
                    // - число: 42
                    // - null
                    //
                    // JSON корректный, ошибок парсинга нет,
                    // но структура не соответствует ожидаемому формату словаря.
                    // Поэтому используется AppInternalError.invalidJSONStructure.
                    promise(.success(.failure(AppInternalError.invalidJSONStructure)))
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
                // В этот блок попадают только ошибки, выбрасываемые JSONEncoder или JSONSerialization.
                //
                // 1) EncodingError — когда JSONEncoder не может закодировать модель.
                //    Причины:
                //    - несериализуемые типы
                //    - неверные CodingKeys
                //    - обязательное поле содержит nil
                //    - некорректная структура модели
                //
                // 2) NSError (NSCocoaErrorDomain, код 3840 и др.) — когда JSONSerialization
                //    обнаруживает повреждённый или невалидный JSON.
                //    Причины:
                //    - битый JSON
                //    - неправильный формат
                //    - отсутствующие скобки, лишние запятые и т.п.
                //
                // Это ошибки ПАРСИНГА, а не ошибки структуры JSON.
                promise(.success(.failure(error)))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future { [weak self] promise in
            guard let bookID = book.id else {
                promise(.success(.failure(AppInternalError.failedDeployOptionalID)))
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
                let error = AppInternalError.failedDeployOptionalID
                promise(.success(.failure(error)))
                return
            }
            
            do {
                let bookData = try JSONEncoder().encode(bookWithID)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String:Any]
                
                guard let bookDict = bookDict else {
                    promise(.success(.failure(AppInternalError.invalidJSONStructure)))
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
                promise(.success(.failure(AppInternalError.failedDeployOptionalID)))
                return
            }
            
            do {
                let bookData = try JSONEncoder().encode(book)
                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String:Any]
                guard let bookDict = bookDict else {
                    promise(.success(.failure(AppInternalError.invalidJSONStructure)))
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
                promise(.success(.failure(AppInternalError.failedDeployOptionalID)))
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






//class FirestoreDatabaseCRUDService: DatabaseCRUDServiceProtocol {
//
//    private var db: Firestore
//
//    init(db: Firestore = Firestore.firestore()) {
//        self.db = db
//    }
//
//    func addBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
//        Future { promise in
//            do {
//                let _ = try self.db.collection(path).addDocument(from: book) { error in
//                    if let error = error {
//                        promise(.success(.failure(error)))
//                    } else {
//                        promise(.success(.success(())))
//                    }
//                }
//            } catch {
//                promise(.success(.failure(error)))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
//        Future { [weak self] promise in
//            guard let bookID = book.id else {
//                promise(.success(.failure(AppInternalError.failedDeployOptionalID)))
//                return
//            }
//
//            do {
//                let encodableBook = EncodableBook(from: book)
//                let bookData = try JSONEncoder().encode(encodableBook)
//                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String: Any]
//
//                guard let bookDict = bookDict else {
//                    promise(.success(.failure(AppInternalError.jsonConversionFailed)))
//                    return
//                }
//
//                self?.db.collection(path).document(bookID).updateData(bookDict) { error in
//                    if let error = error {
//                        promise(.success(.failure(error)))
//                    } else {
//                        promise(.success(.success(())))
//                    }
//                }
//            } catch {
//                promise(.success(.failure(error)))
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
//        Future { [weak self] promise in
//            guard let bookID = book.id else {
//                promise(.success(.failure(AppInternalError.failedDeployOptionalID)))
//                return
//            }
//
//            self?.db.collection(path).document(bookID).delete { error in
//                if let error = error {
//                    promise(.success(.failure(error)))
//                } else {
//                    promise(.success(.success(())))
//                }
//            }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    deinit {
//        print("deinit FirestoreDatabaseCRUDService")
//    }
//}













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
