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

// Поведение Firestore при ошибках unavailable и deadlineExceeded:
//
// Firestore использует модель "local‑first":
// 1) Запись сразу сохраняется в локальный офлайн‑кэш.
// 2) Локальные слушатели мгновенно получают обновлённые данные.
// 3) Операция добавляется в очередь синхронизации.
// 4) Firestore пытается отправить изменения на сервер в фоне.
//
// Если сеть недоступна или соединение нестабильно, Firestore может вернуть
// ошибки:
//   - FirestoreErrorCode.unavailable (14)
//   - FirestoreErrorCode.deadlineExceeded (4)
//
// ВАЖНО:
// Эти ошибки НЕ означают, что запись не выполнена.
// Эти ошибки НЕ удаляют операцию из очереди.
// Эти ошибки НЕ останавливают механизм синхронизации.
//
// Firestore продолжает пытаться отправить данные:
// - пока приложение запущено
// - и даже после перезапуска (если включён persistence, что является значением по умолчанию)
//
// Firestore НЕ имеет "финальной" ошибки, которая говорит:
//   «Я сдаюсь, больше не буду пытаться отправить данные».
// Такой ошибки не существует.
//
// Единственный случай, когда Firestore прекращает попытки и удаляет операцию:
//   - сервер возвращает ошибку безопасности (permissionDenied, unauthenticated,
//     invalidArgument, failedPrecondition и т.п.)
// В этом случае Firestore откатывает локальные изменения,
// и слушатель получает обновлённые данные.
//
// Итог:
// - unavailable / deadlineExceeded — нормальное офлайн‑поведение, их можно игнорировать
// - Firestore будет пытаться отправить данные до успешной синхронизации
// - только ошибки безопасности приводят к окончательному отказу от операции




// retryable + fatal error Firestore



// Firestore: какие ошибки повторяют запись, а какие останавливают её навсегда
//
// Firestore делит ошибки на два типа:
//
// 1) Повторяемые (retryable) — Firestore продолжает пытаться отправить запись.
//    Эти ошибки НЕ удаляют операцию из очереди и НЕ откатывают локальные данные.
//    Запись будет отправлена при первой возможности.
//
//    К таким ошибкам относятся:
//    - unavailable (14) — сервис недоступен, проблемы с сетью
//    - deadline_exceeded (4) — истек таймаут
//    - cancelled (1) — операция отменена из-за сетевого сбоя
//    - aborted (10) — временный конфликт или сбой транзакции
//    - resource_exhausted (8) — временное превышение квот
//    - internal (13) — внутренняя ошибка Firestore
//    - unknown (2) — неизвестная временная ошибка
//    - data_loss (15) — временная потеря данных
//
//    Поведение: Firestore будет пытаться отправлять запись бесконечно,
//    пока приложение работает, и даже после перезапуска (если включён persistence).
//
//
// 2) Фатальные ошибки (fatal) — Firestore прекращает попытки навсегда.
//    Эти ошибки означают, что операция гарантированно НЕ может быть выполнена.
//    Firestore удаляет операцию из очереди и откатывает локальные изменения.
//
//    К таким ошибкам относятся:
//    - permission_denied (7) — нет прав на выполнение операции
//    - unauthenticated (16) — пользователь не авторизован
//    - invalid_argument (3) — переданы некорректные данные
//    - failed_precondition (9) — нарушено предварительное условие
//    - out_of_range (11) — значение вне допустимого диапазона
//    - already_exists (6) — ресурс уже существует (в определённых сценариях)
//    - not_found (5) — документ не найден (например, update несуществующего документа)
//    - unimplemented (12) — операция не поддерживается сервером
//
//    Поведение: Firestore прекращает попытки, локальные данные откатываются,
//    listener получает обновлённое состояние.
//
//
// Итог:
// - Ошибки сети и временные сбои → безопасны, Firestore продолжит синхронизацию.
// - Ошибки безопасности и некорректных данных → фатальны, операция отменяется.
// - unavailable и deadline_exceeded — нормальное офлайн‑поведение, их можно игнорировать.



