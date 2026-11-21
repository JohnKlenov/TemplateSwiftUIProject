//
//  LibraryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 21.11.2026.
//


import SwiftUI
import Combine

struct LibraryView: View {

    // MARK: - ViewModel

    @StateObject private var viewModel: LibraryViewModel

    // MARK: - Environment

    @EnvironmentObject private var libraryCoordinator: LibraryCoordinator
    @EnvironmentObject private var viewBuilderService: ViewBuilderService

    // MARK: - Initialization

    init() {
        _viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                alertManager: AlertManager.shared
            )
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $libraryCoordinator.path) {
            viewBuilderService.dropViewBuild(page: .library)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: DroplistFlow.self) { page in
                    viewBuilderService.dropViewBuild(page: page)
                }
        }
        .sheet(item: $libraryCoordinator.sheet) { sheet in
            viewBuilderService.buildSheet(sheet: sheet)
        }
        .fullScreenCover(item: $libraryCoordinator.fullScreenItem) { cover in
            viewBuilderService.buildCover(cover: cover)
        }
        .onFirstAppear {
            print("onFirstAppear LibraryView")
        }
        .onAppear {
            print("onAppear LibraryView")
        }
        .onDisappear {
            print("onDisappear LibraryView")
        }
    }
}
