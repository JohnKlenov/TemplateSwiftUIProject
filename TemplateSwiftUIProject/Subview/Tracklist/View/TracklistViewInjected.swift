//
//  TracklistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.08.2026.
//


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
