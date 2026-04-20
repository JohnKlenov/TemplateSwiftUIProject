//
//  DroplistViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

//import Combine
//import SwiftUI
//
//struct DropData {}
//struct TrackCloud {}
//
//enum DropeState {
//    case loading
//    case error(String)
//    case myTracks([TrackCloud])
//    case errorList(String)
//    case contentList(DropData)
//}
//
//extension DropeState {
//    var isError: Bool {
//        switch self {
//        case .error, .errorList:
//            return true
//        default:
//            return false
//        }
//    }
//}
//
//
//
//final class DroplistViewModel: ObservableObject {
//    
//    @Published var viewState: DropeState = .loading
//    
//    private let homeManager: HomeManager
//    let managerCRUDS: CRUDSManager
//    private var cancellables = Set<AnyCancellable>()
//    
//    private(set) var myTracks: [TrackCloud] = []
//    private var isDropListLoaded = false
//    
//    init(homeManager: HomeManager,
//         managerCRUDS: CRUDSManager) {
//        self.homeManager = homeManager
//        self.managerCRUDS = managerCRUDS
//        print("init HomeContentView + HomeContentViewModel")
//        
//        homeManager.statePublisher
//            .compactMap { $0 }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.handleHomeManagerState(state)
//            }
//            .store(in: &cancellables)
//    }
//    
//    deinit {
//        print("deinit HomeContentView + HomeContentViewModel")
//    }
//    
//    func setupViewModel() {
//        viewState = .loading
//        homeManager.start()
//        homeManager.observe()
//    }
//    
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        homeManager.setRetryHandler(handler)
//    }
//    
//    func retry() {
//        myTracks = []
//        isDropListLoaded = false
//        viewState = .loading
//        homeManager.retry()
//    }
//    
//    // MARK: - DropList
//    
//    func fetchDataDroplist() {
//        guard !isDropListLoaded else { return }
//        isDropListLoaded = true
//        
//        performFetchDropList { [weak self] result in
//            switch result {
//            case .success(let dropData):
//                self?.viewState = .contentList(dropData)
//            case .failure(let error):
//                self?.viewState = .errorList(error.localizedDescription)
//            }
//        }
//    }
//    
//    func retryFetchDataDroplist() {
//        isDropListLoaded = false
//        fetchDataDroplist()
//    }
//    
//    func refreshDropList() {
//        performGetDropList { [weak self] result in
//            switch result {
//            case .success(let dropData):
//                self?.viewState = .contentList(dropData)
//            case .failure(let error):
//                print("DropList refresh failed: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // MARK: - Handle HomeManager state
//    
//    private func handleHomeManagerState(_ state: DropeState) {
//        switch state {
//            
//        case .loading:
//            viewState = .loading
//            
//        case .error(let message):
//            viewState = .error(message)
//            
//        case .myTracks(let tracks):
//            // Сохраняем треки, но НЕ меняем viewState
//            myTracks = tracks
//            fetchDataDroplist()
//            
//        case .contentList, .errorList:
//            break
//        }
//    }
//    
//    // MARK: - Abstract DropList API
//    
//    private func performFetchDropList(
//        completion: @escaping (Result<DropData, Error>) -> Void
//    ) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            completion(.success(DropData()))
//        }
//    }
//    
//    private func performGetDropList(
//        completion: @escaping (Result<DropData, Error>) -> Void
//    ) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            completion(.success(DropData()))
//        }
//    }
//}

