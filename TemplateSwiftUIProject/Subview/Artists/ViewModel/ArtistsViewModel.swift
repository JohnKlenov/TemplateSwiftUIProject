//
//  ArtistsViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 23.11.2026.
//


import SwiftUI
import FirebaseFirestore

@MainActor
final class ArtistsViewModel: ObservableObject {

    // MARK: - View State

    enum ViewState: Equatable {
        case loading
        case content([Artist])
        case error(String)
    }

    @Published private(set) var viewState: ViewState = .loading
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var paginationError: String?

    // MARK: - Dependencies

    private let dropListDataSource: DropListDataSource

    // MARK: - Pagination

    private let pageSize = 15

    private var lastDocumentSnapshot: DocumentSnapshot?
    private var hasMore = true

    // MARK: - Initialization

    init(dropListDataSource: DropListDataSource) {
        self.dropListDataSource = dropListDataSource
    }

    // MARK: - Initial Loading

    func fetchArtists() async {
        viewState = .loading
        paginationError = nil
        lastDocumentSnapshot = nil
        hasMore = true

        do {
            let page = try await dropListDataSource.fetchArtistsPage(
                after: nil,
                pageSize: pageSize
            )

            lastDocumentSnapshot = page.lastDocumentSnapshot
            hasMore = page.hasMore

            viewState = .content(page.artists)

        } catch {
            viewState = .error(error.localizedDescription)
        }
    }

    // MARK: - Pagination

    func loadNextPage() async {
        guard
            !isLoadingNextPage,
            hasMore,
            case .content(let currentArtists) = viewState
        else {
            return
        }

        isLoadingNextPage = true
        paginationError = nil

        defer {
            isLoadingNextPage = false
        }

        do {
            let page = try await dropListDataSource.fetchArtistsPage(
                after: lastDocumentSnapshot,
                pageSize: pageSize
            )

            lastDocumentSnapshot = page.lastDocumentSnapshot
            hasMore = page.hasMore

            viewState = .content(
                currentArtists + page.artists
            )

        } catch {
            paginationError = error.localizedDescription
        }
    }

    // MARK: - Retry

    func retry() async {
        await fetchArtists()
    }

    func retryNextPage() async {
        await loadNextPage()
    }
}
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
