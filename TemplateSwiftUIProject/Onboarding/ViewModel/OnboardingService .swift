//
//  OnboardingService .swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//

import Foundation

protocol OnboardingServiceProtocol {
    var pages: [OnboardingPage] { get }
    var hasSeenOnboarding: Bool { get set }
}

class OnboardingService : OnboardingServiceProtocol {
    
    @Published var hasSeenOnboarding: Bool {
         didSet {
             UserDefaults.standard.set(hasSeenOnboarding, forKey: "hasSeenOnboarding")
         }
     }

    
    var pages: [OnboardingPage] = [OnboardingPage(title: "Welcome", description: "Welcome to our app", imageName: "house.fill"), OnboardingPage(title: "Discover", description: "Discover new features", imageName: "safari.fill"), OnboardingPage(title: "Get started", description: "Let's get started!", imageName: "flag.fill")]
    
       
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
}


