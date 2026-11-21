//
//  LibraryContentViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 21.11.2026.
//



import SwiftUI

struct LibraryContentViewInjected: View {

    // MARK: - ViewModel

    @StateObject private var viewModel: LibraryContentViewModel

    // MARK: - Initialization

    init() {
        _viewModel = StateObject(
            wrappedValue: LibraryContentViewModel()
        )
    }

    // MARK: - Body

    var body: some View {
        LibraryContentView(
            viewModel: viewModel
        )
    }
}
