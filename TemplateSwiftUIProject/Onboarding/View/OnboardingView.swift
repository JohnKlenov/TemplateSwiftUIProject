//
//  OnboardingView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//

import SwiftUI

struct OnboardingView: View {
    
    @StateObject private var viewModel: OnboardingViewModel
    
    init(viewModel: OnboardingViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    var body: some View {
        VStack {
            ///TabView создаёт контейнер для вкладок или страниц.
            ///Присваивает тег каждому представлению страницы. Это важно для отслеживания текущей страницы, когда пользователь переключается между ними.
            ///index используется как тег для каждого представления страницы.
            ///.tabViewStyle(PageTabViewStyle(indexDisplayMode: .always)): Применяет стиль для TabView, делая его выглядеть как прокручиваемые страницы.
            ///PageTabViewStyle добавляет индикаторы страниц внизу (точки), показывая, на какой странице находится пользователь.
            ///indexDisplayMode: .always заставляет всегда показывать индикаторы страниц.
            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.pages.indices, id: \.self) { index in
                    OnboardingPageView(page: viewModel.pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .animation(.easeInOut, value: viewModel.currentPage)
            
            HStack {
                
                if viewModel.currentPage > 0 {
                    Button("Back") {
                        viewModel.previousPage()
                    }
                    .padding()
                }
                Spacer()
                
                if viewModel.currentPage < viewModel.pages.count - 1 {
                    Button("Next") {
                        viewModel.nextPage()
                    }
                    .padding()
                } else {
                    Button("Get started") {
                        viewModel.completeOnboarding()
                        // Navigate to the main creen
                        
                    }
                    .padding()
                }
                
            }
        }
        /// failed attempt to change scroll indicator color
//        .tint(.blue) // Изменение цвета индикаторов
//        .accentColor(.blue)
        .background(Color.orange)
    }
}

//#Preview {
//    OnboardingView()
//}
