//
//  GalleryContentViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

enum GalleryViewState {
    case loading
    case error(String)
    case content([SectionModel])
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
    @Published var lastUpdated: Date? = nil // Время последнего обновления
    
    // Для получения коллекции моделей GalleryBook:
    private var firestoreService: FirestoreGetService
    private let errorHandler: ErrorHandlerProtocol
    private var alertManager:AlertManager
    
    // Порог для автоматического обновления (например, 1 день)
    private let autoRefreshThreshold: TimeInterval = 24 * 60 * 60
    
    init(alertManager: AlertManager = AlertManager.shared, firestoreService: FirestoreGetService,
         errorHandler: ErrorHandlerProtocol) {
        self.alertManager = alertManager
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        print("init GalleryContentViewModel")
    }
    
    @MainActor
    func fetchData() async {
        
        do {
            async let mallsItems: [Item] = firestoreService.fetchMalls()
            async let shopsItems: [Item] = firestoreService.fetchShops()
            async let popularProductsItems: [Item] = firestoreService.fetchPopularProducts()
            
            let (malls, shops, popularProducts) = try await (mallsItems, shopsItems, popularProductsItems)
            
            let newSections = [
                SectionModel(section: "Malls", items: malls),
                SectionModel(section: "Shops", items: shops),
                SectionModel(section: "PopularProducts", items: popularProducts)
            ]
            
            self.lastUpdated = Date()
            viewState = .content(newSections)
            
        } catch let error as DataFetchError {
            /// тут мы ожидаем ошибку из CloudFirestore а так же ошибку преобразования модели.
            /// нам нужно из любой DataFetchError что сюда приходит достать Error и передать в errorHandler.handle(error: error)
            /// ошибку преобразования модели нужно обязательно логировать но сообзать это юзеру не нужно.
            // Логирование ошибки через Crashlytics или аналогичный сервис
            print("Ошибка загрузки данных: \(error.localizedDescription)")
            self.handleFirestoreError(error)
        } catch {
            /// тут мы ожидаем неизвестную ошибку
            print("Неизвестная ошибка: \(error.localizedDescription)")
            self.handleFirestoreError(error)
        }
    }
    
    @MainActor
    func checkAndRefreshIfNeeded() async {
        if let lastUpdated = lastUpdated {
            let elapsed = Date().timeIntervalSince(lastUpdated)
            if elapsed > autoRefreshThreshold {
                await fetchData()
            }
        } else {
            await fetchData()
        }
    }
    
    private func handleFirestoreError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage, forView: "GalleryView", operationDescription: Localized.DescriptionOfOperationError.database)
        viewState = .error(errorMessage)
    }
}



//    private func bind() {
//        viewState = .loading
//
//        // Приведение к нужному типу AnyPublisher<Result<[GalleryBook], Error>, Never>
//        let publisher: AnyPublisher<Result<[GalleryBook], Error>, Never> = firestorColletionObserverService.observeCollection(at: "GalleryBook")
//
//        publisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] result in
//                guard let self = self else { return }
//                switch result {
//                case .success(let data):
//                    self.viewState = .content(data)
//                case .failure(let error):
//                    self.handleFirestoreError(error)
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    func setupViewModel() {
//        bind()
//    }
//
//    func retry() {
//        bind()
//    }
