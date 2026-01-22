//
//  GalleryManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.01.26.
//

import Foundation

final class GalleryManager {
    
    enum StateError {
        case localError
    }
    
    private let firestoreService: FirestoreGetService
    private let errorHandler: ErrorHandlerProtocol
    private let alertManager: AlertManager
    
    private var stateError: StateError = .localError
    
    init(
        firestoreService: FirestoreGetService,
        errorHandler: ErrorHandlerProtocol,
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
    func fetchData() async -> Result<[UnifiedSectionModel], Error> {
        do {
            async let mallsItems: [MallItem] = firestoreService.fetchMalls()
            async let shopsItems: [ShopItem] = firestoreService.fetchShops()
            async let popularProductsItems: [ProductItem] = firestoreService.fetchPopularProducts()
            
            let (malls, shops, popularProducts) = try await (mallsItems, shopsItems, popularProductsItems)
            
            let mallSection = MallSectionModel(
                header: Localized.Gallery.GalleryCompositView.mallHeader,
                items: malls
            )
            let shopSection = ShopSectionModel(
                header: Localized.Gallery.GalleryCompositView.shopHeader,
                items: shops
            )
            let productSection = PopularProductsSectionModel(
                header: Localized.Gallery.GalleryCompositView.productHeader,
                items: popularProducts
            )
            
            let unifiedSections: [UnifiedSectionModel] = [
                .malls(mallSection),
                .shops(shopSection),
                .popularProducts(productSection)
            ]
            
            return .success(unifiedSections)
        } catch {
            return .failure(error)
        }
    }
    
    func handleError(_ error: Error) -> String {
        // сейчас только localError, но оставляем enum для расширения
        switch stateError {
        case .localError:
            return handleFirestoreError(error)
        }
    }
    
    /// error internet connect не проблема если есть кэш(даже если делаем refresh получаем кэш)
    private func handleFirestoreError(_ error: Error) -> String {
        let message = errorHandler.handle(error: error)
        // при необходимости можно показывать глобальный алерт
        // alertManager.showGlobalAlert(...)
        return message
    }
}

