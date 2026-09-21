//
//  TracklistContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//

import SwiftUI

struct TracklistContentView: View {
    @ObservedObject var viewModel: TracklistViewModel

    let navigationTitle: String
    let details: [String]
    let imageURL: URL?

    @EnvironmentObject var localization: LocalizationService

    @State private var selectedTrack: LowerItem?

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
                        if item.isTrack {
                            selectedTrack = item
                        }
                    },
                    onAddToPlaylist: { item in
                        Task {
                            await viewModel.addToPlaylist(item)
                        }
                    },
                    onPlayInYouTubeMusic: { item in
                        viewModel.playInYouTubeMusic(item)
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
