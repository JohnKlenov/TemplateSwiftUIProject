//
//  TracklistContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//

import SwiftUI

enum PlaylistToast: Equatable {
    case success(String)
    case info(String)
    case error(String)
}

struct TracklistContentView: View {
    @ObservedObject var viewModel: TracklistViewModel

    let navigationTitle: String
    let details: [String]
    let imageURL: URL?

    @EnvironmentObject var localization: LocalizationService

    @State private var selectedTrack: LowerItem?
    @State private var playlistToast: PlaylistToast?

    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .loading:
                ProgressView(
                    Localized.Home.loading.localized()
                )

            case .contentList(let tracklist):
                TracklistView(
                    data: tracklist,
                    details: details,
                    imageURL: imageURL,
                    onLoadNextTracks: {
                        Task {
                            await viewModel.loadNextPage()
                        }
                    },
                    onSelectTrack: { item in
                        selectedTrack = item
                    },
                    onAddToPlaylist: { item in
                        Task {
                            await handleAddToPlaylist(item)
                        }
                    },
                    onPlayInYouTubeMusic: { item in
                        // TODO
                    }
                )
            case .error(let error):
                ContentErrorView(error: error) {
                    Task {
                        await viewModel.retry()
                    }
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let playlistToast {
                PlaylistToastView(
                    toast: playlistToast
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
                .transition(
                    .move(edge: .bottom)
                    .combined(with: .opacity)
                )
            }
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: playlistToast
        )
        .onFirstAppear {
            Task {
                await viewModel.setupViewModel()
            }
        }
        .sheet(item: $selectedTrack) { track in
            SafariPlayerView(
                videoId: track.id
            )
            .presentationDetents([
                .medium,
                .large
            ])
        }
    }
}

private extension TracklistContentView {

    func handleAddToPlaylist(
        _ item: LowerItem
    ) async {
        do {
            let result = try await viewModel.addToPlaylist(item)

            switch result {

            case .added:
                showPlaylistToast(
                    .success("Added to Playlist")
                )

            case .alreadyAdded:
                showPlaylistToast(
                    .info("Track already added")
                )
            }

        } catch {
            showPlaylistToast(
                .error("Failed to add track")
            )
        }
    }

    func showPlaylistToast(
        _ toast: PlaylistToast
    ) {
        withAnimation {
            playlistToast = toast
        }

        Task {
            try? await Task.sleep(
                for: .seconds(2)
            )

            await MainActor.run {
                withAnimation {
                    playlistToast = nil
                }
            }
        }
    }
}

import SwiftUI

struct PlaylistToastView: View {

    let toast: PlaylistToast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )

            Text(message)
                .font(
                    .subheadline.weight(.medium)
                )

            Spacer(minLength: 0)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .shadow(
            color: .black.opacity(0.18),
            radius: 12,
            x: 0,
            y: 4
        )
    }

    private var message: String {
        switch toast {
        case .success(let message),
             .info(let message),
             .error(let message):
            return message
        }
    }

    private var iconName: String {
        switch toast {
        case .success:
            return "checkmark.circle.fill"

        case .info:
            return "info.circle.fill"

        case .error:
            return "exclamationmark.circle.fill"
        }
    }
}



//                TracklistView(
//                    data: tracklist,
//                    details: details,
//                    imageURL: imageURL,
//                    onLoadNextTracks: {
//                        Task {
//                            await viewModel.loadNextPage()
//                        }
//                    },
//                    onSelectTrack: { item in
//                            selectedTrack = item
//                    },
//                    onAddToPlaylist: { item in
//                        Task {
//                            await viewModel.addToPlaylist(item)
//                        }
//                    },
//                    onPlayInYouTubeMusic: { item in
//                        // TODO
//                    },
//                    isTrackInPlaylist: { item in
//                        viewModel.isTrackInPlaylist(item)
//                    }
//                )

//                TracklistView(
//                    data: tracklist,
//                    details: details,
//                    imageURL: imageURL,
//                    onLoadNextTracks: {
//                        Task {
//                            await viewModel.loadNextPage()
//                        }
//                    },
//                    onSelectTrack: { item in
//                            selectedTrack = item
//                    },
//                    onAddToPlaylist: { item in
//                        Task {
//                            await viewModel.addToPlaylist(item)
//                        }
//                    },
//                    onPlayInYouTubeMusic: { item in
//                        viewModel.playInYouTubeMusic(item)
//                    }
//                )


// before add let imageURL for case .droplistDetails
//import SwiftUI
//
//struct TracklistContentView: View {
//    @ObservedObject var viewModel: TracklistViewModel
//
//    let navigationTitle: String
//    let details: [String]
//
//    @EnvironmentObject var localization: LocalizationService
//
//    @State private var selectedTrack: LowerItem?
//
//    var body: some View {
//        ZStack {
//            switch viewModel.viewState {
//
//            case .loading:
//                ProgressView(
//                    Localized.Home.loading.localized()
//                )
//
//            case .contentList(let tracklist):
//                TracklistView(
//                    data: tracklist,
//                    details: details,
//                    onLoadNextTracks: {
//                        Task {
//                            await viewModel.loadNextPage()
//                        }
//                    },
//                    onSelectTrack: { item in
//                        if item.isTrack {
//                            selectedTrack = item
//                        }
//                    },
//                    onAddToPlaylist: { item in
//                        Task {
//                            await viewModel.addToPlaylist(item)
//                        }
//                    },
//                    onPlayInYouTubeMusic: { item in
//                        viewModel.playInYouTubeMusic(item)
//                    }
//                )
//
//            case .error(let error):
//                ContentErrorView(error: error) {
//                    Task {
//                        await viewModel.retry()
//                    }
//                }
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle(navigationTitle)
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//        .sheet(item: $selectedTrack) { track in
//            SafariPlayerView(
//                videoId: track.id
//            )
//            .presentationDetents([
//                .medium,
//                .large
//            ])
//        }
//    }
//}

