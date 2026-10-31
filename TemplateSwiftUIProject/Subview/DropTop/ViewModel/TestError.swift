//
//  Untitled.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 31.10.2026.
//




//
// MARK: - ViewModel


//#if DEBUG
//import Foundation
//
//// =================================================
//// MARK: - DEBUG FAILURE
//// =================================================
//
//enum DropTopDebugFailure {
//    case initialLoad
//    case tagLoad(DropTopTag)
//    case pagination(DropTopTag)
//}
//
//// =================================================
//// MARK: - DEBUG FAILURE CONTROLLER
//// =================================================
//
//actor DropTopDebugFailureController {
//
//    static let shared = DropTopDebugFailureController()
//
//    enum Operation {
//        case initialLoad
//        case tagLoad
//        case pagination
//    }
//
//    private var failure: DropTopDebugFailure?
//
//    private init() {}
//
//    func set(_ failure: DropTopDebugFailure?) {
//        self.failure = failure
//    }
//
//    func throwIfNeeded(
//        for operation: Operation,
//        tag: DropTopTag
//    ) throws {
//        guard let failure else {
//            return
//        }
//
//        let shouldFail: Bool
//
//        switch (failure, operation) {
//        case (.initialLoad, .initialLoad):
//            shouldFail = true
//
//        case (.tagLoad(let failedTag), .tagLoad):
//            shouldFail = failedTag == tag
//
//        case (.pagination(let failedTag), .pagination):
//            shouldFail = failedTag == tag
//
//        default:
//            shouldFail = false
//        }
//
//        guard shouldFail else {
//            return
//        }
//
//        // Искусственная ошибка срабатывает только один раз.
//        self.failure = nil
//
//        throw NSError(
//            domain: "DropTopDebugFailure",
//            code: -1,
//            userInfo: [
//                NSLocalizedDescriptionKey:
//                    "DEBUG: искусственная ошибка DropTop."
//            ]
//        )
//    }
//}
//#endif
//
//// =================================================
//// MARK: - FETCH CONTEXT
//// =================================================
//
//enum DropTopFetchContext {
//    case initialLoad
//    case selectedTag
//}
//

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
//    case error(String)
//}
//
//// =================================================
//// MARK: - STATE HELPERS
//// =================================================
//
//extension DropTopContentState {
//    var isError: Bool {
//        if case .error = self {
//            return true
//        }
//
//        return false
//    }
//}
//
//// =================================================
//// MARK: - VIEW MODEL
//// =================================================
//
//
//import SwiftUI
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
//            context: .initialLoad,
//            useCache: true
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
//            context: .selectedTag,
//            useCache: true
//        )
//    }
//
//    // =================================================
//    // MARK: Loading
//    // =================================================
//
//    private func load(
//        tag: DropTopTag,
//        context: DropTopFetchContext,
//        useCache: Bool
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
//            return
//        }
//
//        guard requestID == currentRequestID else {
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
//                .fetchDropTopPage(
//                    for: tag,
//                    context: context
//                )
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
//    // =================================================
//    // MARK: Retry
//    // =================================================
//
//    func retry() async {
//        let context: DropTopFetchContext =
//            selectedTag == .all
//            ? .initialLoad
//            : .selectedTag
//
//        await load(
//            tag: selectedTag,
//            context: context,
//            useCache: false
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
//        // Не запускаем несколько задач одновременно.
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
//                // Список остаётся на экране.
//                // Ошибка показывается отдельно в footer.
//                paginationError = userError
//
//                print("❌ DropTop pagination error: \(userError)")
//            }
//        }
//    }
//
//    // =================================================
//    // MARK: DEBUG — Reset Cache
//    // =================================================
//
//    #if DEBUG
//    func resetCacheForDebugTest() async {
//        await dropListDataSource.resetDropTopCache()
//    }
//    #endif
//
//    // =================================================
//    // MARK: Playlist Selection
//    // =================================================
//
//    func didSelectPlaylist(
//        _ item: DropTopItem
//    ) {
//        // Навигация остаётся в существующем слое Coordinator.
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









