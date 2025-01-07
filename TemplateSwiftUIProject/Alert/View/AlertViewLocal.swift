//
//  AlertViewLocal.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI

struct AlertViewLocal: View {
    @Binding var isShowAlert: Bool
    @Binding var alertMessage: String
    @StateObject private var viewModel:AlertLocalViewModel
    private let nameView: String
    
    init(isShowAlert: Binding<Bool>, alertMessage: Binding<String>, nameView:String) {
        self._isShowAlert = isShowAlert
        self._alertMessage = alertMessage
        self.nameView = nameView
        _viewModel = StateObject(wrappedValue: AlertLocalViewModel(alertManager: AlertManager.shared))
        print("init AlertView")
    }
    
    var body: some View {
        EmptyView() // Основное содержимое можно оставить пустым, так как alert показывается независимо
            .alert("Local error", isPresented: $isShowAlert) {
                Button("Ok") {
                    isShowAlert = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Логика сброса сообщения алерта
                        viewModel.alertManager.resetFirstLocalAlert(forView: nameView)
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                print("onAppear AlertView")
            }
            .onDisappear {
                print("onDisappear AlertView")

            }
    }
}
