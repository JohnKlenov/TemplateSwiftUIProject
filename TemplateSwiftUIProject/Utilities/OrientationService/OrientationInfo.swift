//
//  OrientationInfo.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.05.25.


// MARK: - DeviceOrientationService

// будем синхронизировать данные из сервиса ориентации с локальными размерами GeometryReader.





// MARK: - GeometryReader how main listener orientation

// если мы хотим из DeviceOrientationService передавать текущий размер контейнера и ориентацию одновременно
// мы можем сделать RootSizeReader основным для определения оринатции по принципц ширина больше высоты мы в ландшафте а после этого сравниить с UIDevice
// и тогда как только мы определяем нашу ориентацию мы можем изменить состояние @Published private(set) var orientation и в DeviceOrientationService на текущий момент уже будет размер контейнера с которым можно будет раьотать.

//Подход A. Не морочиться — оставить как есть или Подход B. Свести источники в один сервис (рекомендуемый) / Подход C. Комбинировать прямо в View (CombineLatest)
//Когда вы используете и DeviceOrientationService и GeometryReader в одном View, могут возникать:
///Конфликты данных - Системная ориентация и размеры контейнера могут временно не совпадать
///Разная скорость обновления - UIDevice.orientation обновляется быстрее, чем GeometryReader
///Дребезг значений - Особенно при анимациях поворота

// MARK: - Adaptive UI (iPod + iOS)

// оставим поддержку iPad но отключу режимы Split View, Slide Over, Stage Manager в info.plist
///
///Запрещает запуск приложения в Split View и Slide Over — оно всегда будет работать только полноэкранно.
///В iPadOS 16+ Stage Manager позволяет пользователям масштабировать окна вручную, но ты можешь запретить поддержку внешнего экрана:
///Обеспечивает только полноэкранный запуск, без поддержки оконного режима.
///Stage Manager не будет работать, потому что приложение всегда занимает весь экран.


// MARK: - Setting

//var isRotationLocked
///let supportedOrientations = UIApplication.shared.supportedInterfaceOrientations(for: nil) - Запрашивает разрешённые ориентации экрана для текущего приложения.
///Чем это управляется? - Info.plist (UISupportedInterfaceOrientations), AppDelegate (application(_:supportedInterfaceOrientationsFor:)), UIViewController.supportedInterfaceOrientations (в текущем VC)
///supportedOrientations → это маска (UIInterfaceOrientationMask), содержащая допустимые ориентации (.portrait, .landscapeLeft, .landscapeRight и т. д.).
///return supportedOrientations == .portrait || supportedOrientations.isSubset(of: .portrait) - Проверяем, заблокирован ли поворот
///Возвращает true, если приложение разрешает только портретную ориентацию.
///если в Info.plist записано только .portrait, то считается, что поворот заблокирован.
///supportedOrientations.isSubset(of: .portrait) - Проверяет, содержит ли маска только портретную ориентацию. Это помогает поймать ситуацию, когда кроме .portrait вообще ничего не разрешено.
///Если в supportedOrientations есть только .portrait → isSubset(of: .portrait) == true. ❌ Если там есть и .portrait, и .landscapeLeft → isSubset(of: .portrait) == false.
///Результат: Если в supportedOrientations есть только портрет — isRotationLocked == true. Если разрешены ландшафтные режимы — isRotationLocked == false.
///Этот код проверяет, заблокирован ли экран в портретном режиме. Он помогает понять, будет ли приложение переключаться в .landscape, и правильно адаптировать UI.
///
///Почему не достаточно одной проверки supportedOrientations == .portrait?
///isRotationLocked становится более надёжным и учитывает больше сценариев!
///supportedOrientations == .portrait // `true`, если приложение поддерживает ТОЛЬКО портрет! Но если supportedOrientations содержит ещё и ландшафт, сравнение вернёт false, даже если приложение в портретном режиме.
///supportedOrientations.isSubset(of: .portrait) // `true`, если доступны ТОЛЬКО портретные режимы
///Эта проверка нужна, чтобы убедиться, что в supportedOrientations нет никаких других ориентаций кроме .portrait.
///Этот метод определяет, содержит ли текущая маска ТОЛЬКО .portrait, даже если в Info.plist явно перечислены .portrait, .portraitUpsideDown (что всё равно является портретной ориентацией).
///Первая (== .portrait) ловит ровно один вариант: чистый портрет без других ориентаций. 🔹 Вторая (isSubset(of: .portrait)) дополнительно проверяет, что в маске разрешений нет ничего кроме портретных режимов.
///Оператор || (логическое ИЛИ) означает, что если любая из двух проверок вернёт true, вся конструкция тоже будет true.
///то есть если бы мы оставили только supportedOrientations == .portrait и в supportedOrientations было бы (.portrait, .portraitUpsideDown) то результат был бы false но он бы нам подошел!

