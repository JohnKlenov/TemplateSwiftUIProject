//
//  OrientationInfo.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.05.25.
//

///UIDevice.current.orientation относится именно к физической ориентации устройства, а не к ориентации интерфейса.
///Если устройство заблокировано в портретном режиме, но повернуто в ландшафт, UIDevice.current.orientation.isLandscape может все равно вернуть true, хотя сам интерфейс останется в портретном положении.
///Для правильной адаптации UI лучше использовать Size Classes или GeometryReader, чтобы определить фактические размеры доступного пространства.

//Разница между UIDevice.current.orientation и UIInterfaceOrientation
///UIDevice.current.orientation Определяет физическое положение устройства. Даже если экран заблокирован в портретном режиме, но сам iPhone повернут в landscape, оно всё равно покажет .landscapeLeft или .landscapeRight.

//UIInterfaceOrientation (из UIApplication.shared.statusBarOrientation)
///Определяет ориентацию пользовательского интерфейса, т.е. как приложение отображает контент.
///Если приложение запретило смену ориентации
///(supportedInterfaceOrientations ограничены только портретом), то интерфейс останется в портретном режиме, даже если устройство физически повернуто в landscape.

///Если вы запретили переход в landscape (Info.plist или supportedInterfaceOrientations), но пользователь наклонил устройство в сторону, тогда:
///UIDevice.current.orientation.isLandscape будет true, потому что физически устройство в landscape.




// MARK: - Combined service
// MARK: - методами определения ориентации устройства в пространстве

//Физическая ориентация устройства (через UIDevice.orientation)
///Даже если приложение заблокировано в портретном режиме, физическое поворот устройства может изменять значение UIDevice.current.orientation

//Фактический layout интерфейса (через PreferenceKey, GeometryReader)
///Если ориентация приложения заблокирована (например, только портретная компоновка), то размеры контейнера не изменятся даже при физическом повороте устройства.
///если контент заблокирован и не вращается, то вариант на основе измерения контейнера (GeometryReader с PreferenceKey) будет отражать актуальные размеры UI, потому что они будут зафиксированы в выбранной ориентации.

//Как запретить изменение ориентации на устройстве
///Настройка в Info.plist: Задайте поддерживаемые ориентации для вашего приложения. Например, чтобы разрешить только портрет, в Info.plist  добавьте ключ UISupportedInterfaceOrientations со значением UIInterfaceOrientationPortrait (а для iPad – при необходимости, либо отдельно определить портретные ориентации).
///Переопределение поведения контроллера: Если вам нужно программно запретить авто-поворот, можно в вашем UIViewController
///Для SwiftUI: Хотя SwiftUI напрямую не предоставляет API для блокировки ориентации, обычно это делается через настройку Info.plist  или через UIKit-обёртку в AppDelegate/SceneDelegate.

///Если вы запрещаете поворот UI, то для определения текущего интерфейсного состояния используйте измерение контейнера (GeometryReader / PreferenceKey), так как реальный размер экрана для UI не меняется.

///Объединённый сервис, который выбирает источник в зависимости от устройства, может, например, для iPad полагаться на размеры контейнера, а для iPhone – на системные уведомления. Но учтите, если вы блокируете ротейшн в обоих случаях (через Info.plist  или переопределяя shouldAutorotate), то размеры контейнера всегда будут соответствовать зафиксированной ориентации, а системные уведомления могут всё равно меняться, отражая только физическое положение устройства, а не интерфейс.


//Когда точно нужен GeometryReader (iPad):
///Если приложение поддерживает iPad
///Если нужна поддержка Split View/Slide Over
///Если есть кастомные контроллеры представления
///Если важна точность при запрете ориентаций

///Для простого iPhone-приложения можно использовать только UIDevice.orientation, но для production-решения лучше комбинированный подход.

//Когда достаточно только UIDevice.orientation:
///Приложение только для iPhone
///На iPad заблокированы все ориентации кроме портретной
///Не требуется поддержка Split View или Slide Over


