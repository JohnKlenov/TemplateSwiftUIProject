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

//func fetchDataDroplist() {
//    guard !isDropListLoaded else { return }
//    isDropListLoaded = true
//    
//    loadDropList(isInitial: true) { [weak self] result in
//        switch result {
//        case .success(let dropData):
//            self?.viewState = .contentList(dropData)
//        case .failure(let error):
//            self?.viewState = .errorList(error.localizedDescription)
//        }
//    }
//}

//    
//    func retryFetchDataDroplist() {
//        isDropListLoaded = false
//        fetchDataDroplist()
//    }
//    
//func refreshDropList() {
//    loadDropList(isInitial: false) { [weak self] result in
//        switch result {
//        case .success(let dropData):
//            self?.viewState = .contentList(dropData)
//        case .failure(let error):
//            print("DropList refresh failed: \(error.localizedDescription)")
//        }
//    }
//}

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
//private func loadDropList(
//    isInitial: Bool,
//    completion: @escaping (Result<DropData, Error>) -> Void
//) {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//        completion(.success(DropData()))
//    }
//}
//}













// MARK: - ferst version code base + pagination



//import Foundation
//import FirebaseFirestore
//
//// Общая модель, которую будет принимать DroplistCompositView
//struct DropData {
//    let topSections: [TopSectionModel]        // верхняя секция (небольшой объём)
//    let carouselItems: [CarouselItem]         // средняя секция (категории)
//    let initialLowerSection: LowerSectionPage // первая порция для дефолтного carousel item
//}
//
//// Верхняя секция
//struct TopSectionModel: Identifiable {
//    let id: String
//    let title: String
//    let items: [TopItem]
//}
//
//struct TopItem: Identifiable, Decodable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//}
//
//// Элемент карусели (категория)
//struct CarouselItem: Identifiable, Decodable, Equatable {
//    let id: String
//    let title: String
//    let type: CarouselItemType
//}
//
//enum CarouselItemType: String, Decodable {
//    case droplist
//    case allTracks
//    case gym
//    case party
//    case rnb
//    // ... другие типы
//}
//
//// Нижняя секция — одна страница результатов + курсор для следующей
//struct LowerSectionPage {
//    let items: [LowerItem]
//    let lastDocumentSnapshot: DocumentSnapshot? // Firestore cursor
//    let hasMore: Bool
//}
//
//struct LowerItem: Identifiable, Decodable {
//    let id: String
//    let title: String
//    let subtitle: String?
//    let imageURL: URL?
//    // другие поля
//}





//import Foundation
//import FirebaseFirestore
//
//protocol DropListFirestoreServiceProtocol {
//    // Верхняя секция и карусель — небольшие запросы, можно параллельно
//    func fetchTopSections() async throws -> [TopSectionModel]
//    func fetchCarouselItems() async throws -> [CarouselItem]
//    
//    // Пагинация для нижней секции: pageSize и optional cursor (DocumentSnapshot)
//    func fetchLowerItems(for carouselItem: CarouselItem,
//                         pageSize: Int,
//                         after document: DocumentSnapshot?) async throws -> (items: [LowerItem], lastSnapshot: DocumentSnapshot?, hasMore: Bool)
//}




