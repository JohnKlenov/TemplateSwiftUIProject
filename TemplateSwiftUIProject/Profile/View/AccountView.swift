//
//  AccountView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.04.25.
//

import SwiftUI
import Combine

struct AccountView: View {
    
    
    @StateObject private var viewModel:AccountViewModel
    
    @EnvironmentObject var accountCoordinator:AccountCoordinator
    @EnvironmentObject var viewBuilderService:ViewBuilderService
    
    init() {
        _viewModel = StateObject(wrappedValue: AccountViewModel(alertManager: AlertManager.shared))
        print("init AccountView")
    }
    
    var body: some View {
        ///в момент rerendering в init View передаются те же параметры что и при первой инициализации
        ///поэксперементировать с homeCoordinator - вынести его из состояния в HomeView
        NavigationStack(path: $accountCoordinator.path) {
            viewBuilderService.accountViewBuild(page: .account)
                .navigationDestination(for: AccountFlow.self) { page in
                    viewBuilderService.accountViewBuild(page: page)
                }
        }
        .sheet(item: $accountCoordinator.sheet) { sheet in
            viewBuilderService.buildSheet(sheet: sheet)
        }
        .fullScreenCover(item: $accountCoordinator.fullScreenItem) { cover in
            viewBuilderService.buildCover(cover: cover)
        }
        .onFirstAppear {
            print("onFirstAppear AccountView")
        }
        .onAppear {
            print("onAppear AccountView")
        }
        .onDisappear {
            print("onDisappear AccountView")
        }
    }
}




// MARK: - old implemintation with var isViewVisible: Bool


//struct AccountView: View {
//    
//    @StateObject private var viewModel:AccountViewModel
//    
//    //alert
//    @State private var isShowAlert: Bool = false
//    @State private var alertMessage: String = ""
//    @State private var alertTitle: String = ""
//    @State private var cancellables = Set<AnyCancellable>()
//    
//    @EnvironmentObject var accountCoordinator:AccountCoordinator
//    @EnvironmentObject var viewBuilderService:ViewBuilderService
//    
//    init() {
//        _viewModel = StateObject(wrappedValue: AccountViewModel(alertManager: AlertManager.shared))
//        print("init AccountView")
//    }
//    
//    var body: some View {
//        ///в момент rerendering в init View передаются те же параметры что и при первой инициализации
//        ///поэксперементировать с homeCoordinator - вынести его из состояния в HomeView
//        NavigationStack(path: $accountCoordinator.path) {
//            viewBuilderService.accountViewBuild(page: .account)
//                .navigationDestination(for: AccountFlow.self) { page in
//                    viewBuilderService.accountViewBuild(page: page)
//                }
//        }
//        .sheet(item: $accountCoordinator.sheet) { sheet in
//            viewBuilderService.buildSheet(sheet: sheet)
//        }
//        .fullScreenCover(item: $accountCoordinator.fullScreenItem) { cover in
//            viewBuilderService.buildCover(cover: cover)
//        }
//        .onFirstAppear {
//            print("onFirstAppear")
//            subscribeToLocalAlerts()
//        }
//        .onAppear {
//            viewModel.alertManager.isAccountViewVisible = true
//            print("onAppear AccountView")
//        }
//        .onDisappear {
//            viewModel.alertManager.isAccountViewVisible = false
//            print("onDisappear AccountView")
//        }
//        .background {
//            AlertViewLocal(isShowAlert: $isShowAlert, alertTitle: $alertTitle, alertMessage: $alertMessage, nameView: "AccountView")
//        }
//    }
//    
//    private func subscribeToLocalAlerts() {
//        viewModel.alertManager.$localAlerts
//            .combineLatest(viewModel.alertManager.$isAccountViewVisible)
//            .sink { (localAlert, isAccountViewVisible) in
//                print(".sink { (localAlert, isAccountViewVisible)")
//                if isAccountViewVisible, let alert = localAlert["AccountView"] {
//                    print("if isAccountViewVisible, let alert = localAlert")
//                    alertMessage = alert.first?.message.localized() ?? Localized.Alerts.defaultMessage.localized()
//                    alertTitle = alert.first?.operationDescription.localized() ?? Localized.Alerts.title.localized()
//                    isShowAlert = true
//                }
//            }
//            .store(in: &cancellables)
//    }
//}
