//
//  GalleryContentViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//


// MARK: - Последовательные запросы let malls = try await firestoreService.fetchMalls() -

///Использование async let порождает несколько задач, выполняющихся параллельно, и затем try await ожидает их всех одновременно. Это намного быстрее, если независимые запросы не зависят друг от друга, но не подходит, если требуется строгая последовательность.

//do {
//    let malls = try await firestoreService.fetchMalls()          // Выполнение завершится
//    let shops = try await firestoreService.fetchShops()            // Только после завершения malls
//    let popularProducts = try await firestoreService.fetchPopularProducts() // После shops завершается
//       
//    let newSections = [
//        SectionModel(section: "Malls", items: malls),
//        SectionModel(section: "Shops", items: shops),
//        SectionModel(section: "PopularProducts", items: popularProducts)
//    ]
//    
//    self.lastUpdated = Date()
//    viewState = .content(newSections)
//} catch let error as DataFetchError {
//    print("Ошибка загрузки данных: \(error.localizedDescription)")
//    self.handleFirestoreError(error)
//} catch {
//    print("Неизвестная ошибка: \(error.localizedDescription)")
//    self.handleFirestoreError(error)
//}


//[SectionModel]
import SwiftUI

enum GalleryViewState {
    case loading
    case error(String)
    case content([UnifiedSectionModel])
}

extension GalleryViewState {
    var isError:Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

class GalleryContentViewModel: ObservableObject {
    
    @Published var viewState: GalleryViewState = .loading
    @Published var lastUpdated: Date? = nil { // Время последнего обновления
        didSet {
            print("didSet lastUpdated ")
        }
    }
    
    // Для получения коллекции моделей GalleryBook:
    private var firestoreService: FirestoreGetService
    private let errorHandler: ErrorHandlerProtocol
    private var alertManager:AlertManager
    
//    private let autoRefreshThreshold: TimeInterval = 2 * 60 * 60 // 2 часа (7200 секунд)

    // Порог для автоматического обновления (1 минута)
    private let autoRefreshThreshold: TimeInterval = 60

    
    init(alertManager: AlertManager = AlertManager.shared, firestoreService: FirestoreGetService,
         errorHandler: ErrorHandlerProtocol) {
        self.alertManager = alertManager
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        print("init GalleryContentViewModel")
    }
    
    @MainActor
    func fetchData() async {
        // паралельные запросы async let (быстрее последовательных)
        ///С помощью ключевого слова async let запускаются три запроса параллельно
        ///"async let" и "try await": – async let позволяет запустить несколько операций параллельно, – try await гарантирует, что выполнение будет приостановлено до завершения всех этих операций, и если возникает ошибка, она передается в блок catch.
        print("fetchData() GalleryContentViewModel")
        do {
            async let mallsItems: [MallItem] = firestoreService.fetchMalls()
            async let shopsItems: [ShopItem] = firestoreService.fetchShops()
            async let popularProductsItems: [ProductItem] = firestoreService.fetchPopularProducts()
            
            let (malls, shops, popularProducts) = try await (mallsItems, shopsItems, popularProductsItems)
            
            let mallSection = MallSectionModel(header: Localized.Gallery.GalleryCompositView.mallHeader, items: malls)
            let shopSection = ShopSectionModel(header:  Localized.Gallery.GalleryCompositView.shopHeader, items: shops)
            let productSection = PopularProductsSectionModel(header:  Localized.Gallery.GalleryCompositView.productHeader, items: popularProducts)
            
            let unifiedSections: [UnifiedSectionModel] = [
                .malls(mallSection),
                .shops(shopSection),
                .popularProducts(productSection)
            ]
            
            self.lastUpdated = Date()
            viewState = .content(unifiedSections)
        } catch {
            self.handleFirestoreError(error)
        }
    }
    ///@MainActor, что означает—всё его содержимое выполняется на главном потоке. Это важно, когда вы обновляете UI-связанные свойства (viewState).
    ///Date().timeIntervalSince(lastUpdated) Это выражение вернёт количество секунд, прошедших с момента сохранённого времени до текущего.
    @MainActor
    func checkAndRefreshIfNeeded() async {
        if let lastUpdated = lastUpdated {
            let elapsed = Date().timeIntervalSince(lastUpdated)
            if elapsed > autoRefreshThreshold {
                await fetchData()
            }
        } else {
            print("lastUpdated == nil")
            await fetchData()
        }
    }
    
    private func handleFirestoreError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage,
                                      forView: "GalleryView",
                                      operationDescription: Localized.DescriptionOfOperationError.database)
        // Переключаемся в состояние ошибки только если данных ещё не было получено
        if case .content = viewState {
            print(".content = viewState")
            // Если уже отображается контент, оставляем state как есть;
            // тем самым ContentErrorView не показывается.
        } else {
            print("viewState = .error")
            viewState = .error(errorMessage)
        }
    }
}




// MARK: - old code

///async let mallsItems: [Item] = firestoreService.fetchMalls()
///async let shopsItems: [Item] = firestoreService.fetchShops()
///async let popularProductsItems: [Item] = firestoreService.fetchPopularProducts()

//func fetchData() async {
//    // паралельные запросы async let (быстрее последовательных)
//    ///С помощью ключевого слова async let запускаются три запроса параллельно
//    ///"async let" и "try await": – async let позволяет запустить несколько операций параллельно, – try await гарантирует, что выполнение будет приостановлено до завершения всех этих операций, и если возникает ошибка, она передается в блок catch.
//    do {
//        async let mallsItems: [Item] = firestoreService.fetchCollection(from: "mall")
//        async let shopsItems: [Item] = firestoreService.fetchCollection(from: "shop")
//        async let popularProductsItems: [Item] = firestoreService.fetchCollection(from: "popularProduct")
//        
//        let (malls, shops, popularProducts) = try await (mallsItems, shopsItems, popularProductsItems)
//        
//        let newSections = [
//            SectionModel(section: "Malls", items: malls),
//            SectionModel(section: "Shops", items: shops),
//            SectionModel(section: "PopularProducts", items: popularProducts)
//        ]
//        print("newSections = \(newSections)")
//        
//        self.lastUpdated = Date()
//        viewState = .content(newSections)
//    } catch {
//        self.handleFirestoreError(error)
//    }
//}
