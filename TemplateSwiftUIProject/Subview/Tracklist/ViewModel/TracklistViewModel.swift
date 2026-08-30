//
//  TracklistViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//

// c DataRefreshState работает с allTrack + gym .. + в будущем со списком DropTop! (playlist + dropTopItem не меняется никогда поэтому их мы не отслеживаем для обновления)

import SwiftUI

enum TracklistState {
    case loading
    case error(String)
    case contentList(Tracklist)
}

@MainActor
final class TracklistViewModel: ObservableObject {

    @Published var viewState: TracklistState = .loading

    private let dropListDataSource: DropListDataSource
    private let trackType: CarouselItemType

    private var isLoadingNextPage = false

    init(
        dropListDataSource: DropListDataSource,
        trackType: CarouselItemType
    ) {
        self.dropListDataSource = dropListDataSource
        self.trackType = trackType
    }

    func setupViewModel() async {
        await fetchData()
    }

    func retry() async {
        await fetchData()
    }

    // MARK: - Fetch Data

    func fetchData() async {

        viewState = .loading

        let needsRefresh = await dropListDataSource.needsDataRefresh(
            for: trackType
        )

        // Если экран уже видел текущую revision —
        // используем cache.
        if !needsRefresh,
           let cached = await dropListDataSource.cachedPage(
               for: trackType
           ) {

            print("Tracklist — cached")

            viewState = .contentList(
                Tracklist(
                    tracks: cached,
                    footerState: .idle
                )
            )

            return
        }

        // Cache отсутствует или revision изменилась —
        // обязательно идём в сеть.

        do {

            let page = try await dropListDataSource.fetchTracksForTag(
                trackType
            )

            print("Tracklist — network")

            viewState = .contentList(
                Tracklist(
                    tracks: page,
                    footerState: .idle
                )
            )

            // Этот конкретный экран теперь видел текущую revision.
            await dropListDataSource.markDataSeen(
                for: trackType
            )

        } catch {

            print("Tracklist — catch")

            viewState = .error(
                dropListDataSource.handleError(error)
            )
        }
    }

    // MARK: - Pagination

    func loadNextPage() async {

        guard !isLoadingNextPage else {
            return
        }

        guard case .contentList(let currentTracklist) = viewState else {
            return
        }

        guard currentTracklist.tracks.hasMore else {
            return
        }

        isLoadingNextPage = true

        defer {
            isLoadingNextPage = false
        }

        viewState = .contentList(
            Tracklist(
                tracks: currentTracklist.tracks,
                footerState: .loading
            )
        )

        do {

            let result = try await dropListDataSource.loadNextPageIfNeeded(
                for: trackType
            )

            guard case .contentList(let latestTracklist) = viewState else {
                return
            }

            switch result {

            case .loaded(let mergedPage):

                viewState = .contentList(
                    Tracklist(
                        tracks: mergedPage,
                        footerState: .idle
                    )
                )

            case .noMore:

                let cached = await dropListDataSource.cachedPage(
                    for: trackType
                ) ?? latestTracklist.tracks

                viewState = .contentList(
                    Tracklist(
                        tracks: cached,
                        footerState: .idle
                    )
                )

            case .invalidState:

                viewState = .contentList(
                    Tracklist(
                        tracks: latestTracklist.tracks,
                        footerState: .idle
                    )
                )
            }

        } catch {

            guard case .contentList(let latestTracklist) = viewState else {
                return
            }

            viewState = .contentList(
                Tracklist(
                    tracks: latestTracklist.tracks,
                    footerState: .error("Не удалось загрузить данные")
                )
            )
        }
    }
}


//    try? await Task.sleep(nanoseconds: 5_000_000_000)
//    viewState = .contentList(
//        Tracklist(
//            tracks: currentTracklist.tracks,
//            footerState: .error(
//                "Не удалось загрузить данные"
//            )
//        )
//    )
    









// MARK: - before DataRefreshStateStore


