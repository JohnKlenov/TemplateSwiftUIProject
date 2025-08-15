//
//  FirestoreGetService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.



// MARK: - code explanation

///Если путь db.collection("shops") в вашей базе данных Firestore не существует (то есть коллекция "shops" не была создана в Firestore), Firestore вернёт результат без ошибки. В этом случае массив snapshot.documents будет пустым.

///async throws — это комбинация для функций, которые выполняют асинхронные операции (требующие ожидания await) и могут выбрасывать ошибки (требующие обработки через try или catch).
///withCheckedThrowingContinuation: – Это механизм, позволяющий «обернуть» callback-функцию (здесь, Firestore getDocuments с closure) в асинхронную функцию, работающую с async/await.
///continuation.resume(returning:) для возврата значений
///continuation.resume(throwing:) для выбрасывания ошибки.

///let item = try document.data(as: T.self) - если документ декодируется с ошибкой работа переъодит в блок catch и возвращает nil
///Опциональные поля: Все свойства в модели, которые могут отсутствовать, объявлены как опциональные (например, title: LocalizedText?, author: String?, description: LocalizedText?, urlImage: String?). Благодаря этому, если Firestore возвращает документ, в котором, скажем, поле title или urlImage отсутствует, декодирование пройдет успешно, и соответствующее свойство будет равно nil.
///Codable (то есть Decodable), если для некоторого поля значение отсутствует, стандартный декодер просто установит значение nil для опциональных свойств. Это очень удобно для работы с данными Firestore, где структура документов может меняться или быть неполной.

///Если в документе поле называется "ttle" (опечатка), то стандартный декодер не находит ключ "title".
///поскольку модель объявлена с var title: LocalizedText?, если в Firestore вместо "title" приходит "ttle", то свойство title просто будет декодировано как nil.
///если поле title: LocalizedText не опционал и такого ключа от сервера не приходит то будет ошибка.

///Если в документе из Firestore присутствуют дополнительные поля, которых нет в вашей модели, стандартный декодер (на основе протоколов Decodable/Codable) просто их игнорирует.
///в документе окажутся, например, ещё и location, rating и т. д., никаких ошибок выброшено не будет — эти дополнительные данные не будут пытаться декодироваться, и объект будет создан со значениями для тех свойств, которые описаны в модели.


// MARK: - какого типа данные мы получаем из CloudFirestore

///В Swift тип Data представляет собой именно набор байтов — то есть, он является представлением бинарных данных. Можно сказать, что "данные в виде Data" и "бинарные данные" — по сути одно и то же: это последовательность байтов.
///Когда вы вызываете метод вроде getDocuments(), SDK Firestore получает бинарный ответ, преобразует его в понятную структуру – например, в объект QuerySnapshot. Внутри этого объекта каждый документ представлен как DocumentSnapshot.
///Каждый DocumentSnapshot предоставляет метод .data(), который возвращает словарь [String: Any]. Этот словарь можно интерпретировать как аналог JSON-объекта, но фактически вы уже работаете с готовыми Swift-словари.


// MARK: - CodingKeys

///CodingKeys – это специальное перечисление (enum), которое вы обычно объявляете внутри вашего типа, реализующего Codable. Оно позволяет явно указать сопоставление между именами ваших свойств и именами ключей в исходных данных (например, JSON). На реальных проектах CodingKeys используется в нескольких типичных сценариях:
///1. Иногда сервер возвращает данные с именами ключей, которые не соответствуют стилю и соглашениям Swift. Например, если JSON возвращает "user_name" в то время как в модели вы хотите использовать свойство username (camelCase). В таких случаях вы определяете CodingKeys для преобразования: case username = "user_name"


// MARK: - error требующий логирования

