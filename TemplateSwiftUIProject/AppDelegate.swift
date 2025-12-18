//
//  AppDelegate.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 13.10.24.
//

import UIKit
import Firebase
import FirebaseCore
import GoogleSignIn
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
    
    // Этот метод вызывается системой, когда приложение открывается через URL-схему.
    // В нашем случае — после того, как пользователь выбрал аккаунт Google
    // и Google вернул управление обратно в приложение.
//    func application(_ app: UIApplication,
//                     open url: URL,
//                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//        // Передаём URL в GoogleSignIn SDK.
//        // SDK проверяет, соответствует ли URL схеме REVERSED_CLIENT_ID,
//        // которую мы добавили в Info.plist → URL Types.
//        // Если схема совпадает, SDK завершает процесс авторизации
//        // и возвращает результат в наше приложение.
//        return GIDSignIn.sharedInstance.handle(url)
//    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Передаём URL в GoogleSignIn SDK
        let handled = GIDSignIn.sharedInstance.handle(url)
        
        // Логируем для отладки
        if handled {
            print("✅ Google Sign-In: URL успешно обработан -> \(url.absoluteString)")
        } else {
            print("❌ Google Sign-In: URL не был обработан -> \(url.absoluteString)")
        }
        
        return handled
    }

}

