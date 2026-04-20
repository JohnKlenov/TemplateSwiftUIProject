//
//  DroplistView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

//import SwiftUI
//import Combine
//
//
//struct DroplistView: View {
//    
//    @StateObject private var viewModel:HomeViewModel
//    
//    @EnvironmentObject var homeCoordinator:HomeCoordinator
//    @EnvironmentObject var viewBuilderService:ViewBuilderService
//    
//    init() {
//        _viewModel = StateObject(wrappedValue: HomeViewModel(alertManager: AlertManager.shared))
//        print("init HomeView")
//    }
//    
//    var body: some View {
//        ///в момент rerendering в init View передаются те же параметры что и при первой инициализации
//        ///поэксперементировать с homeCoordinator - вынести его из состояния в HomeView
//        NavigationStack(path: $homeCoordinator.path) {
//            viewBuilderService.homeViewBuild(page: .home)
//                .navigationDestination(for: HomeFlow.self) { page in
//                    viewBuilderService.homeViewBuild(page: page)
//                }
//        }
//        .sheet(item: $homeCoordinator.sheet) { sheet in
//            viewBuilderService.buildSheet(sheet: sheet)
//        }
//        .fullScreenCover(item: $homeCoordinator.fullScreenItem) { cover in
//            viewBuilderService.buildCover(cover: cover)
//        }
//        .onFirstAppear {
//            print("onFirstAppear HomeView")
//        }
//        .onAppear {
//            print("onAppear HomeView")
//        }
//        .onDisappear {
//            print("onDisappear HomeView")
//        }
//    }
//}
