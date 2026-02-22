//
//  GalleryManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.01.26.
//



// сейчас мы любую ошибку пришедшую в FirestoreGetService передаем в GalleryManager 
// а от туда ее передаем в GalleryContentView черезз .error(let error): в ContentErrorView(error: error)
// в ContentErrorView(error: error) мы пока не передаем локализованный текст ошибки
// а при любой ошибки отображаем текст try agayn (как и в HomeView на таб бар)
// мы можем отображать текст локализаии но почти в любом случае мы увиддем try agayn,
// кроме трех кейсов Localized.Firestore.cancelled + Localized.Firestore.unavailable + Localized.Firestore.deadlineExceeded
// я думая что в данном контексте это нормально и можно так пока и оставить!

// log + Context
// лотирование нужно интегрировать в GalleryManager через ErrorDiagnosticsProtocol передав туда контекст
// правда хотелось бы передать точный источник ошибки через контекст то есть как мы делали через enum ErrorContext(GalleryManager_fetchData_FirestoreGetService ) + длбавить с какого метода в FirestoreGetService ошибка пришла

// cash getDocuments
// кэширование в db.collection("SomePath").getDocuments
// если после первого удачного вызова db.collection("MallCenters").getDocuments вызову его - db.collection("MallCenters").getDocuments { snapshot, error in .. } еще раз но без сети то мне вернется snapshot из кэша? а при дет ли при этом ошибка что нет интернет соединения? и как поведет себя getDocuments после того как сеть появится он снова вернет данные в snapshot повторно но уже от сервера ? ведь меня это интересует по тому что данные с прошлого раза могли изменится на сервере!




import Foundation

struct UserFacingError: Error {
    let message: String
}


final class GalleryManager {

    enum StateError {
        case localError
    }

    private let firestoreService: FirestoreGetService
    private let errorHandler: ErrorDiagnosticsProtocol
    private let alertManager: AlertManager

    private var stateError: StateError = .localError

    init(
        firestoreService: FirestoreGetService,
        errorHandler: ErrorDiagnosticsProtocol,
        alertManager: AlertManager = .shared
    ) {
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        self.alertManager = alertManager
        print("init GalleryManager")
    }

    deinit {
        print("deinit GalleryManager")
    }

    // паралельные запросы async let (быстрее последовательных)
    ///С помощью ключевого слова async let запускаются три запроса параллельно
    ///"async let" и "try await": – async let позволяет запустить несколько операций параллельно, – try await гарантирует, что выполнение будет приостановлено до завершения всех этих операций, и если возникает ошибка, она передается в блок catch.
    func fetchData() async -> Result<[UnifiedSectionModel], UserFacingError> {
        do {
            async let mallsItems: [MallItem] = firestoreService.fetchMalls()
            async let shopsItems: [ShopItem] = firestoreService.fetchShops()
            async let popularProductsItems: [ProductItem] = firestoreService.fetchPopularProducts()

            let (malls, shops, popularProducts) = try await (mallsItems, shopsItems, popularProductsItems)

            let unifiedSections: [UnifiedSectionModel] = [
                .malls(MallSectionModel(header: Localized.Gallery.GalleryCompositView.mallHeader, items: malls)),
                .shops(ShopSectionModel(header: Localized.Gallery.GalleryCompositView.shopHeader, items: shops)),
                .popularProducts(PopularProductsSectionModel(header: Localized.Gallery.GalleryCompositView.productHeader, items: popularProducts))
            ]

            return .success(unifiedSections)

        } catch {
            let message = handleError(error)
            return .failure(UserFacingError(message: message))
        }
    }

    private func handleError(_ error: Error) -> String {
        if let serviceError = error as? FirestoreGetServiceError {
            
            let combinedContext =
            "\(serviceError.context.rawValue) | \(ErrorContext.GalleryManager_fetchData_FirestoreGetService.rawValue)"
            
            return errorHandler.handle(
                error: serviceError.underlying,
                context: combinedContext
            )
            
        } else {
            
            return errorHandler.handle(
                error: error,
                context: ErrorContext.GalleryManager_fetchData_FirestoreGetService.rawValue
            )
        }
    }
}


//    func handleError(_ error: Error) -> String {
//        // сейчас только localError, но оставляем enum для расширения
//        switch stateError {
//        case .localError:
//            return handleFirestoreError(error)
//        }
//    }
//
//    /// error internet connect не проблема если есть кэш(даже если делаем refresh получаем кэш)
//    private func handleFirestoreError(_ error: Error) -> String {
//        let message = errorHandler.handle(error: error)
//        // при необходимости можно показывать глобальный алерт
//        // alertManager.showGlobalAlert(...)
//        return message
//    }





// MARK: - before ErrorDiagnosticsProtocol


//import Foundation
//
//final class GalleryManager {
//    
//    enum StateError {
//        case localError
//    }
//    
//    private let firestoreService: FirestoreGetService
//    private let errorHandler: ErrorHandlerProtocol
//    private let alertManager: AlertManager
//    
//    private var stateError: StateError = .localError
//    
//    init(
//        firestoreService: FirestoreGetService,
//        errorHandler: ErrorHandlerProtocol,
//        alertManager: AlertManager = .shared
//    ) {
//        self.firestoreService = firestoreService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        print("init GalleryManager")
//    }
//    
//    deinit {
//        print("deinit GalleryManager")
//    }
//    
//    // паралельные запросы async let (быстрее последовательных)
//    ///С помощью ключевого слова async let запускаются три запроса параллельно
//    ///"async let" и "try await": – async let позволяет запустить несколько операций параллельно, – try await гарантирует, что выполнение будет приостановлено до завершения всех этих операций, и если возникает ошибка, она передается в блок catch.
//    func fetchData() async -> Result<[UnifiedSectionModel], Error> {
//        do {
//            async let mallsItems: [MallItem] = firestoreService.fetchMalls()
//            async let shopsItems: [ShopItem] = firestoreService.fetchShops()
//            async let popularProductsItems: [ProductItem] = firestoreService.fetchPopularProducts()
//            
//            let (malls, shops, popularProducts) = try await (mallsItems, shopsItems, popularProductsItems)
//            
//            let mallSection = MallSectionModel(
//                header: Localized.Gallery.GalleryCompositView.mallHeader,
//                items: malls
//            )
//            let shopSection = ShopSectionModel(
//                header: Localized.Gallery.GalleryCompositView.shopHeader,
//                items: shops
//            )
//            let productSection = PopularProductsSectionModel(
//                header: Localized.Gallery.GalleryCompositView.productHeader,
//                items: popularProducts
//            )
//            
//            let unifiedSections: [UnifiedSectionModel] = [
//                .malls(mallSection),
//                .shops(shopSection),
//                .popularProducts(productSection)
//            ]
//            
//            return .success(unifiedSections)
//        } catch {
//            return .failure(error)
//        }
//    }
//    
//    func handleError(_ error: Error) -> String {
//        // сейчас только localError, но оставляем enum для расширения
//        switch stateError {
//        case .localError:
//            return handleFirestoreError(error)
//        }
//    }
//    
//    /// error internet connect не проблема если есть кэш(даже если делаем refresh получаем кэш)
//    private func handleFirestoreError(_ error: Error) -> String {
//        let message = errorHandler.handle(error: error)
//        // при необходимости можно показывать глобальный алерт
//        // alertManager.showGlobalAlert(...)
//        return message
//    }
//}
