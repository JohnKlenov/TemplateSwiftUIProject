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

//    private var size: CGSize { orientationService.containerSize }


// MARK: - version OnboardingPageView simple animation



//import SwiftUI
//
//struct OnboardingPageView: View {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    let page: OnboardingPage                        // модель страницы
//
//    var body: some View {
//        GeometryReader { geo in                     // нужен только размер окна
//            ZStack {                                // кладём две компоновки «друг на друга»
//                
//                // ── ПОРТРЕТ ───────────────────────────────────────────────
//                PortraitContent(page: page, maxHeight: geo.size.height)
//                    .opacity(orientationService.orientation == .portrait ? 1 : 0)
//                    .offset(x: 0,
//                            y: orientationService.orientation == .portrait ? 0 : 40)
//                
//                // ── ЛАНДШАФТ ─────────────────────────────────────────────
//                LandscapeContent(page: page, maxWidth: geo.size.width)
//                    .opacity(orientationService.orientation == .landscape ? 1 : 0)
//                    .offset(x: orientationService.orientation == .landscape ? 0 : 40,
//                            y: 0)
//            }
//            .padding()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .animation(.easeInOut(duration: 0.35),       // одна-единственная анимация
//                       value: orientationService.orientation)
//        }
//    }
//}
//
//// MARK: 2 «чистых» под-вью вместо AnyLayout / matchedGeometryEffect
////       (их кадры просто «выплывают» или «уплывают» через opacity + offset)
//
//private struct PortraitContent: View {
//    let page: OnboardingPage
//    let maxHeight: CGFloat
//
//    var body: some View {
//        VStack(spacing: 24) {
//            Image(systemName: page.imageName)
//                .resizable()
//                .scaledToFit()
//                .frame(height: maxHeight * 0.30)
//
//            Text(page.title)
//                .font(.largeTitle).bold()
//                .multilineTextAlignment(.center)
//
//            Text(page.description)
//                .multilineTextAlignment(.center)
//        }
//    }
//}
//
//private struct LandscapeContent: View {
//    let page: OnboardingPage
//    let maxWidth: CGFloat
//
//    var body: some View {
//        HStack(spacing: 24) {
//            Image(systemName: page.imageName)
//                .resizable()
//                .scaledToFit()
//                .frame(width: maxWidth * 0.20)
//
//            VStack(alignment: .leading, spacing: 16) {
//                Text(page.title)
//                    .font(.title).bold()
//                    .multilineTextAlignment(.leading)
//
//                Text(page.description)
//                    .multilineTextAlignment(.leading)
//            }
//        }
//    }
//}



// MARK: - version OnboardingPageView  AnyLayout

// AnyLayout

// Как добиться «шёлковой» анимации при смене ориентации?
///Раздражающий «рывок» появляется, когда SwiftUI выкидывает один стек (HStack) и заново строит другой (VStack). Дадим системе шанс плавно «перераскладывать» те же субвью, а не пересоздавать их.
///AnyLayout (iOS 16+) умеет анимировать переход между любыми двумя Layout-типами. Меняем один-единственный объект layout вместо if/else с разными стеками.
///
///

//import SwiftUI
//
//struct OnboardingPageView: View {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    let page: OnboardingPage
//    let namespace: Namespace.ID   // Передаём идентификатор для `matchedGeometryEffect`
//
//    private var layout: AnyLayout {
//        orientationService.orientation == .landscape
//        ? AnyLayout(HStackLayout(spacing: 24))
//        : AnyLayout(VStackLayout(spacing: 24))
//    }
//
//    var body: some View {
//        layout {
//            Image(systemName: page.imageName)
//                .resizable()
//                .scaledToFit()
//                .frame(maxWidth: 180, maxHeight: 240)
//                .matchedGeometryEffect(id: "image\(page.id)", in: namespace)
//
//            VStack(alignment: .leading, spacing: 16) {
//                Text(page.title)
//                    .font(.title).bold()
//                    .multilineTextAlignment(
//                        orientationService.orientation == .landscape ? .leading : .center
//                    )
//                Text(page.description)
//                    .font(.body)
//                    .multilineTextAlignment(
//                        orientationService.orientation == .landscape ? .leading : .center
//                    )
//            }
//            .matchedGeometryEffect(id: "text\(page.id)", in: namespace)
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .animation(.easeInOut(duration: 0.35), value: orientationService.orientation)
//    }
//}

//struct OnboardingPageView: View {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    let page: OnboardingPage
//    @Namespace private var ns                       // для matchedGeometry
//
//    private var layout: AnyLayout {
//        orientationService.orientation == .landscape
//        ? AnyLayout(HStackLayout(spacing: 24))
//        : AnyLayout(VStackLayout(spacing: 24))
//    }
//
//    var body: some View {
//        layout {
//            Image(systemName: page.imageName)
//                .resizable()
//                .scaledToFit()
//                .frame(maxWidth: 180, maxHeight: 240)   // обе ориентации сразу
//                .matchedGeometryEffect(id: "image\(page.id)", in: ns)
//
//            VStack(alignment: .leading, spacing: 16) {
//                Text(page.title)
//                    .font(.title).bold()
//                    .multilineTextAlignment(
//                        orientationService.orientation == .landscape ? .leading : .center
//                    )
//                Text(page.description)
//                    .font(.body)
//                    .multilineTextAlignment(
//                        orientationService.orientation == .landscape ? .leading : .center
//                    )
//            }
//            .matchedGeometryEffect(id: "text\(page.id)", in: ns)
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        // ОДНА глобальная анимация для всех изменений
//        .animation(.easeInOut(duration: 0.35), value: orientationService.orientation)
//    }
//}

// MARK: - version OnboardingPageView before private var layout: AnyLayout

//import SwiftUI
//
//struct OnboardingPageView: View {
//
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    let page: OnboardingPage
//
//
//    var body: some View {
//        AdaptiveStack(orientationService.orientation)     // кастомный layout
//
//    }
//
//    // Простейший layout-переключатель
//    @ViewBuilder
//    private func AdaptiveStack(_ orientation: Orientation) -> some View {
//        if orientation == .landscape {
//            HStack(spacing: 24) {
//                Image(systemName: page.imageName)
//                    .resizable().scaledToFit()
//                    .frame(maxWidth: 180)                     // жёсткий верхний предел
//                VStack(alignment: .leading, spacing: 16) {
//                    Text(page.title)
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.leading)
//                    Text(page.description)
//                        .font(.body)
//                        .multilineTextAlignment(.leading)
//                }
//                .padding()
//            }
//        } else {
//            VStack(spacing: 24) {
//                Image(systemName: page.imageName)
//                    .resizable()
//                ///Используя .scaledToFit без явного задания высоты(.frame(height: geometry.size.height * 0.3)), система гарантирует сохранение пропорций изображения, а высота подстроится автоматически под указанную ширину.
//                    .scaledToFit()
//                // Задаём высоту как долю от общей высоты экрана
//                //                            .frame(height: size.height * 0.3)
//                    .frame(maxHeight: 240)
//                //                            .background(.red)
//                Text(page.title)
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//                Text(page.description)
//                    .font(.body)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//            }
//            .padding(.horizontal)
//        }
//    }
//
//}
//
//
// MARK: - version OnboardingPageView before @EnvironmentObject private var orientationService: DeviceOrientationService


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
//
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
