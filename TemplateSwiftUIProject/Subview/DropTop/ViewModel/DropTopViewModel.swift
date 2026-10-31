//
//  DropTopViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//


import SwiftUI
import Foundation

// =================================================
// MARK: - CONTENT STATE
// =================================================

enum DropTopContentState {
    case loading
    case contentList(DropTopPage)
    case error(String)
}

// =================================================
// MARK: - STATE HELPERS
// =================================================

extension DropTopContentState {
    var isError: Bool {
        if case .error = self {
            return true
        }

        return false
    }
}



// =================================================
// MARK: - VIEW MODEL
// =================================================

@MainActor
final class DropTopViewModel: ObservableObject {

    // =================================================
    // MARK: Published
    // =================================================

    @Published private(set) var viewState: DropTopContentState = .loading
    @Published private(set) var selectedTag: DropTopTag = .all
    @Published private(set) var displayedTag: DropTopTag?
    @Published private(set) var paginationError: String?

    // =================================================
    // MARK: Dependencies
    // =================================================

    private let dropListDataSource: DropListDataSource

    // =================================================
    // MARK: Request Control
    // =================================================

    private var currentRequestID = UUID()
    private var currentPaginationTask: Task<Void, Never>?

    // =================================================
    // MARK: Init
    // =================================================

    init(
        dropListDataSource: DropListDataSource
    ) {
        self.dropListDataSource = dropListDataSource
    }

    // =================================================
    // MARK: Setup
    // =================================================

    func setupViewModel() async {
        await load(
            tag: .all,
            useCache: true
        )
    }

    // =================================================
    // MARK: Tag Selection
    // =================================================

    func selectTag(
        _ tag: DropTopTag
    ) async {
        guard selectedTag != tag else {
            return
        }

        selectedTag = tag

        await load(
            tag: tag,
            useCache: true
        )
    }

    // =================================================
    // MARK: Initial / Cached Page
    // =================================================

    private func load(
        tag: DropTopTag,
        useCache: Bool
    ) async {
        let requestID = UUID()
        currentRequestID = requestID

        currentPaginationTask?.cancel()
        currentPaginationTask = nil

        paginationError = nil

        // -------------------------------------------------
        // Сначала проверяем кэш выбранного тега.
        // -------------------------------------------------

        if useCache,
           let cachedPage = await dropListDataSource
            .cachedDropTopPage(for: tag) {

            guard requestID == currentRequestID else {
                return
            }

            viewState = .contentList(cachedPage)
            displayedTag = tag
            return
        }

        // -------------------------------------------------
        // Кэша нет — загружаем первую страницу.
        // -------------------------------------------------

        viewState = .loading

        do {
            let page = try await dropListDataSource
                .fetchDropTopPage(for: tag)

            guard requestID == currentRequestID else {
                return
            }

            viewState = .contentList(page)
            displayedTag = tag

        } catch {
            guard requestID == currentRequestID else {
                return
            }

            let userError = dropListDataSource.handleError(error)

            viewState = .error(userError)
        }
    }

    // =================================================
    // MARK: Retry
    // =================================================

    func retry() async {
        await load(
            tag: selectedTag,
            useCache: false
        )
    }

    // =================================================
    // MARK: Pagination
    // =================================================

    func loadNextPage() {
        // Пагинация доступна только при отображении списка.
        guard case .contentList(let currentPage) = viewState else {
            return
        }

        guard currentPage.hasMore else {
            return
        }

        // Не запускаем несколько задач одновременно.
        guard currentPaginationTask == nil else {
            return
        }

        paginationError = nil

        let requestID = UUID()
        let requestedTag = selectedTag

        currentRequestID = requestID

        currentPaginationTask = Task { @MainActor in
            defer {
                // Старая задача не должна обнулить ссылку
                // на более новую задачу пагинации.
                if requestID == currentRequestID {
                    currentPaginationTask = nil
                }
            }

            do {
                let result = try await dropListDataSource
                    .loadNextDropTopPageIfNeeded(
                        for: requestedTag
                    )

                guard !Task.isCancelled else {
                    return
                }

                guard requestID == currentRequestID else {
                    return
                }

                guard requestedTag == selectedTag else {
                    return
                }

                guard case .contentList(let latestPage) = viewState else {
                    return
                }

                switch result {
                case .loaded(let page):
                    viewState = .contentList(page)

                case .noMore:
                    let cachedPage = await dropListDataSource
                        .cachedDropTopPage(for: requestedTag)
                        ?? latestPage

                    guard requestID == currentRequestID else {
                        return
                    }

                    viewState = .contentList(cachedPage)

                case .invalidState:
                    viewState = .contentList(latestPage)
                }

            } catch {
                guard !Task.isCancelled else {
                    return
                }

                guard requestID == currentRequestID else {
                    return
                }

                guard requestedTag == selectedTag else {
                    return
                }

                guard case .contentList = viewState else {
                    return
                }

                let userError = dropListDataSource.handleError(error)

                // Список остаётся на экране.
                // Ошибка показывается отдельно в footer.
                paginationError = userError

                print("❌ DropTop pagination error: \(userError)")
            }
        }
    }

