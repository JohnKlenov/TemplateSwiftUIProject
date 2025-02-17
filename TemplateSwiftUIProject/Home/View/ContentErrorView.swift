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
    let error: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            ContentUnavailableView(
                label: {
                    Label("Ups :(", systemImage: "exclamationmark.triangle")
                },
                description: {
                    Text("Try again! Something went wrong!")
                },
                actions: {
                    Button("Refresh") {
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

