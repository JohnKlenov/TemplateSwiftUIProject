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


import Combine
import FirebaseFirestore


protocol FirestoreCollectionObserverProtocol {
    func observeCollection(at path: String) -> AnyPublisher<Result<[String], Error>, Never>
}

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
                print("db.collection(path).addSnapshotListener - \(String(describing: error))")
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