    // =================================================
    // MARK: Select Playlist
    // =================================================

    func didSelectPlaylist(
        _ item: DropTopItem
    ) {
        // Навигация выполняется в DropTopContentView.
    }

    // =================================================
    // MARK: Deinit
    // =================================================

    deinit {
        currentPaginationTask?.cancel()
        print("deinit DropTopViewModel")
    }
}











// no case tagError


//import SwiftUI
//import Foundation
//
//// =================================================
//// MARK: - CONTENT STATE
//// =================================================
//
//enum DropTopContentState {
//    case loading
//    case contentList(DropTopPage)
//
//    // Ошибка первоначальной загрузки экрана.
//    case error(String)
//
//    // Ошибка первой загрузки конкретного тега.
//    case tagError(
//        tag: DropTopTag,
//        message: String
//    )
//}
//
//// =================================================
//// MARK: - STATE HELPERS
//// =================================================
//
//extension DropTopContentState {
//
//    var isError: Bool {
//        switch self {
//        case .error, .tagError:
//            return true
//
//        case .loading, .contentList:
//            return false
//        }
//    }
//}
//
//
//
//
//
//// =================================================
//// MARK: - VIEW MODEL
//// =================================================
//
//@MainActor
//final class DropTopViewModel: ObservableObject {
//
//    // =================================================
//    // MARK: Published
//    // =================================================
//
//    @Published private(set) var viewState: DropTopContentState = .loading
//    @Published private(set) var selectedTag: DropTopTag = .all
//    @Published private(set) var displayedTag: DropTopTag?
//    @Published private(set) var paginationError: String?
//
//    // =================================================
//    // MARK: Dependencies
//    // =================================================
//
//    private let dropListDataSource: DropListDataSource
//
//    // =================================================
//    // MARK: Request Control
//    // =================================================
//
//    private var currentRequestID = UUID()
//    private var currentPaginationTask: Task<Void, Never>?
//
//    // =================================================
//    // MARK: Init
//    // =================================================
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // =================================================
//    // MARK: Setup
//    // =================================================
//
//    func setupViewModel() async {
//        await load(
//            tag: .all,
//            useCache: true,
//            showFullScreenError: true
//        )
//    }
//
//    // =================================================
//    // MARK: Tag Selection
//    // =================================================
//
//    func selectTag(
//        _ tag: DropTopTag
//    ) async {
//        guard selectedTag != tag else {
//            return
//        }
//        
//        selectedTag = tag
//
//        await load(
//            tag: tag,
//            useCache: true,
//            showFullScreenError: false
//        )
//    }
//
//    // =================================================
//    // MARK: Initial / Cached Page
//    // =================================================
//
//    private func load(
//        tag: DropTopTag,
//        useCache: Bool,
//        showFullScreenError: Bool
//    ) async {
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        currentPaginationTask?.cancel()
//        currentPaginationTask = nil
//
//        paginationError = nil
//
//        // -------------------------------------------------
//        // Сначала проверяем кэш выбранного тега.
//        // -------------------------------------------------
//
//        if useCache,
//           let cachedPage = await dropListDataSource
//            .cachedDropTopPage(for: tag) {
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(cachedPage)
//            displayedTag = tag
//
//            return
//        }
//
//        // -------------------------------------------------
//        // Кэша нет — загружаем первую страницу.
//        // -------------------------------------------------
//
//        viewState = .loading
//
//        do {
//            let page = try await dropListDataSource
//                .fetchDropTopPage(for: tag)
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(page)
//            displayedTag = tag
//
//        } catch {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            let userError = dropListDataSource.handleError(error)
//
//            if showFullScreenError {
//                // Первоначальная загрузка экрана.
//                viewState = .error(userError)
//            } else {
//                // Ошибка относится только к выбранному тегу.
//                viewState = .tagError(
//                    tag: tag,
//                    message: userError
//                )
//            }
//        }
//    }
//
//    // =================================================
//    // MARK: Retry — Initial Screen
//    // =================================================
//
//    func retry() async {
//
//        await load(
//            tag: selectedTag,
//            useCache: false,
//            showFullScreenError: true
//        )
//    }
//
//    // =================================================
//    // MARK: Retry — Selected Tag
//    // =================================================
//
//    // заяем мы вызываем сброс currentRequestID ... (это же есть в retry() + selectTag) если он есть в load
//    func retrySelectedTag() async {
//
//        // Повторяем запрос только для выбранного тега.
//        // Кэш остальных тегов не сбрасываем.
//        await load(
//            tag: selectedTag,
//            useCache: false,
//            showFullScreenError: false
//        )
//    }
//
//    // =================================================
//    // MARK: Pagination
//    // =================================================
//
//    func loadNextPage() {
//        guard case .contentList(let currentPage) = viewState else {
//            return
//        }
//
//        guard currentPage.hasMore else {
//            return
//        }
//
//        // Не запускаем несколько задач пагинации одновременно.
//        guard currentPaginationTask == nil else {
//            return
//        }
//
//        paginationError = nil
//
//        let requestID = UUID()
//        let requestedTag = selectedTag
//
//        currentRequestID = requestID
//
//        currentPaginationTask = Task { @MainActor in
//            defer {
//                // Старая задача не должна обнулить ссылку
//                // на более новую задачу пагинации.
//                if requestID == currentRequestID {
//                    currentPaginationTask = nil
//                }
//            }
//
//            do {
//                let result = try await dropListDataSource
//                    .loadNextDropTopPageIfNeeded(
//                        for: requestedTag
//                    )
//
//                guard !Task.isCancelled else {
//                    return
//                }
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard requestedTag == selectedTag else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                switch result {
//
//                case .loaded(let page):
//                    viewState = .contentList(page)
//
//                case .noMore:
//                    let cachedPage = await dropListDataSource
//                        .cachedDropTopPage(for: requestedTag)
//                        ?? latestPage
//
//                    guard requestID == currentRequestID else {
//                        return
//                    }
//
//                    viewState = .contentList(cachedPage)
//
//                case .invalidState:
//                    viewState = .contentList(latestPage)
//                }
//
//            } catch {
//                guard !Task.isCancelled else {
//                    return
//                }
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard requestedTag == selectedTag else {
//                    return
//                }
//
//                guard case .contentList = viewState else {
//                    return
//                }
//
//                let userError = dropListDataSource.handleError(error)
//
//                // Сохраняем список и показываем ошибку в footer.
//                paginationError = userError
//
//                print("❌ DropTop pagination error: \(userError)")
//            }
//        }
//    }
//
//    // =================================================
//    // MARK: Select Playlist
//    // =================================================
//
//    func didSelectPlaylist(
//        _ item: DropTopItem
//    ) {
//        // Навигация выполняется в DropTopContentView.
//    }
//
//    // =================================================
//    // MARK: Deinit
//    // =================================================
//
//    deinit {
//        currentPaginationTask?.cancel()
//        print("deinit DropTopViewModel")
//    }
//}
//
//
//
//


















// Убрать дублирующие операции из selectTag(), retry() и retrySelectedTag(), оставив их в load().

//        currentRequestID = UUID()
//
//        currentPaginationTask?.cancel()
//        currentPaginationTask = nil
//
//        paginationError = nil



// MARK: - before .tagError

//import SwiftUI
//
//// =========================================================
//// MARK: - CONTENT STATE
//// =========================================================
//
//enum DropTopContentState {
//    case loading
//    case contentList(DropTopPage)
//    case error(String)
//}
//
//extension DropTopContentState {
//
//    var isError: Bool {
//        if case .error = self {
//            return true
//        }
//
//        return false
//    }
//}
//
//// =========================================================
//// MARK: - VIEW MODEL
//// =========================================================
//
//@MainActor
//final class DropTopViewModel: ObservableObject {
//
//    // =====================================================
//    // MARK: Published
//    // =====================================================
//
//    @Published private(set) var viewState: DropTopContentState = .loading
//
//    @Published private(set) var selectedTag: DropTopTag = .all
//
//    // Тег, данные которого сейчас отображаются в списке.
//    // Используется View для восстановления позиции скролла.
//    @Published private(set) var displayedTag: DropTopTag?
//
//    // =====================================================
//    // MARK: Dependencies
//    // =====================================================
//
//    private let dropListDataSource: DropListDataSource
//
//    // =====================================================
//    // MARK: Request Control
//    // =====================================================
//
//    private var currentRequestID = UUID()
//
//    private var currentPaginationTask: Task<Void, Never>?
//
//    // =====================================================
//    // MARK: Init
//    // =====================================================
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // =====================================================
//    // MARK: Setup
//    // =====================================================
//
//    func setupViewModel() async {
//        await load(tag: .all)
//    }
//
//    // =====================================================
//    // MARK: Tag Selection
//    // =====================================================
//
//    func selectTag(
//        _ tag: DropTopTag
//    ) async {
//        guard selectedTag != tag else {
//            return
//        }
//
//        currentRequestID = UUID()
//        currentPaginationTask?.cancel()
//
//        selectedTag = tag
//
//        await load(tag: tag)
//    }
//
//    // =====================================================
//    // MARK: Initial / Cached Page
//    // =====================================================
//
//    private func load(
//        tag: DropTopTag
//    ) async {
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        // -------------------------------------------------
//        // Сначала проверяем кеш.
//        // -------------------------------------------------
//
//        if let cachedPage = await dropListDataSource
//            .cachedDropTopPage(for: tag) {
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(cachedPage)
//            displayedTag = tag
//
//            return
//        }
//
//        // -------------------------------------------------
//        // Кеша нет — показываем загрузку.
//        // -------------------------------------------------
//
//        viewState = .loading
//
//        do {
//            let page = try await dropListDataSource
//                .fetchDropTopPage(for: tag)
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(page)
//            displayedTag = tag
//
//        } catch {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            let userError = dropListDataSource.handleError(error)
//
//            viewState = .error(userError)
//        }
//    }
//
//    // =====================================================
//    // MARK: Pagination
//    // =====================================================
//
//    func loadNextPage() {
//        guard case .contentList(let currentPage) = viewState else {
//            return
//        }
//
//        guard currentPage.hasMore else {
//            return
//        }
//
//        currentPaginationTask?.cancel()
//
//        let requestID = UUID()
//        let requestedTag = selectedTag
//
//        currentRequestID = requestID
//
//        viewState = .contentList(
//            DropTopPage(
//                items: currentPage.items,
//                lastDocumentSnapshot:
//                    currentPage.lastDocumentSnapshot,
//                hasMore: true
//            )
//        )
//
//        currentPaginationTask = Task { @MainActor in
//            do {
//                let result = try await dropListDataSource
//                    .loadNextDropTopPageIfNeeded(
//                        for: requestedTag
//                    )
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                switch result {
//
//                case .loaded(let page):
//                    viewState = .contentList(page)
//
//                case .noMore:
//                    let cachedPage = await dropListDataSource
//                        .cachedDropTopPage(for: requestedTag)
//                        ?? latestPage
//
//                    viewState = .contentList(cachedPage)
//
//                case .invalidState:
//                    viewState = .contentList(latestPage)
//                }
//
//            } catch {
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                let userError = dropListDataSource.handleError(error)
//
//                viewState = .contentList(
//                    DropTopPage(
//                        items: latestPage.items,
//                        lastDocumentSnapshot:
//                            latestPage.lastDocumentSnapshot,
//                        hasMore: latestPage.hasMore
//                    )
//                )
//
//                print(
//                    "❌ DropTop pagination error: \(userError)"
//                )
//            }
//        }
//    }
//
//    // =====================================================
//    // MARK: Retry
//    // =====================================================
//
//    func retry() async {
//        currentRequestID = UUID()
//        currentPaginationTask?.cancel()
//
//        viewState = .loading
//
//        await dropListDataSource.resetDropTopCache()
//
//        await load(tag: selectedTag)
//    }
//
//    // =====================================================
//    // MARK: Select Playlist
//    // =====================================================
//
//    func didSelectPlaylist(
//        _ item: DropTopItem
//    ) {
//        // Навигация выполняется в DropTopContentView.
//        // ViewModel хранит состояние данных экрана.
//    }
//
//    // =====================================================
//    // MARK: Deinit
//    // =====================================================
//
//    deinit {
//        currentPaginationTask?.cancel()
//        print("deinit DropTopViewModel")
//    }
//}


// MARK: - before savedScrollPositions


//import SwiftUI
//
//
//enum DropTopContentState {
//    case loading
//    case contentList(DropTopPage)
//    case error(String)
//}
//
//extension DropTopContentState {
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
//final class DropTopViewModel: ObservableObject {
//
//    // =========================================================
//    // MARK: Published
//    // =========================================================
//
//    @Published private(set) var viewState: DropTopContentState = .loading
//    @Published private(set) var selectedTag: DropTopTag = .all
//
//    // =========================================================
//    // MARK: Dependencies
//    // =========================================================
//
//    private let dropListDataSource: DropListDataSource
//
//    // =========================================================
//    // MARK: Request control
//    // =========================================================
//
//    private var currentRequestID = UUID()
//    private var currentPaginationTask: Task<Void, Never>?
//
//    // =========================================================
//    // MARK: Init
//    // =========================================================
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // =========================================================
//    // MARK: Setup
//    // =========================================================
//
//    func setupViewModel() async {
//        await load(tag: .all)
//    }
//
//    // =========================================================
//    // MARK: Tag selection
//    // =========================================================
//
//    func selectTag(_ tag: DropTopTag) async {
//        guard selectedTag != tag else {
//            return
//        }
//
//        currentRequestID = UUID()
//        currentPaginationTask?.cancel()
//
//        selectedTag = tag
//
//        await load(tag: tag)
//    }
//
//    // =========================================================
//    // MARK: Initial / cached page
//    // =========================================================
//
//    private func load(tag: DropTopTag) async {
////        viewState = .loading
//
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        // -----------------------------------------------------
//        // Сначала пытаемся получить данные из cache.
//        // -----------------------------------------------------
//
//        if let cachedPage = await dropListDataSource.cachedDropTopPage(
//            for: tag
//        ) {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(cachedPage)
//            return
//        }
//
//        // -----------------------------------------------------
//        // Cache отсутствует → идём в Firestore.
//        // -----------------------------------------------------
//
//        viewState = .loading
//        
//        do {
//            let page = try await dropListDataSource.fetchDropTopPage(
//                for: tag
//            )
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(page)
//
//        } catch {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            let userError = dropListDataSource.handleError(error)
//
//            viewState = .error(userError)
//        }
//    }
//
//    // =========================================================
//    // MARK: Pagination
//    // =========================================================
//
//    func loadNextPage() {
//        guard case .contentList(let currentPage) = viewState else {
//            return
//        }
//
//        guard currentPage.hasMore else {
//            return
//        }
//
//        currentPaginationTask?.cancel()
//
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        viewState = .contentList(
//            DropTopPage(
//                items: currentPage.items,
//                lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
//                hasMore: true
//            )
//        )
//
//        currentPaginationTask = Task { @MainActor in
//
//            do {
//                let result =
//                    try await dropListDataSource
//                        .loadNextDropTopPageIfNeeded(
//                            for: selectedTag
//                        )
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                switch result {
//
//                case .loaded(let page):
//                    viewState = .contentList(page)
//
//                case .noMore:
//                    let cached =
//                        await dropListDataSource
//                            .cachedDropTopPage(
//                                for: selectedTag
//                            )
//                        ?? latestPage
//
//                    viewState = .contentList(cached)
//
//                case .invalidState:
//                    viewState = .contentList(latestPage)
//                }
//
//            } catch {
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                let userError = dropListDataSource.handleError(error)
//
//                viewState = .contentList(
//                    DropTopPage(
//                        items: latestPage.items,
//                        lastDocumentSnapshot: latestPage.lastDocumentSnapshot,
//                        hasMore: latestPage.hasMore
//                    )
//                )
//
//                print(
//                    "❌ DropTop pagination error: \(userError)"
//                )
//            }
//        }
//    }
//
//    // =========================================================
//    // MARK: Retry
//    // =========================================================
//
//    func retry() async {
//        currentRequestID = UUID()
//        currentPaginationTask?.cancel()
//
//        viewState = .loading
//
//        await dropListDataSource.resetDropTopCache()
//
//        await load(tag: selectedTag)
//    }
//
//    // =========================================================
//    // MARK: Select playlist
//    // =========================================================
//
//    func didSelectPlaylist(_ item: DropTopItem) {
//        // Навигация выполняется в DropTopContentView.
//        // ViewModel только хранит данные экрана.
//    }
//
//    deinit {
//        currentPaginationTask?.cancel()
//        print("deinit DropTopViewModel")
//    }
//}
