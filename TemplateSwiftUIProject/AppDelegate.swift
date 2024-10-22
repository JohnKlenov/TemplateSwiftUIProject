//
//  AppDelegate.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 13.10.24.
//

import UIKit
import Firebase

///AppDelegate в SwiftUI используется для конфигурации приложений и интеграции сторонних сервисов, как Firebase, которые требуют настройки при запуске приложения. AppDelegate позволяет использовать методы жизненного цикла приложения, такие как application(_:didFinishLaunchingWithOptions:).
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

