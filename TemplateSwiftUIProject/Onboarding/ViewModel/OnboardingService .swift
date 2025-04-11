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
    

    var pages: [OnboardingPage] = [OnboardingPage(title: Localized.Onboarding.welcomeTitle.localized(), description: Localized.Onboarding.welcomeDescription.localized(), imageName: "house.fill"), OnboardingPage(title: Localized.Onboarding.discoverTitle.localized(), description: Localized.Onboarding.discoverDescription.localized(), imageName: "safari.fill"), OnboardingPage(title: Localized.Onboarding.getStartedTitle.localized(), description: Localized.Onboarding.getStartedDescription.localized(), imageName: "flag.fill")]
    
       
    init() {
        self.hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
}


