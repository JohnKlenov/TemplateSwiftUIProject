//
//  AlertViewGlobal.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI



// MARK: - Localization Alert

struct AlertViewGlobal: View {
    
    @StateObject private var viewModel: AlertViewModel
    @EnvironmentObject var retryHandler: GlobalRetryHandler
    @EnvironmentObject var localization: LocalizationService
    
    @Binding var isShowAlert: Bool
    @Binding var alertMessage: String
    @Binding var alertTitle: String
    @Binding var alertType: AlertType
    
    
    init(isShowAlert: Binding<Bool>,
         alertTitle: Binding<String>,
         alertMessage: Binding<String>,
         alertType: Binding<AlertType>) {
        
        self._isShowAlert = isShowAlert
        self._alertMessage = alertMessage
        self._alertTitle = alertTitle
        self._alertType = alertType
        _viewModel = StateObject(wrappedValue: AlertViewModel(alertManager: AlertManager.shared))
        print("init GlobalAlertView")
    }
    
    // Вычисляемое свойство для определения текста кнопки в зависимости от типа ошибки
    var alertButtonText: String {
        switch alertType {
        case .tryAgain:
            return Localized.AlertViewGlobal.tryAgain.localized()
        case .ok:
            return Localized.AlertViewGlobal.ok.localized()
        }
    }
    
    var body: some View {
        // Используем невидимую вьюшку, от которой показываем модальное уведомление
        EmptyView()
            .alert(alertTitle, isPresented: $isShowAlert) {
                Button(alertButtonText) {
                    // Вызываем обработку retry через ViewModel
//                    viewModel.handleRetryAction(for: alertType)
                    handleRetryAction(for: alertType)
                    resetAlert()
                    
                }
            } message: {
                Text(alertMessage)
            }
    }
    
    private func handleRetryAction(for alertType: AlertType) {
        if alertType == .tryAgain {
            retryHandler.triggerRetry()
        }
    }
    
    private func resetAlert() {
        alertMessage = ""
        alertTitle = ""
        isShowAlert = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewModel.resetFirstGlobalAlert()
        }
    }
}



//                    if alertType == .authentication {
//                        // Если тип ошибки – аутентификация, вызываем дополнительное действие (например, повторный запрос)
//                        print("Retrying authentication...")
//                    } else {
//                        // Для общих ошибок – просто закрываем алерт
//                        print("Acknowledging alert")
//                    }
//                    // Сброс состояния алерта
//                    alertMessage = ""
//                    alertTitle = ""
//                    isShowAlert = false
//
//                    // С небольшим отложением сбрасываем первый глобальный алерт
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        viewModel.alertManager.resetFirstGlobalAlert()
//                    }

// если бы мы напряму через onRetry в ContentView вызывали retry

//struct AlertViewGlobal: View {
//    
//    @StateObject private var viewModel: AlertViewModel
//    
//    @Binding var isShowAlert: Bool
//    @Binding var alertMessage: String
//    @Binding var alertTitle: String
//    @Binding var alertType: AlertType
//    
//    // Дополнительное замыкание для обработки retry, если тип ошибки – authentication
//    var onRetry: (() -> Void)?
//    
//    init(isShowAlert: Binding<Bool>,
//         alertTitle: Binding<String>,
//         alertMessage: Binding<String>,
//         alertType: Binding<AlertType>,
//         onRetry: (() -> Void)? = nil) {
//        
//        self._isShowAlert = isShowAlert
//        self._alertMessage = alertMessage
//        self._alertTitle = alertTitle
//        self._alertType = alertType
//        self.onRetry = onRetry
//        _viewModel = StateObject(wrappedValue: AlertViewModel(alertManager: AlertManager.shared))
//        print("init GlobalAlertView")
//    }
//    
//    // Вычисляемое свойство для определения текста кнопки в зависимости от типа ошибки
//    var alertButtonText: String {
//        switch alertType {
//        case .authentication:
//            return "Try again"
//        case .common:
//            return "Ok"
//        }
//    }
//    
//    var body: some View {
//        // Используем невидимую вьюшку, от которой показываем модальное уведомление
//        EmptyView()
//            .alert(alertTitle, isPresented: $isShowAlert) {
//                Button(alertButtonText) {
//                    if alertType == .authentication {
//                        // Если тип ошибки – аутентификация, вызываем дополнительное действие (например, повторный запрос)
//                        print("Retrying authentication...")
//                        onRetry?()
//                    } else {
//                        // Для общих ошибок – просто закрываем алерт
//                        print("Acknowledging alert")
//                    }
//                    // Сброс состояния алерта
//                    alertMessage = ""
//                    alertTitle = ""
//                    isShowAlert = false
//                    
//                    // С небольшим отложением сбрасываем первый глобальный алерт
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        viewModel.alertManager.resetFirstGlobalAlert()
//                    }
//                }
//            } message: {
//                Text(alertMessage)
//            }
//    }
//}



//// Обособленное представление для алертов
//struct AlertViewGlobal: View {
//    
//    @StateObject private var viewModel:AlertViewModel
//    
//    @Binding var isShowAlert: Bool
//    @Binding var alertMessage: String
//    @Binding var alertTitle:String
//    
//    init(isShowAlert: Binding<Bool>, alertTitle: Binding<String>, alertMessage: Binding<String>) {
//        self._isShowAlert = isShowAlert
//        self._alertMessage = alertMessage
//        self._alertTitle = alertTitle
//        _viewModel = StateObject(wrappedValue: AlertViewModel(alertManager: AlertManager.shared))
//        print("init GlobalAlertView")
//    }
//    
//    var body: some View {
//        EmptyView()
//            .alert(alertTitle, isPresented: $isShowAlert) {
//                Button("Ok") {
//                    alertMessage = ""
//                    alertTitle = ""
//                    isShowAlert = false
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        // Логика сброса сообщения алерта
//                        viewModel.alertManager.resetFirstGlobalAlert()
//                    }
//                }
//            } message: {
//                Text(alertMessage)
//            }
//    }
//}
