//
//  ArtistsViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 23.11.2026.
//


import SwiftUI

// =================================================
// MARK: - Artists View State
// =================================================

enum ArtistsViewState {
    case loading
    case content([Artist])
    case error
}

// =================================================
// MARK: - Artists ViewModel
// =================================================

@MainActor
final class ArtistsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var viewState: ArtistsViewState = .loading

    @Published private(set) var isRefreshing = false

    @Published private(set) var isLoadingNextPage = false

    @Published private(set) var paginationError = false

    // MARK: - Private Properties

    private let dropListDataSource: DropListDataSource

    private var currentRequestID = UUID()

    // MARK: - Initialization

    init(
        dropListDataSource: DropListDataSource
    ) {
        self.dropListDataSource = dropListDataSource
    }

    // MARK: - Initial Loading

    func fetchArtists() async {
        guard case .loading = viewState else {
            return
        }

        let requestID = UUID()
        currentRequestID = requestID

        do {
            let page = try await dropListDataSource.loadInitialArtists()

            guard currentRequestID == requestID else {
                return
            }

            viewState = .content(page.artists)
        } catch {
            guard currentRequestID == requestID else {
                return
            }

            viewState = .error
        }
    }

    // MARK: - Refresh

    func refresh() async {
        guard !isRefreshing else {
            return
        }

        let requestID = UUID()
        currentRequestID = requestID

        isRefreshing = true
        paginationError = false

        defer {
            isRefreshing = false
        }

        do {
            let page = try await dropListDataSource.refreshArtists()

            guard currentRequestID == requestID else {
                return
            }

            viewState = .content(page.artists)
        } catch {
            guard currentRequestID == requestID else {
                return
            }

            // При ошибке обновления сохраняем уже отображаемые данные.
            if case .content = viewState {
                return
            }

            viewState = .error
        }
    }

    // MARK: - Pagination

    func loadNextPageIfNeeded(for artist: Artist) async {
        guard !isLoadingNextPage,
              !isRefreshing,
              !paginationError,
              case .content(let artists) = viewState,
              artists.last?.id == artist.id
        else {
            return
        }

        isLoadingNextPage = true

        defer {
            isLoadingNextPage = false
        }

        do {
            guard let page = try await dropListDataSource.loadNextArtistsPage() else {
                return
            }

            viewState = .content(page.artists)
        } catch {
            paginationError = true
        }
    }

    // MARK: - Retry

    func retry() async {
        paginationError = false

        if case .content = viewState {
            await loadNextPageRetry()
        } else {
            viewState = .loading
            await fetchArtists()
        }
    }

    private func loadNextPageRetry() async {
        guard !isLoadingNextPage else {
            return
        }

        isLoadingNextPage = true
        paginationError = false

        defer {
            isLoadingNextPage = false
        }

        do {
            guard let page = try await dropListDataSource.loadNextArtistsPage() else {
                return
            }

            viewState = .content(page.artists)
        } catch {
            paginationError = true
        }
    }
}

// =================================================
// MARK: - LowerSectionPage Mapping
// =================================================

private extension LowerSectionPage {

    var artists: [Artist] {
        items.map { item in
            Artist(
                id: item.id,
                name: item.title,
                tag: item.tag ?? item.id,
                orderIndex: item.orderIndex ?? 0,
                imageURL: item.coverImageURL
            )
        }
    }
}


// MARK: - before new implementetion artist

//import SwiftUI
//import FirebaseFirestore
//
//@MainActor
//final class ArtistsViewModel: ObservableObject {
//
//    // MARK: - View State
//
//    enum ViewState: Equatable {
//        case loading
//        case content([Artist])
//        case error(String)
//    }
//
//    @Published private(set) var viewState: ViewState = .loading
//    @Published private(set) var isLoadingNextPage = false
//    @Published private(set) var paginationError: String?
//
//    // MARK: - Dependencies
//
//    private let dropListDataSource: DropListDataSource
//
//    // MARK: - Pagination
//
//    private let pageSize = 15
//
//    private var lastDocumentSnapshot: DocumentSnapshot?
//    private var hasMore = true
//
//    // MARK: - Initialization
//
//    init(dropListDataSource: DropListDataSource) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // MARK: - Initial Loading
//
//    func fetchArtists() async {
//        viewState = .loading
//        paginationError = nil
//        lastDocumentSnapshot = nil
//        hasMore = true
//
//        do {
//            let page = try await dropListDataSource.fetchArtistsPage(
//                after: nil,
//                pageSize: pageSize
//            )
//
//            lastDocumentSnapshot = page.lastDocumentSnapshot
//            hasMore = page.hasMore
//
//            viewState = .content(page.artists)
//
//        } catch {
//            viewState = .error(error.localizedDescription)
//        }
//    }
//
//    // MARK: - Pagination
//
//    func loadNextPage() async {
//        guard
//            !isLoadingNextPage,
//            hasMore,
//            case .content(let currentArtists) = viewState
//        else {
//            return
//        }
//
//        isLoadingNextPage = true
//        paginationError = nil
//
//        defer {
//            isLoadingNextPage = false
//        }
//
//        do {
//            let page = try await dropListDataSource.fetchArtistsPage(
//                after: lastDocumentSnapshot,
//                pageSize: pageSize
//            )
//
//            lastDocumentSnapshot = page.lastDocumentSnapshot
//            hasMore = page.hasMore
//
//            viewState = .content(
//                currentArtists + page.artists
//            )
//
//        } catch {
//            paginationError = error.localizedDescription
//        }
//    }
//
//    // MARK: - Retry
//
//    func retry() async {
//        await fetchArtists()
//    }
//
//    func retryNextPage() async {
//        await loadNextPage()
//    }
//}




//import SwiftUI
//
//@MainActor
//final class ArtistsViewModel: ObservableObject {
//
//    // MARK: - State
//
//    enum ViewState: Equatable {
//
//        case loading
//        case content([Artist])
//        case error(String)
//    }
//
//    @Published private(set) var viewState: ViewState = .loading
//
//    // MARK: - Dependencies
//
//    private let dropListDataSource: DropListDataSource
//
//    // MARK: - Init
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // MARK: - Fetch
//
//    func fetchArtists() async {
//
//        viewState = .loading
//
//        do {
//            let artists = try await dropListDataSource.fetchArtists()
//
//            viewState = .content(
//                artists.sorted {
//                    $0.orderIndex < $1.orderIndex
//                }
//            )
//
//        } catch {
//            viewState = .error(
//                error.localizedDescription
//            )
//        }
//    }
//
//    // MARK: - Retry
//
//    func retry() async {
//
//        await fetchArtists()
//    }
//}