//var currentInterfaceOrientation: UIInterfaceOrientation
///Что делает currentInterfaceOrientation?
///Это новый способ получения ориентации, появившийся в iOS 16+.
///currentInterfaceOrientation точнее определяет как выглядит UI, а не как повернуто устройство. ✅ Он полезен в адаптивных приложениях, особенно с Split View, Stage Manager. ✅ Использование default в switch позволяет обработать случаи, когда UIDevice.orientation даёт ошибочные данные.
///currentInterfaceOrientation — это ваш вспомогательный геттер, который вы, скорее всего, добавили в DeviceOrientationService. Он просто достаёт поле interfaceOrientation у первой активной UIWindowScene.(WindowGroup — это декларативная «обёртка» над UIKit-сценой. в любом SwiftUI-приложении (кроме виджета) хотя бы одна UIWindowScene существует автоматически, даже если вы никогда не видели её в коде.)
/// default ловит все «грязные» ситуации • .unknown, .faceUp, .faceDown (устройство на столе лицом вверх или вниз)
/// Минимум вычислений Проверить UIDevice.orientation дешевле, чем каждый раз искать активную UIWindowScene и дёргать её interfaceOrientation. Мы делаем это лишь тогда, когда датчик не дал однозначного ответа.

//UIDevice.orientation  vs currentInterfaceOrientation
///«Датчик-чайник» — UIDevice.orientation
///«Оркестр-дирижёр» — UIWindowScene.interfaceOrientation (то, что мы читаем как currentInterfaceOrientation)
///
///Как думает датчик (UIDevice.orientation)
///Он тупо подслушивает акселерометр: «Корпус повернули на 90°? Супер, ставлю .landscapeLeft. Лежим экраном вверх? Ну ок, .faceUp. Вообще не понимаю, что происходит? Ладно, кину .unknown.»
///Проблема: датчик ничего не знает про твоё приложение, про разрешённые ориентации или про Split View. Он честно докладывает положение устройства, но это ноль пользы, когда UI жить не хочет в ландшафте.
///
///Как думает дирижёр (currentInterfaceOrientation)
///Сначала к нему приходят сырые данные того же датчика.
///Он смотрит, что разрешено в Info.plist, делегатах и контроллерах. ‑ «Ага, у тебя UISupportedInterfaceOrientations = PortraitOnly? Окей, забудь про ландшафт, даже если корпус лежит боком.»
///Он учитывает, как система разместила окно: • Полноэкранное? • 70/30 Split View? • Окно Stage Manager на внешнем дисплее?
///Только потом он говорит: «Вот моё окончательное решение: UI сейчас .portrait (или .landscapeLeft / .landscapeRight).» ‑ Если окно вообще не повернули, он не меняет значение, даже если датчик орал «landscape!». ‑ Если UI заблокирован, он упрямо держит .portrait. ‑ Он никогда не возвращает .unknown, .faceUp, .faceDown: для пользовательского интерфейса эти позы бессмысленны.
///
///Живой пример, где «ум» заметен
///Ты разрешил только портрет. Пользователь кладёт iPad на диван боком → • Датчик: «landscapeRight!» • Дирижёр: «Не ведусь. UI останется портретным, потому что так просил разработчик.»
///Split View, устройство вертикально, но окно растянули так, что оно шире высоты → • Датчик: «portrait!» (корпус в портрете) • Дирижёр: «UI-координаты всё ещё портрет, разделитель просто дал нам широкую площадку. Значит, остаёмся .portrait.»
///Stage Manager, iPad держат вертикально, а окно утащили на внешний монитор, где Landscape → • Датчик: «portrait!» • Дирижёр (глядя на монитор): «Окно реально лежит горизонтально — объявляю .landscapeRight.»
///
///Почему мы держим их обоих
///Быстро: датчик отвечает мгновенно и подходит для анимации камеры или AR.
///Надёжно: дирижёр прикрывает, когда датчик врёт или UI под замком.