// Почему в FirestoreDatabaseCRUDService мы игнорируем только unavailable и deadlineExceeded:
//
// Firestore имеет много retryable‑ошибок, но только две из них являются
// нормальным офлайн‑поведением:
//   - unavailable (нет сети)
//   - deadlineExceeded (слишком медленное соединение)
//
// Эти ошибки возникают постоянно и не требуют реакции пользователя,
// поэтому Alert для них не показывается.
//
// Остальные retryable‑ошибки (cancelled, internal, aborted, resource_exhausted,
// unknown, data_loss и др.) встречаются редко и могут указывать на реальные
// проблемы: сбои SDK, конфликты транзакций, превышение квот, нестабильность
// соединения и т.п.
//
// Поэтому:
// - в CRUDSManager мы показываем Alert для всех ошибок, кроме двух офлайн‑ошибок
// - в AnonAccountTrackerService мы игнорируем почти все ошибки, чтобы не
//   засорять Crashlytics и не тревожить пользователя
//
// Важно:
// Retryable‑ошибки НЕ откатывают локальные данные и НЕ удаляют операцию из
// очереди. Поэтому UI может показать обновлённые данные, даже если Alert
// сообщает об ошибке — Firestore продолжит попытки синхронизации в фоне.





// Разница обработки ошибок Firestore при записи и чтении:




// normalizeFirestoreError используется ТОЛЬКО для операций записи
// (add/update/delete). Причина:
// - при записи Firestore сначала сохраняет данные в локальный офлайн‑кэш
// - retryable‑ошибки (unavailable, deadlineExceeded) означают лишь отсутствие сети
// - Firestore гарантированно отправит данные позже
// - UI уже обновлён локальными данными
// Поэтому офлайн‑ошибки при записи считаются "успехом".
//
// При ЧТЕНИИ данных логика полностью другая:
// - если чтение завершилось ошибкой — данных НЕТ
// - офлайн‑ошибки нельзя скрывать, иначе UI покажет пустые данные как "успех"
// - Firestore не может вернуть локальный кэш, если он ещё не был загружен
// Поэтому при чтении ЛЮБАЯ ошибка (включая unavailable и deadlineExceeded)
// должна возвращаться как ошибка, без normalizeFirestoreError.
//
// Итог:
// - Запись: офлайн‑ошибки → успех (normalizeFirestoreError применяется)
// - Чтение: любая ошибка → ошибка (normalizeFirestoreError НЕ используется)




