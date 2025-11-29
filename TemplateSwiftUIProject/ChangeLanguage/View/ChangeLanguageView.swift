//
//  ChangeLanguageView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.11.25.
//

import SwiftUI

struct ChangeLanguageView: View {
    @ObservedObject var viewModel: ChangeLanguageViewModel
    @EnvironmentObject var localization: LocalizationService
    
    var body: some View {
        List(viewModel.availableLanguages, id: \.self) { code in
            Button(action: {
                viewModel.selectLanguage(code)
            }) {
                HStack {
                    Text(viewModel.displayName(for: code))
                    Spacer()
                    if code == viewModel.selectedLanguage {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        .navigationTitle("Change Language")
    }
}

