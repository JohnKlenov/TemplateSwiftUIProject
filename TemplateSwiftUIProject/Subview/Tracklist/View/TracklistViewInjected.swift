//
//  TracklistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//



// TracklistViewInjected мы используем в (AllTrack + Droplist + TopDropItem верх секц гл экр + TopDropItem в TopDrop + все вкладки в будущем каталоге (включая фильтры по тегам Gym .. ))
// сейчас когда мы делаем первый старт и он успешный то происходит установка таймера на 2 часа await dropListDataSource.markDataUpdated()
// и когда мы заходим на главный экран в любой раз в жизненом цикле апп происходит func checkAndRefreshIfNeeded() где идет проверка прошло ли 2 часа с момента последней успешной подгрузки данных и если да то снова делаем await refreshDropList() и обновляем dropListDataSource.markDataUpdated() при успешном обновлении что бы снова включить таймер на 2 часа
// то есть данные обновляются когда пользователь заходит на главный экран спустя 2 часа или больше после успешной загрузки или при рефрешь с главного экрана в любой момент времени!
// сейчас если мы делаем рефреш на главном экране мы при переходе на любой экран TracklistViewInjected идем в сеть за данными потому что мы в func refreshDropList()  делаем await dropListDataSource.refreshAll() а в await dropListDataSource.refreshAll() делаем await pagesCache.reset() то есть удаляем кэшь для всех наших (AllTrack + Droplist + TopDropItem верх секц гл экр + TopDropItem в TopDrop + все вкладки в будущем каталоге (включая фильтры по тегам Gym .. ))
// и когда мы при загрузки TracklistViewInjected 
// а нам нет необходимости удалять кэш для Droplist + TopDropItem верх секц гл экр так как они навсегда будут неизменны ???



import SwiftUI

struct TracklistViewInjected: View {
    @StateObject private var viewModel: TracklistViewModel

    private let navigationTitle: String
    private let details: [String]
    private let imageURL: URL?

    init(
        dropListDataSource: DropListDataSource,
        playlistUser: PlaylistUser,
        trackType: CarouselItemType,
        navigationTitle: String,
        details: [String] = [],
        imageURL: URL? = nil
    ) {
        self.navigationTitle = navigationTitle
        self.details = details
        self.imageURL = imageURL

        _viewModel = StateObject(
            wrappedValue: TracklistViewModel(
                dropListDataSource: dropListDataSource,
                playlistUser: playlistUser,
                trackType: trackType
            )
        )
    }

    var body: some View {
        TracklistContentView(
            viewModel: viewModel,
            navigationTitle: navigationTitle,
            details: details,
            imageURL: imageURL
        )
    }
}

// before add let imageURL for case .droplistDetails
//import SwiftUI
//
//struct TracklistViewInjected: View {
//    @StateObject private var viewModel: TracklistViewModel
//
//    private let navigationTitle: String
//    private let details: [String]
//
//    init(
//        dropListDataSource: DropListDataSource,
//        playlistUser: PlaylistUser,
//        trackType: CarouselItemType,
//        navigationTitle: String,
//        details: [String] = []
//    ) {
//        self.navigationTitle = navigationTitle
//        self.details = details
//
//        _viewModel = StateObject(
//            wrappedValue: TracklistViewModel(
//                dropListDataSource: dropListDataSource,
//                playlistUser: playlistUser,
//                trackType: trackType
//            )
//        )
//    }
//
//    var body: some View {
//        TracklistContentView(
//            viewModel: viewModel,
//            navigationTitle: navigationTitle,
//            details: details
//        )
//    }
//}


// MARK: -  before add let title for case .droplistDetails

//struct TracklistViewInjected: View {
//    @StateObject private var viewModel: TracklistViewModel
//
//    private let navigationTitle: String
//    private let details: [String]
//
//    init(
//        dropListDataSource: DropListDataSource,
//        playlistUser: PlaylistUser,
//        trackType: CarouselItemType,
//        navigationTitle: String,
//        details: [String] = []
//    ) {
//        self.navigationTitle = navigationTitle
//        self.details = details
//
//        _viewModel = StateObject(
//            wrappedValue: TracklistViewModel(
//                dropListDataSource: dropListDataSource,
//                playlistUser: playlistUser,
//                trackType: trackType
//            )
//        )
//    }
//
//    var body: some View {
//        TracklistContentView(
//            viewModel: viewModel,
//            navigationTitle: navigationTitle,
//            details: details
//        )
//    }
//}


// MARK: - before add PlaylistDetailsView

//import SwiftUI
//
//struct TracklistViewInjected: View {
//
//    @StateObject private var viewModel: TracklistViewModel
//    private let navigationTitle: String
//
//    init(
//        dropListDataSource: DropListDataSource,
//        playlistUser: PlaylistUser,
//        trackType: CarouselItemType,
//        navigationTitle: String
//    ) {
//        self.navigationTitle = navigationTitle
//
//        _viewModel = StateObject(
//            wrappedValue: TracklistViewModel(
//                dropListDataSource: dropListDataSource,
//                playlistUser: playlistUser,
//                trackType: trackType
//            )
//        )
//    }
//
//    var body: some View {
//        TracklistContentView(
//            viewModel: viewModel,
//            navigationTitle: navigationTitle
//        )
//    }
//}

// MARK: - before PlaylistUser

//import SwiftUI
//
//struct TracklistViewInjected: View {
//
//    @StateObject private var viewModel: TracklistViewModel
//
//    private let navigationTitle: String
//
//    init(dropListDataSource: DropListDataSource, trackType: CarouselItemType, navigationTitle: String) {
//        
//        self.navigationTitle = navigationTitle
//        _viewModel = StateObject(wrappedValue: TracklistViewModel(dropListDataSource: dropListDataSource, trackType: trackType))
//    }
//
//    var body: some View {
//        TracklistContentView(viewModel: viewModel, navigationTitle: navigationTitle)
//    }
//}



//import SwiftUI
//
//struct TracklistViewInjected: View {
//    
//    @StateObject private var viewModel: TracklistViewModel
//    
//    init(dropListDataSource:DropListDataSource, trackType: CarouselItemType) {
//        
//        _viewModel = StateObject(
//            wrappedValue: TracklistViewModel(dropListDataSource: dropListDataSource, trackType: trackType)
//        )
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        TracklistContentView(viewModel: viewModel)
//    }
//}







// MARK: - old implement

//import SwiftUI
//
//struct TracklistViewInjected: View {
//    
//    @StateObject private var viewModel: TracklistViewModel
//    
//    init(dropListDataSource:DropListDataSource) {
//        
//        _viewModel = StateObject(
//            wrappedValue: TracklistViewModel(dropListDataSource: dropListDataSource)
//        )
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        TracklistContentView(viewModel: viewModel)
//    }
//}
