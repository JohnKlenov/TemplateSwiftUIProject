//
//  GalleryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI
import Combine

struct GalleryView: View {
    
    @StateObject private var viewModel:GalleryViewModel
    
    //alert
    @State private var isShowAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var cancellables = Set<AnyCancellable>()
    
    @EnvironmentObject var galleryCoordinator:GalleryCoordinator
    @EnvironmentObject var viewBuilderService:ViewBuilderService
    
    init() {
        _viewModel = StateObject(wrappedValue: GalleryViewModel(alertManager: AlertManager.shared))
        print("init GalleryView")
    }
    
    var body: some View {
        ///в момент rerendering в init View передаются те же параметры что и при первой инициализации
        ///поэксперементировать с homeCoordinator - вынести его из состояния в HomeView
        NavigationStack(path: $galleryCoordinator.path) {
            viewBuilderService.galleryViewBuild(page: .gallery)
                .navigationDestination(for: GalleryFlow.self) { page in
                    viewBuilderService.galleryViewBuild(page: page)
                }
        }
        .sheet(item: $galleryCoordinator.sheet) { sheet in
            viewBuilderService.buildSheet(sheet: sheet)
        }
        .fullScreenCover(item: $galleryCoordinator.fullScreenItem) { cover in
            viewBuilderService.buildCover(cover: cover)
        }
        .onFirstAppear {
            print("onFirstAppear GalleryView")
            subscribeToLocalAlerts()
        }
        .onAppear {
            viewModel.alertManager.isGalleryViewVisible = true
            print("onAppear GalleryView")
        }
        .onDisappear {
            viewModel.alertManager.isGalleryViewVisible = false
            print("onDisappear GalleryView")
        }
        .background {
            AlertViewLocal(isShowAlert: $isShowAlert, alertTitle: $alertTitle, alertMessage: $alertMessage, nameView: "GalleryView")
        }
    }
    
    private func subscribeToLocalAlerts() {
        viewModel.alertManager.$localAlerts
            .combineLatest(viewModel.alertManager.$isGalleryViewVisible)
            .sink { (localAlert, isGalleryViewVisible) in
                print(".sink { (localAlert, isGalleryViewVisible)")
                if isGalleryViewVisible, let alert = localAlert["GalleryView"] {
                    print("if isGalleryViewVisible, let alert = localAlert")
                    alertMessage = alert.first?.message.localized() ?? Localized.Alerts.defaultMessage.localized()
                    alertTitle = alert.first?.operationDescription.localized() ?? Localized.Alerts.title.localized()
                    isShowAlert = true
                }
            }
            .store(in: &cancellables)
    }
    
}
