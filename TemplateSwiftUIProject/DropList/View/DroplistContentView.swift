//
//  DroplistContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

// тут нужно все наши call back в DroplistCompositView связать с соответствующими вызовами в DroplistViewModel
// но перед этим нужно ответить на вопрос как мы будем обрабатывать ошибки которые придут из сети, то есть как будет реагировать UI

import SwiftUI

struct DroplistContentView: View {
    
    @ObservedObject var viewModel: DroplistViewModel
    
    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
    @EnvironmentObject var localization: LocalizationService
    @EnvironmentObject var retryHandler: GlobalRetryHandler
    
    var body: some View {
        ZStack {
            switch viewModel.viewState {
                
            case .loading:
                ProgressView(Localized.Home.loading.localized())
                
            case .myTracks:
                // На DroplistContentView мы НЕ отображаем треки
                ProgressView(Localized.Home.loading.localized())
                
            case .contentList(let dropData):
                DroplistCompositView(data: dropData, onRefresh: {
                    Task { await viewModel.refreshDropList() }
                }, onSelectCarouselItem: { carouselItem in
                    print("onSelectCarouselItem - \(carouselItem)")
                    Task { await viewModel.didSelectCarouselItem(carouselItem) }
                }, onLoadNextPage: { carouselItem in
                    print("onLoadNextPage - \(carouselItem)")
                }, onSelectLowerItem: { lowerItem in
                    print("onSelectLowerItem - \(lowerItem)")
                })
                
                // При смене viewState (с .contentList на .error) SwiftUI полностью удаляет старый View из иерархии.
                // Поэтому DroplistCompositView исчезает, и его refresh/pull-to-refresh больше недоступны.
                // нужно протестировать иначе нужно блокировать вызов func refreshDropList()
            case .error(let error):
                ContentErrorView(error: error) {
                    viewModel.retry()
                }
                
            case .errorList(let error):
                ContentErrorView(error: error) {
                    viewModel.retryFetchDataDroplist()
                }
            }
        }
        .background(AppColors.background)
        .navigationTitle(Localized.Home.title.localized())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(Localized.Home.addButton.localized()) {
                    let sheetContent = AnyView(
                        AdminView()
                    )
                    droplistCoordinator.presentSheet(SheetItem(content: sheetContent))
                }
                .foregroundStyle(AppColors.activeColor)
                .padding()
                .disabled(viewModel.viewState.isError)
            }
        }
        .onFirstAppear {
            viewModel.setRetryHandler(retryHandler)
            viewModel.setupViewModel()
        }
        .onAppear {
            // 
            Task { await viewModel.checkAndRefreshIfNeeded() }
        }

    }
}


//// Временный заглушечный DropListView
//struct DroplistCompositView: View {
//    let data: DropData
//    let onRefresh: () -> Void
//    
//    var body: some View {
//        VStack {
//            Text("DropListView")
//            Button("Refresh") {
//                onRefresh()
//            }
//        }
//    }
//}
