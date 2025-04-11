//
//  OnboardingView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//

import SwiftUI


import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    init() {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(onboardingService: OnboardingService()))
    }
    
    var body: some View {
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
        .background(Color.orange)
//        .edgesIgnoringSafeArea(.all)
    }
}



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
