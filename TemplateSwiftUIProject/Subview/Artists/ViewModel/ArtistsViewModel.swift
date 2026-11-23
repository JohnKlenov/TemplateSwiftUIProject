//
//  ArtistsViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 23.11.2026.
//

import SwiftUI

@MainActor
final class ArtistsViewModel: ObservableObject {

    // MARK: - State

    enum ViewState: Equatable {

        case loading
        case content([Artist])
        case error(String)
    }

    @Published private(set) var viewState: ViewState = .loading

    // MARK: - Dependencies

    private let dropListDataSource: DropListDataSource

    // MARK: - Init

    init(
        dropListDataSource: DropListDataSource
    ) {
        self.dropListDataSource = dropListDataSource
    }

    // MARK: - Fetch

    func fetchArtists() async {

        viewState = .loading

        do {
            let artists = try await dropListDataSource.fetchArtists()

            viewState = .content(
                artists.sorted {
                    $0.orderIndex < $1.orderIndex
                }
            )

        } catch {
            viewState = .error(
                error.localizedDescription
            )
        }
    }

    // MARK: - Retry

    func retry() async {

        await fetchArtists()
    }
}