import SwiftUI
import UIKit
import Combine

enum Orientation {
    case portrait
    case landscape
}

class DeviceOrientationService: ObservableObject {

    @Published private(set) var orientation: Orientation = .portrait
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        updateOrientation()
        
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateOrientation()
            }
            .store(in: &cancellables)
    }
    
    private func updateOrientation() {
        let newOrientation: Orientation
        
        if isRotationLocked {
            newOrientation = .portrait
        } else {
            let deviceOrientation = UIDevice.current.orientation
            
            switch deviceOrientation {
            case .portrait, .portraitUpsideDown:
                newOrientation = .portrait
            case .landscapeLeft, .landscapeRight:
                newOrientation = .landscape
            default:
                // Новый способ получения interfaceOrientation
                newOrientation = currentInterfaceOrientation?.isLandscape ?? false ? .landscape : .portrait
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.orientation = newOrientation
        }
    }
    
    private var currentInterfaceOrientation: UIInterfaceOrientation? {
        if #available(iOS 15.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?
                .interfaceOrientation
        } else {
            return UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        }
    }
    
    private var isRotationLocked: Bool {
        let supportedOrientations = UIApplication.shared.supportedInterfaceOrientations(for: nil)
        return supportedOrientations == .portrait || supportedOrientations.isSubset(of: .portrait)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

extension UIInterfaceOrientation {
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
}



struct RootSizeReader: View {
    @EnvironmentObject var orientation: DeviceOrientationService
    
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear {
//                    print("RootSizeReader onAppear geo.size - \(geo.size)")
//                    orientation.update(raw: geo.size)
                }
                .onChange(of: geo.size) { _, newSize in
//                    print("RootSizeReader onChange geo.size - \(geo.size)")
//                    orientation.update(raw: newSize)
                }
        }
    }
}


// MARK: - синхронизируем данные из сервиса ориентации с локальными размерами GeometryReader.


// MARK: AdaptiveView

// Оборачиваем любой контент, которому нужны и размер, и ориентация.
// Универсальная обёртка: кладёшь внутрь любой контент
// builder(size, orientation) → View, где уже можно верстать.

// MARK: AdaptiveView – локальный size + ориентация в одном «пакете»
import SwiftUI
import Combine

struct AdaptiveView<Content: View>: View {

    // внешняя ориентация
    @EnvironmentObject private var orient: DeviceOrientationService
    // локальный размер
    @State private var containerSize = CGSize.zero

    // Subject, чтобы сделать из size полноценный Publisher
    private let sizeSubject = CurrentValueSubject<CGSize, Never>(.zero)

    // Builder-замыкание, возвращающее любой View
    private let builder: (CGSize, Orientation) -> Content
    init(@ViewBuilder _ builder: @escaping (CGSize, Orientation) -> Content) {
        self.builder = builder
    }

    // CombineLatest двух «настоящих» Publisher-ов
    private var combined: AnyPublisher<(CGSize, Orientation), Never> {
        Publishers.CombineLatest(
            sizeSubject.removeDuplicates(),
            orient.$orientation.removeDuplicates()
        )
        .eraseToAnyPublisher()
    }

    var body: some View {
        GeometryReader { geo in
            builder(containerSize, orient.orientation)          // ← сам контент
                .onAppear { updateSize(geo.size) }
                .onChange(of: geo.size) { old, new in  updateSize(new) }
        }
        .animation(.easeInOut(duration: 0.35), value: orient.orientation)
        .onReceive(combined) { (size, orient) in                // кортеж в скобках!
            debugPrint("⇢ sync  size:", size, "orient:", orient)
            // здесь можно запускать побочные эффекты или кастомные анимации
        }
    }

    private func updateSize(_ newSize: CGSize) {
        guard newSize != containerSize else { return }
        containerSize = newSize        // для SwiftUI-перерисовки
        sizeSubject.send(newSize)      // для CombineLatest
    }
}


