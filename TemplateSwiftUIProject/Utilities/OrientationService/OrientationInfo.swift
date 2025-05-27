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

import SwiftUI
import Combine

class OrientationInfo: ObservableObject {
    @Published var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    private var cancellable: AnyCancellable?

    init() {
        // Подписываемся на уведомления о перемене ориентации
        cancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { _ in
                // Пересчитываем состояние на основе текущей ориентации.
                let orientation = UIDevice.current.orientation
                if orientation.isValidInterfaceOrientation {
                    DispatchQueue.main.async {
                        self.isLandscape = orientation.isLandscape
                    }
                }
            }
    }
}

///Проверить, что текущая ориентация устройства относится к "действительным" для интерфейса, то есть к тем, которые обычно используются для компоновки UI: .portrait, .portraitUpsideDown, .landscapeLeft и .landscapeRight.
///Почему это нужно: Когда вы запрашиваете текущую ориентацию через UIDevice.current.orientation, система может вернуть и другие значения, например, .faceUp, .faceDown или .unknown, которые не подходят для корректного размещения элементов интерфейса. Это расширение фильтрует такие состояния, гарантируя, что используются только те ориентации, которые реально влияют на расположение интерфейса.
///Свойство isValidInterfaceOrientation возвращает true, если значение UIDeviceOrientation равно одному из «валидных» вариантов. Иначе — false.
extension UIDeviceOrientation {
    var isValidInterfaceOrientation: Bool {
        // Исключаем неизвестное, лицевое вниз и вверх
        return self == .portrait || self == .portraitUpsideDown || self == .landscapeLeft || self == .landscapeRight
    }
}



// MARK: - View
// Создаём объект ориентации один раз и передаём его через environment
//@StateObject var orientationInfo = OrientationInfo()
//.environmentObject(orientationInfo)

//@EnvironmentObject var orientationInfo: OrientationInfo
//.frame(maxWidth: orientationInfo.isLandscape ? 300 : .infinity)




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


// MARK: - Полный исходный код

import Combine
import UIKit

class DeviceOrientationService: ObservableObject {
    enum Orientation { case portrait, landscape }
    
    @Published private(set) var orientation: Orientation = .portrait
    private var cancellables = Set<AnyCancellable>()
    private var lastContainerSize: CGSize = .zero
    
    init() {
        setupOrientationTracking()
    }
    
    private func setupOrientationTracking() {
        // Системные уведомления об изменении ориентации
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .sink { [weak self] _ in
                self?.handleDeviceOrientationChange()
            }
            .store(in: &cancellables)
        
        // Первоначальное обновление
        updateOrientation()
    }
    
    // Обработчик изменений от GeometryReader
    func updateContainerSize(_ size: CGSize) {
        lastContainerSize = size
        updateOrientation()
    }
    
    private func handleDeviceOrientationChange() {
        guard UIDevice.current.orientation.isValidInterfaceOrientation else { return }
        updateOrientation()
    }
    
    private func updateOrientation() {
        let newOrientation = calculateOrientation()
        
        DispatchQueue.main.async {
            if self.orientation != newOrientation {
                self.orientation = newOrientation
            }
        }
    }
    
    private func calculateOrientation() -> Orientation {
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Для iPhone доверяем физической ориентации
            return UIDevice.current.orientation.isLandscape ? .landscape : .portrait
        } else {
            // Для iPad/Mac используем комбинированный подход
            let isDeviceLandscape = UIDevice.current.orientation.isLandscape
            let isContainerLandscape = lastContainerSize.width > lastContainerSize.height
            
            // Разрешение конфликтов
            if isDeviceLandscape == isContainerLandscape {
                return isDeviceLandscape ? .landscape : .portrait
            } else {
                // Приоритет данным контейнера для iPad
                return isContainerLandscape ? .landscape : .portrait
            }
        }
    }
}



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

struct DeviceOrientationModifier: ViewModifier {
    let orientationService: DeviceOrientationService
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ContainerSizeKey.self,
                            value: geometry.size
                        )
                }
            )
            .onPreferenceChange(ContainerSizeKey.self) { size in
                orientationService.updateContainerSize(size)
            }
    }
}

    
struct ContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

//Для точных измерений экрана (игнорирует safe area:)
struct ScreenSizeModifier: ViewModifier {
    @Binding var screenSize: CGSize
    
    func body(content: Content) -> some View {
        content
            .ignoresSafeArea()
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: ScreenSizeKey.self,
                            value: proxy.size
                        )
                }
            )
            .onPreferenceChange(ScreenSizeKey.self) { size in
                screenSize = size
                //                if screenSize != newSize {
                //                                    screenSize = newSize
                //                                }

            }
    }
}

//Определяем ключ для отслеживания размеров экрана
struct ScreenSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}



//Setting

//@main
//struct MyApp: App {
//    @StateObject private var orientationService = DeviceOrientationService()
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environmentObject(orientationService)
//                .modifier(DeviceOrientationModifier())
//                .onAppear {
//                    // Активируем генерацию уведомлений
//                    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
//                }
//                .onDisappear {
//                    UIDevice.current.endGeneratingDeviceOrientationNotifications()
//                }
//        }
//    }
//}


//Example

//struct ContentView: View {
//    @EnvironmentObject private var orientationService: DeviceOrientationService
//    
//    var body: some View {
//        ZStack {
//            Color(.systemBackground)
//            
//            VStack {
//                Text(currentOrientationText)
//                    .font(.largeTitle)
//                
//                Button("Check Orientation") {
//                    print("Current: \(orientationService.orientation)")
//                }
//                .padding()
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//            }
//        }
//        .ignoresSafeArea()
//    }
//    
//    private var currentOrientationText: String {
//        switch orientationService.orientation {
//        case .portrait: return "Portrait 📱"
//        case .landscape: return "Landscape 🌄"
//        }
//    }
//}
