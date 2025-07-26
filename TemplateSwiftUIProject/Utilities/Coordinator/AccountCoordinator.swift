//
//  AccountCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.04.25.
//

// func setupNotifications() была необходима потому что в SignUpView .onChange(of: viewModel.registeringState) отрабатывает только когда view isVisible и когда мы уходим на другой экран он не отработывает

import SwiftUI
import Combine

class AccountCoordinator:ObservableObject {
    
    @Published var path: NavigationPath = NavigationPath() {
        didSet {
            print("NavigationPath updated: \(path.count)")
        }
    }
    @Published var sheet:SheetItem? {
        didSet {
            print("sheet updated: \(String(describing: sheet))")
        }
    }
    @Published var fullScreenItem:FullScreenItem?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("init AccountCoordinator")
        setupNotifications()
    }
    
    func navigateTo(page:AccountFlow) {
        path.append(page)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
    func presentSheet(_ sheet: SheetItem) {
        self.sheet = sheet
    }
    
    func presentFullScreenCover(_ cover: FullScreenItem) {
        self.fullScreenItem = cover
    }
    
    func dismissSheet() {
        self.sheet = nil
    }
    
    func dismissCover() {
        self.fullScreenItem = nil
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .authDidSucceed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let payload = notification.object as? AuthNotificationPayload else { return }
                self?.handleAuthSuccess(payload.authType)
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthSuccess(_ type: AuthType) {
        print("AccountCoordinator handleAuthSuccess type - \(type)")
        popToRoot()
    }
    
    deinit {
        cancellables.forEach { NotificationCenter.default.removeObserver($0) }
    }
}


enum AuthType {
    // Основные сценарии
    case emailSignIn
    case emailSignUp
    case appleSignIn
    case googleSignIn
    case appleSignUp
    case googleSignUp
}

extension Notification.Name {
    static let authDidSucceed = Notification.Name("AuthDidSucceedNotification")
}

// Для типизированной передачи данных
struct AuthNotificationPayload {
    let authType: AuthType
}
