//
//  OnboardingPageView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//



// MARK: - version OnboardingPageView  AnyLayout


// MARK: -  AnyLayout

// Как добиться «шёлковой» анимации при смене ориентации?
///Раздражающий «рывок» появляется, когда SwiftUI выкидывает один стек (HStack) и заново строит другой (VStack). Дадим системе шанс плавно «перераскладывать» те же субвью, а не пересоздавать их.
///AnyLayout (iOS 16+) умеет анимировать переход между любыми двумя Layout-типами. Меняем один-единственный объект layout вместо if/else с разными стеками.
///
///До iOS 16, когда мы хотим переключаться между различными макетами, мы должны полагаться на оператор if.
///SwiftUI рассматривает переключение макетов, подобное как удаление и добавление нового макета.
///В результате вы увидите затухающий переход.
///SwiftUI рассматривает переключение макета с if-else как замену старого макета на новый.

///AnyLayout введен для сглаживания перехода между макетами.
///Это экземпляр протокола Layout, стираемый по типу. Использование экземпляра AnyLayout позволяет нам изменять типы макетов, не разрушая состояние базовых подпросмотров.
///Поскольку идентичность иерархии представлений всегда остается неизменной, SwiftUI рассматривает это как вид, который меняется, а не как новый вид, как if-else.
///Обратите внимание, что типы, которые вы используете с AnyLayout, должны соответствовать протоколу Layout. SwiftUI создает четыре новые версии существующих макетов для использования с AnyLayout, HStackLayout, VStackLayout, ZStackLayout и GridLayout.
///С помощью этого простого изменения SwiftUI может создать плавный переход между различными типами макета.
///AnyLayoutработает с любым макетом, соответствующим протоколу Layout. Сюда входит пользовательский макет, который вы создали.
///let layout = isHorizontal ? AnyLayout(HStackLayout()): AnyLayout(BackslashStack())


// MARK: - matchedGeometryEffect

//мы просто указали как должны распологаться эти view а swiftUI уже сам смог все это про анимировать.

//@Namespace

///В SwiftUI — @Namespaceэто оболочка свойств, используемая для создания пространства имен для координации анимаций между различными представлениями. Обычно используется, когда требуется создать плавные переходы между представлениями, особенно во время навигации или изменения состояния представления.
///При использовании @Namespaceоболочки свойств SwiftUI может отслеживать идентичность представлений при переходах и применять анимацию более плавно. Это особенно полезно, когда у вас есть связанные представления, которые могут присутствовать в разных состояниях, например, в панели вкладок или представлении навигации.
///
///В этом примере @Namespace свойство namespace используется для создания общего пространства имен для matchedGeometryEffect. matchedGeometryEffect Позволяет Image плавно поменяться местами с VStack  при переходе из HStackLayout в VStackLayout.
///
///Имейте в виду, что @Namespaceон часто используется в сочетании с другими функциями SwiftUI, такими как matchedGeometryEffect, и играет решающую роль в создании плавной и визуально привлекательной анимации между различными представлениями.

//MatchedGeometryEffect

///Это модификатор который позволяет сопостовлять некоторые View между собой.
///И с помощью магии под капотом SwiftUI она становится более простой для нас, для написания но и более красивой для пользователя.
///Для того что бы использовать MatchedGeometryEffect мы объявляем @Namespace в котором будет происходить эта анимация.
///И мы должны применить модификаторы на View.
///И мы говорим что к определенным view мы должны относится как к одной

//@Namespace + matchedGeometryEffect связывают «до» и «после».
//AnyLayout позволяет сменить горизонтальный ↔︎ вертикальный алгоритм, не разрушая дерево View.
//Вся группа обёрнута одной animation(.easeInOut(duration: 0.35), value: orientationService.orientation), поэтому весь «переезд» работает одним синхронным тайм-лайном.
//В результате картинка и текст «скользят» в нужные места, а не исчезают и появляются заново.

//тайм лайн
///В контексте анимации синхронный тайм-лайн означает, что все связанные элементы двигаются по единому ритму, используя один временной диапазон.
///Синхронный тайм-лайн создаёт ощущение естественности, когда все элементы UI изменяются как одно целое. 🟢 В SwiftUI для этого используются: ✔ Единое управляемое состояние (@State) для связанных объектов. ✔ Общий withAnimation, чтобы все анимации стартовали вместе. ✔ matchedGeometryEffect, чтобы создавать плавный переход форм и позиций.

import SwiftUI

struct OnboardingPageView: View {
    @EnvironmentObject private var orientationService: DeviceOrientationService
    let page: OnboardingPage
    let namespace: Namespace.ID   // Передаём идентификатор для `matchedGeometryEffect`

    private var layout: AnyLayout {
        orientationService.orientation == .landscape
        ? AnyLayout(HStackLayout(spacing: 24))
        : AnyLayout(VStackLayout(spacing: 24))
    }

    var body: some View {
        layout {
            Image(systemName: page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 180, maxHeight: 240)
                .matchedGeometryEffect(id: "image\(page.id)", in: namespace)

            VStack(alignment: .leading, spacing: 16) {
                Text(page.title)
                    .font(.title).bold()
                    .multilineTextAlignment(
                        orientationService.orientation == .landscape ? .leading : .center
                    )
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(
                        orientationService.orientation == .landscape ? .leading : .center
                    )
            }
            .matchedGeometryEffect(id: "text\(page.id)", in: namespace)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.35), value: orientationService.orientation)
    }
}



// MARK: - version OnboardingPageView before private var layout: AnyLayout with GeometryReader



//import SwiftUI
//
//struct OnboardingPageView: View {
//    let page: OnboardingPage
//    
//    var body: some View {
//        GeometryReader { geometry in
//            // Определяем ориентацию: если ширина больше высоты – ландшафт.
//            let isLandscape = geometry.size.width > geometry.size.height
//            
//            Group {
//                if isLandscape {
//                    // Горизонтальная компоновка для ландшафтного режима:
//                    HStack {
//                        Image(systemName: page.imageName)
//                            .resizable()
//                            .scaledToFit()
//                            // Задаём ширину как долю от доступной ширины
//                            .frame(width: geometry.size.width * 0.2)
////                            .background(.red)
//                        VStack(alignment: .leading, spacing: 16) {
//                            Text(page.title)
//                                .font(.title)
//                                .fontWeight(.bold)
//                                .multilineTextAlignment(.leading)
//                            Text(page.description)
//                                .font(.body)
//                                .multilineTextAlignment(.leading)
//                        }
//                        .padding()
//                    }
//                } else {
//                    // Вертикальная компоновка для портретного режима:
//                    VStack(spacing: 16) {
//                        Image(systemName: page.imageName)
//                            .resizable()
//                        ///Используя .scaledToFit без явного задания высоты(.frame(height: geometry.size.height * 0.3)), система гарантирует сохранение пропорций изображения, а высота подстроится автоматически под указанную ширину.
//                            .scaledToFit()
//                            // Задаём высоту как долю от общей высоты экрана
//                            .frame(height: geometry.size.height * 0.3)
////                            .background(.red)
//                        Text(page.title)
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//                        Text(page.description)
//                            .font(.body)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//                    }
//                }
//            }
//            .frame(width: geometry.size.width, height: geometry.size.height)
//            // Анимация сглаживает переход при изменении ориентации
//            .animation(.easeInOut, value: isLandscape)
////            .onAppear {
////                print("Initial size: \(geometry.size)")
////            }
////            .onChange(of: geometry.size) { olodSize, newSize in
////                print("Updated size: \(newSize)")
////            }
//        }
//    }
//}




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
