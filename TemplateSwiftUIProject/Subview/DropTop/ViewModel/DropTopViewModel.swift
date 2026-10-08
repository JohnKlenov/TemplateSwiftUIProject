//
//  DropTopViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//

import SwiftUI


enum DropTopContentState {
    case loading
    case contentList(DropTopPage)
    case error(String)
}

extension DropTopContentState {
    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }
}

@MainActor
final class DropTopViewModel: ObservableObject {

    // =========================================================
    // MARK: Published
    // =========================================================

    @Published private(set) var viewState: DropTopContentState = .loading
    @Published private(set) var selectedTag: DropTopTag = .all

    // =========================================================
    // MARK: Dependencies
    // =========================================================

    private let dropListDataSource: DropListDataSource

    // =========================================================
    // MARK: Request control
    // =========================================================

    private var currentRequestID = UUID()
    private var currentPaginationTask: Task<Void, Never>?

    // =========================================================
    // MARK: Init
    // =========================================================

    init(
        dropListDataSource: DropListDataSource
    ) {
        self.dropListDataSource = dropListDataSource
    }

    // =========================================================
    // MARK: Setup
    // =========================================================

    func setupViewModel() async {
        await load(tag: .all)
    }

    // =========================================================
    // MARK: Tag selection
    // =========================================================

    func selectTag(_ tag: DropTopTag) async {
        guard selectedTag != tag else {
            return
        }

        currentRequestID = UUID()
        currentPaginationTask?.cancel()

        selectedTag = tag

        await load(tag: tag)
    }

    // =========================================================
    // MARK: Initial / cached page
    // =========================================================

    private func load(tag: DropTopTag) async {
//        viewState = .loading

        let requestID = UUID()
        currentRequestID = requestID

        // -----------------------------------------------------
        // Сначала пытаемся получить данные из cache.
        // -----------------------------------------------------

        if let cachedPage = await dropListDataSource.cachedDropTopPage(
            for: tag
        ) {
            guard requestID == currentRequestID else {
                return
            }

            viewState = .contentList(cachedPage)
            return
        }

        // -----------------------------------------------------
        // Cache отсутствует → идём в Firestore.
        // -----------------------------------------------------

        viewState = .loading
        
        do {
            let page = try await dropListDataSource.fetchDropTopPage(
                for: tag
            )

            guard requestID == currentRequestID else {
                return
            }

            viewState = .contentList(page)

        } catch {
            guard requestID == currentRequestID else {
                return
            }

            let userError = dropListDataSource.handleError(error)

            viewState = .error(userError)
        }
    }

    // =========================================================
    // MARK: Pagination
    // =========================================================

    func loadNextPage() {
        guard case .contentList(let currentPage) = viewState else {
            return
        }

        guard currentPage.hasMore else {
            return
        }

        currentPaginationTask?.cancel()

        let requestID = UUID()
        currentRequestID = requestID

        viewState = .contentList(
            DropTopPage(
                items: currentPage.items,
                lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
                hasMore: true
            )
        )

        currentPaginationTask = Task { @MainActor in

            do {
                let result =
                    try await dropListDataSource
                        .loadNextDropTopPageIfNeeded(
                            for: selectedTag
                        )

                guard requestID == currentRequestID else {
                    return
                }

                guard case .contentList(let latestPage) = viewState else {
                    return
                }

                switch result {

                case .loaded(let page):
                    viewState = .contentList(page)

                case .noMore:
                    let cached =
                        await dropListDataSource
                            .cachedDropTopPage(
                                for: selectedTag
                            )
                        ?? latestPage

                    viewState = .contentList(cached)

                case .invalidState:
                    viewState = .contentList(latestPage)
                }

            } catch {

                guard requestID == currentRequestID else {
                    return
                }

                guard case .contentList(let latestPage) = viewState else {
                    return
                }

                let userError = dropListDataSource.handleError(error)

                viewState = .contentList(
                    DropTopPage(
                        items: latestPage.items,
                        lastDocumentSnapshot: latestPage.lastDocumentSnapshot,
                        hasMore: latestPage.hasMore
                    )
                )

                print(
                    "❌ DropTop pagination error: \(userError)"
                )
            }
        }
    }

    // =========================================================
    // MARK: Retry
    // =========================================================

    func retry() async {
        currentRequestID = UUID()
        currentPaginationTask?.cancel()

        viewState = .loading

        await dropListDataSource.resetDropTopCache()

        await load(tag: selectedTag)
    }

    // =========================================================
    // MARK: Select playlist
    // =========================================================

    func didSelectPlaylist(_ item: DropTopItem) {
        // Навигация выполняется в DropTopContentView.
        // ViewModel только хранит данные экрана.
    }

    deinit {
        currentPaginationTask?.cancel()
        print("deinit DropTopViewModel")
    }
}
