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
    @Binding var alertTitle:String
    
    @StateObject private var viewModel:AlertViewModel
    private let nameView: String
    
    init(isShowAlert: Binding<Bool>, alertTitle: Binding<String>, alertMessage: Binding<String>, nameView:String) {
        self._isShowAlert = isShowAlert
        self._alertMessage = alertMessage
        self._alertTitle = alertTitle
        self.nameView = nameView
        _viewModel = StateObject(wrappedValue: AlertViewModel(alertManager: AlertManager.shared))
        print("init AlertView - \(nameView)")
    }
    
    var body: some View {
        EmptyView() // Основное содержимое можно оставить пустым, так как alert показывается независимо
            .alert(alertTitle, isPresented: $isShowAlert) {
                Button("Ok") {
                    alertMessage = ""
                    alertTitle = ""
                    isShowAlert = false
                    viewModel.alertManager.resetFirstLocalAlert(forView: nameView)
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        // Логика сброса сообщения алерта
//                        viewModel.alertManager.resetFirstLocalAlert(forView: nameView)
//                    }
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
