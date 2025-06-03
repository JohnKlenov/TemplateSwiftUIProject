//
//  OrientationInfo.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.05.25.



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

import SwiftUI
import UIKit
import Combine


class DeviceOrientationService: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }
    
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