//Почему при показе sheet/модалки GeometryReader внезапно отдаёт 361 × 782 pt вместо 393 × 852 pt
///Когда .sheet появляется, UIKit: создаёт дочернее окно, в котором живёт сам лист; сжимает/отодвигает presenting-контроллер (ваш WindowGroup) — добавляет горизонтальные отступы ≈16 pt с каждой стороны и поднимает его вверх, чтобы за листом было видно «слой фона». Именно поэтому GeometryReader, прикреплённый к «старому» представлению, вдруг видит размер 361 × 782,6 pt (393 − 32 и 852 − ≈70).
///Используйте onChange(UIScreen.main.bounds.size) на iPhone можно, На iPad передавайте geo.size, но игнорируйте небольшие скачки от модалки.

import SwiftUI
import UIKit
import Combine

// MARK: - Unified Orientation Service

/// Сервис, объединяющий данные о физической ориентации (для iPhone)
/// и информацию о размере контейнера (для iPad), чтобы определить текущую ориентацию.
class DeviceOrientationService: ObservableObject {
    enum Orientation: String {
        case portrait
        case landscape
        case square
    }
    
    /// Публикуемое свойство, на которое подписаны вью для обновления UI
    @Published private(set) var orientation: Orientation = .portrait {
        didSet {
            print("orientation - \(orientation)")
        }
    }
    
    /// Последний размер контейнера (используется для iPad)
    private var containerSize: CGSize = .zero
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Предмет для дебаунсирования обновлений контейнерного размера (для iPad)
    private let containerSizeSubject = PassthroughSubject<CGSize, Never>()
    
    /// Порог, по которому считаем, что размеры почти равны (для "square")
    private let squareThreshold: CGFloat = 50
    
    init() {
        // Если устройство — iPhone, подписываемся на системные уведомления изменения ориентации.
        if UIDevice.current.userInterfaceIdiom == .phone {
            NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
                .sink { [weak self] _ in
                    self?.updateOrientationForiPhone()
                }
                .store(in: &cancellables)
        }
        
        // Для iPad обновления контейнерного размера обрабатываем с дебаунсом,
        // чтобы снизить частоту обновлений при быстром изменении размеров.
        if UIDevice.current.userInterfaceIdiom == .pad {
            containerSizeSubject
                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
                .sink { [weak self] size in
                    self?.containerSize = size
                    self?.updateOrientationForiPad()
                }
                .store(in: &cancellables)
        }
    }
    
    /// Метод, который должен вызываться (например, через GeometryReader)
    /// для обновления размера контейнера (работает только на iPad)
    func updateContainerSize(_ size: CGSize) {
        print("geometry.size - \(size)")
        if UIDevice.current.userInterfaceIdiom == .pad {
            containerSizeSubject.send(size)
        }
    }
    
    // MARK: - Orientation Update Methods
    
    /// Определение, заблокирован ли поворот экрана.
    /// Здесь мы полагаемся на supportedInterfaceOrientations (определённые в Info.plist или контроллере).
    /// Info.plist (UISupportedInterfaceOrientations*) ‒ базовые правила для приложения.
    /// application(_:supportedInterfaceOrientationsFor:) в AppDelegate (если переопределили).
    /// UIWindow.rootViewController → активный верхний UIViewController (или представленный модально) со своим supportedInterfaceOrientations.
    /// То есть isRotationLocked не привязан строго к Info.plist: он отражает текущее состояние окна. Вы контролируете это состояниe либо статично (Info.plist), либо динамически (разные VC + setNeedsUpdateOfSupportedInterfaceOrientations()).
    private var isRotationLocked: Bool {
        UIApplication.shared.supportedInterfaceOrientations(for: nil) == .portrait
    }

    
    /// Обновление ориентации для iPhone.
    /// При заблокированном повороте всегда возвращает portrait,
    /// иначе — учитывается физическая ориентация устройства.
    /// если оринтация .portraitUpsideDown то deviceOrientation.isLandscape вернет .portrait
    /// но UI роспалагается как будто это ландшавт но в перевернутом portret - поэтому мы его переопределили
    
