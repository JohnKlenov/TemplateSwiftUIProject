//
//  GalleryViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.03.25.
//

import Foundation
import Combine

enum GalleryViewState {
    case loading
    case error(String)
    case content([GalleryBook])
}

extension GalleryViewState {
    var isError:Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

class GalleryViewModel: ObservableObject {
    
    @Published var viewState: GalleryViewState = .loading
    private var cancellables = Set<AnyCancellable>()
    
    // Для получения коллекции моделей GalleryBook:
    private var firestorColletionObserverService: FirestoreCollectionObserverProtocol
    private let errorHandler: ErrorHandlerProtocol
    private var alertManager:AlertManager
    
    init(alertManager: AlertManager = AlertManager.shared, firestorColletionObserverService: FirestoreCollectionObserverProtocol,
         errorHandler: ErrorHandlerProtocol) {
        self.alertManager = alertManager
        self.firestorColletionObserverService = firestorColletionObserverService
        self.errorHandler = errorHandler
        print("init GalleryViewModel")
    }
    
    private func bind() {
        viewState = .loading
        
        // Приведение к нужному типу AnyPublisher<Result<[GalleryBook], Error>, Never>
        let publisher: AnyPublisher<Result<[GalleryBook], Error>, Never> = firestorColletionObserverService.observeCollection(at: "GalleryBook")

        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let data):
                    self.viewState = .content(data)
                case .failure(let error):
                    self.handleFirestoreError(error)
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleFirestoreError(_ error: Error) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showLocalalAlert(message: errorMessage, forView: "GalleryView", operationDescription: Localized.DescriptionOfOperationError.database)
        viewState = .error(errorMessage)
    }
}

