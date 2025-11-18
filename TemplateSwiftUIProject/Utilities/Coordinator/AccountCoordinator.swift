//
//  AccountCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.04.25.
//

// func setupNotifications() была необходима потому что в SignUpView .onChange(of: viewModel.registeringState) отрабатывает только когда view isVisible и когда мы уходим на другой экран он не отработывает


import SwiftUI
import Combine

// MARK: - Типы и уведомления

enum AuthType {
    case emailSignIn
    case emailSignUp
    case appleSignIn
    case googleSignIn
    case appleSignUp
    case googleSignUp
    case reauthenticate
}


struct AuthNotificationPayload {
    let authType: AuthType
}

extension Notification.Name {
    static let authDidSucceed       = Notification.Name("AuthDidSucceedNotification")
    static let needReauthenticate   = Notification.Name("NeedReauthenticateNotification")
}


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
        /// ???
        guard !path.isEmpty else { return }
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
    
    // MARK: - Слушатели уведомлений
    
    private func setupNotifications() {
        // При успешной аутентификации — возвращаемся на корневой экран
        NotificationCenter.default.publisher(for: .authDidSucceed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard
                    let payload = notification.object as? AuthNotificationPayload
                else { return }
                self?.handleAuthSuccess(payload.authType)
            }
            .store(in: &cancellables)
        
        // При необходимости реаутентификации — пушим экран .reauthenticate
        NotificationCenter.default.publisher(for: .needReauthenticate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard
                    let payload = notification.object as? AuthNotificationPayload,
                    payload.authType == .reauthenticate
                else { return }
                self?.handleNeedReauthenticate()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Обработчики событий
    
    private func handleAuthSuccess(_ type: AuthType) {
        print("AccountCoordinator handleAuthSuccess type - \(type)")
        popToRoot()
    }
    
    private func handleNeedReauthenticate() {
        print("AccountCoordinator handleNeedReauthenticate")
        navigateTo(page: .reauthenticate)
    }
    
    deinit {
        cancellables.forEach { NotificationCenter.default.removeObserver($0) }
    }
}




//enum AuthType {
//    // Основные сценарии
//    case emailSignIn
//    case emailSignUp
//    case appleSignIn
//    case googleSignIn
//    case appleSignUp
//    case googleSignUp
//    case reauthenticate
//}
//
//extension Notification.Name {
//    static let authDidSucceed = Notification.Name("AuthDidSucceedNotification")
//}
//
//// Для типизированной передачи данных
//struct AuthNotificationPayload {
//    let authType: AuthType
//}

//    private func setupNotifications() {
//        NotificationCenter.default.publisher(for: .authDidSucceed)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] notification in
//                guard let payload = notification.object as? AuthNotificationPayload else { return }
//                self?.handleAuthSuccess(payload.authType)
//            }
//            .store(in: &cancellables)
//    }


//    private func handleReauthenticate (_ type: AuthType) {
//        navigateTo(page: .reauthenticate)
//    }
