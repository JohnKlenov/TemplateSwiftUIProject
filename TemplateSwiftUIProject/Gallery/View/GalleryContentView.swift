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
            Task {
                await viewModel.checkAndRefreshIfNeeded()
            }
        }
    }
}