struct Onboarding: View {
    let page: OnboardingPage

    var body: some View {
        AdaptiveView { size, orient in
            if orient == .landscape {
                HStack(spacing: 24) {
                    Image(systemName: page.imageName)
                        .resizable().scaledToFit()
                        .frame(width: size.width * 0.20)
                    VStack(alignment: .leading, spacing: 16) {
                        Text(page.title).font(.title).bold()
                        Text(page.description)
                    }
                }
                .padding()
            } else {
                VStack(spacing: 24) {
                    Image(systemName: page.imageName)
                        .resizable().scaledToFit()
                        .frame(height: size.height * 0.30)
                    Text(page.title).font(.largeTitle).bold()
                    Text(page.description)
                }
                .padding(.horizontal)
            }
        }
    }
}


// MARK: - Если хочется иметь и ориентацию и размер контейнера одновременно


//Подход B. Свести источники в один сервис (рекомендуемый)




///Сервис хранит и размер, и ориентацию, вычисляя последнюю из «чистой» геометрии.
///View слушает ТОЛЬКО сервис → гарантированно получает синхронные данные.




//@MainActor
//final class DeviceOrientationService: ObservableObject {
//
//    enum Orientation { case portrait, landscape }
//
//    @Published private(set) var orientation  : Orientation = .portrait
//    @Published private(set) var containerSize: CGSize      = .zero
//
//    private var cancellables = Set<AnyCancellable>()
//    private let sizeSubject  = PassthroughSubject<CGSize, Never>()
//
//    init() {
//
//        // ❶ Сырой датчик (UIDevice) — только fallback
//        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .sink { [weak self] _ in self?.fallbackFromDevice() }
//            .store(in: &cancellables)
//
//        // ❷ Истинный «мастер-таймлайн» — размер окна
//        sizeSubject
//            .removeDuplicates()
//            .debounce(for: .milliseconds(40), scheduler: RunLoop.main) // ждать, пока юзер отпустит палец
//            .sink { [weak self] size in self?.apply(size) }
//            .store(in: &cancellables)
//    }
//
//    func updateSize(_ size: CGSize) { sizeSubject.send(size) }
//
//    // MARK: - private
//
//    private func apply(_ size: CGSize) {
//        containerSize = size
//        orientation   = size.width > size.height ? .landscape : .portrait
//    }
//
//    private func fallbackFromDevice() {
//        guard containerSize == .zero else { return } // уже пришёл geo.size—фалбек не нужен
//        let device = UIDevice.current.orientation
//        orientation = (device == .landscapeLeft || device == .landscapeRight) ? .landscape : .portrait
//    }
//}

//struct RootSizeReader: View {
//    @EnvironmentObject var orient: DeviceOrientationService
//    var body: some View {
//        GeometryReader { geo in
//            Color.clear
//                .ignoresSafeArea()
//                .onAppear                     { orient.updateSize(geo.frame(in: .global).size) }
//                .onChange(of: geo.frame(in: .global).size) { new in
//                    orient.updateSize(new)
//                }
//        }
//    }
//}

//struct OnboardingPageView: View {
//    @EnvironmentObject private var orient: DeviceOrientationService
//    var body: some View {
//        if orient.orientation == .landscape {
//            LandscapeLayout(size: orient.containerSize)
//        } else {
//            PortraitLayout(size: orient.containerSize)
//        }
//        .animation(.easeInOut(duration: 0.35), value: orient.orientation)
//    }
//}





//Подход C. Комбинировать прямо в View (CombineLatest)


///Если не хочется переписывать сервис, можно «скрестить» два Publisher прямо в конкретной вьюхе:


//struct AdaptiveView: View {
//    @EnvironmentObject private var orient: DeviceOrientationService
//    @State private var size: CGSize = .zero
//
//    var body: some View {
//        GeometryReader { geo in
//            Color.clear
//                .onAppear { size = geo.size }
//                .onChange(of: geo.size) { size = $0 }
//        }
//        .overlay(content)
//        .onReceive(Publishers.CombineLatest($size, orient.$orientation)) { newSize, newOrient in
//            // здесь у вас гарантированно «одновременный» кадр и ориентация
//            // можно, например, запускать анимацию вручную
//        }
//    }