///InvalidArgument (код 3): Если в запрос переданы некорректные параметры или формат запроса не соответствует требованиям API. Это свидетельствует о программной ошибке в формировании запроса, которую нужно исправить в коде или на сервере.
///PermissionDenied (код 7): Указывает на то, что для данного запроса недостаточно прав согласно правилам безопасности Firestore. Если возникает эта ошибка, скорее всего, необходимо пересмотреть правила безопасности или настройки аутентификации/авторизации.
///ResourceExhausted (код 8): Сообщает, что исчерпаны выделенные ресурсы, например, превышены квоты или лимиты запросов. Хотя иногда подобные ошибки могут быть транзиторными, их появление на постоянной основе требует участия разработчиков для пересмотра лимитов или оптимизации запросов.
///FailedPrecondition (код 9): Означает, что операция не может быть выполнена, потому что система не находится в требуемом состоянии (например, вызов операции в неподходящем контексте). Это часто свидетельствует о том, что сервер ожидает соблюдения определённого порядка операций, и нарушение этого порядка требует корректировки на стороне сервера или клиента.
///Unimplemented (код 12): Операция или функция не поддерживается сервером. Если такая ошибка возникает, возможно, вы вызываете API, которое не реализовано или используется неверно, и это требует вмешательства разработчиков.
///Internal (код 13): Возникает при внутренних ошибках сервера или при нарушении внутренних инвариантов в Firestore. Такие ошибки, как правило, не решаются на стороне клиента и требуют серверной диагностики и исправлений.
///DataLoss (код 15): Сообщает о непоправимой потере или повреждении данных. Это очень критичная ошибка, которая указывает на сбои в целостности данных, и она обязательно требует вмешательства технической поддержки или разработчиков.
///Unauthenticated (код 16): Возникает, когда запрос не содержит действительных учетных данных. Хотя иногда это может быть результатом временной проблемы (например, истекший токен), если это повторяющаяся проблема, то требуется анализ и исправление логики аутентификации или настройки безопасности.

///Краткий вывод: Ошибки, такие как InvalidArgument, PermissionDenied, ResourceExhausted, FailedPrecondition, Unimplemented, Internal, DataLoss и Unauthenticated, считаются критическими, потому что они указывают либо на структурные проблемы в настройках, либо на ошибки в логике запроса или серверной части. Их появление требует участия разработчиков для диагностики и корректировки, так как они не разрешаются автоматически на стороне клиента.



import FirebaseFirestore
import Foundation

final class FirestoreGetService {
    private let db = Firestore.firestore()
    