//import SwiftUI
//
//enum TracklistState {
//    case loading
//    case error(String)
//    case contentList(Tracklist)
//}
//
//
//@MainActor
//final class TracklistViewModel: ObservableObject {
//
//    @Published var viewState: TracklistState = .loading
//
//    private let dropListDataSource: DropListDataSource
//    private let trackType: CarouselItemType
//
//    /// оставим на случай если появиться паралельный метод обновляющий viewState
//    private var currentRequestID = UUID()
//    private var isLoadingNextPage = false
//
//    init(
//        dropListDataSource: DropListDataSource,
//        trackType: CarouselItemType
//    ) {
//        self.dropListDataSource = dropListDataSource
//        self.trackType = trackType
//    }
//
//    func setupViewModel() async {
//        await fetchData()
//    }
//
//    func retry() async {
//        await fetchData()
//    }
//
//    //        // пауза 5 секунд
//    //        try? await Task.sleep(nanoseconds: 5_000_000_000)
//    //        viewState = .error("error")
//    func fetchData() async {
//        viewState = .loading
//
//        if let cached = await dropListDataSource.cachedPage(for: trackType) {
//            print("cached")
//            viewState = .contentList(
//                Tracklist(
//                    tracks: cached,
//                    footerState: .idle
//                )
//            )
//            return
//        }
//
//        do {
//            let page =
//                try await dropListDataSource.fetchTracksForTag(
//                    trackType
//                )
//            print("page")
//            viewState = .contentList(
//                Tracklist(
//                    tracks: page,
//                    footerState: .idle
//                )
//            )
//        } catch {
//            print("catch")
//            viewState = .error(
//                dropListDataSource.handleError(error)
//            )
//        }
//    }
//
//
//    func loadNextPage() async {
//        guard !isLoadingNextPage else {
//            return
//        }
//
//        guard case .contentList(let currentTracklist) = viewState else {
//            return
//        }
//
//        guard currentTracklist.tracks.hasMore else {
//            return
//        }
//
//        isLoadingNextPage = true
//        defer {
//            isLoadingNextPage = false
//        }
//
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        viewState = .contentList(
//            Tracklist(
//                tracks: currentTracklist.tracks,
//                footerState: .loading
//            )
//        )
//
//        do {
//            let result =
//                try await dropListDataSource.loadNextPageIfNeeded(
//                    for: trackType
//                )
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            guard case .contentList(let latestTracklist) = viewState else {
//                return
//            }
//
//            switch result {
//            case .loaded(let mergedPage):
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: mergedPage,
//                        footerState: .idle
//                    )
//                )
//
//            case .noMore:
//                let cached =
//                    await dropListDataSource.cachedPage(
//                        for: trackType
//                    ) ?? latestTracklist.tracks
//
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: cached,
//                        footerState: .idle
//                    )
//                )
//
//            case .invalidState:
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: latestTracklist.tracks,
//                        footerState: .idle
//                    )
//                )
//            }
//        } catch {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            guard case .contentList(let latestTracklist) = viewState else {
//                return
//            }
//
//            viewState = .contentList(
//                Tracklist(
//                    tracks: latestTracklist.tracks,
//                    footerState: .error(
//                        "Не удалось загрузить данные"
//                    )
//                )
//            )
//        }
//    }
//}

// MARK: - before GPT


//enum TracklistState {
//    case loading
//    case error(String)
//    case contentList(Tracklist)
//}
//
//extension TracklistState {
//    var isError: Bool {
//        switch self {
//        case .error:
//            return true
//        default:
//            return false
//        }
//    }
//}


//@MainActor
//final class TracklistViewModel: ObservableObject {
//    
//    // MARK: Published
//    @Published var viewState: TracklistState = .loading
//    
//    // MARK: Dependencies
//    private let dropListDataSource: DropListDataSource
//    
//    // токен актуальности
//    private var currentRequestID = UUID()
//
//    // Задачи пагинации
//    private var currentPaginationTask: Task<Void, Never>? = nil
//    
//    private let trackType: CarouselItemType
//    // MARK: Init
//    
//    init(
//        dropListDataSource: DropListDataSource,
//        trackType: CarouselItemType
//    ) {
//        self.dropListDataSource = dropListDataSource
//        self.trackType = trackType
//    }
//    
//    // MARK: - Setup
//
//    func setupViewModel() async {
//        await fetchData()
//    }
//    
//    func retry() async {
//        await fetchData()
//    }
//    
//    func fetchData() async {
//        
//        viewState = .loading
//        
//            // 1. Проверяем кэш
//        if let cached = await dropListDataSource.cachedPage(for: trackType) {
//
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: cached,
//                        footerState: .idle
//                    )
//                )
//                return
//            }
//
//            // 3. Загружаем данные
//            do {
//                let page = try await dropListDataSource.fetchTracksForTag(trackType)
//
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: page,
//                        footerState: .idle
//                    )
//                )
//
//            } catch {
//                let err = dropListDataSource.handleError(error)
//                viewState = .error(err)
//            }
//    }
//    
//    // MARK:  loadNextPage
//    
//func loadNextPage() async {
//    guard case .contentList(let currentTracklist) = viewState else { return }
//    guard currentTracklist.tracks.hasMore else {
//        return
//    }
//
//    let requestID = UUID()
//    currentRequestID = requestID
//
//    currentPaginationTask?.cancel()
//
//    guard requestID == currentRequestID else { return }
//    guard !viewState.isError else { return }
//    
//    // Показываем footer spinner
//    viewState = .contentList(
//        Tracklist(
//            tracks: currentTracklist.tracks,
//            footerState: .loading
//        )
//    )
//
//    currentPaginationTask = Task { @MainActor in
//        do {
//            let result = try await dropListDataSource.loadNextPageIfNeeded(for: trackType)
//
//            guard requestID == currentRequestID else { return }
//            guard case .contentList(let latestTracklist) = viewState else { return }
//            guard !viewState.isError else { return }
//
//            switch result {
//            case .loaded(let mergedPage):
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: mergedPage,
//                        footerState: .idle
//                    )
//                )
//
//            case .noMore:
//                let cached = await dropListDataSource.cachedPage(for: trackType)
//                    ?? latestTracklist.tracks
//
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: cached,
//                        footerState: .idle
//                    )
//                )
//
//            case .invalidState:
//                viewState = .contentList(
//                    Tracklist(
//                        tracks: latestTracklist.tracks,
//                        footerState: .idle
//                    )
//                )
//            }
//
//        } catch {
//            guard requestID == currentRequestID else { return }
//            guard case .contentList(let latestTracklist) = viewState else { return }
//            guard !viewState.isError else { return }
//
//            viewState = .contentList(
//                Tracklist(
//                    tracks: latestTracklist.tracks,
//                    footerState: .error("Не удалось загрузить данные")
//                )
//            )
//        }
//    }
//}
//    
//    deinit {
//        print("deinit TracklistViewModel")
//    }
//    
//}







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
////    private var currentSelectionTask: Task<Void, Never>? = nil
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
//        
//        // Обновляем токен актуальности
//        currentRequestID = UUID()
//        
//        // Полный сброс состояния Droplist
//        dropListDataSource.resetCache()
//        
//        myTracks = []
//        isDropListLoaded = false
//        isRefreshing = false
//        lastUpdated = nil
//
//        // Отменяем все фоновые задачи
////        currentSelectionTask?.cancel()
//        currentPaginationTask?.cancel()
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
////        currentSelectionTask?.cancel()
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
//    
//    // MARK: - loadNextPage
//    
//func loadNextPage(for item: CarouselItemType) async {
//    guard case .contentList(let currentDropData) = viewState else { return }
//    guard currentDropData.initialLowerSection.hasMore else {
//        return
//    }
//
//    let requestID = UUID()
//    currentRequestID = requestID
//
//    currentPaginationTask?.cancel()
//
//    guard requestID == currentRequestID else { return }
//    guard !viewState.isError else { return }
//    
//    // Показываем footer spinner
//    viewState = .contentList(
//        DropData(
//            topSection: currentDropData.topSection,
//            initialLowerSection: currentDropData.initialLowerSection,
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
//            case .loaded(let mergedPage):
//                viewState = .contentList(
//                    DropData(
//                        topSection: latestDropData.topSection,
//                        initialLowerSection: mergedPage,
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
//                        initialLowerSection: cached,
//                        footerState: .idle
//                    )
//                )
//
//            case .invalidState:
//                viewState = .contentList(
//                    DropData(
//                        topSection: latestDropData.topSection,
//                        initialLowerSection: latestDropData.initialLowerSection,
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
//                    initialLowerSection: latestDropData.initialLowerSection,
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
//// можем обновляем токен актуальности - currentRequestID = UUID() вместо проверок case .error в методах
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



