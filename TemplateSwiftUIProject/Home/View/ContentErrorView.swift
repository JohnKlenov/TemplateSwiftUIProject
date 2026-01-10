//
//  ContentErrorView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.02.25.
//

/// так как errorView заполняет пространство при первом старте или неожиданно возникшей ошибкой уже после успеха
/// но дублируется локальным или гобальным алертам
/// мы должны сделать его контент подходящим для любой ситуации


import SwiftUI

struct ContentErrorView: View {
    @EnvironmentObject var localization: LocalizationService
    
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            ContentUnavailableView(
                label: {
                    Label(Localized.Home.ContentErrorView.title.localized(), systemImage: AppIcons.ContentErrorView.warning)
                },
                description: {
                    Text(Localized.Home.ContentErrorView.description.localized())
                },
                actions: {
                    Button(Localized.Home.ContentErrorView.refreshButton.localized()) {
                        retryAction()
                    }
                }
            )
            .frame(maxWidth: .infinity)
            Spacer()
        }
        .ignoresSafeArea(edges: [.horizontal])
    }
}


