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

import Combine
import FirebaseFirestore
import FirebaseDatabase


protocol FirestoreCollectionObserverProtocol {
    func observeCollection(at path: String) -> AnyPublisher<Result<[BookRealtime], Error>, Never>
}


class FirestoreCollectionObserverService: FirestoreCollectionObserverProtocol {
    private let db: Firestore
    private var listener: ListenerRegistration?
    

    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func observeCollection(at path: String) -> AnyPublisher<Result<[BookRealtime], Error>, Never> {
        guard PathValidator.validateCollectionPath(path) else {
            return Just(.failure(DatabaseEnternalAppError.invalidCollectionPath)).eraseToAnyPublisher()
        }
        let subject = PassthroughSubject<Result<[BookRealtime], Error>, Never>()
        
        listener?.remove()
        listener = db.collection(path)
            .addSnapshotListener { (querySnapshot, error) in
                if let error = error {
                    subject.send(.failure(error))
                } else {
                    let data = querySnapshot?.documents.compactMap({ queryDocumentSnapshot in
                        try? queryDocumentSnapshot.data(as: BookRealtime.self)
                    })
                    subject.send(.success(data ?? []))
                }

            }
        return subject.eraseToAnyPublisher()
    }
}


class RealtimeCollectionObserverService : FirestoreCollectionObserverProtocol {
    
    
    private var listenerHandle:DatabaseHandle?
    private let db:DatabaseReference
    
    ///let mockFirestore = FirestoreMock() // Твой mock-объект Firestore
    init(db: DatabaseReference = Database.database().reference()) {
        self.db = db
    }
    
    func observeCollection(at path: String) -> AnyPublisher<Result<[BookRealtime], any Error>, Never> {
        guard PathValidator.validateCollectionPath(path) else {
            return Just(.failure(DatabaseEnternalAppError.invalidCollectionPath)).eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<Result<[BookRealtime], Error>, Never>()
    
        if let handler = listenerHandle {
            db.child(path).removeObserver(withHandle: handler)
        }
        
        listenerHandle = db.child(path).observe(.value, with: { snapshot in
            var books:[BookRealtime] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot, let book = try? snapshot.data(as: BookRealtime.self) {
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



