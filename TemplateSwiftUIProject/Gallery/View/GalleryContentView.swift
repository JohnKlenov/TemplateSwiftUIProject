//
//  GalleryContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//


// MARK: - Task + async/await -

///SwiftUI требует, чтобы любой асинхронный вызов (await) был сделан внутри асинхронного контекста, такого как Task.
///Асинхронные операции должны выполняться в асинхронных контекстах, таких как Task, чтобы избежать блокировки главного потока и поддерживать плавный и отзывчивый интерфейс.
///Task гарантирует, что код внутри будет выполняться в асинхронном контексте, а если задача приостанавливается (например, во время сетевого запроса), то выполнение будет продолжено позже, как только данные придут.

///Ключевое слово await означает, что выполнение данной задачи (Task) приостанавливается до тех пор, пока метод не завершится
///Всякий раз, когда вызывается асинхронная функция (отмеченная async), вы должны использовать await, чтобы указать, что выполнение «подождёт» окончания операции.

///GalleryCompositView(data: data, refreshAction: {
   /// await viewModel.fetchData()
///})
/// В данном случае, оборачивать await viewModel.fetchData() в Task не обязательно. Это связано с тем, что метод refreshAction в GalleryCompositView уже передан как асинхронное замыкание(let refreshAction: () async -> Void).
//print("did tap GalleryCompositView")

import SwiftUI

struct GalleryContentView: View {
    
    @EnvironmentObject var localization: LocalizationService
    @StateObject private var viewModel: GalleryContentViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: GalleryContentViewModel(firestoreService: FirestoreGetService(), errorHandler: SharedErrorHandler()))
        print("init GalleryContentView")
    }

    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .loading:
                ProgressView(Localized.Gallery.loading.localized())
            case .error(let error):
                ContentErrorView(error: error) {
                    refreshData()
                }
            case .content(let data):
                GalleryCompositView(data: data, refreshAction: {
                    print("did tap GalleryCompositView")
                    ImageCacheManager.shared.getCacheSize()
//                    await viewModel.fetchData()
                })
            }
        }
        .background(AppColors.background)
        .navigationTitle(Localized.Gallery.title.localized())
        .onAppear {
            refreshData()
        }
    }
    
    private func refreshData() {
        Task {
            await viewModel.checkAndRefreshIfNeeded()
        }
    }
}




//    @EnvironmentObject var galleryCoordinator:GalleryCoordinator
//        .toolbar{
//            ToolbarItem(placement: .topBarTrailing) {
//                Button(Localized.Home.addButton.localized()) {
//                    galleryCoordinator.navigateTo(page: .someHomeView)
//                }
//                .foregroundStyle(AppColors.activeColor)
//                .padding()
//                .disabled(viewModel.viewState.isError)
//            }
//        }