// MARK: - View
//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//
//    // =================================================
//    // MARK: - DEBUG
//    // =================================================
//
//    #if DEBUG
//    @State private var didInjectPaginationFailure = false
//    #endif
//
//    // =================================================
//    // MARK: - Scroll Position
//    // =================================================
//
//    // SwiftUI автоматически обновляет ID при прокрутке.
//    @State private var currentScrollID: String?
//
//    // Сохраняем отдельную позицию для каждого тега.
//    @State private var savedScrollPositions: [DropTopTag: String] = [:]
//
//    // =================================================
//    // MARK: - Body
//    // =================================================
//
//    var body: some View {
//        VStack(spacing: 0) {
//            tagSelector
//
//            Divider()
//
//            content
//                .frame(
//                    maxWidth: .infinity,
//                    maxHeight: .infinity
//                )
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                #if DEBUG
//                await viewModel.resetCacheForDebugTest()
//
//                await DropTopDebugFailureController.shared
//                    .set(.initialLoad)
//                #endif
//
//                await viewModel.setupViewModel()
//            }
//        }
//        .onChange(of: viewModel.selectedTag) { oldTag, _ in
//            saveScrollPosition(for: oldTag)
//            currentScrollID = nil
//        }
//        .onChange(of: viewModel.displayedTag) { _, newTag in
//            guard let tag = newTag else {
//                return
//            }
//
//            guard tag == viewModel.selectedTag else {
//                return
//            }
//
//            restoreScrollPosition(for: tag)
//        }
//    }
//}
//
//// =================================================
//// MARK: - TAG SELECTOR
//// =================================================
//
//private extension DropTopContentView {
//
//    var tagSelector: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//                ForEach(DropTopTag.allCases) { tag in
//                    Button {
//                        Task {
//                            #if DEBUG
//                            if tag == .topYear,
//                               tag != viewModel.selectedTag {
//
//                                await viewModel.resetCacheForDebugTest()
//
//                                await DropTopDebugFailureController.shared
//                                    .set(.tagLoad(.topYear))
//                            }
//                            #endif
//
//                            await viewModel.selectTag(tag)
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(.subheadline.weight(.medium))
//                            .foregroundColor(
//                                viewModel.selectedTag == tag
//                                    ? .white
//                                    : .primary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background {
//                                Capsule()
//                                    .fill(
//                                        viewModel.selectedTag == tag
//                                            ? Color.accentColor
//                                            : Color.secondary.opacity(0.12)
//                                    )
//                            }
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//        }
//    }
//}
//
//// =================================================
//// MARK: - CONTENT
//// =================================================
//
//private extension DropTopContentView {
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.viewState {
//
//        case .loading:
//            ProgressView()
//
//        case .error(let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//
//        case .contentList(let page):
//            dropTopList(page)
//        }
//    }
//}
//
//// =================================================
//// MARK: - LIST
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopList(
//        _ page: DropTopPage
//    ) -> some View {
//        ScrollView {
//            LazyVStack(spacing: 0) {
//                ForEach(page.items) { item in
//                    dropTopRow(item)
//                        .onAppear {
//                            guard item.id == page.items.last?.id else {
//                                return
//                            }
//
//                            handlePagination()
//                        }
//                }
//
//                if page.hasMore {
//                    paginationFooter
//                }
//            }
//            .scrollTargetLayout()
//        }
//        .scrollPosition(
//            id: $currentScrollID,
//            anchor: .top
//        )
//        .refreshable {
//            await viewModel.retry()
//        }
//    }
//
//    // -------------------------------------------------
//    // Запуск пагинации.
//    // -------------------------------------------------
//
//    func handlePagination() {
//        #if DEBUG
//        if viewModel.selectedTag == .topQuarter,
//           !didInjectPaginationFailure {
//
//            didInjectPaginationFailure = true
//
//            Task {
//                await DropTopDebugFailureController.shared
//                    .set(.pagination(.topQuarter))
//
//                viewModel.loadNextPage()
//            }
//
//            return
//        }
//        #endif
//
//        viewModel.loadNextPage()
//    }
//
//    // -------------------------------------------------
//    // Footer пагинации.
//    // При ошибке показываем Retry вместо индикатора,
//    // чтобы не провоцировать бесконечные запросы.
//    // -------------------------------------------------
//
//    @ViewBuilder
//    var paginationFooter: some View {
//        if viewModel.paginationError != nil {
//            VStack(spacing: 8) {
//                Text("Что-то пошло не так!")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//
//                Button {
//                    viewModel.loadNextPage()
//                } label: {
//                    Label(
//                        "Загрузить ещё",
//                        systemImage: "arrow.clockwise"
//                    )
//                    .font(.subheadline.weight(.medium))
//                }
//                .buttonStyle(.plain)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 20)
//
//        } else {
//            ProgressView()
//                .padding(.vertical, 20)
//        }
//    }
//}
//
//// =================================================
//// MARK: - SCROLL POSITION
//// =================================================
//
//private extension DropTopContentView {
//
//    func saveScrollPosition(
//        for tag: DropTopTag
//    ) {
//        guard let currentScrollID else {
//            return
//        }
//
//        savedScrollPositions[tag] = currentScrollID
//    }
//
//    func restoreScrollPosition(
//        for tag: DropTopTag
//    ) {
//        guard case .contentList(let page) = viewModel.viewState else {
//            return
//        }
//
//        guard
//            let savedID = savedScrollPositions[tag],
//            page.items.contains(where: { $0.id == savedID })
//        else {
//            // Нет сохранённой позиции или элемента в текущей странице.
//            currentScrollID = nil
//            return
//        }
//
//        // Ждём обновления списка перед восстановлением позиции.
//        Task { @MainActor in
//            await Task.yield()
//            currentScrollID = savedID
//        }
//    }
//}
//
//// =================================================
//// MARK: - ROW
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//        Button {
//            openPlaylist(item)
//        } label: {
//            HStack(spacing: 12) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(
//                        width: 60,
//                        height: 60
//                    ),
//                    context: "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(cornerRadius: 8)
//                )
//
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                        .lineLimit(2)
//
//                    Text(item.description)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .contentShape(Rectangle())
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// =================================================
//// MARK: - NAVIGATION
//// =================================================
//
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
//        // droplistCoordinator.navigate(
//        //     to: .topDropDetails(
//        //         playlistId: item.id,
//        //         title: item.title,
//        //         imageURL: item.imageURL
//        //     )
//        // )
//    }
//}

//
// MARK: - DropListDataSource

/// =================================================
//// MARK: - DropTop — Cache
//// =================================================
//
//extension DropListDataSource {
//
//    func cachedDropTopPage(
//        for tag: DropTopTag
//    ) async -> DropTopPage? {
//        await dropTopPagesCache.get(tag.cacheKey)
//    }
//}
//
//// =================================================
//// MARK: - DropTop — Initial Fetch
//// =================================================
//
//extension DropListDataSource {
//
//    func fetchDropTopPage(
//        for tag: DropTopTag,
//        context: DropTopFetchContext
//    ) async throws -> DropTopPage {
//
//        #if DEBUG
//        let operation: DropTopDebugFailureController.Operation
//
//        switch context {
//        case .initialLoad:
//            operation = .initialLoad
//
//        case .selectedTag:
//            operation = .tagLoad
//        }
//
//        try await DropTopDebugFailureController.shared
//            .throwIfNeeded(
//                for: operation,
//                tag: tag
//            )
//        #endif
//
//        let page = try await firestoreService
//            .fetchInitialDropTopPage(
//                for: tag,
//                pageSize: dropTopPageSize
//            )
//
//        await dropTopPagesCache.set(
//            tag.cacheKey,
//            page: page
//        )
//
//        return page
//    }
//}
//
//// =================================================
//// MARK: - DropTop — Pagination
//// =================================================
//
//extension DropListDataSource {
//
//    func loadNextDropTopPageIfNeeded(
//        for tag: DropTopTag
//    ) async throws -> NextDropTopPageResult {
//        let cacheKey = tag.cacheKey
//
//        // Получаем текущую страницу из кэша.
//        guard let currentPage = await dropTopPagesCache.get(cacheKey) else {
//            return .invalidState
//        }
//
//        // Если данные закончились, запрос не нужен.
//        guard currentPage.hasMore else {
//            return .noMore
//        }
//
//        // Не допускаем параллельную загрузку одного тега.
//        let canStart = await dropTopPagesCache.beginLoading(cacheKey)
//
//        guard canStart else {
//            return .invalidState
//        }
//
//        // Для следующей страницы нужен последний snapshot.
//        guard let lastSnapshot = currentPage.lastDocumentSnapshot else {
//            await dropTopPagesCache.endLoading(cacheKey)
//            return .invalidState
//        }
//
//        do {
//            #if DEBUG
//            // Искусственная ошибка срабатывает один раз.
//            try await DropTopDebugFailureController.shared
//                .throwIfNeeded(
//                    for: .pagination,
//                    tag: tag
//                )
//            #endif
//
//            // Загружаем следующую страницу из Firestore.
//            let nextPage = try await firestoreService
//                .fetchNextDropTopPage(
//                    for: tag,
//                    after: lastSnapshot,
//                    pageSize: dropTopPageSize
//                )
//
//            // Пустая страница означает конец списка.
//            if nextPage.items.isEmpty {
//                let finishedPage = DropTopPage(
//                    items: currentPage.items,
//                    lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
//                    hasMore: false
//                )
//
//                await dropTopPagesCache.set(
//                    cacheKey,
//                    page: finishedPage
//                )
//
//                await dropTopPagesCache.endLoading(cacheKey)
//
//                return .noMore
//            }
//
//            // Объединяем уже загруженные элементы с новыми.
//            let mergedPage = DropTopPage(
//                items: currentPage.items + nextPage.items,
//                lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//                hasMore: nextPage.hasMore
//            )
//
//            await dropTopPagesCache.set(
//                cacheKey,
//                page: mergedPage
//            )
//
//            await dropTopPagesCache.endLoading(cacheKey)
//
//            return .loaded(page: mergedPage)
//
//        } catch {
//            // Освобождаем состояние даже при ошибке.
//            await dropTopPagesCache.endLoading(cacheKey)
//            throw error
//        }
//    }
//}
//
//// =================================================
//// MARK: - DropTop — Reset Cache
//// =================================================
//
//extension DropListDataSource {
//
//    func resetDropTopCache() async {
//        await dropTopPagesCache.reset()
//    }
//}

