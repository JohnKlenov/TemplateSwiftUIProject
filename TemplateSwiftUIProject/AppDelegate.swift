//
//  AppDelegate.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 13.10.24.
//

import UIKit
import Firebase

///AppDelegate в SwiftUI используется для конфигурации приложений и интеграции сторонних сервисов, как Firebase, которые требуют настройки при запуске приложения. AppDelegate позволяет использовать методы жизненного цикла приложения, такие как application(_:didFinishLaunchingWithOptions:).

///При первом физическом перевороте устройство начинает анимацию перехода в ландшафтное положение. Однако, в момент, когда система обновляет ориентацию, происходит запрос разрешённых ориентаций через метод из AppDelegate:
///Если orientationLock установлен в .portrait, система понимает, что контроллер может работать только в портрете.

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // Глобальная переменная для блокировки ориентации.
    // По умолчанию разрешаем все ориентации.
    static var orientationLock: UIInterfaceOrientationMask = .all
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

