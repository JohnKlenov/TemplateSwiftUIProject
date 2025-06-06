//
//  Layout.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 6.06.25.
//

import Foundation
import SwiftUI


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

