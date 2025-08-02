//
//  ReauthenticateView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.08.25.
//

import SwiftUI

struct ReauthenticateView: View {
    @ObservedObject var viewModel: ReauthenticateViewModel
    
    var body: some View {
        Text("ReauthenticateView")
    }
}

//    var body: some View {
//        VStack(spacing: 16) {
//            Text("Для выполнения удаления аккаунта нужна свежая авторизация")
//                .multilineTextAlignment(.center)
//                .padding()
//
//            TextField("Email", text: $viewModel.email)
//                .textFieldStyle(.roundedBorder)
//            SecureField("Пароль", text: $viewModel.password)
//                .textFieldStyle(.roundedBorder)
//
//            if let err = viewModel.emailError {
//                Text(err).foregroundColor(.red).font(.caption)
//            }
//
//            Button(action: viewModel.reauthenticate) {
//                if viewModel.registeringState == .loading {
//                    ProgressView()
//                } else {
//                    Text("Повторить вход")
//                }
//            }
//            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty)
//            .buttonStyle(.borderedProminent)
//        }
//        .padding()
//    }
