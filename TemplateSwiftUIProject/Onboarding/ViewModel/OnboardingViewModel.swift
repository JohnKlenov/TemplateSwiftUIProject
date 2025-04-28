//
//  OnboardingViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.10.24.
//

import Foundation

class OnboardingViewModel: ObservableObject {
    
    private var onboardingService: OnboardingServiceProtocol
    
    @Published var currentPage = 0
    
    var pages: [OnboardingPage] {
        onboardingService.pages
    }
    
    var hasSeenOnboarding: Bool {
        get { onboardingService.hasSeenOnboarding}
        set {onboardingService.hasSeenOnboarding = newValue}
    }
    
    init(onboardingService: OnboardingServiceProtocol) {
        self.onboardingService = onboardingService
    }
    
    func nextPage() {
        if currentPage < onboardingService.pages.count - 1 {
            currentPage += 1
        }
    }
    
    func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
    }
    
    deinit {
        print("deinit OnboardingViewModel")
    }
}
