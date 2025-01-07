//
//  AlertViewGlobal.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI

// Обособленное представление для алертов
struct AlertViewGlobal: View {
    @Binding var showAlert: Bool
    @Binding var alertMessage: String
    
    init(showAlert: Binding<Bool>, alertMessage: Binding<String>) {
        self._showAlert = showAlert
        self._alertMessage = alertMessage
        print("init GlobalAlertView")
    }
    
    var body: some View {
        EmptyView()
            .alert("Global error", isPresented: $showAlert) {
                Button("Ok") {}
            } message: {
                Text(alertMessage)
            }
    }
}
