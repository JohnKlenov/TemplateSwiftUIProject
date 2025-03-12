//
//  GalleryContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct GalleryContentView: View {
    
    // Получаем сервис локализации через EnvironmentObject
    @EnvironmentObject var localization: LocalizationService
    @StateObject private var viewModel:GalleryContentViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue:GalleryContentViewModel(firestoreService: FirestoreGetService(), errorHandler: SharedErrorHandler()))
    }
    
    var body: some View {
        ZStack {
            //            Color.blue
            switch viewModel.viewState {
            case .loading:
                ProgressView(Localized.Gallery.loading.localized())
            case .error(let error):
                ///error на ContentErrorView не распечатывается
                ContentErrorView(error: error) {
                    //                    viewModel.retry()
                }
            case .content(let data):
                GalleryCompositView(data: data, refreshAction: {
                    await viewModel.fetchData()
                })
            }
        }
        .background(AppColors.background)
        .navigationTitle(Localized.Gallery.title.localized())
        .onAppear{
            // При появлении вкладки проверяем, не пора ли обновить данные
            Task {
                await viewModel.checkAndRefreshIfNeeded()
            }
        }
    }
}