// MARK: - before add PlaylistDetailsView

//import SwiftUI
//
//struct TracklistContentView: View {
//
//    @ObservedObject var viewModel: TracklistViewModel
//    let navigationTitle: String
//
//    @EnvironmentObject var localization: LocalizationService
//
//    @State private var selectedTrack: LowerItem?
//
//    var body: some View {
//
//        ZStack {
//
//            switch viewModel.viewState {
//
//            case .loading:
//                ProgressView(
//                    Localized.Home.loading.localized()
//                )
//
//            case .contentList(let tracklist):
//
//                TracklistView(
//                    data: tracklist,
//
//                    onLoadNextTracks: {
//                        Task {
//                            await viewModel.loadNextPage()
//                        }
//                    },
//
//                    onSelectTrack: { item in
//                        if item.isTrack {
//                            selectedTrack = item
//                        }
//                    },
//
//                    onAddToPlaylist: { item in
//                        Task {
//                            await viewModel.addToPlaylist(item)
//                        }
//                    },
//
//                    onPlayInYouTubeMusic: { item in
//                        viewModel.playInYouTubeMusic(item)
//                    }
//                )
//
//            case .error(let error):
//
//                ContentErrorView(error: error) {
//                    Task {
//                        await viewModel.retry()
//                    }
//                }
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle(navigationTitle)
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//        .sheet(item: $selectedTrack) { track in
//
//            // YouTubePlayerView(videoId: track.id)
//
//            SafariPlayerView(
//                videoId: track.id
//            )
//            .presentationDetents([
//                .medium,
//                .large
//            ])
//        }
//    }
//}

// MARK: - before add 2 action onAddToPlaylist + onPlayInYouTubeMusic

//import SwiftUI
//
//struct TracklistContentView: View {
//
//    @ObservedObject var viewModel: TracklistViewModel
//    let navigationTitle: String
//
//    @EnvironmentObject var localization: LocalizationService
//
//    @State private var selectedTrack: LowerItem?
//
//    var body: some View {
//        ZStack {
//            switch viewModel.viewState {
//
//            case .loading:
//                ProgressView(Localized.Home.loading.localized())
//
//            case .contentList(let tracklist):
//                TracklistView(
//                    data: tracklist,
//                    onLoadNextTracks: {
//                        Task { await viewModel.loadNextPage() }
//                    },
//                    onSelectTrack: { item in
//                        if item.isTrack {
//                            selectedTrack = item
//                        }
//                    }
//                )
//
//            case .error(let error):
//                ContentErrorView(error: error) {
//                    Task { await viewModel.retry() }
//                }
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle(navigationTitle)
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task { await viewModel.setupViewModel() }
//        }
//        .sheet(item: $selectedTrack) { track in
////            YouTubePlayerView(videoId: track.id)
////                .edgesIgnoringSafeArea(.all)
//            SafariPlayerView(videoId: track.id)
//                .presentationDetents([.medium, .large])
//        }
//    }
//}



// MARK: - before add PlayerView

//import SwiftUI
//
//struct TracklistContentView: View {
//
//    @ObservedObject var viewModel: TracklistViewModel
//
//    let navigationTitle: String
//
//    @EnvironmentObject var localization: LocalizationService
//
//    var body: some View {
//        ZStack {
//            switch viewModel.viewState {
//
//            case .loading:
//                ProgressView(
//                    Localized.Home.loading.localized()
//                )
//
//            case .contentList(let tracklist):
//                TracklistView(
//                    data: tracklist
//                ) {
//                    Task {
//                        await viewModel.loadNextPage()
//                    }
//                } onSelectTrack: { trackItem in
//                    print("onSelectTrack - \(trackItem)")
//                }
//
//            case .error(let error):
//                ContentErrorView(error: error) {
//                    Task {
//                        await viewModel.retry()
//                    }
//                }
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle(navigationTitle)
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//    }
//}

//
//struct TracklistContentView: View {
//    
//    @ObservedObject var viewModel: TracklistViewModel
//    
////    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//    @EnvironmentObject var localization: LocalizationService
//    
//    var body: some View {
//        ZStack {
//            switch viewModel.viewState {
//                
//            case .loading:
//                ProgressView(Localized.Home.loading.localized())
//                
//            case .contentList(let tracklist):
//                TracklistView(data: tracklist) {
//                    print("did tap onLoadNextPage")
//                    Task { await viewModel.loadNextPage() }
//                } onSelectTrack: { trackItem in
//                    print("onSelectTrack - \(trackItem)")
//                }
//
//
//            case .error(let error):
//                ContentErrorView(error: error) {
//                    Task { await viewModel.retry() }
//                }
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle("Traks")
//        .navigationBarTitleDisplayMode(.inline)
////        .navigationTitle(Localized.Home.title.localized())
//        .onFirstAppear {
//            Task { await viewModel.setupViewModel() }
//        }
//    }
//}

//        .onAppear {
//            // тут можно сделать проаерку если case .errorList или case .error
//            // то мы не вызываем checkAndRefreshIfNeeded
//            Task { await viewModel.checkAndRefreshIfNeeded() }
//        }
