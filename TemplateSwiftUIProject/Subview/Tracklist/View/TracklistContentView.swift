//
//  TracklistContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//


// вынести playlistUser(myTracks) в отдельную сущность PlaylistUser которую мы будем инициализировать в ViewBuilderService и передавать в ViewInjected а там уже в их ViewModel для каждого экрана на котором есть список треков! Это делается для того что бы мы могли при добавлении трека в плэйлист видеть по id из PlaylistUser есть этот трек в корзине или нет (если есть тогда кнопку добавить трек в корзину делаем не активной или в обратном случае активной)
// в DroplistViewModel вместо myTracks будет наша новая сущность PlaylistUser в которую мы будем записывать наш playlistUser(myTracks). Нужно добавить что DroplistViewModel будет управляющим так сказать центром для жизненного цикла PlaylistUser потому что именно тут у нас находиться private func handleHomeManagerState для sessionManager.statePublisher и наш экран Droplist и его DroplistViewModel живут в памяти с начала и до конца сессии нашего приложения.

// для каждой ячейки lowerItemCell добавить в ее крайне правой части кнопку с иконкой многоточие(как на скрин шоте) и по нажатии на нее что бы открывалось контекстное меню с двумя кнопками (контекстное меню как на скрин шоте реализовать через готовое решение в SwiftUI):
// 1. добавить кнопку addTrack для каждого трека в списке в его контекстном меню  (реализовать логику - если трек есть в PlaylistUser то кнопка добавить не доступна)
// 2. добавить кнопку для каждого трека в его контекстном меню что бы по ней можно было переходить на прослушивание трека в приложении YoutubeMusic на устройстве пользователя (DeepLink но логику перехода реализуем позже)

// адаптировать размер нашей WebImageView посмотреть на скрин шот и сделать такой же размер как там (в нашей реализации похоже он больше у нас сейчас 60 * 60)

// TracklistViewInjected оставить для таких списков как (allTracks + gym + rnb ..) для таких списков как (droplist + droptop) продумать отдельный TracklistViewInjected в котором TracklistView будет иметь отдельное информационное View которое будет иметь информацию о том с каких альбомов у на треки этих артистов например. возможно это окно будет только для droplist а droptop будет как обычный TracklistViewInjected

// такие View как DropTop могут в перспективе иметь большое количество ячеек типа (топ по голдам топ по месяцам или список по артистам или топ 10 по годам и так далее - в которых при переходе мы будем попадать на список треков) и у нас будет очень большой список за несколько лет и я думаю мы можем пойти двумя путями (создавать вложенные директории например в ячейки топ по годам будет список с ячейками топ 2026 + топ 2027 и при переходе на которым мы будем уже попадать на список треков) или же у нас будет все таки большой список без вложенных списков но у нас будет отдельное вью для фильтров(где мы будем выбирать допустим только топ по годам или только топ по месяцам или еще как то) - пока можно оставить второй варант а фильтр разработать как фичу для версии 2.0

// для версии 2.0  нужно оставить так же стратегию использования AppleMusic - то есть интерфейс будет все тот же но дата сорс уже будет тругой

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
//            YouTubePlayerView(videoId: track.id)
//                .edgesIgnoringSafeArea(.all)
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
