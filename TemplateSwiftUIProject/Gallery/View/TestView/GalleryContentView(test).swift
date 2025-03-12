//
//  GalleryContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.03.25.
//

//import SwiftUI
//
//struct GalleryContentView: View {
//    
//    // Получаем сервис локализации через EnvironmentObject
//    @EnvironmentObject var localization: LocalizationService
//    @StateObject private var viewModel:GalleryContentViewModel
//    
//    init() {
//        _viewModel = StateObject(wrappedValue:GalleryContentViewModel(firestorColletionObserverService: FirestoreCollectionObserverService(), errorHandler: SharedErrorHandler()))
//    }
//
//    var body: some View {
//        ZStack {
////            Color.blue
//            switch viewModel.viewState {
//            case .loading:
//                ProgressView(Localized.Gallery.loading.localized())
//            case .error(let error):
//                ///error на ContentErrorView не распечатывается
//                ContentErrorView(error: error) {
//                    viewModel.retry()
//                }
//            case .content(let data):
//                GalleryListView(data: data)
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle(Localized.Gallery.title.localized())
//        .onFirstAppear {
//            viewModel.setupViewModel()
//        }
//    }
//}
