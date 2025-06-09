//
//  Layout.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 6.06.25.
//

import Foundation
import SwiftUI



// MARK: -  механизм Layout’a в SwiftUI

///Принцип работы алгоритма простой: SwiftUI для каждого элемента в иерархии предлагает доступное место. Элемент на основе полученных данных решает, сколько места предложить дочерним внутри себя. После размещения элемент возвращает контейнеру размер, который ему необходим. Исходя из этой информации родитель располагает этот элемент внутри себя.
///
///На практике все чуть сложнее. В текущих версиях iOS мы взаимодействуем с механизмом Layout’a в основном через .frame модификатор. View в SwiftUI имеет несколько свойств и ограничений, определяющих необходимое ему место. Через .frame-модификатор можно указать максимальный, минимальный и идеальный размеры. Также у View есть предпочтения по отступам с разных сторон в различных контекстах, подробнее об этом написано в статье автора javier на swiftui-lab.
///
///При таком подходе в комбинации с .frame модификатором используются GeometryReader для прочтения предлагаемого контейнером размера и PreferenceKey для сохранения параметров одной или нескольких View, чтобы на их основании еще раз вернуться в корень иерархии и подкорректировать Layout.
///Такой подход абсолютно неочевиден, сильно усложняет код, а в случае с PreferenceKey при неправильном обращении может привести к бесконечному циклу Layout’ов и падению приложения.



// MARK: - protocol Layout : Animatable

//https://habr.com/ru/amp/publications/685374/

///Layout протокол - большой скачок для SwiftUI, решающий массу проблем. С его появлением в iOS 16 стало заметно проще решать задачи, связанные с выделением места и расположением элементов на экране с минимумом кода и максимумом читаемости. Но не стоит забывать, что этот новый инструмент пока на Бета-стадии, и до релиза он может добраться в несколько измененном виде. 

//https://swiftui-lab.com/frame-behaviors/


// MARK: -  AnyLayout

//let layout = isHorizontal ? AnyLayout(HStackLayout()): AnyLayout(BackslashStack())

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



// MARK: - ViewThatFits

///ViewThatFits — это мощный инструмент в SwiftUI, представленный в iOS 16, который помогает динамически выбирать лучшее представление из нескольких вариантов, основываясь на доступном пространстве. Он позволяет определить несколько представлений внутри контейнера, а затем автоматически отображает первое из них, которое умещается в предоставленной области.
///ViewThatFits рендерит только первый из перечисленных вариантов, который полностью умещается в отведенное пространство.
///Не нужно вручную рассчитывать размеры, ломать голову над конфигурациями — он делает всё это сам.
///Он не «сжимает» представления. Вместо этого ищет первый вариант, который вписывается в выделенные рамки.
///Если ни один из предоставленных вариантов в ViewThatFits не вписывается в доступное пространство, последний вариант из списка (ViewThatFits) будет выбран по умолчанию, даже если он не идеально подходит.
///Чтобы гарантировать, что хотя бы одно представление всегда корректно отображается, можно предусмотреть «резервный» вариант, который будет занимать минимум пространства.
///https://medium.com/nuances-of-programming/осваиваем-viewthatfits-часть-1-725cb277bd66




// MARK: - .fixedSize()

///Модификатор .fixedSize() в SwiftUI используется для того, чтобы зафиксировать размер view на её "идеальном" (intrinsic) размере, игнорируя внешние ограничения (например, от родительского контейнера). Это полезно, когда система автоматической компоновки пытается растянуть или сжать view, а вы хотите сохранить её естественный размер.
///https://swiftwithmajid.com/2020/04/29/the-magic-of-fixed-size-modifier-in-swiftui/






// MARK: - Layout Без ручных frame

//С iOS 16 можно довериться системе и устроить гибкий лэйаут без вычислений:

//struct OnboardingPageView: View {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    let page: OnboardingPage
//
//    var body: some View {
//        AdaptiveStack(orientationService.orientation)     // кастомный layout
//    }
//}
//
//// Простейший layout-переключатель
//@ViewBuilder
//private func AdaptiveStack(_ orientation: Orientation) -> some View {
//    if orientation == .landscape {
//        HStack(spacing: 24) {
//            Image(systemName: page.imageName)
//                .resizable().scaledToFit()
//                .frame(maxWidth: 180)                     // жёсткий верхний предел
//            VStack(alignment: .leading, spacing: 16) { … }
//            Spacer()
//        }
//        .padding()
//    } else {
//        VStack(spacing: 24) {
//            Image(systemName: page.imageName)
//                .resizable().scaledToFit()
//                .frame(maxHeight: 240)
//            VStack(spacing: 16) { … }
//        }
//        .padding(.horizontal)
//    }
//}



