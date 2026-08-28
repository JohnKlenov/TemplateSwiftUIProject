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

    init(
        dropListDataSource: DropListDataSource,
        trackType: CarouselItemType,
        navigationTitle: String
    ) {
        self.navigationTitle = navigationTitle

        _viewModel = StateObject(
            wrappedValue: TracklistViewModel(
                dropListDataSource: dropListDataSource,
                trackType: trackType
            )
        )
    }

    var body: some View {
        TracklistContentView(
            viewModel: viewModel,
            navigationTitle: navigationTitle
        )
    }
}



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
