//
//  ArtistsViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 23.11.2026.
//

import SwiftUI

struct ArtistsViewInjected: View {

    // MARK: - ViewModel

    @StateObject private var viewModel: ArtistsViewModel

    // MARK: - Initialization

    init(
        dropListDataSource: DropListDataSource
    ) {
        _viewModel = StateObject(
            wrappedValue: ArtistsViewModel(
                dropListDataSource: dropListDataSource
            )
        )
    }

    // MARK: - Body

    var body: some View {

        ArtistsView(
            viewModel: viewModel
        )
    }
}
