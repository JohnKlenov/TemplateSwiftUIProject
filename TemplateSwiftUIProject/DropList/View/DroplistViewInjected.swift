//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//


import SwiftUI

struct DroplistViewInjected: View {

    // ============================================================
    // MARK: - ViewModel
    // ============================================================

    @StateObject private var viewModel: DroplistViewModel

    // ============================================================
    // MARK: - Init
    // ============================================================

    init(
        sessionManager: AppSessionManager,
        dropListDataSource: DropListDataSource,
        playlistUser: PlaylistUser
    ) {
        _viewModel = StateObject(
            wrappedValue: DroplistViewModel(
                sessionManager: sessionManager,
                dropListDataSource: dropListDataSource,
                playlistUser: playlistUser
            )
        )
    }

    // ============================================================
    // MARK: - Body
    // ============================================================

    var body: some View {
        let _ = Self._printChanges()

        DroplistContentView(
            viewModel: viewModel
        )
    }
}

// MARK: - before PlaylistUser

//import SwiftUI
//
//struct DroplistViewInjected: View {
//    
//    @StateObject private var viewModel: DroplistViewModel
//    
//    init(sessionManager: AppSessionManager, dropListDataSource:DropListDataSource) {
//        
//        _viewModel = StateObject(
//            wrappedValue: DroplistViewModel(
//                sessionManager: sessionManager, dropListDataSource: dropListDataSource)
//        )
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        DroplistContentView(viewModel: viewModel)
//    }
//}