//Плюсы: минимальный хард-код, легко менять дизайн. Минусы: если нужно очень точное соотношение (0.247 ширины), придётся всё-таки знать размеры.





// MARK: - GeometryReader

//Почему UIScreen.main.bounds не всегда подходит?
///Проблемы с UIScreen.main.bounds - Он показывает размеры ВСЕГО экрана, а не окна приложения - В мультиоконности UIScreen.main.bounds ≠ GeometryReader.size - Не учитывает подключенный внешний дисплей
///Если приложение всегда полноэкранное (например, ты отключил Split View, Stage Manager), UIScreen.main.bounds может работать. Но если нужна адаптация, orientationService.containerSize гораздо надёжнее, потому что он даёт реальную ширину/высоту окна, а не общие параметры устройства.

// Почему GeometryReader «спамит» обновлениями?

///GeometryReader отдаёт новый geo.size каждый раз, когда меняется хоть один пиксель рамки содержащего окна. Когда пользователь:
///перетягивает разделитель Split View / Stage Manager (срабатывает десятки раз в секунду);
///открывает/закрывает клавиатуру (safe-area прыгает на 2 pt вверх-вниз);
///запускает анимацию, где вью слегка «дышит»; — onChange(of: geo.size) будет стрелять столько же раз.
///Если ты пересылаешь эти события напрямую в orientationService.update(by:), то сервис публикует изменения так же часто → все подписанные вью получают «Re-render!».

//Debounce — в двух словах

///debounce = «пропусти весь шум, дай только последнее значение, когда буря утихнет». Алгоритм:
///Приходит событие → запоминаем его, заводим таймер на N мс.
///Приходит следующее до истечения таймера → ⏹ отменяем старый таймер, заводим новый.
///Если в течение N мс ничего не случилось → 🔔 публикуем последнее значение.
///Итог: пока пользователь активно тянет окно, ты молчишь; отпустил — отдаёшь финальный размер.

///120 мс — комфортное значение: UI не «дёргается», но реагирует почти мгновенно после отпускания тач-пада.
///Хочешь моментальный отклик, но реже — сделай 60–80 мс.

//Краткий чек-лист

///RootSizeReader — один на приложение. - отдает нам размер с учетом Safe-area учитывает Dynamic Island / Home Indicator / статус-бар. если ты адаптируешь UI под Split View / Stage Manager, safe area полезна и лучше не добавлять .ignoreSafeArea
///GeometryReader описывает рамку окна (точнее — safe-area в пределах окна)
///orientationService.update(raw:) — вызываем оттуда.
///В сервисе debounce (Combine или GCD) → гладкие, редкие апдейты.
///Теперь даже если пользователь бешено таскает окно Stage Manager, подписчики увидят одно-единственное изменение, и у тебя не просядет FPS.


//Как «живёт» GeometryReader на самом верхнем уровне ?

///RootSizeReader сидит прямо в WindowGroup, а значит его GeometryReader описывает рамку окна (точнее — safe-area в пределах окна). SwiftUI пересчитывает эту рамку каждый раз, когда система делает новый layout-pass. Ниже перечислены все типичные события, которые заставляют этот layout-pass случиться и тем самым вызывают onChange(of: geo.size).

