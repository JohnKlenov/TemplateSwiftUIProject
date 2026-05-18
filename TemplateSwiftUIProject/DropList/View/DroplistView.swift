//
//  DroplistView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

import SwiftUI
import Combine


struct DroplistView: View {
    
    @StateObject private var viewModel:DropViewModel
    
    @EnvironmentObject var droplistCoordinator:DroplistCoordinator
    @EnvironmentObject var viewBuilderService:ViewBuilderService
    
    init() {
        _viewModel = StateObject(wrappedValue: DropViewModel(alertManager: AlertManager.shared))
        print("init DroplistView")
    }
    
    var body: some View {
        ///в момент rerendering в init View передаются те же параметры что и при первой инициализации
        ///поэксперементировать с homeCoordinator - вынести его из состояния в HomeView
        NavigationStack(path: $droplistCoordinator.path) {
            viewBuilderService.dropViewBuild(page: .droplist)
                .navigationDestination(for: DroplistFlow.self) { page in
                    viewBuilderService.dropViewBuild(page: page)
                }
        }
        .sheet(item: $droplistCoordinator.sheet) { sheet in
            viewBuilderService.buildSheet(sheet: sheet)
        }
        .fullScreenCover(item: $droplistCoordinator.fullScreenItem) { cover in
            viewBuilderService.buildCover(cover: cover)
        }
        .onFirstAppear {
            print("onFirstAppear DroplistView")
        }
        .onAppear {
            print("onAppear DroplistView")
        }
        .onDisappear {
            print("onDisappear DroplistView")
        }
    }
}