    //    private func updateOrientationForiPhone() {
    //        let newOrientation: Orientation
    //
    //        if isRotationLocked {
    //            newOrientation = .portrait
    //        } else {
    //            let deviceOrientation = UIDevice.current.orientation
    //            if deviceOrientation.isValidInterfaceOrientation {
    //                newOrientation = deviceOrientation.isLandscape ? .landscape : .portrait
    //            } else {
    //                newOrientation = .portrait
    //            }
    //        }
    //
    //        DispatchQueue.main.async { [weak self] in
    //            guard let self = self, self.orientation != newOrientation else { return }
    //            self.orientation = newOrientation
    //        }
    //    }
    private func updateOrientationForiPhone() {
        let newOrientation: Orientation
        
        if isRotationLocked {
            newOrientation = .portrait
        } else {
            let deviceOrientation = UIDevice.current.orientation
            if deviceOrientation.isValidInterfaceOrientation {
                switch deviceOrientation {
                case .landscapeLeft, .landscapeRight, .portraitUpsideDown:
                    newOrientation = .landscape
                case .portrait:
                    newOrientation = .portrait
                default:
                    newOrientation = .portrait
                }
            } else {
                newOrientation = .portrait
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.orientation != newOrientation else { return }
            self.orientation = newOrientation
        }
    }

    
    /// Обновление ориентации для iPad на основе размера контейнера.
    /// Если разница между шириной и высотой меньше порогового значения — считаем, что
    /// приложение находится в "square" режиме (например, Split View или Stage Manager).
    private func updateOrientationForiPad() {
        let width = containerSize.width
        let height = containerSize.height
        let newOrientation: Orientation
        
        if abs(width - height) < squareThreshold {
            newOrientation = .square
        } else {
            newOrientation = width > height ? .landscape : .portrait
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.orientation != newOrientation else { return }
            self.orientation = newOrientation
        }
    }
}

// Вспомогательное расширение для проверки допустимой ориентации устройства.
///Проверить, что текущая ориентация устройства относится к "действительным" для интерфейса, то есть к тем, которые обычно используются для компоновки UI: .portrait, .portraitUpsideDown, .landscapeLeft и .landscapeRight.
///Почему это нужно: Когда вы запрашиваете текущую ориентацию через UIDevice.current.orientation, система может вернуть и другие значения, например, .faceUp, .faceDown или .unknown, которые не подходят для корректного размещения элементов интерфейса. Это расширение фильтрует такие состояния, гарантируя, что используются только те ориентации, которые реально влияют на расположение интерфейса.
///Свойство isValidInterfaceOrientation возвращает true, если значение UIDeviceOrientation равно одному из «валидных» вариантов. Иначе — false.
extension UIDeviceOrientation {
    var isValidInterfaceOrientation: Bool {
        return self == .portrait ||
               self == .portraitUpsideDown ||
               self == .landscapeLeft ||
               self == .landscapeRight
    }
}
//.onChange(of: geo.frame(in: .global).size) { oldSize, newSize
///почему когда делаю ротацию устройства с портрета на ландшавт (newSize отрабатывает ) затем с ландшавта в перевернутый верх ногами портрет (newSize не отрабатывает) затем с перевернутого верх ногами портрета в перевернутый верх ногами ландшавт (newSize не отрабатывает) и затем с перевернутого верх ногами ландшавта в портрет (newSize отрабатывает ) ? за всю ротацию по кругу отрабатывает только два раза, как сделать что бы отрабатывал всегда?
///SwiftUI сравнивает старое и новое значение (CGSize – Equatable). Если они различаются → вызывает ваше замыкание и кладёт туда (oldSize, newSize).

// MARK: - Модификатор без PreferenceKey
struct RootSizeReader: ViewModifier {
    
    let onChange: (CGSize) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .ignoresSafeArea()
                        .onAppear {
                            onChange(geo.frame(in: .global).size)
                        }
                        .onChange(of: geo.frame(in: .global).size) { oldSize, newSize in           // любое изменение
                            onChange(newSize)
                        }
                }
                    .ignoresSafeArea()
            )
    }
}