    func fetchMalls() async throws -> [MallItem] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("MallCenters").getDocuments { snapshot, error in
                if let error = error {
                    // Логирование (Crashlytics, Sentry, и т.д.) - тех ошибок которые с большой вероятностью не смогут исчерпать себя самостоятельно или без участия разработчиков на стороне сервера(InvalidArgument, PermissionDenied, ResourceExhausted, FailedPrecondition, Unimplemented, Internal, DataLoss, Unauthenticated).
                    print("MallSection error = \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    // Если коллекция существует, но документов нет, считаем это ошибкой:
                    if snapshot.documents.isEmpty {
                        print("MallSection: empty snapshot")
                        continuation.resume(throwing: FirebaseInternalError.emptyResult)
                        return
                    }
                    let items: [MallItem] = snapshot.documents.compactMap { document -> MallItem? in
                        do {
                            let item = try document.data(as: MallItem.self)
                            return item
                        } catch {
                            // Логирование (Crashlytics, Sentry, и т.д.)
                            print("MallSection error converting document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    // Если после преобразования массив пустой, можем считать это ошибкой
                    if items.isEmpty {
                        // Логирование (Crashlytics, Sentry, и т.д.)
                        print("MallSection: conversion yielded empty")
                        continuation.resume(throwing: FirebaseInternalError.emptyResult)
                    } else {
                        print("MallSection snapshot != nil = \(items)")
                        continuation.resume(returning: items)
                    }
                } else {
                    // Логирование (Crashlytics, Sentry, и т.д.)
                    print("MallSection snapshot == nil")
                    continuation.resume(throwing: FirebaseInternalError.emptyResult)
                }
            }
        }
    }
    
   
    func fetchShops() async throws -> [ShopItem] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("BookStores").getDocuments { snapshot, error in
                if let error = error {
                    // Логирование (Crashlytics, Sentry, и т.д.) - тех ошибок которые с большой вероятностью не смогут исчерпать себя самостоятельно или без участия разработчиков на стороне сервера(InvalidArgument, PermissionDenied, ResourceExhausted, FailedPrecondition, Unimplemented, Internal, DataLoss, Unauthenticated).
                    print("ShopSection error = \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    if snapshot.documents.isEmpty {
                        // Логирование (Crashlytics, Sentry, и т.д.)
                        print("ShopSection: empty snapshot")
                        continuation.resume(throwing: FirebaseInternalError.emptyResult)
                        return
                    }
                    let items: [ShopItem] = snapshot.documents.compactMap { document -> ShopItem? in
                        do {
                            let item = try document.data(as: ShopItem.self)
                            return item
                        } catch {
                            // Логирование (Crashlytics, Sentry, и т.д.)
                            print("ShopSection error converting document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    if items.isEmpty {
                        // Логирование (Crashlytics, Sentry, и т.д.)
                        print("ShopSection: conversion yielded empty")
                        continuation.resume(throwing: FirebaseInternalError.emptyResult)
                    } else {
                        print("ShopSection snapshot != nil = \(items)")
                        continuation.resume(returning: items)
                    }
                } else {
                    // Логирование (Crashlytics, Sentry, и т.д.)
                    print("ShopSection snapshot == nil")
                    continuation.resume(throwing: FirebaseInternalError.emptyResult)
                }
            }
        }
    }
        
    func fetchPopularProducts() async throws -> [ProductItem] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("books").getDocuments { snapshot, error in
                if let error = error {
                    // Логирование (Crashlytics, Sentry, и т.д.) - тех ошибок которые с большой вероятностью не смогут исчерпать себя самостоятельно или без участия разработчиков на стороне сервера(InvalidArgument, PermissionDenied, ResourceExhausted, FailedPrecondition, Unimplemented, Internal, DataLoss, Unauthenticated).
                    print("PopularProducts error = \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    if snapshot.documents.isEmpty {
                        // Логирование (Crashlytics, Sentry, и т.д.)
                        print("PopularProducts: empty snapshot")
                        continuation.resume(throwing: FirebaseInternalError.emptyResult)
                        return
                    }
                    let items: [ProductItem] = snapshot.documents.compactMap { document -> ProductItem? in
                        do {
                            let item = try document.data(as: ProductItem.self)
                            return item
                        } catch {
                            // Логирование (Crashlytics, Sentry, и т.д.)
                            print("PopularProducts error converting document \(document.documentID): \(error.localizedDescription)")
                            return nil
                        }
                    }
                    if items.isEmpty {
                        // Логирование (Crashlytics, Sentry, и т.д.)
                        print("PopularProducts: conversion yielded empty")
                        continuation.resume(throwing: FirebaseInternalError.emptyResult)
                    } else {
                        print("PopularProducts snapshot != nil = \(items)")
                        continuation.resume(returning: items)
                    }
                } else {
                    // Логирование (Crashlytics, Sentry, и т.д.)
                    print("PopularProducts snapshot == nil")
                    continuation.resume(throwing: FirebaseInternalError.emptyResult)
                }
            }
        }
    }
}


// MARK: - first code and different methods


