//
//  HomeView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI
import Combine



import SwiftUI


struct HomeView: View {
    
    @StateObject private var viewModel: HomeViewModel
    
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else {
                List(viewModel.data, id: \.self) { item in
                    Text(item)
                }
                ///.alert(isPresented: $showAlert, error: error)
                /// Используя Binding<Bool>, ты создаёшь двустороннюю привязку к свойству errorMessage
                /// get: Возвращает true, если errorMessage не равно nil, что означает, что есть ошибка, и алерт должен быть показан.
                /// set: Если newValue равен false (то есть, когда алерт закрывается), устанавливает errorMessage в nil, что скрывает алерт.
                .alert("Error", isPresented:  Binding<Bool>(
                    get: { viewModel.errorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            viewModel.errorMessage = nil
                        }
                    }
                )) {
                    Button("Retry") {
                        viewModel.retry()
                    }
                    Button("Cancel", role: .cancel) {
                        print("didTapAlertCancel")
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "Try again later")
                }
            }
        }
    }
    
}

//struct HomeView: View {
//    
//    @StateObject private var viewModel: HomeViewModelWrapper
//    
//    ///Таким образом, ты говоришь компилятору, что viewModel может быть любого типа, который соответствует HomeViewModelProtocol.
//    init(viewModel: any HomeViewModelProtocol) {
//        _viewModel = StateObject(wrappedValue: HomeViewModelWrapper(wrapped: viewModel))
//    }
//    
//    var body: some View {
//        ZStack {
//            if viewModel.isLoading {
//                ProgressView("Loading...")
//            } else {
//                List(viewModel.data, id: \.self) { item in
//                    Text(item)
//                }
//                ///.alert(isPresented: $showAlert, error: error)
//                .alert("Error", isPresented:  Binding<Bool>(
//                    get: { viewModel.errorMessage != nil },
//                    set: { newValue in
//                        if !newValue {
//                            viewModel.errorMessage = nil
//                        }
//                    }
//                )) {
//                    Button("Retry") {
//                        viewModel.retry()
//                    }
//                    Button("Cancel", role: .cancel) {
//                        print("didTapAlertCancel")
//                    }
//                } message: {
//                    Text(viewModel.errorMessage ?? "Try again later")
//                }
//            }
//        }
//    }
//}






//#Preview {
//    HomeView()
//}




// MARK: - Trush

//    @ObservedObject private var viewModelWrapper: AnyViewModelWrapper
//
//    init(viewModel: any HomeViewModelProtocol) {
//        self.viewModelWrapper = AnyViewModelWrapper(wrapped: viewModel)
//    }

//struct HomeView: View {
//
//    @StateObject private var viewModel: HomeViewModel
//
//        init(viewModel: HomeViewModel) {
//            _viewModel = StateObject(wrappedValue: viewModel)
//        }
//
//    var body: some View {
//        ZStack {
//
//        }
//
//    }
//}

//            Color.purple
//                .ignoresSafeArea()
//            Text("I'm Home")
//                .font(.system(.largeTitle, design: .monospaced, weight: .black))
