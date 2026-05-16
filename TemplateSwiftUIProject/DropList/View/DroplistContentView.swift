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
    
    @EnvironmentObject var homeCoordinator: HomeCoordinator
    @EnvironmentObject var localization: LocalizationService
    @EnvironmentObject var retryHandler: GlobalRetryHandler
    
    var body: some View {
        ZStack {
            switch viewModel.viewState {
                
            case .loading:
                ProgressView(Localized.Home.loading.localized())
                
            case .myTracks:
                // На HomeContentView мы НЕ отображаем треки
                ProgressView(Localized.Home.loading.localized())
                
            case .contentList(let dropData):
                DroplistCompositView(data: dropData, onRefresh: {
                    <#code#>
                }, onSelectCarouselItem: { <#CarouselItem#> in
                    <#code#>
                }, onLoadNextPage: { <#CarouselItem#> in
                    <#code#>
                }, onSelectLowerItem: { <#LowerItem#> in
                    <#code#>
                })
//                DroplistCompositView(
//                    data: dropData,
//                    onRefresh: {
//                        viewModel.refreshDropList()
//                    }
//                )
                
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
                        BookEditView(
                            managerCRUDS: viewModel.managerCRUDS,
                            presentEditView: "HomeView"
                        )
                    )
                    homeCoordinator.presentSheet(SheetItem(content: sheetContent))
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
