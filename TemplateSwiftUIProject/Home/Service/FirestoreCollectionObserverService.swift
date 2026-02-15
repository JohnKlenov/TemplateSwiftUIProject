//
//  FirestoreCollectionObserverService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.10.24.
//


///$0: Каждый документ в коллекции.
///$0.get("value"): Получает значение из поля "value" документа.
///Из каждого документа в коллекции data мы извлекаем значение поля value и приводим его к строке.
///Firestore всегда возвращает QuerySnapshot, даже если путь не существует.
///querySnapshot?.documents будет пустым массивом, если коллекция пуста или путь не существует.
///На момент отключения интернета addSnapshotListener не будет генерировать ошибки в обработчике.
///В случае продолжительной потери интернета: Через какое-то время ошибка может быть выброшена, показывая, что попытки восстановить соединение не увенчались успехом.

//Поведение addSnapshotListener

///если у вас включена оффлайн-поддержка и Firestore имеет доступ к кэшу, то даже если устройство оказывается без сети, addSnapshotListener не вызовет ошибку. Вместо этого он вернёт данные, сохранённые в локальном кэше (или пустой snapshot, если кэш пуст). При этом в объекте snapshot можно будет увидеть, что данные получены из кэша (свойство isFromCache равно true).
///Таким образом, если вы уверены, что нужные данные уже ранее были закэшированы, то как и в случае с addSnapshotListener, get-запрос отобразит данные из кэша и не вызовет ошибку даже в течение длительного отсутствия сети. Однако если кэш пустой, то вызов ошибки возможен.

/// мы решили пока оставить вызов алерта при подключенном наблюдатели(тут нужна более тонкая настройка со знанием всех возможных ошибок)
///Периодические обновления: Наблюдатель будет получать обновления данных в реальном времени.
///Ошибки сети и сервера: Если возникнут сетевые проблемы или проблемы на сервере Firestore, в блоке может появиться ошибка позже.
///Автоматическое переподключение: Firestore автоматически пытается переподключиться, но если не удается восстановить соединение, ошибка может быть передана в блок.

//RealTimeDatabase ошибок в консоли нет, проблема в CloudFirestore

///Возвращение Publisher:
///Затем метод observeCollection завершает свое выполнение и возвращает Publisher.
///Этот шаг является синхронным и гарантированно выполняется до любых асинхронных операций.

///Синхронные операции (создание PassthroughSubject, возврат Publisher через eraseToAnyPublisher) всегда выполняются немедленно и завершаются до того, как любая асинхронная операция может начаться.
///Асинхронные операции, такие как addSnapshotListener, происходят позже, после того, как функции завершили свои синхронные действия. Они не могут начать выполнение до завершения текущих синхронных операций.

///db.child(path).observe(.value, with: { snapshot in ... }), он будет продолжать свою работу, независимо от того, произошла ли ошибка при записи, удалении или обновлении. Так как данные попадают в локальный кэш и затем пытаются синхранизироваться с сервером..
/// не все ошибки которые приходят из addSnapshotListener критичные, есть временные ошибки котороые не останавливают работу слушателя. 


// error в addSnapshotListener

////После успешного подключения слушателя через addSnapshotListener возможны ошибки, возникающие уже в процессе получения обновлений. Наиболее частыми причинами таких ошибок являются:
///Проблемы с правами доступа(PERMISSION_DENIED) + Проблемы с аутентификацией: При истечении срока действия токена или если пользователь перестаёт быть аутентифицированным, может вернуться ошибка с кодом UNAUTHENTICATED + Сетевые проблемы + Системные или внутренние ошибки
///Что касается частоты возникновения таких ошибок в продакшене, то: При корректно настроенных правилах безопасности, стабильном интернет-соединении и наличии механизма офлайн-поддержки Firestore, ошибки после успешной активации слушателя встречаются довольно редко (обычно речь идёт о погрешностях, возникающих в менее чем 1% запросов).
///Таким образом, хотя ошибки в addSnapshotListener возможны, они в подавляющем большинстве сценариев являются редкими и транзиторными, особенно если приложение стабильно и настроено правильно.



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
import FirebaseFirestore
import FirebaseDatabase


import Combine

protocol FirestoreCollectionObserverProtocol {
    func observeCollection<T: Decodable & Identifiable>(at path: String) -> AnyPublisher<Result<[T], Error>, Never>
}


// MARK: -  .receive(on: RunLoop.main) ???? обновление UI должно быть везде на главном потоке!!!! -

// тут важно понимать что это func observeCollection джинерик + и следовательно он может быть вызван в разных менеджерах
// для ErrorContext в методе handleError можно передать дополнительный параметр из observeCollection - какой менеджер вызывает
class FirestoreCollectionObserverService: FirestoreCollectionObserverProtocol {
    private let db: Firestore
    private var listener: ListenerRegistration?
    private let errorHandler: ErrorDiagnosticsProtocol
    