// Firestore кэширует данные локально, но только если они уже были загружены ранее.
// Методы чтения работают по-разному:
//
// 1) addSnapshotListener() — всегда возвращает данные из кэша (если есть),
//    затем пытается обновить их с сервера.
//
// 2) getDocument() / getDocuments() — могут вернуть кэш,
//    но если кэша нет и сети нет — вернётся ошибка.
//
// 3) source: .cache — читает ТОЛЬКО из кэша, без сети.
// 4) source: .server — читает ТОЛЬКО с сервера, кэш игнорируется.
//
// Важно:
// normalizeFirestoreError используется только для операций записи.
// При чтении любая ошибка (включая unavailable/deadlineExceeded)
// должна возвращаться как ошибка, потому что данных может не быть.





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

    
    
    //  - write methods -
    
    func addBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
        Future {  promise in
            
            do {
                let _ = try self.db.collection(path).addDocument(from: book) { error in
                    print("func addBook addDocument - \(String(describing: error))")
                    if let error = error {
                        if let normalized = self.normalizeFirestoreError(error) {
                            promise(.success(.failure(normalized)))
                        } else {
                            // офлайн‑ошибка → считаем успехом
                            promise(.success(.success(())))
                        }
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
                        if let normalized = self?.normalizeFirestoreError(error) {
                            promise(.success(.failure(normalized)))
                        } else {
                            // офлайн‑ошибка → считаем успехом
                            promise(.success(.success(())))
                        }
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
                    if let normalized = self?.normalizeFirestoreError(error) {
                        promise(.success(.failure(normalized)))
                    } else {
                        // офлайн‑ошибка → считаем успехом
                        promise(.success(.success(())))
                    }
                } else {
                    promise(.success(.success(())))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // - read methods -
    
    
    // - helpe methods -
    
    // Мы фильтруем только unavailable и deadlineExceeded,
    // потому что это единственные ошибки Firestore,
    // которые гарантированно возникают в нормальном офлайн‑режиме.
    // Остальные retryable‑ошибки редкие и могут указывать на реальные проблемы,
    // поэтому их нужно передавать выше.
    /// Нормализация ошибок Firestore.
    /// Возвращает:
    /// - nil → если ошибка является нормальным офлайн‑поведением Firestore
    /// - error → если ошибка важная и должна быть обработана выше
    private func normalizeFirestoreError(_ error: Error) -> Error? {
        let nsError = error as NSError

        // Если ошибка не из Firestore — вернуть как есть
        guard nsError.domain == FirestoreErrorDomain else {
            return error
        }

        switch nsError.code {

        // 🔄 Нормальные офлайн‑ошибки Firestore
        // Firestore продолжит пытаться отправить данные, локальные изменения НЕ откатываются
        case FirestoreErrorCode.unavailable.rawValue,
             FirestoreErrorCode.deadlineExceeded.rawValue:
            return nil // считаем операцию успешной

        // ❗ Все остальные ошибки — важные (retryable или fatal)
        // Их нужно вернуть наверх, чтобы менеджер показал Alert или залогировал
        default:
            return error
        }
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









// MARK: - before func normalizeFirestoreError




//import Combine
//import FirebaseDatabase
//import FirebaseFirestore
//
//protocol DatabaseCRUDServiceProtocol:ObservableObject {
//    func addBook(path:String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
//    func updateBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
//    func removeBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void,Error>, Never>
//}
//
//
//
//class FirestoreDatabaseCRUDService: DatabaseCRUDServiceProtocol {
//    
//    private var db:Firestore
//    
//    
//    init(db: Firestore = Firestore.firestore()) {
//        self.db = db
//    }
//
//    func addBook(path: String, _ book: BookCloud) -> AnyPublisher<Result<Void, any Error>, Never> {
//        Future {  promise in
//            
//            do {
//                let _ = try self.db.collection(path).addDocument(from: book) { error in
//                    print("func addBook addDocument - \(String(describing: error))")
//                    if let error = error {
//                        promise(.success(.failure(error)))
//                    } else {
//                        promise(.success(.success(())))
//                    }
//                }
//            }
//            catch {
//                // В блок catch попадают только ошибки кодирования модели (EncodingError).
//                // Это происходит, когда JSONEncoder не может преобразовать BookCloud в JSON.
//                // Возможные причины:
//                // - модель содержит несериализуемые типы (например, Date без стратегии, URL и т.п.)
//                // - неверно указаны CodingKeys
//                // - обязательное поле имеет значение nil
//                // - вложенные структуры не соответствуют протоколу Codable
//                // - кастомная реализация encode(to:) вручную выбрасывает ошибку
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
//            do {
//                let encodableBook = EncodableBook(from: book)
//                let bookData = try JSONEncoder().encode(encodableBook)
//                let bookDict = try JSONSerialization.jsonObject(with: bookData) as? [String: Any]
//                
//                guard let bookDict = bookDict else {
//                    // Эта ошибка возникает, когда JSON валиден и успешно распарсен JSONSerialization,
//                    // но его структура НЕ является словарём верхнего уровня ([String: Any]).
//                    //
//                    // Примеры валидного, но неподходящего JSON:
//                    // - массив: [1, 2, 3]
//                    // - строка: "hello"
//                    // - число: 42
//                    // - null
//                    //
//                    // JSON корректный, ошибок парсинга нет,
//                    // но структура не соответствует ожидаемому формату словаря.
//                    // Поэтому используется AppInternalError.invalidJSONStructure.
//                    promise(.success(.failure(AppInternalError.invalidJSONStructure)))
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
//                // В этот блок попадают только ошибки, выбрасываемые JSONEncoder или JSONSerialization.
//                //
//                // 1) EncodingError — когда JSONEncoder не может закодировать модель.
//                //    Причины:
//                //    - несериализуемые типы
//                //    - неверные CodingKeys
//                //    - обязательное поле содержит nil
//                //    - некорректная структура модели
//                //
//                // 2) NSError (NSCocoaErrorDomain, код 3840 и др.) — когда JSONSerialization
//                //    обнаруживает повреждённый или невалидный JSON.
//                //    Причины:
//                //    - битый JSON
//                //    - неправильный формат
//                //    - отсутствующие скобки, лишние запятые и т.п.
//                //
//                // Это ошибки ПАРСИНГА, а не ошибки структуры JSON.
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
//







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
