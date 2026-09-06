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
            SafariPlayerView(videoId: track.id)
                .presentationDetents([.medium, .large])
        }
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