extension View {
    func readRootSize(_ onChange: @escaping (CGSize) -> Void) -> some View {
        self.modifier(RootSizeReader(onChange: onChange))
    }
}







// MARK: - PreferenceKey


///DeviceOrientationModifier измеряет размер того контейнера, к которому он применён, а не всего экрана устройства.
///Что влияет на размер: Safe Area (вырез, индикатор дома) + NavigationBar/Toolbar + TabBar + Любые другие padding'и
///TabView { .. } .modifier(DeviceOrientationModifier()) // ← Будет учитывать высоту TabBar

//Как получить реальные размеры экрана
///Если вам нужны полные размеры экрана (без учета safe area и других элементов):
///ContentView().ignoresSafeArea() // ← Игнорируем safe area .modifier(DeviceOrientationModifier()) // ← Теперь получим полный экран

//он учитывает реальное доступное пространство.
//struct DeviceOrientationModifier: ViewModifier {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//
//    func body(content: Content) -> some View {
//        content
//            .background(
//                GeometryReader { geometry in
//                    Color.clear
//                        .preference(
//                            key: ContainerSizeKey.self,
//                            value: geometry.size
//                        )
//                }
//            )
//            .onPreferenceChange(ContainerSizeKey.self) { size in
//                orientationService.updateContainerSize(size)
//            }
//    }
//}

///// Удобное расширение для применения модификатора
//extension View {
//    func trackContainerSize() -> some View {
//        modifier(DeviceOrientationModifier())
//    }
//}

//struct ContainerSizeKey: PreferenceKey {
//    static var defaultValue: CGSize = .zero
//    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
//        value = nextValue()
//    }
//}

// MARK: - old implement DeviceOrientationService

//import Combine
//import SwiftUI
//
//class DeviceOrientationService: ObservableObject {
//    enum Orientation { case portrait, landscape }
//    
//    @Published private(set) var orientation: Orientation = .portrait
//    private var cancellables = Set<AnyCancellable>()
//    private var lastContainerSize: CGSize = .zero
//    
//    init() {
//        setupOrientationTracking()
//    }
//    
//    private func setupOrientationTracking() {
//        // Системные уведомления об изменении ориентации
//        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
//            .sink { [weak self] _ in
//                self?.handleDeviceOrientationChange()
//            }
//            .store(in: &cancellables)
//        
//        // Первоначальное обновление
//        updateOrientation()
//    }
//    
//    // Обработчик изменений от GeometryReader
//    func updateContainerSize(_ size: CGSize) {
//        print("geometry.size - \(size)")
//        lastContainerSize = size
//        updateOrientation()
//    }
//    
//    private func handleDeviceOrientationChange() {
//        guard UIDevice.current.orientation.isValidInterfaceOrientation else { return }
//        updateOrientation()
//    }
//    
//    private func updateOrientation() {
//        let newOrientation = calculateOrientation()
//        
//        DispatchQueue.main.async {
//            if self.orientation != newOrientation {
//                self.orientation = newOrientation
//            }
//        }
//    }
//    
//    private func calculateOrientation() -> Orientation {
//        if UIDevice.current.userInterfaceIdiom == .phone {
//            // Для iPhone доверяем физической ориентации
//            return UIDevice.current.orientation.isLandscape ? .landscape : .portrait
//        } else {
//            // Для iPad/Mac используем комбинированный подход
//            let isDeviceLandscape = UIDevice.current.orientation.isLandscape
//            let isContainerLandscape = lastContainerSize.width > lastContainerSize.height
//            
//            // Разрешение конфликтов
//            if isDeviceLandscape == isContainerLandscape {
//                return isDeviceLandscape ? .landscape : .portrait
//            } else {
//                // Приоритет данным контейнера для iPad
//                return isContainerLandscape ? .landscape : .portrait
//            }
//        }
//    }
//}
//
//
//
//extension UIDeviceOrientation {
//    var isValidInterfaceOrientation: Bool {
//        // Исключаем неизвестное, лицевое вниз и вверх
//        return self == .portrait || self == .portraitUpsideDown || self == .landscapeLeft || self == .landscapeRight
//    }
//}
