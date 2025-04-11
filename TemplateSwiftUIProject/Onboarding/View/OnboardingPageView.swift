//
//  OnboardingPageView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//

//ViewThatFits

///ViewThatFits — это мощный инструмент в SwiftUI, представленный в iOS 16, который помогает динамически выбирать лучшее представление из нескольких вариантов, основываясь на доступном пространстве. Он позволяет определить несколько представлений внутри контейнера, а затем автоматически отображает первое из них, которое умещается в предоставленной области.
///ViewThatFits рендерит только первый из перечисленных вариантов, который полностью умещается в отведенное пространство.
///Не нужно вручную рассчитывать размеры, ломать голову над конфигурациями — он делает всё это сам.
///Он не «сжимает» представления. Вместо этого ищет первый вариант, который вписывается в выделенные рамки.
///Если ни один из предоставленных вариантов в ViewThatFits не вписывается в доступное пространство, последний вариант из списка (ViewThatFits) будет выбран по умолчанию, даже если он не идеально подходит.
///Чтобы гарантировать, что хотя бы одно представление всегда корректно отображается, можно предусмотреть «резервный» вариант, который будет занимать минимум пространства.
///https://medium.com/nuances-of-programming/осваиваем-viewthatfits-часть-1-725cb277bd66

//.fixedSize()
///Модификатор .fixedSize() в SwiftUI используется для того, чтобы зафиксировать размер view на её "идеальном" (intrinsic) размере, игнорируя внешние ограничения (например, от родительского контейнера). Это полезно, когда система автоматической компоновки пытается растянуть или сжать view, а вы хотите сохранить её естественный размер.
///https://swiftwithmajid.com/2020/04/29/the-magic-of-fixed-size-modifier-in-swiftui/

import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        GeometryReader { geometry in
            // Определяем ориентацию: если ширина больше высоты – ландшафт.
            let isLandscape = geometry.size.width > geometry.size.height
            
            Group {
                if isLandscape {
                    // Горизонтальная компоновка для ландшафтного режима:
                    HStack {
                        Image(systemName: page.imageName)
                            .resizable()
                            .scaledToFit()
                            // Задаём ширину как долю от доступной ширины
                            .frame(width: geometry.size.width * 0.2)
//                            .background(.red)
                        VStack(alignment: .leading, spacing: 16) {
                            Text(page.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.leading)
                            Text(page.description)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                    }
                } else {
                    // Вертикальная компоновка для портретного режима:
                    VStack(spacing: 16) {
                        Image(systemName: page.imageName)
                            .resizable()
                        ///Используя .scaledToFit без явного задания высоты(.frame(height: geometry.size.height * 0.3)), система гарантирует сохранение пропорций изображения, а высота подстроится автоматически под указанную ширину.
                            .scaledToFit()
                            // Задаём высоту как долю от общей высоты экрана
                            .frame(height: geometry.size.height * 0.3)
//                            .background(.red)
                        Text(page.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text(page.description)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            // Анимация сглаживает переход при изменении ориентации
            .animation(.easeInOut, value: isLandscape)
        }
    }
}


// MARK: - ViewThatFits + .fixedSize

//struct OnboardingPageView: View {
//    let page: OnboardingPage
//    // Отслеживаем горизонтальный size class (напр., для iPad или iPhone)
//    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//
//    var body: some View {
//        GeometryReader { geometry in
//            // ViewThatFits попытается отобразить первое представление, которое хорошо вмещается.
//            // Здесь мы предлагаем два варианта компоновки: горизонтальный и вертикальный.
//            ViewThatFits {
////                // Горизонтальное расположение — для регулярного size class или когда ширина больше высоты
////                if horizontalSizeClass == .regular || geometry.size.width > geometry.size.height {
//                    HStack(spacing: 16) {
//                        Image(systemName: page.imageName)
//                            .resizable()
//                            .scaledToFit()
//                            // Изображение займёт 40% от ширины контейнера
//                            .frame(width: geometry.size.width * 0.5)
//
//                        VStack(alignment: .leading, spacing: 8) {
//                            Text(page.title)
//                                .font(.title)
//                                .fontWeight(.bold)
//                            Text(page.description)
//                                .font(.body)
//                        }
//                        .padding()
//                    }
//
//                // Вертикальное расположение — для компактного width (например, на iPhone в портретном режиме)
//                VStack(spacing: 16) {
//                    Image(systemName: page.imageName)
//                        .resizable()
//                        .scaledToFit()
//                        // Изображение ограничено примерно 30% от высоты экрана
//                        .frame(height: geometry.size.height * 0.2)
//                    Text(page.title)
//                        .font(.largeTitle)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                    Text(page.description)
//                        .font(.body)
//                        .multilineTextAlignment(.center)
//                }
//                .padding()
//            }
//
//            .frame(width: geometry.size.width, height: geometry.size.height)
//            // Анимация сглаживает переход при изменении размеров контейнера/ориентации
////            .animation(.easeInOut, value: geometry.size)
//        }
//    }
//}


// MARK: - first code

//struct OnboardingPageView: View {
//    
//    let page:OnboardingPage
//    var body: some View {
//        VStack {
//            Image(systemName: page.imageName)
//                .resizable()
//                .scaledToFit()
//                .frame(height: 200)
//            Text(page.title)
//                .font(.largeTitle)
//                .padding()
//            Text(page.description)
//                .font(.body)
//                .padding()
//        }
//    }
//}
//
//#Preview {
//    OnboardingPageView(page: OnboardingPage(title: "Welcome", description: "Welcome to our app", imageName: "house.fill"))
//}
