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
