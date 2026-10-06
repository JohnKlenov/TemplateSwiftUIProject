//
//  DropTopViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//

import SwiftUI

struct DropTopViewInjected: View {

    @StateObject private var viewModel: DropTopViewModel

    init(
        dropListDataSource: DropListDataSource
    ) {
        _viewModel = StateObject(
            wrappedValue: DropTopViewModel(
                dropListDataSource: dropListDataSource
            )
        )
    }

    var body: some View {
        DropTopContentView(
            viewModel: viewModel
        )
    }
}