//import Foundation
//import FirebaseFirestore
//
//final class DropListDataSource {
//    private let firestore: DropListFirestoreServiceProtocol
//    private let pageSize: Int
//    
//    init(firestore: DropListFirestoreServiceProtocol, pageSize: Int = 20) {
//        self.firestore = firestore
//        self.pageSize = pageSize
//    }
//    
//    /// Первичная загрузка: topSections + carousel + первая страница для дефолтного item
//    /// defaultSelectedIndex — индекс item в carousel, для которого нужно загрузить первую страницу (обычно 0)
//    func loadInitialDropList(defaultSelectedIndex: Int = 0) async throws -> DropData {
//        // Параллельно загружаем верх и карусель
//        async let topSectionsTask = firestore.fetchTopSections()
//        async let carouselTask = firestore.fetchCarouselItems()
//        
//        let (topSections, carouselItems) = try await (topSectionsTask, carouselTask)
//        
//        // Защита: если carousel пуст — возвращаем пустую DropData
//        guard !carouselItems.isEmpty else {
//            let emptyLower = LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false)
//            return DropData(topSections: topSections, carouselItems: carouselItems, initialLowerSection: emptyLower)
//        }
//        
//        // Выбираем дефолтный item (по индексу или 0)
//        let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
//        let defaultItem = carouselItems[index]
//        
//        // Загружаем первую страницу для defaultItem
//        let (items, lastSnapshot, hasMore) = try await firestore.fetchLowerItems(for: defaultItem, pageSize: pageSize, after: nil)
//        let lowerPage = LowerSectionPage(items: items, lastDocumentSnapshot: lastSnapshot, hasMore: hasMore)
//        
//        return DropData(topSections: topSections, carouselItems: carouselItems, initialLowerSection: lowerPage)
//    }
//    
//    /// Загрузить следующую страницу для конкретного carouselItem
//    func loadNextPage(for item: CarouselItem, after lastSnapshot: DocumentSnapshot?) async throws -> LowerSectionPage {
//        let (items, lastSnapshotNew, hasMore) = try await firestore.fetchLowerItems(for: item, pageSize: pageSize, after: lastSnapshot)
//        return LowerSectionPage(items: items, lastDocumentSnapshot: lastSnapshotNew, hasMore: hasMore)
//    }
//    
//    /// Загрузить первую страницу для выбранного carouselItem (при смене категории)
//    func loadFirstPage(for item: CarouselItem) async throws -> LowerSectionPage {
//        let (items, lastSnapshot, hasMore) = try await firestore.fetchLowerItems(for: item, pageSize: pageSize, after: nil)
//        return LowerSectionPage(items: items, lastDocumentSnapshot: lastSnapshot, hasMore: hasMore)
//    }
//}