//    func fetchCollection<T: Decodable>(from collectionPath: String) async throws -> [T] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection(collectionPath).getDocuments { snapshot, error in
//                if let error = error {
//                    // Логирование (Crashlytics, Sentry, и т.д.) - тех ошибок которые с большой вероятностью не смогут исчерпать себя самостоятельно или без участия разработчиков на стороне сервера(InvalidArgument, PermissionDenied, ResourceExhausted, FailedPrecondition, Unimplemented, Internal, DataLoss, Unauthenticated).
//                    print("\(collectionPath) error: \(error.localizedDescription)")
//                    continuation.resume(throwing: error)
//                } else if let snapshot = snapshot {
//                    // Если коллекция существует, но документов нет, считаем это ошибкой:
//                    if snapshot.documents.isEmpty {
//                        // Логирование (Crashlytics, Sentry, и т.д.)
//                        print("\(collectionPath): empty snapshot")
//                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        return
//                    }
//                    let items: [T] = snapshot.documents.compactMap { document -> T? in
//                        do {
//                            let item = try document.data(as: T.self)
//                            return item
//                        } catch {
//                            // Логирование (Crashlytics, Sentry, и т.д.)
//                            print("Error converting document \(document.documentID) in collection \(collectionPath): \(error.localizedDescription)")
//                            return nil
//                        }
//                    }
//                    // Если после преобразования массив пустой, можем считать это ошибкой
//                    if items.isEmpty {
//                        // Логирование (Crashlytics, Sentry, и т.д.)
//                        print("\(collectionPath): conversion yielded empty")
//                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                    } else {
//                        print("\(collectionPath) snapshot != nil = \(items)")
//                        continuation.resume(returning: items)
//                    }
//                } else {
//                    // Логирование (Crashlytics, Sentry, и т.д.)
//                    print("\(collectionPath): snapshot is nil")
//                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                }
//            }
//        }
//    }




//final class FirestoreGetService {
//    private let db = Firestore.firestore()
//    
//    func fetchMalls() async throws -> [Item] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("mall").getDocuments { snapshot, error in
//                if let error = error {
//                    print("malls error = \(error.localizedDescription)")
//                    continuation.resume(throwing: error)
//                } else if let snapshot = snapshot {
//                    // Если коллекция существует, но документов нет
//                    if snapshot.documents.isEmpty {
//                        print("malls: empty snapshot")
//                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        return
//                    }
//                    do {
//                        let items = try snapshot.documents.compactMap { doc -> Item? in
//                            guard let title = doc.data()["title"] as? String else {
//                                throw FirebaseEnternalError.jsonConversionFailed
//                            }
//                            return Item(id: doc.documentID, title: title)
//                        }
//                        // Если после преобразования получился пустой массив, выбрасываем ошибку
//                        if items.isEmpty {
//                            print("malls: conversion yielded empty")
//                            continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        } else {
//                            print("malls snapshot != nil - \(items)")
//                            continuation.resume(returning: items)
//                        }
//                    } catch {
//                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
//                    }
//                } else {
//                    print("malls snapshot == nil")
//                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
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
//                    if snapshot.documents.isEmpty {
//                        print("shops: empty snapshot")
//                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        return
//                    }
//                    do {
//                        let items = try snapshot.documents.compactMap { doc -> Item? in
//                            guard let title = doc.data()["title"] as? String else {
//                                throw FirebaseEnternalError.jsonConversionFailed
//                            }
//                            return Item(id: doc.documentID, title: title)
//                        }
//                        if items.isEmpty {
//                            print("shops: conversion yielded empty")
//                            continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        } else {
//                            print("shops snapshot != nil - \(items)")
//                            continuation.resume(returning: items)
//                        }
//                    } catch {
//                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
//                    }
//                } else {
//                    print("shops snapshot == nil")
//                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
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
//                    if snapshot.documents.isEmpty {
//                        print("popularProducts: empty snapshot")
//                        continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        return
//                    }
//                    do {
//                        let items = try snapshot.documents.compactMap { doc -> Item? in
//                            guard let title = doc.data()["title"] as? String else {
//                                throw FirebaseEnternalError.jsonConversionFailed
//                            }
//                            return Item(id: doc.documentID, title: title)
//                        }
//                        if items.isEmpty {
//                            print("popularProducts: conversion yielded empty")
//                            continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                        } else {
//                            print("popularProducts snapshot != nil - \(items)")
//                            continuation.resume(returning: items)
//                        }
//                    } catch {
//                        continuation.resume(throwing: FirebaseEnternalError.jsonConversionFailed)
//                    }
//                } else {
//                    print("popularProducts snapshot == nil")
//                    continuation.resume(throwing: FirebaseEnternalError.emptyResult)
//                }
//            }
//        }
//    }
//}





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
