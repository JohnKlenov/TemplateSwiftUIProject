//
//  AlertViewGlobal.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI

// Обособленное представление для алертов
struct AlertViewGlobal: View {
    
    @StateObject private var viewModel:AlertViewModel
    
    @Binding var isShowAlert: Bool
    @Binding var alertMessage: String
    @Binding var alertTitle:String
    
    init(isShowAlert: Binding<Bool>, alertTitle: Binding<String>, alertMessage: Binding<String>) {
        self._isShowAlert = isShowAlert
        self._alertMessage = alertMessage
        self._alertTitle = alertTitle
        _viewModel = StateObject(wrappedValue: AlertViewModel(alertManager: AlertManager.shared))
        print("init GlobalAlertView")
    }
    
    var body: some View {
        EmptyView()
            .alert(alertTitle, isPresented: $isShowAlert) {
                Button("Ok") {
                    alertMessage = "Something went wrong try again!"
                    alertTitle = "Error"
                    isShowAlert = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // Логика сброса сообщения алерта
                        viewModel.alertManager.resetFirstGlobalAlert()
                    }
                }
            } message: {
                Text(alertMessage)
            }
    }
}