    init(db: Firestore = Firestore.firestore(), errorHandler: ErrorDiagnosticsProtocol) {
        self.db = db
        self.errorHandler = errorHandler
        
    }
    //addSnapshotListener(includeMetadataChanges: true)
    /// у нас сейчас includeMetadataChanges: false
    /// если мы успешно удаляем account то для card product нужно удалить listener?.remove()
    func observeCollection<T: Decodable & Identifiable>(at path: String) -> AnyPublisher<Result<[T], Error>, Never> {
        // Проверка валидности пути
        guard PathValidator.validateCollectionPath(path) else {
            return Just(.failure(AppInternalError.invalidCollectionPath))
                .eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<Result<[T], Error>, Never>()
        
        // Отписываемся от предыдущего слушателя (если был)
        listener?.remove()
        listener = db.collection(path).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                subject.send(.failure(error))
            } else {
                
                // Пытаемся преобразовать каждый документ в модель T
                // Примечание:
                // try? + compactMap означает, что документы, которые не удалось декодировать,
                // будут отброшены (nil не попадёт в массив). Если из 10 документов декодируются
                // только 9 — вернётся массив из 9 элементов. Если не декодируется ни один —
                // compactMap вернёт пустой массив, но без ошибки.
                // Причины, по которым документ может не декодироваться:
                // 1) Структура данных в Firestore не совпадает с моделью T (отсутствуют поля, неверные типы).
                // 2) Поля имеют неожиданный формат (например, строка вместо числа).
                // 3) Документ содержит вложенные объекты, которые не соответствуют Decodable‑структуре.
                // 4) Firestore вернул данные, которые были частично повреждены или изменены вручную.
                // 5) Модель T требует обязательные поля, которых нет в документе.
                // В таких случаях try? возвращает nil, и compactMap просто пропускает этот документ.
                //в handleError передается ошибка с доменом nsError.domain == FirestoreErrorDomain
                let data : [T] = querySnapshot?.documents.compactMap { document in
                    do {
                        return try document.data(as: T.self)
                    } catch {
                        print("❌ Firestore decode error for document \(document.documentID): \(error)")
                        self.handleError( error, context: .FirestoreCollectionObserverService_decodeDocument, documentID: document.documentID )
                        return nil
                    }
                } ?? []
                
                print("FirestoreCollectionObserverService Received objects: \(data)")
                subject.send(.success(data))
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    private func handleError(_ error: Error, context: ErrorContext, documentID: String) {
        let fullContext = "\(context.rawValue) | documentID: \(documentID)"
        let _ = errorHandler.handle(error: error, context: fullContext)
    }
}



//let data = querySnapshot?.documents.compactMap({ document in
//    try? document.data(as: T.self)
//}) ?? []








// MARK: - before generic tupe for Firestore
protocol FirestoreCollectionObserverProtocolBefore {
    func observeCollection(at path: String) -> AnyPublisher<Result<[BookCloud], Error>, Never>
}
//
//
//class FirestoreCollectionObserverService: FirestoreCollectionObserverProtocol {
//    private let db: Firestore
//    private var listener: ListenerRegistration?
//    
//
//    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
//    init(db: Firestore = Firestore.firestore()) {
//        self.db = db
//    }
//
//    func observeCollection(at path: String) -> AnyPublisher<Result<[BookCloud], Error>, Never> {
//        guard PathValidator.validateCollectionPath(path) else {
//            return Just(.failure(FirebaseEnternalError.invalidCollectionPath)).eraseToAnyPublisher()
//        }
//        let subject = PassthroughSubject<Result<[BookCloud], Error>, Never>()
//        
//        listener?.remove()
//        listener = db.collection(path)
//            .addSnapshotListener { (querySnapshot, error) in
//                if let error = error {
//                    subject.send(.failure(error))
//                } else {
//                    let data = querySnapshot?.documents.compactMap({ queryDocumentSnapshot in
//                        try? queryDocumentSnapshot.data(as: BookCloud.self)
//                    })
//                    print("books  \(String(describing: data))")
//                    subject.send(.success(data ?? []))
//                }
//
//            }
//        return subject.eraseToAnyPublisher()
//    }
//}


// тут мы не работали с ошибками try document.data как в FirestoreCollectionObserverService
class RealtimeCollectionObserverService : FirestoreCollectionObserverProtocolBefore {
    
    
    private var listenerHandle:DatabaseHandle?
    private let db:DatabaseReference
    
    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
    init(db: DatabaseReference = Database.database().reference()) {
        self.db = db
    }
    
    func observeCollection(at path: String) -> AnyPublisher<Result<[BookCloud], any Error>, Never> {
        guard PathValidator.validateCollectionPath(path) else {
            return Just(.failure(AppInternalError.invalidCollectionPath)).eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<Result<[BookCloud], Error>, Never>()
    
        if let handler = listenerHandle {
            db.child(path).removeObserver(withHandle: handler)
        }
        
        listenerHandle = db.child(path).observe(.value, with: { snapshot in
            var books:[BookCloud] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot, let book = try? snapshot.data(as: BookCloud.self) {
                    books.append(book)
                }
            }
            print("books  \(books)")
            subject.send(.success(books))
        }) { error in
            print("error  \(error)")
            subject.send(.failure(error))
        }
        return subject.eraseToAnyPublisher()
    }
    
    
    
    
}