//final class HomeContentViewModel: ObservableObject {
//    // ... существующие поля
//    
//    private let dropListDataSource: DropListDataSource
//    // Храним состояние нижней секции для текущего выбранного carouselItem
//    private var lowerSectionStateByItem: [String: LowerSectionPage] = [:] // key = carouselItem.id
//    private var currentSelectedCarouselItem: CarouselItem?
//    
//    init(homeManager: HomeManager,
//         managerCRUDS: CRUDSManager,
//         dropListFirestoreService: DropListFirestoreServiceProtocol) {
//        self.homeManager = homeManager
//        self.managerCRUDS = managerCRUDS
//        self.dropListDataSource = DropListDataSource(firestore: dropListFirestoreService, pageSize: 20)
//        // подписки...
//    }
//    
//    // MARK: - DropList (реализация через data source)
//    
//    private func performFetchDropList(
//        completion: @escaping (Result<DropData, Error>) -> Void
//    ) {
//        Task {
//            do {
//                let dropData = try await dropListDataSource.loadInitialDropList(defaultSelectedIndex: 0)
//                
//                // Сохраняем initial lower page для выбранного item
//                if let firstItem = dropData.carouselItems.first {
//                    currentSelectedCarouselItem = firstItem
//                    lowerSectionStateByItem[firstItem.id] = dropData.initialLowerSection
//                }
//                
//                await MainActor.run {
//                    completion(.success(dropData))
//                }
//            } catch {
//                await MainActor.run {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    private func performGetDropList(
//        completion: @escaping (Result<DropData, Error>) -> Void
//    ) {
//        // getDataDroplist — мягкий refresh: если уже есть DropData, обновляем carousel/topSections and keep UI if fails
//        Task {
//            do {
//                // Попробуем обновить topSections и carousel
//                async let topSectionsTask = dropListDataSource.firestore.fetchTopSections()
//                async let carouselTask = dropListDataSource.firestore.fetchCarouselItems()
//                let (topSections, carouselItems) = try await (topSectionsTask, carouselTask)
//                
//                // Если есть текущий выбранный item — обновим его страницу (first page)
//                var initialLower = LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false)
//                if let selected = currentSelectedCarouselItem {
//                    // Попробуем загрузить первую страницу для текущего выбранного item
//                    let page = try await dropListDataSource.loadFirstPage(for: selected)
//                    lowerSectionStateByItem[selected.id] = page
//                    initialLower = page
//                } else if let first = carouselItems.first {
//                    currentSelectedCarouselItem = first
//                    let page = try await dropListDataSource.loadFirstPage(for: first)
//                    lowerSectionStateByItem[first.id] = page
//                    initialLower = page
//                }
//                
//                let dropData = DropData(topSections: topSections, carouselItems: carouselItems, initialLowerSection: initialLower)
//                await MainActor.run {
//                    completion(.success(dropData))
//                }
//            } catch {
//                // Мягкая ошибка: не переводим UI в errorList, возвращаем failure чтобы вызывающий мог решить как показать toast
//                await MainActor.run {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    // Вызов при прокрутке вниз: подгрузить следующую страницу
//    func loadNextPageIfNeeded(for item: CarouselItem) {
//        guard let page = lowerSectionStateByItem[item.id], page.hasMore else { return }
//        // уже загружено, берем lastSnapshot
//        let lastSnapshot = page.lastDocumentSnapshot
//        Task {
//            do {
//                let nextPage = try await dropListDataSource.loadNextPage(for: item, after: lastSnapshot)
//                // объединяем
//                var merged = page.items
//                merged.append(contentsOf: nextPage.items)
//                let newPage = LowerSectionPage(items: merged, lastDocumentSnapshot: nextPage.lastDocumentSnapshot, hasMore: nextPage.hasMore)
//                lowerSectionStateByItem[item.id] = newPage
//                
//                // Если текущий выбранный item — обновляем UI
//                if currentSelectedCarouselItem?.id == item.id {
//                    await MainActor.run {
//                        self.viewState = .contentList(DropData(topSections: [], carouselItems: [], initialLowerSection: newPage))
//                        // Примечание: лучше иметь отдельную структуру DropData для incremental updates,
//                        // здесь для простоты мы обновляем contentList с новой lower page.
//                    }
//                }
//            } catch {
//                print("Failed to load next page: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // При смене item в карусели
//    func didSelectCarouselItem(_ item: CarouselItem) {
//        currentSelectedCarouselItem = item
//        // Если уже есть сохранённая страница — показываем её
//        if let page = lowerSectionStateByItem[item.id] {
//            viewState = .contentList(DropData(topSections: [], carouselItems: [], initialLowerSection: page))
//            return
//        }
//        // Иначе — загружаем первую страницу для этого item
//        Task {
//            do {
//                let page = try await dropListDataSource.loadFirstPage(for: item)
//                lowerSectionStateByItem[item.id] = page
//                await MainActor.run {
//                    self.viewState = .contentList(DropData(topSections: [], carouselItems: [], initialLowerSection: page))
//                }
//            } catch {
//                await MainActor.run {
//                    self.viewState = .errorList(error.localizedDescription)
//                }
//            }
//        }
//    }
//}



//func fetchLowerItems(for carouselItem: CarouselItem, pageSize: Int, after document: DocumentSnapshot?) async throws -> (items: [LowerItem], lastSnapshot: DocumentSnapshot?, hasMore: Bool) {
//    try await withCheckedThrowingContinuation { continuation in
//        var query = db.collection("lowerItems")
//            .whereField("categoryId", isEqualTo: carouselItem.id)
//            .order(by: "createdAt", descending: false)
//            .limit(to: pageSize)
//        if let doc = document {
//            query = query.start(afterDocument: doc)
//        }
//        query.getDocuments { snapshot, error in
//            if let error = error { continuation.resume(throwing: error); return }
//            guard let snapshot = snapshot else { continuation.resume(throwing: AppInternalError.nilSnapshot); return }
//            let items = snapshot.documents.compactMap { try? $0.data(as: LowerItem.self) }
//            let last = snapshot.documents.last
//            let hasMore = items.count == pageSize
//            continuation.resume(returning: (items, last, hasMore))
//        }
//    }
//}
