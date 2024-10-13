//
//  TemplateSwiftUIProjectApp.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.10.24.
//

import SwiftUI

@main
struct TemplateSwiftUIProjectApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    ///использование @AppStorage позволяет привязать переменную(tiedOnboarding) к UserDefaults, а SwiftUI автоматически отслеживает и реагирует на изменения этой переменной, что приводит к обновлению пользовательского интерфейса без необходимости явных вызовов для переключения представлений.
    @AppStorage("hasSeenOnboarding") var tiedOnboarding:Bool = false
    
    init() {
#if DEBUG
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
#endif
    }
    
    var body: some Scene {
       
        WindowGroup {
            
            if tiedOnboarding {
                ContentView()
                
            } else {
                let onboardingService = OnboardingService()
                let viewModel = OnboardingViewModel(onboardingService: onboardingService)
                OnboardingView(viewModel: viewModel)
            }
                
        }
    }
    
    
}
