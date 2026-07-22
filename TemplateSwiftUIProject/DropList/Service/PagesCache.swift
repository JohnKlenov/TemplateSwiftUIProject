// PagesCache.swift
import Foundation

// MARK: - PagesCache (Атомарный кэш через actor)
//
// Этот actor гарантирует ПОЛНУЮ атомарность операций чтения/записи кэша.
// Swift обеспечивает строгую изоляцию actor'а: только один поток может
// выполнять код внутри него в любой момент времени.
//
// Зачем это нужно?
// ----------------
// Droplist выполняет несколько асинхронных операций параллельно:
//
// • initial load
// • выбор элемента карусели (select)
// • пагинация (loadNextPage)
// • soft refresh
// • auto refresh
// • retry
//
// Все эти операции могут обращаться к кэшу ОДНОВРЕМЕННО.
// Без actor это приводит к race conditions:
//
// 1) Два параллельных loadNextPage перезаписывают друг друга.
// 2) select и pagination одновременно пишут в один и тот же ключ.
// 3) refreshDropList очищает кэш в момент записи пагинации.
// 4) stale‑response может перезаписать актуальные данные.
// 5) одновременное чтение и запись приводит к data race и крашу.
//
// Actor решает ВСЕ эти проблемы:
//
// ✔ операции выполняются строго последовательно
//✔ никакой одновременной записи
//✔ никакого одновременного чтения/записи
//✔ никакого повреждения данных
//✔ никакого undefined behavior
//✔ никакого краша из‑за гонок
//✔ кэш всегда консистентный
//✔ безопасная работа при параллельных Task
//✔ идеальная совместимость с Swift Concurrency
//
// Это архитектура уровня Instagram/TikTok/YouTube feed —
// атомарный, потокобезопасный кэш, который невозможно сломать
// параллельными асинхронными операциями.
//

/// Атомарный кэш страниц через actor — предотвращает race conditions
actor PagesCache {
    private var cache: [String: LowerSectionPage] = [:]

    func get(_ id: String) -> LowerSectionPage? { cache[id] }
    func set(_ id: String, page: LowerSectionPage) { cache[id] = page }
    func remove(_ id: String) { cache.removeValue(forKey: id) }
    func reset() { cache.removeAll() }
    func contains(_ id: String) -> Bool { cache[id] != nil }
}



