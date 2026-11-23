//
//  ArtistsView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 23.11.2026.
//

import SwiftUI

struct ArtistsView: View {

    // MARK: - ViewModel

    @ObservedObject var viewModel: ArtistsViewModel

    // MARK: - Environment

    @EnvironmentObject private var libraryCoordinator: LibraryCoordinator

    // MARK: - Body

    var body: some View {

        Group {

            switch viewModel.viewState {

            case .loading:
                loadingView

            case .content(let artists):
                contentView(artists)

            case .error(let message):
                errorView(message)
            }
        }
        .navigationTitle("Artists")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .loading = viewModel.viewState {
                await viewModel.fetchArtists()
            }
        }
    }

    // =================================================
    // MARK: - Loading
    // =================================================

    private var loadingView: some View {

        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // =================================================
    // MARK: - Content
    // =================================================

    private func contentView(
        _ artists: [Artist]
    ) -> some View {

        List(artists) { artist in

            Button {
                openArtist(artist)
            } label: {

                artistRow(artist)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // =================================================
    // MARK: - Artist Row
    // =================================================

    private func artistRow(
        _ artist: Artist
    ) -> some View {

        HStack(spacing: 14) {

            artistImage(artist)

            Text(artist.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // =================================================
    // MARK: - Artist Image
    // =================================================

    @ViewBuilder
    private func artistImage(
        _ artist: Artist
    ) -> some View {

        if let imageURL = artist.imageURL {

            AsyncImage(url: imageURL) { phase in

                switch phase {

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .empty, .failure:
                    imagePlaceholder

                @unknown default:
                    imagePlaceholder
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())

        } else {

            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {

        Image(systemName: "music.mic")
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 54, height: 54)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
    }

    // =================================================
    // MARK: - Navigation
    // =================================================

    private func openArtist(
        _ artist: Artist
    ) {

        libraryCoordinator.navigateTo(
            page: .artistDetails(
                tag: artist.tag,
                title: artist.name,
                imageURL: artist.imageURL
            )
        )
    }

    // =================================================
    // MARK: - Error
    // =================================================

    private func errorView(
        _ message: String
    ) -> some View {

        VStack(spacing: 16) {

            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Повторить") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
