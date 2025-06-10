//
//  OnboardingView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//



// MARK: - version OnboardingView  AnyLayout

//import SwiftUI
//import Combine
//
//struct OnboardingView: View {
//    @StateObject private var viewModel: OnboardingViewModel
//
//    @Namespace private var ns  // Для анимации элементов при смене ориентации
//
//    init() {
//        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onboardingService: OnboardingService()))
//    }
//
//    var body: some View {
//        ZStack {
//            AppColors.orange
//                .ignoresSafeArea()
//                .transition(.opacity)  // Плавная смена фона при изменениях
//
//            VStack {
//                // Основной контейнер страниц
//                TabView(selection: $viewModel.currentPage) {
//                    ForEach(viewModel.pages.indices, id: \.self) { index in
//                        OnboardingPageView(page: viewModel.pages[index], namespace: ns)
//                            .tag(index)
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                .animation(.easeInOut(duration: 0.25), value: viewModel.currentPage)
//
//                // Кнопки управления страницами
//                HStack {
//                    if viewModel.currentPage > 0 {
//                        Button(Localized.Onboarding.backButton.localized()) {
//                            withAnimation(.easeInOut(duration: 0.25)) {
//                                viewModel.previousPage()
//                            }
//                        }
//                        .padding(.leading)
//                    }
//                    Spacer()
//                    if viewModel.currentPage < viewModel.pages.count - 1 {
//                        Button(Localized.Onboarding.nextButton.localized()) {
//                            withAnimation(.easeInOut(duration: 0.25)) {
//                                viewModel.nextPage()
//                            }
//                        }
//                        .padding(.trailing)
//                    } else {
//                        Button(Localized.Onboarding.getStartedButton.localized()) {
//                            withAnimation(.easeInOut(duration: 0.25)) {
//                                viewModel.completeOnboarding()
//                            }
//                            // Здесь можно выполнить навигацию к основному экрану
//                        }
//                        .padding(.trailing)
//                    }
//                }
//                .padding()
//            }
//        }
//        .onAppear {
//            // Устанавливаем блокировку только на портрет
//            // AppDelegate.orientationLock = .portrait
//        }
//        .onDisappear {
//            // Возвращаем стандартную ориентацию для остальных экранов
//            // AppDelegate.orientationLock = .all
//        }
//    }
//}

// MARK: - version OnboardingView before private var layout: AnyLayout

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onboardingService: OnboardingService()))
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Основной контейнер страниц
                TabView(selection: $viewModel.currentPage) {
                    ForEach(viewModel.pages.indices, id: \.self) { index in
                        OnboardingPageView(page: viewModel.pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .animation(.easeInOut, value: viewModel.currentPage)
                
                // Кнопки управления страницами
                HStack {
                    if viewModel.currentPage > 0 {
                        Button(Localized.Onboarding.backButton.localized()) {
                            viewModel.previousPage()
                        }
                        .padding(.leading)
                    }
                    Spacer()
                    if viewModel.currentPage < viewModel.pages.count - 1 {
                        Button(Localized.Onboarding.nextButton.localized()) {
                            viewModel.nextPage()
                        }
                        .padding(.trailing)
                    } else {
                        Button(Localized.Onboarding.getStartedButton.localized()) {
                            viewModel.completeOnboarding()
                            // Здесь можно выполнить навигацию к основному экрану
                        }
                        .padding(.trailing)
                    }
                }
                .padding()
            }
            .background(AppColors.orange)
            .onAppear {
                // Устанавливаем блокировку только на портрет
                // AppDelegate.orientationLock = .portrait
            }
            .onDisappear {
                // При исчезновении возвращаем стандартную ориентацию для остальных экранов
                // AppDelegate.orientationLock = .all
            }
        }
    }
}


// MARK: - before networkMonitor
 
//struct OnboardingView: View {
//    @StateObject private var viewModel: OnboardingViewModel
//
//    init() {
//        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onboardingService: OnboardingService()))
//    }
//    
//    var body: some View {
//        VStack {
//            // Основной контейнер страниц
//            TabView(selection: $viewModel.currentPage) {
//                ForEach(viewModel.pages.indices, id: \.self) { index in
//                    OnboardingPageView(page: viewModel.pages[index])
//                        .tag(index)
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
//            .animation(.easeInOut, value: viewModel.currentPage)
//            
//            // Кнопки управления страницами
//            HStack {
//                if viewModel.currentPage > 0 {
//                    Button(Localized.Onboarding.backButton.localized()) {
//                        viewModel.previousPage()
//                    }
//                    .padding(.leading)
//                }
//                Spacer()
//                if viewModel.currentPage < viewModel.pages.count - 1 {
//                    Button(Localized.Onboarding.nextButton.localized()) {
//                        viewModel.nextPage()
//                    }
//                    .padding(.trailing)
//                } else {
//                    Button(Localized.Onboarding.getStartedButton.localized()) {
//                        viewModel.completeOnboarding()
//                        // Здесь можно выполнить навигацию к основному экрану
//                    }
//                    .padding(.trailing)
//                }
//            }
//            .padding()
//        }
//        .background(Color.orange)
//        .onAppear {
//            // Устанавливаем блокировку только на портрет
////            AppDelegate.orientationLock = .portrait
//        }
//        .onDisappear {
//            // При исчезновении возвращаем стандартную ориентацию для остальных экранов
////            AppDelegate.orientationLock = .all
//        }
////        .edgesIgnoringSafeArea(.all)
//    }
//}



// MARK: - first code

//struct OnboardingView: View {
//    
//    @StateObject private var viewModel: OnboardingViewModel
//    
//    init() {
//        _viewModel = StateObject(wrappedValue:  OnboardingViewModel(onboardingService: OnboardingService()))
//    }
//    var body: some View {
//        VStack {
//            ///TabView создаёт контейнер для вкладок или страниц.
//            ///Присваивает тег каждому представлению страницы. Это важно для отслеживания текущей страницы, когда пользователь переключается между ними.
//            ///index используется как тег для каждого представления страницы.
//            ///.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)): Применяет стиль для TabView, делая его выглядеть как прокручиваемые страницы.
//            ///PageTabViewStyle добавляет индикаторы страниц внизу (точки), показывая, на какой странице находится пользователь.
//            ///indexDisplayMode: .always заставляет всегда показывать индикаторы страниц.
//            TabView(selection: $viewModel.currentPage) {
//                ForEach(viewModel.pages.indices, id: \.self) { index in
//                    OnboardingPageView(page: viewModel.pages[index])
//                        .tag(index)
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
//            .animation(.easeInOut, value: viewModel.currentPage)
//            
//            HStack {
//                
//                if viewModel.currentPage > 0 {
//                    Button(Localized.Onboarding.backButton.localized()) {
//                        viewModel.previousPage()
//                    }
//                    .padding()
//                }
//                Spacer()
//                
//                if viewModel.currentPage < viewModel.pages.count - 1 {
//                    Button(Localized.Onboarding.nextButton.localized()) {
//                        viewModel.nextPage()
//                    }
//                    .padding()
//                } else {
//                    Button(Localized.Onboarding.getStartedButton.localized()) {
//                        viewModel.completeOnboarding()
//                        // Navigate to the main creen
//                        
//                    }
//                    .padding()
//                }
//                
//            }
//        }
//        /// failed attempt to change scroll indicator color
////        .tint(.blue) // Изменение цвета индикаторов
////        .accentColor(.blue)
//        .background(Color.orange)
//    }
//}
//
////#Preview {
////    OnboardingView()
////}