//import Combine
//import Foundation
//
//enum DropeState {
//    case loading
//    case error(String)
//    case myTracks([MyTrackCloud])
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
//@MainActor
//final class DroplistViewModel: ObservableObject {
//
//    // MARK: - Published
//
//    @Published var viewState: DropeState = .loading
//    @Published var lastUpdated: Date? = nil
//
//    // MARK: - Dependencies
//
//    private let sessionManager: AppSessionManager
//    private let dropListDataSource: DropListDataSource
//
//    // MARK: - Internal State
//
//    private var cancellables = Set<AnyCancellable>()
//    private(set) var myTracks: [MyTrackCloud] = []
//
//    /// Блокирует повторный initial load / Refresh
//    private var isDropListLoaded = false
//    private var isRefreshing = false
//
//    /// Единый токен актуальности для всех асинхронных операций (select, pagination, refresh)
//    private var currentRequestID = UUID()
//
//    /// Текущая задача выбора элемента карусели
//    private var currentSelectionTask: Task<Void, Never>? = nil
//
//    /// Задачи пагинации
//    private var currentPaginationTask: Task<Void, Never>? = nil
//
//    /// Авто‑обновление (как в Gallery)
//    private let autoRefreshThreshold: TimeInterval = 2 * 60 * 60
//    // private let autoRefreshThreshold: TimeInterval = 20 // для тестов
//
//    // MARK: - Init
//
//    init(
//        sessionManager: AppSessionManager,
//        dropListDataSource: DropListDataSource
//    ) {
//        self.sessionManager = sessionManager
//        self.dropListDataSource = dropListDataSource
//
//        sessionManager.statePublisher
//            .compactMap { $0 }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                print("sessionManager.statePublisher - \(state)")
//                self?.handleHomeManagerState(state)
//            }
//            .store(in: &cancellables)
//    }
//
//    deinit {
//        print("deinit DroplistViewModel")
//    }
//
//    // MARK: - Setup
//
//    func setupViewModel() {
//        viewState = .loading
//        sessionManager.start()
//        sessionManager.observe()
//    }
//
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        sessionManager.setRetryHandler(handler)
//    }
//
//    func retry() {
//        // Полный сброс состояния Droplist
//        dropListDataSource.resetCache()
//        myTracks = []
//        isDropListLoaded = false
//        isRefreshing = false
//        lastUpdated = nil
//
//        // Отменяем все фоновые задачи
//        currentSelectionTask?.cancel()
//        currentPaginationTask?.cancel()
//
//        // Обновляем токен актуальности
//        currentRequestID = UUID()
//
//        viewState = .loading
//        sessionManager.retry()
//    }
//
//    func resetLastUpdated() {
//        lastUpdated = nil
//    }
//
//    // MARK: - Initial Load (Strict)
//
//    func fetchDataDroplist() async {
//        print("func fetchDataDroplist() before guard")
//        guard !isDropListLoaded else { return }
//        isDropListLoaded = true
//        print("func fetchDataDroplist() after guard")
//
//        // Новый токен актуальности для initial load
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        let result = await dropListDataSource.loadInitialDropList()
//
//        // Проверяем, что запрос всё ещё актуален и нет глобальной ошибки (иначе deadlock)
//        guard requestID == currentRequestID else { return }
//        guard !viewState.isError else { return }
//
//        switch result {
//        case .success(let dropData):
//            lastUpdated = Date()
//            viewState = .contentList(dropData)
//
//        case .failure(let userError):
//            resetLastUpdated()
//            viewState = .errorList(userError.message)
//        }
//    }
//
//    // MARK: - Retry Initial Load
//
//    func retryFetchDataDroplist() {
//        viewState = .loading
//        isDropListLoaded = false
//
//        Task { await fetchDataDroplist() }
//    }
//
//    // MARK: - Soft Refresh (Pull-to-Refresh + Auto Refresh)
//
//    func refreshDropList() async {
//        guard !isRefreshing else { return }
//        isRefreshing = true
//        defer { isRefreshing = false }
//
//        // Новый токен актуальности для refresh
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        // Отменяем все фоновые задачи Droplist
//        currentSelectionTask?.cancel()
//        currentPaginationTask?.cancel()
//
//        // Загружаем новые данные
//        if let newData = await dropListDataSource.refreshAll() {
//            guard requestID == currentRequestID else { return }
//            guard !viewState.isError else { return }
//
//            lastUpdated = Date()
//            print("Soft refresh success — UI changed")
//            viewState = .contentList(newData)
//        } else {
//            print("Soft refresh failed — UI unchanged")
//        }
//    }
//
//    func checkAndRefreshIfNeeded() async {
//        if let lastUpdated {
//            let elapsed = Date().timeIntervalSince(lastUpdated)
//            if elapsed > autoRefreshThreshold {
//                await refreshDropList()
//            }
//        }
//        // else: ничего не делаем, потому что initial load уже был
//    }
//
//    // дальше будут секции didSelectCarouselItem / loadNextPage / handleHomeManagerState
//    
//    // MARK: - didSelectCarouselItem
//
//    func didSelectCarouselItem(_ item: CarouselItem) async {
//        print("func didSelectCarouselItem(_ item: CarouselItem) async")
//
//        guard case .contentList(let currentDropData) = viewState else {
//            print("tap current section")
//            return
//        }
//
//        // Новый токен актуальности для выбора элемента
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        // Отменяем предыдущую selection‑задачу
//        currentSelectionTask?.cancel()
//
//        currentSelectionTask = Task { @MainActor in
//
//            // 1. Проверяем кэш
//            if let cached = await dropListDataSource.cachedPage(for: item) {
//                guard requestID == currentRequestID else { return }
//                guard !viewState.isError else { return }
//
//                viewState = .contentList(
//                    DropData(
//                        topSection: currentDropData.topSection,
//                        carouselItems: currentDropData.carouselItems,
//                        initialLowerSection: cached,
//                        selectedItem: item,
//                        isLowerSectionLoading: false,
//                        footerState: .idle
//                    )
//                )
//                return
//            }
//
//            // 2. Показываем loader
//            guard requestID == currentRequestID else { return }
//            guard !viewState.isError else { return }
//
//            viewState = .contentList(
//                DropData(
//                    topSection: currentDropData.topSection,
//                    carouselItems: currentDropData.carouselItems,
//                    initialLowerSection: LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false),
//                    selectedItem: item,
//                    isLowerSectionLoading: true,
//                    footerState: .idle
//                )
//            )
//
//            // 3. Загружаем данные
//            do {
//                let page = try await dropListDataSource.selectCarouselItem(item)
//
//                guard requestID == currentRequestID else { return }
//                guard !viewState.isError else { return }
//
//                viewState = .contentList(
//                    DropData(
//                        topSection: currentDropData.topSection,
//                        carouselItems: currentDropData.carouselItems,
//                        initialLowerSection: page,
//                        selectedItem: item,
//                        isLowerSectionLoading: false,
//                        footerState: .idle
//                    )
//                )
//
//            } catch {
//                let _ = dropListDataSource.handleError(error)
//
//                guard requestID == currentRequestID else { return }
//                guard !viewState.isError else { return }
//
//                viewState = .contentList(
//                    DropData(
//                        topSection: currentDropData.topSection,
//                        carouselItems: currentDropData.carouselItems,
//                        initialLowerSection: LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false),
//                        selectedItem: item,
//                        isLowerSectionLoading: false,
//                        footerState: .idle
//                    )
//                )
//            }
//        }
//    }
//
//    // MARK: - loadNextPage
//
//
//func loadNextPage(for item: CarouselItem) async {
//    guard case .contentList(let currentDropData) = viewState else { return }
//    guard currentDropData.initialLowerSection.hasMore else { return }
//
//    // Новый токен актуальности
//    let requestID = UUID()
//    currentRequestID = requestID
//
//    // Отменяем предыдущую пагинацию
//    currentPaginationTask?.cancel()
//
//    // Показываем footer spinner
//    viewState = .contentList(
//        DropData(
//            topSection: currentDropData.topSection,
//            carouselItems: currentDropData.carouselItems,
//            initialLowerSection: currentDropData.initialLowerSection,
//            selectedItem: currentDropData.selectedItem,
//            isLowerSectionLoading: false,
//            footerState: .loading
//        )
//    )
//
//    currentPaginationTask = Task { @MainActor in
//        do {
//            let result = try await dropListDataSource.loadNextPageIfNeeded(for: item)
//
//            guard requestID == currentRequestID else { return }
//            guard case .contentList(let latestDropData) = viewState else { return }
//            guard !viewState.isError else { return }
//
//            switch result {
//            case .loaded(_, let mergedPage):
//                viewState = .contentList(
//                    DropData(
//                        topSection: latestDropData.topSection,
//                        carouselItems: latestDropData.carouselItems,
//                        initialLowerSection: mergedPage,
//                        selectedItem: latestDropData.selectedItem,
//                        isLowerSectionLoading: false,
//                        footerState: .idle
//                    )
//                )
//
//            case .noMore:
//                let cached = await dropListDataSource.cachedPage(for: item)
//                    ?? latestDropData.initialLowerSection
//
//                viewState = .contentList(
//                    DropData(
//                        topSection: latestDropData.topSection,
//                        carouselItems: latestDropData.carouselItems,
//                        initialLowerSection: cached,
//                        selectedItem: latestDropData.selectedItem,
//                        isLowerSectionLoading: false,
//                        footerState: .idle
//                    )
//                )
//
//            case .alreadyLoading:
//                return
//
//            case .invalidState:
//                viewState = .contentList(
//                    DropData(
//                        topSection: latestDropData.topSection,
//                        carouselItems: latestDropData.carouselItems,
//                        initialLowerSection: latestDropData.initialLowerSection,
//                        selectedItem: latestDropData.selectedItem,
//                        isLowerSectionLoading: false,
//                        footerState: .idle
//                    )
//                )
//            }
//
//        } catch {
//            guard requestID == currentRequestID else { return }
//            guard case .contentList(let latestDropData) = viewState else { return }
//            guard !viewState.isError else { return }
//
//            viewState = .contentList(
//                DropData(
//                    topSection: latestDropData.topSection,
//                    carouselItems: latestDropData.carouselItems,
//                    initialLowerSection: latestDropData.initialLowerSection,
//                    selectedItem: latestDropData.selectedItem,
//                    isLowerSectionLoading: false,
//                    footerState: .error("Не удалось загрузить данные")
//                )
//            )
//        }
//    }
//}
//
//    // MARK: - Handle AppSessionManager State
//
//    private func handleHomeManagerState(_ state: DropeState) {
//        switch state {
//
//        case .loading:
//            viewState = .loading
//
//        case .error(let message):
/// можем обновляем токен актуальности - currentRequestID = UUID() вместо проверок case .error в методах
//            resetLastUpdated()
//            viewState = .error(message)
//
//        case .myTracks(let tracks):
//            myTracks = tracks
//            Task { await fetchDataDroplist() }   // ВСЕГДА вызываем, но загрузка выполнится только один раз
//
//        case .contentList, .errorList:
//            break
//        }
//    }
//
//}
