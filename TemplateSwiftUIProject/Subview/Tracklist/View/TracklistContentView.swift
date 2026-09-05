//
//  TracklistContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//


// добавить кнопку addPlaylist (реализовать логику - если есть в корзине то кнопка добавить не доступна) + как отобразить добавление в корзину
// запустить трек на плеере - fullScreen 

import SwiftUI

struct TracklistContentView: View {

    @ObservedObject var viewModel: TracklistViewModel
    let navigationTitle: String

    @EnvironmentObject var localization: LocalizationService

    @State private var selectedTrack: LowerItem?

    var body: some View {
        ZStack {
            switch viewModel.viewState {

            case .loading:
                ProgressView(Localized.Home.loading.localized())

            case .contentList(let tracklist):
                TracklistView(
                    data: tracklist,
                    onLoadNextTracks: {
                        Task { await viewModel.loadNextPage() }
                    },
                    onSelectTrack: { item in
                        if item.isTrack {
                            selectedTrack = item
                        }
                    }
                )

            case .error(let error):
                ContentErrorView(error: error) {
                    Task { await viewModel.retry() }
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            Task { await viewModel.setupViewModel() }
        }
        .sheet(item: $selectedTrack) { track in
            PlayerViews(videoId: track.id)
                    .presentationDetents([.medium, .large])
//            YouTubePlayerView(videoId: track.id)
//                .edgesIgnoringSafeArea(.all)
        }
    }
}

//PlayerViews(videoId: track.id)
//        .presentationDetents([.medium, .large])


//        .fullScreenCover(item: $selectedTrack) { track in
//            return EmbedPlayer(videoId: track.id)
//                .frame(height: 280)
//                .background(Color.black)
//                .cornerRadius(12)
//                .padding(.horizontal, 8)
//
//        }

// Видео
//            EmbedPlayer(videoId: track.id)
//                .frame(height: 280)
//                .background(Color.black)
//                .cornerRadius(12)
//                .padding(.horizontal, 8)
//            YouTubePlayerView(videoId: track.id)
//                .edgesIgnoringSafeArea(.all)
//            PlayerView(videoId: track.id)
//                .presentationDetents([.medium, .large])


//                        if item.isTrack {
//                                YouTubeAppPlayer.open(videoId: item.id)
//                            }

struct YouTubeAppPlayer {
    static func open(videoId: String) {
        let appURL = URL(string: "youtube://\(videoId)")!
        let webURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}


import SwiftUI
import SafariServices

struct SafariPlayerView: UIViewControllerRepresentable {
    let videoId: String

    func makeUIViewController(context: Context) -> SFSafariViewController {
        // Обычный watch-вариант — YouTube доверяет ему
        let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!

        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        config.barCollapsingEnabled = true   // красивый эффект схлопывания

        let vc = SFSafariViewController(url: url, configuration: config)

        vc.preferredControlTintColor = .white        // цвет кнопок
        vc.preferredBarTintColor = .black            // фон навбара
        vc.dismissButtonStyle = .close               // стиль кнопки закрытия

        return vc
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}


struct PlayerViews: View {
    let videoId: String

    var body: some View {
        SafariPlayerView(videoId: videoId)
            .edgesIgnoringSafeArea(.all)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
    }
}



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
