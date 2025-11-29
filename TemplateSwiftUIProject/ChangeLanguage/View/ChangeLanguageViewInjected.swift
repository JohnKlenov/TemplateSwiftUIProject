//
//  ChangeLanguageViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.11.25.
//

import SwiftUI

struct ChangeLanguageViewInjected: View {
    @StateObject private var viewModel: ChangeLanguageViewModel
    
    init(localizationService: LocalizationService = .shared) {
        let _ = Self._printChanges()
        _viewModel = StateObject(
            wrappedValue: ChangeLanguageViewModel(localizationService: localizationService)
        )
    }
    
    var body: some View {
        ChangeLanguageView(viewModel: viewModel)
    }
}