///Физический поворот устройства
///Триггеры: • Поворот iPhone / iPad между Portrait ⇄ Landscape. • Анимация смены ориентации длится ~0,3 секунды.
///яется: • Высота и ширина экрана меняются местами. • Safe-area-инсеты (например, от Dynamic Island) перерасчитываются.
///
///Мультизадачность iPad
///Триггеры: • Перетягивание разделителя Split View (70/30 → 50/50 → 30/70 и промежуточные шаги). • Изменение размеров окна Stage Manager. • Переключение между Slide Over и Split View.
///Что меняется: • Ширина и/или высота окна изменяются непрерывно (срабатывает каждый кадр при перетягивании).
///
///Перемещение на внешний дисплей
///Триггеры: • Перетаскивание окна Stage Manager на внешний монитор. • Изменение размера окна уже на внешнем экране.
///Что меняется: • Полностью новый CGRect окна. • Плотность точек (@2x vs @3x) и пропорции могут измениться.
///
///Системные оверлеи
///Триггеры: • Открытие клавиатуры → уменьшается высота доступного пространства. • Всплывающее уведомление (CallBar, PIP-видео, Screen Recording-бар). • Dynamic Island расширяется на iPhone 15 Pro.
///Что меняется: • geo.size.height уменьшается на высоту оверлея. • Safe-area перерасчитывается → элементы UI могут «поджаться» или сдвинуться.
///
///Временные системные анимации
///Триггеры: • Жест «назад» (свайп от края) слегка наклоняет окно. • Регулировка громкости → прозрачная палитра UI.
///Что меняется: • Во время анимации система пересчитывает layout каждую миллисекунду, но UI почти не меняется.
///
///Изменение доступности
///Триггеры: • Включение Лупы / Zoom в настройках. • Пользователь меняет режим Display Zoom (увеличенный размер элементов UI).
///Что меняется: • Система пересчитывает размеры окна, увеличивая/уменьшая pt-масштаб.
///
///На iPhone в полноэкранном режиме единственный часто встречающийся «шум» — анимация поворота + отображение клавиатуры; на iPad, где пользователь волен растягивать окно пиксель-за-пикселем, событий приходит значительно больше.

//Готовый код с debounce (Combine-версия)

//import Combine
//import SwiftUI
//
//@MainActor
//final class DeviceOrientationService: ObservableObject {
//
//    // Публичные данные для View
//    @Published private(set) var orientation: Orientation = .portrait
//    @Published private(set) var containerSize: CGSize    = .zero
//
//    // ---- internal ----
//    private let sizeSubject = PassthroughSubject<CGSize, Never>()
//    private var bag = Set<AnyCancellable>()
//
//    init(debounce: TimeInterval = 0.12) {
//        // ❶ Ловим все "сырые" размеры
//        sizeSubject
//            .removeDuplicates()                    // те же размеры — игнор
//            .debounce(for: .seconds(debounce),     // ❷ ждём затишья 120 мс
//                      scheduler: RunLoop.main)
//            .sink { [weak self] size in            // ❸ публикуем «чистое» значение
//                self?.apply(size)
//            }
//            .store(in: &bag)
//    }
//
//    // публичный «приёмник» из GeometryReader
//    func update(raw size: CGSize) {
//        sizeSubject.send(size)
//    }
//
//    // приватная логика ориентации
//    private func apply(_ size: CGSize) {
//        containerSize = size
//        orientation   = size.width > size.height ? .landscape : .portrait
//    }
//}

//Как использовать?

//struct RootSizeReader: View {
//    @EnvironmentObject var orientation: DeviceOrientationService
//
//    var body: some View {
//        GeometryReader { geo in
//            Color.clear
//                .onAppear                   { orientation.update(raw: geo.size) }
//                .onChange(of: geo.size) { new in orientation.update(raw: new) }
//        }
//    }
//}

// В вашем `TemplateSwiftUIProjectApp`:
//WindowGroup {
//    RootSizeReader()          // <-- вставляем
//    AppRootView(hasSeenOnboarding: hasSeenOnboarding)
//        .environmentObject(orientationService)
//        … остальные environment …
//}

//View

//struct OnboardingPageView: View {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    let page: OnboardingPage
//
//    private var size: CGSize { orientationService.containerSize }
//
//    var body: some View {
//        Group {
//            if orientationService.isLandscape {
//                HStack {
//                    Image(systemName: page.imageName)
//                        .resizable().scaledToFit()
//                        .frame(width: size.width * 0.2)
//
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text(page.title).font(.title).bold()
//                        Text(page.description)
//                    }.padding()
//                }
//            } else {
//                VStack(spacing: 16) {
//                    Image(systemName: page.imageName)
//                        .resizable().scaledToFit()
//                        .frame(height: size.height * 0.3)
//
//                    Text(page.title).font(.largeTitle).bold().padding(.horizontal)
//                    Text(page.description).padding(.horizontal)
//                }
//            }
//        }
//        .animation(.easeInOut, value: orientationService.orientation)
//    }
//}

