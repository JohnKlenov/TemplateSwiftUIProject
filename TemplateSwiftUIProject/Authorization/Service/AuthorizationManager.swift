//
//  AuthorizationManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.06.25.
//

// AuthorizationManager мы будем использовать в нескольких View из разных навигационных стеков
// у нас есть возможность не дождавшись ответа от сервера покинуть View (и если бы не было единого AuthorizationManager мы не смогли бы дождаться ответа) если есть ошибка она будет выбрашена через глобальный алерт если success то мы будем оповещены алертом глобальным
// если мы введем данные в SignUp и нажмем кнопку регистрации и не дождавшись ответа перейдем на экран SignIn то так как AuthorizationManager общий с общей state машиной мы и на экране SignIn увидим что идет загрузка и не сможем перегруждать сервер различными операциями авторизации пока не дождемся последовательного выполнения каждого из них


// почему в  func signUp(email: String, password: String) при .finished вызов alert оборачиваем в DispatchQueue.main.async?

/// потому что операции NotificationCenter.default.post + alert + .. будут вызваны последовательно (Система начинает обработку цепочки синхронно в текущем run loop)
/// когда начинутся Навигационные изменения (popToRoot) они не успеют завершится как вызовется алерт - Навигационные изменения (popToRoot) ставятся в очередь, но не могут выполниться, пока не завершится показ алерта.
/// DispatchQueue.main.async добавляет задачу в конец текущего цикла RunLoop
/// Навигационные изменения успевают обработаться до показа алерта
/// Даже с задержкой 0 это работает, потому что это уже следующий "тик" системы

// Без async:
/// Один "тик" RunLoop
//┌──────────────┐
//│ 1. Навигация │
//│ 2. Алерт     │ ← блокирует завершение 1
//└──────────────┘

//С async:
/// Первый "тик"
//┌──────────────┐
//│ 1. Навигация │ ← выполняется полностью
//└──────────────┘
/// Второй "тик"
//┌──────────────┐
//│ 2. Алерт     │
//└──────────────┘


//Всегда используйте DispatchQueue.main.async для:Показа алертов после навигации + Любых UI-изменений, которые должны произойти после системных анимаций

//DispatchQueue.main.async vs DispatchQueue.main.asyncAfter
// почему можно без DispatchQueue.main.asyncAfter?

/// Задача в DispatchQueue.main.async добавляется в очередь текущего или следующего тика RunLoop.
/// Если навигационная анимация уже началась, алерт покажется после её завершения.
/// SwiftUI/UIKit автоматически управляют очередями: Анимации навигации имеют высший приоритет. + DispatchQueue.main.async не прерывает их, а ставит задачи в очередь.
/// Добавляйте asyncAfter только если: Замечаете "конфликты" анимаций. + Нужна гарантированная задержка (например, для кастомных переходов).




    
import Combine
import SwiftUI

final class AuthorizationManager: ObservableObject {
    enum State {
        case idle, loading, success, failure
    }
    
//    @Published private(set) var state: State = .idle
    // Global flag
    @Published private(set) var isAuthOperationInProgress: Bool = false
    
    // Local states
    @Published private(set) var signInState: State = .idle
    @Published private(set) var signUpState: State = .idle
    @Published private(set) var deleteAccountState: State = .idle
    @Published private(set) var reauthState: State = .idle
    
    // User info
    @Published private(set) var isUserAnonymous: Bool = true
    @Published private(set) var currentAuthUser: AuthUser?
    @Published private(set) var primaryProvider: String?
    @Published private(set) var providers: [String] = []
    
    private let authService: AuthorizationService
    private let errorHandler: ErrorHandlerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Отдельные cancellable для провайдеров
    private var providersCancellable: AnyCancellable?
    private var primaryProviderCancellable: AnyCancellable?
    
    var alertManager: AlertManager
    
    init(service: AuthorizationService,
         errorHandler: ErrorHandlerProtocol,
         alertManager: AlertManager = AlertManager.shared) {
        self.authService = service
        self.errorHandler = errorHandler
        self.alertManager = alertManager
        
        setupAuthStateSubscription()
    }
    
    // MARK: - Подписки
    
    private func setupAuthStateSubscription() {
        authService.authStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] authUser in
                self?.handleAuthStateChange(authUser)
            }
            .store(in: &cancellables)
    }
    
    private func handleAuthStateChange(_ authUser: AuthUser?) {
        isUserAnonymous = authUser?.isAnonymous ?? true
        currentAuthUser = authUser
        
        // ⚡️ Сбрасываем провайдеры при смене пользователя
        resetProviders()
        
        // ⚡️ Подписываемся только если пользователь перманентный
        guard let user = authUser, !user.isAnonymous else {
            print("ℹ️ AuthorizationManager: анонимный или nil user — провайдеры не запрашиваем")
            return
        }
        
        subscribeToProviders()
        subscribeToPrimaryProvider()
    }
    
    private func resetProviders() {
        primaryProvider = nil
        providers = []
        
        // Отменяем старые подписки
        providersCancellable?.cancel()
        providersCancellable = nil
        
        primaryProviderCancellable?.cancel()
        primaryProviderCancellable = nil
    }
    
    private func subscribeToProviders() {
        providersCancellable?.cancel() // отменяем старую подписку
        providersCancellable = authService.authProvidersPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] providers in
                self?.providers = providers
                if providers.isEmpty {
                    print("⚠️ AuthorizationManager: пустой список провайдеров для перманентного пользователя")
                    // TODO: Crashlytics.log("Empty providers list for permanent user")
                }
                print("⚠️ AuthorizationManager: subscribeToProviders - \(providers)")
            }
    }
    
    private func subscribeToPrimaryProvider() {
        primaryProviderCancellable?.cancel() // отменяем старую подписку
        primaryProviderCancellable = authService.primaryAuthProviderPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] provider in
                self?.primaryProvider = provider
//                self?.primaryProvider = nil
                if provider == nil {
                    print("⚠️ AuthorizationManager: primary provider == nil для перманентного пользователя")
                    // TODO: Crashlytics.log("Primary provider is nil for permanent user")
                }
                print("⚠️ AuthorizationManager: subscribeToPrimaryProvider - \(String(describing: provider))")
            }
    }

    func handleError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }
    
    private func handleAuthenticationError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }
    
    func signUp(email: String, password: String) {
        guard !isAuthOperationInProgress else { return } // defensive programming: мы не доверяем только UI, а дублируем проверку в бизнес‑логике.
        isAuthOperationInProgress = true
        signUpState = .loading
        
        authService.signUpBasic(email: email, password: password)
            .sink { [weak self] completion in
                self?.signUpState = .idle
                self?.isAuthOperationInProgress = false
                guard let self = self else { return }
                switch completion {
                case .failure(let err):
                    self.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signUp)
                case .finished:
                    NotificationCenter.default.post(
                        name: .authDidSucceed,
                        object: AuthNotificationPayload(authType: .emailSignUp)
                    )
                    DispatchQueue.main.async {
                        self.alertManager.showGlobalAlert(
                            message: Localized.MessageOfSuccessOperationFirebase.signUp,
                            operationDescription: Localized.TitleOfSuccessOperationFirebase.signUp,
                            alertType: .ok
                        )
                    }
                    self.authService.sendVerificationEmail()
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) {
        guard !isAuthOperationInProgress else { return }
        isAuthOperationInProgress = true
        signInState = .loading
        
        authService.signInBasic(email: email, password: password)
            .sink { [weak self] completion in
                self?.signInState = .idle
                self?.isAuthOperationInProgress = false
                guard let self = self else { return }
                switch completion {
                case .failure(let err):
                    self.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signIn)
                case .finished:
                    NotificationCenter.default.post(
                        name: .authDidSucceed,
                        object: AuthNotificationPayload(authType: .emailSignIn)
                    )
                    DispatchQueue.main.async {
                        self.alertManager.showGlobalAlert(
                            message: Localized.MessageOfSuccessOperationFirebase.signIn,
                            operationDescription: Localized.TitleOfSuccessOperationFirebase.signIn,
                            alertType: .ok
                        )
                    }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func deleteAccount() {
        // Глобальная защита от параллельных операций
        guard !isAuthOperationInProgress else { return }
        
        isAuthOperationInProgress = true
        deleteAccountState = .loading
        
        authService.deleteAccount()
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                // Сбрасываем состояния
                self.deleteAccountState = .idle
                self.isAuthOperationInProgress = false
                
                // Обрабатываем результат
                self.handleDeleteAccountCompletion(completion)
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    // Private Methods for deleteAccount()
    
    private func handleDeleteAccountCompletion(_ completion: Subscribers.Completion<DeleteAccountError>) {
        
        switch completion {
        case .failure(let error):
            handleDeleteAccountError(error)
        case .finished:
            showAccountDeletionSuccess()
        }
    }
    
    private func handleDeleteAccountError(_ error:  DeleteAccountError) {
        switch error {
        case .reauthenticationRequired(let reauthError):
            notifyReauthenticationNeeded()
            // Специальная обработка для навигационных переходов
            DispatchQueue.main.async { [weak self] in
                self?.showAccountDeletionError(
                    reauthError,
                    operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion
                )
            }
            
        case .underlying(let underlyingError):
            // Обычные ошибки уже на главном потоке благодаря receive(on:)
            showAccountDeletionError(
                underlyingError,
                operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion
            )
        }
    }
    
    private func notifyReauthenticationNeeded() {
        NotificationCenter.default.post(
            name: .needReauthenticate,
            object: AuthNotificationPayload(authType: .reauthenticate)
        )
    }
    
    private func showAccountDeletionError(_ error: Error, operationDescription: String) {
        handleAuthenticationError(error, operationDescription: operationDescription)
    }
    
    private func showAccountDeletionSuccess() {
        alertManager.showGlobalAlert(
            message: Localized.MessageOfSuccessOperationFirebase.accountDeletion,
            operationDescription: Localized.TitleOfSuccessOperationFirebase.accountDeletion,
            alertType: .ok
        )
    }

    func confirmIdentity(email: String, password: String) {
        // Глобальная защита от параллельных операций
        guard !isAuthOperationInProgress else { return }
        
        isAuthOperationInProgress = true
        reauthState = .loading
        
        authService.reauthenticate(email: email, password: password)
            .sink { [weak self] completion in
                guard let self = self else { return }
                
                // Сбрасываем состояния
                self.reauthState = .idle
                self.isAuthOperationInProgress = false
                
                switch completion {
                case .finished:
                    NotificationCenter.default.post(
                        name: .authDidSucceed,
                        object: AuthNotificationPayload(authType: .reauthenticate)
                    )
                    DispatchQueue.main.async {
                        self.alertManager.showGlobalAlert(
                            message: "Повторная аутентификация прошла успешно!",
                            operationDescription: "Аутентификация",
                            alertType: .ok
                        )
                    }
                case .failure(let error):
                    self.handleAuthenticationError(error, operationDescription: "Аутентификация")
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func signOutAccount() {
        
        authService.signOut()
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.handleAuthenticationError(error, operationDescription: "SignOut")
                case .finished:
                    DispatchQueue.main.async { [weak self] in
                        self?.alertManager.showGlobalAlert(message:"Success signOut user!", operationDescription:"SignOut", alertType: .ok)
                    }
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
}
    


//import Combine
//import Foundation
//
//final class AuthorizationManager: ObservableObject {
//    
//    enum State {
//        case idle, loading, success, failure
//    }
//    
//    // MARK: - Global flag
//    @Published private(set) var isAuthOperationInProgress: Bool = false
//    
//    // MARK: - Local states
//    @Published private(set) var signInState: State = .idle
//    @Published private(set) var signUpState: State = .idle
//    @Published private(set) var deleteAccountState: State = .idle
//    @Published private(set) var reauthState: State = .idle
//    
//    // MARK: - User info
//    @Published private(set) var isUserAnonymous: Bool = true
//    @Published private(set) var currentAuthUser: AuthUser?
//    @Published private(set) var primaryProvider: String?
//    @Published private(set) var providers: [String] = []
//    
//    private let authService: AuthorizationService
//    private let errorHandler: ErrorHandlerProtocol
//    private let alertManager: AlertManager
//    private var cancellables = Set<AnyCancellable>()
//    
//    init(service: AuthorizationService,
//         errorHandler: ErrorHandlerProtocol,
//         alertManager: AlertManager = AlertManager.shared) {
//        self.authService = service
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        
//        setupAuthStateSubscription()
//    }
//    
//    // MARK: - Auth State Subscription
//    private func setupAuthStateSubscription() {
//        authService.authStatePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] authUser in
//                self?.handleAuthStateChange(authUser)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func handleAuthStateChange(_ authUser: AuthUser?) {
//        isUserAnonymous = authUser?.isAnonymous ?? true
//        currentAuthUser = authUser
//        
//        resetProviders()
//        
//        guard let user = authUser, !user.isAnonymous else {
//            print("ℹ️ AuthorizationManager: анонимный или nil user — провайдеры не запрашиваем")
//            return
//        }
//        
//        subscribeToProviders()
//        subscribeToPrimaryProvider()
//    }
//    
//    private func resetProviders() {
//        providers = []
//        primaryProvider = nil
//    }
//    
//    // MARK: - Sign Up
//    func signUp(email: String, password: String) {
//        guard !isAuthOperationInProgress else { return }
//        isAuthOperationInProgress = true
//        signUpState = .loading
//        
//        authService.signUpBasic(email: email, password: password)
//            .sink { [weak self] completion in
//                self?.signUpState = .idle
//                self?.isAuthOperationInProgress = false
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let err):
//                    self.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signUp)
//                case .finished:
//                    NotificationCenter.default.post(
//                        name: .authDidSucceed,
//                        object: AuthNotificationPayload(authType: .emailSignUp)
//                    )
//                    DispatchQueue.main.async {
//                        self.alertManager.showGlobalAlert(
//                            message: Localized.MessageOfSuccessOperationFirebase.signUp,
//                            operationDescription: Localized.TitleOfSuccessOperationFirebase.signUp,
//                            alertType: .ok
//                        )
//                    }
//                    self.authService.sendVerificationEmail()
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Sign In
//    func signIn(email: String, password: String) {
//        guard !isAuthOperationInProgress else { return }
//        isAuthOperationInProgress = true
//        signInState = .loading
//        
//        authService.signInBasic(email: email, password: password)
//            .sink { [weak self] completion in
//                self?.signInState = .idle
//                self?.isAuthOperationInProgress = false
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let err):
//                    self.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signIn)
//                case .finished:
//                    NotificationCenter.default.post(
//                        name: .authDidSucceed,
//                        object: AuthNotificationPayload(authType: .emailSignIn)
//                    )
//                    DispatchQueue.main.async {
//                        self.alertManager.showGlobalAlert(
//                            message: Localized.MessageOfSuccessOperationFirebase.signIn,
//                            operationDescription: Localized.TitleOfSuccessOperationFirebase.signIn,
//                            alertType: .ok
//                        )
//                    }
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Delete Account
//    func deleteAccount() {
//        guard !isAuthOperationInProgress else { return }
//        isAuthOperationInProgress = true
//        deleteAccountState = .loading
//        
//        authService.deleteAccount()
//            .sink { [weak self] completion in
//                self?.deleteAccountState = .idle
//                self?.isAuthOperationInProgress = false
//                self?.handleDeleteAccountCompletion(completion)
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    private func handleDeleteAccountCompletion(_ completion: Subscribers.Completion<DeleteAccountError>) {
//        switch completion {
//        case .failure(let error):
//            handleDeleteAccountError(error)
//        case .finished:
//            showAccountDeletionSuccess()
//        }
//    }
//    
//    private func handleDeleteAccountError(_ error: DeleteAccountError) {
//        switch error {
//        case .reauthenticationRequired(let reauthError):
//            notifyReauthenticationNeeded()
//            DispatchQueue.main.async { [weak self] in
//                self?.showAccountDeletionError(
//                    reauthError,
//                    operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion
//                )
//            }
//        case .underlying(let underlyingError):
//            showAccountDeletionError(
//                underlyingError,
//                operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion
//            )
//        }
//    }
//    
//    private func notifyReauthenticationNeeded() {
//        NotificationCenter.default.post(
//            name: .needReauthenticate,
//            object: AuthNotificationPayload(authType: .reauthenticate)
//        )
//    }
//    
//    private func showAccountDeletionError(_ error: Error, operationDescription: String) {
//        handleAuthenticationError(error, operationDescription: operationDescription)
//    }
//    
//    private func showAccountDeletionSuccess() {
//        alertManager.showGlobalAlert(
//            message: Localized.MessageOfSuccessOperationFirebase.accountDeletion,
//            operationDescription: Localized.TitleOfSuccessOperationFirebase.accountDeletion,
//            alertType: .ok
//        )
//    }
//    
//    // MARK: - Reauthenticate
//    func confirmIdentity(email: String, password: String) {
//        guard !isAuthOperationInProgress else { return }
//        isAuthOperationInProgress = true
//        reauthState = .loading
//        
//        authService.reauthenticate(email: email, password: password)
//            .sink { [weak self] completion in
//                self?.reauthState = .idle
//                self?.isAuthOperationInProgress = false
//                switch completion {
//                case .finished:
//                    NotificationCenter.default.post(
//                        name: .authDidSucceed,
//                        object: AuthNotificationPayload(authType: .reauthenticate)
//                    )
//                    DispatchQueue.main.async {
//                        self?.alertManager.showGlobalAlert(
//                            message: "Повторная аутентификация прошла успешно!",
//                            operationDescription: "Аутентификация",
//                            alertType: .ok
//                        )
//                    }
//                case .failure(let error):
//                    self?.handleAuthenticationError(error, operationDescription: "Аутентификация")
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Error Handling
//    private func handleAuthenticationError(_ error: Error, operationDescription: String) {
//        errorHandler.handle(error, operationDescription: operationDescription)
//    }
//}





// MARK: - before Local states


//final class AuthorizationManager: ObservableObject {
//    enum State {
//        case idle, loading, success, failure
//    }
//    
//    @Published private(set) var state: State = .idle
//    @Published private(set) var isUserAnonymous: Bool = true
//    @Published private(set) var currentAuthUser: AuthUser?
//    @Published private(set) var primaryProvider: String?
//    @Published private(set) var providers: [String] = []
//    
//    private let authService: AuthorizationService
//    private let errorHandler: ErrorHandlerProtocol
//    private var cancellables = Set<AnyCancellable>()
//    
//    // Отдельные cancellable для провайдеров
//    private var providersCancellable: AnyCancellable?
//    private var primaryProviderCancellable: AnyCancellable?
//    
//    var alertManager: AlertManager
//    
//    init(service: AuthorizationService,
//         errorHandler: ErrorHandlerProtocol,
//         alertManager: AlertManager = AlertManager.shared) {
//        self.authService = service
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        
//        setupAuthStateSubscription()
//    }
//    
//    // MARK: - Подписки
//    
//    private func setupAuthStateSubscription() {
//        authService.authStatePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] authUser in
//                self?.handleAuthStateChange(authUser)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func handleAuthStateChange(_ authUser: AuthUser?) {
//        isUserAnonymous = authUser?.isAnonymous ?? true
//        currentAuthUser = authUser
//        
//        // ⚡️ Сбрасываем провайдеры при смене пользователя
//        resetProviders()
//        
//        // ⚡️ Подписываемся только если пользователь перманентный
//        guard let user = authUser, !user.isAnonymous else {
//            print("ℹ️ AuthorizationManager: анонимный или nil user — провайдеры не запрашиваем")
//            return
//        }
//        
//        subscribeToProviders()
//        subscribeToPrimaryProvider()
//    }
//    
//    private func resetProviders() {
//        primaryProvider = nil
//        providers = []
//        
//        // Отменяем старые подписки
//        providersCancellable?.cancel()
//        providersCancellable = nil
//        
//        primaryProviderCancellable?.cancel()
//        primaryProviderCancellable = nil
//    }
//    
//    private func subscribeToProviders() {
//        providersCancellable?.cancel() // отменяем старую подписку
//        providersCancellable = authService.authProvidersPublisher()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] providers in
//                self?.providers = providers
//                if providers.isEmpty {
//                    print("⚠️ AuthorizationManager: пустой список провайдеров для перманентного пользователя")
//                    // TODO: Crashlytics.log("Empty providers list for permanent user")
//                }
//                print("⚠️ AuthorizationManager: subscribeToProviders - \(providers)")
//            }
//    }
//    
//    private func subscribeToPrimaryProvider() {
//        primaryProviderCancellable?.cancel() // отменяем старую подписку
//        primaryProviderCancellable = authService.primaryAuthProviderPublisher()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] provider in
//                self?.primaryProvider = provider
////                self?.primaryProvider = nil
//                if provider == nil {
//                    print("⚠️ AuthorizationManager: primary provider == nil для перманентного пользователя")
//                    // TODO: Crashlytics.log("Primary provider is nil for permanent user")
//                }
//                print("⚠️ AuthorizationManager: subscribeToPrimaryProvider - \(String(describing: provider))")
//            }
//    }
//
//    func handleError(_ error: Error, operationDescription:String) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
//    }
//    
//    private func handleAuthenticationError(_ error: Error, operationDescription:String) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
//    }
//    
//    func signUp(email: String, password: String) {
//        state = .loading
//        
//        authService.signUpBasic(email: email, password: password)
//            .sink { [weak self] completion in
//                self?.state = .idle
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let err):
//                    self.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signUp)
//                case .finished:
//                    NotificationCenter.default.post(
//                        name: .authDidSucceed,
//                        object: AuthNotificationPayload(authType: .emailSignUp)
//                    )
//                    DispatchQueue.main.async { [weak self] in
//                        self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.signUp, operationDescription:Localized.TitleOfSuccessOperationFirebase.signUp, alertType: .ok)
//                    }
//                    self.authService.sendVerificationEmail()
//                    
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    func signIn(email: String, password: String) {
//        state = .loading
//        
//        authService.signInBasic(email: email, password: password)
//            .sink { [weak self] completion in
//                self?.state = .idle
//                guard let self = self else { return }
//                switch completion {
//                case .failure(let err):
//                    self.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signIn)
//                case .finished:
//                    NotificationCenter.default.post(
//                        name: .authDidSucceed,
//                        object: AuthNotificationPayload(authType: .emailSignIn)
//                    )
//                    DispatchQueue.main.async { [weak self] in
//                        self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.signIn, operationDescription:Localized.TitleOfSuccessOperationFirebase.signIn, alertType: .ok)
//                    }
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    
//    func deleteAccount() {
//        state = .loading
//        
//        authService.deleteAccount()
//            .sink { [weak self] completion in
//                self?.handleDeleteAccountCompletion(completion)
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    // Private Methods for deleteAccount()
//    
//    private func handleDeleteAccountCompletion(_ completion: Subscribers.Completion<DeleteAccountError>) {
//        state = .idle
//        
//        switch completion {
//        case .failure(let error):
//            handleDeleteAccountError(error)
//        case .finished:
//            showAccountDeletionSuccess()
//        }
//    }
//    
//    private func handleDeleteAccountError(_ error:  DeleteAccountError) {
//        switch error {
//        case .reauthenticationRequired(let reauthError):
//            notifyReauthenticationNeeded()
//            // Специальная обработка для навигационных переходов
//            DispatchQueue.main.async { [weak self] in
//                self?.showAccountDeletionError(
//                    reauthError,
//                    operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion
//                )
//            }
//            
//        case .underlying(let underlyingError):
//            // Обычные ошибки уже на главном потоке благодаря receive(on:)
//            showAccountDeletionError(
//                underlyingError,
//                operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion
//            )
//        }
//    }
//    
//    private func notifyReauthenticationNeeded() {
//        NotificationCenter.default.post(
//            name: .needReauthenticate,
//            object: AuthNotificationPayload(authType: .reauthenticate)
//        )
//    }
//    
//    private func showAccountDeletionError(_ error: Error, operationDescription: String) {
//        handleAuthenticationError(error, operationDescription: operationDescription)
//    }
//    
//    private func showAccountDeletionSuccess() {
//        alertManager.showGlobalAlert(
//            message: Localized.MessageOfSuccessOperationFirebase.accountDeletion,
//            operationDescription: Localized.TitleOfSuccessOperationFirebase.accountDeletion,
//            alertType: .ok
//        )
//    }
//
//    
//    func confirmIdentity(email: String, password: String) {
//        state = .loading
//        authService.reauthenticate(email: email, password: password)
//            .sink { [weak self] completion in
//                self?.state = .idle
//                switch completion {
//                case .finished:
//                    NotificationCenter.default.post(
//                        name: .authDidSucceed,
//                        object: AuthNotificationPayload(authType: .reauthenticate)
//                    )
//                    DispatchQueue.main.async { [weak self] in
//                        self?.alertManager.showGlobalAlert(message:"Повторная аутентификация прошла успешно!", operationDescription: "Аутентификация", alertType: .ok)
//                    }
//                case .failure(let error):
//                    self?.handleAuthenticationError(error, operationDescription: "Аутентификация")
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//    
//    func signOutAccount() {
//        state = .loading
//        
//        authService.signOut()
//            .sink { [weak self] completion in
//                self?.state = .idle
//                switch completion {
//                case .failure(let error):
//                    self?.handleAuthenticationError(error, operationDescription: "SignOut")
//                case .finished:
//                    DispatchQueue.main.async { [weak self] in
//                        self?.alertManager.showGlobalAlert(message:"Success signOut user!", operationDescription:"SignOut", alertType: .ok)
//                    }
//                }
//            } receiveValue: { _ in }
//            .store(in: &cancellables)
//    }
//}











// MARK: - before subscribeToProvider

//import Combine
//import SwiftUI
////@MainActor
//final class AuthorizationManager: ObservableObject {
//
//    enum State {
//        case idle
//        case loading
//        case success
//        case failure
//    }
//
//    @Published private(set) var state: State = .idle
//    @Published private(set) var isUserAnonymous: Bool = true
//    @Published private(set) var currentAuthUser: AuthUser?
//    var alertManager:AlertManager
//    private let authService: AuthorizationService
//    private let errorHandler: ErrorHandlerProtocol
//    private var cancellables = Set<AnyCancellable>()
//
//    init(service: AuthorizationService, errorHandler: ErrorHandlerProtocol, alertManager: AlertManager = AlertManager.shared) {
//        print("init AuthorizationManager")
//        self.authService = service
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//
//        // ??? может на вский случай тут менять state = .idle
//        authService.authStatePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] authUser in
//                self?.isUserAnonymous = authUser?.isAnonymous ?? true
//                self?.currentAuthUser = authUser // Сохраняем текущего пользователя
//            }
//            .store(in: &cancellables)
//    }











    
    //    func deleteAccount() {
    //        state = .loading
    //
    //        authService.deleteAccount()
    //            .sink { [weak self] completion in
    //                self?.state = .idle
    //                switch completion {
    //                case .failure(let error):
    //                    switch error {
    //                    case .reauthenticationRequired(let reauthError):
    //                        NotificationCenter.default.post(
    //                            name: .needReauthenticate,
    //                            object: AuthNotificationPayload(authType: .reauthenticate)
    //                        )
    //                        DispatchQueue.main.async { [weak self] in
    //                            self?.handleAuthenticationError(reauthError, operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion)
    //                        }
    //                    case .underlying(let underlyingError):
    //                        self?.handleAuthenticationError(underlyingError, operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion)
    //                    }
    //
    //                case .finished:
    //                    DispatchQueue.main.async { [weak self] in
    //                        self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.accountDeletion, operationDescription:Localized.TitleOfSuccessOperationFirebase.accountDeletion, alertType: .ok)
    //                    }
    //                }
    //            } receiveValue: { _ in }
    //            .store(in: &cancellables)
    //    }
        
            
    // before DeleteAccountError
    //    func deleteAccount() {
    //        state = .loading
    //
    //        authService.deleteAccount()
    //            .sink { [weak self] completion in
    //                self?.state = .idle
    //                switch completion {
    //                case .failure(let error):
    //                    self?.handleAuthenticationError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.accountDeletion)
    //                case .finished:
    //                    DispatchQueue.main.async { [weak self] in
    //                        self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.accountDeletion, operationDescription:Localized.TitleOfSuccessOperationFirebase.accountDeletion, alertType: .ok)
    //                    }
    //                }
    //            } receiveValue: { _ in }
    //            .store(in: &cancellables)
    //    }
    
    //    func createProfile(name: String) {
    //        state = .loading
    //
    //        authService.createProfile(name: name)
    //            .sink { [weak self] completion in
    //                switch completion {
    //                case .failure(_):
    //                    self?.state = .failure
    //                case .finished:
    //                    self?.state = .success
    //                }
    //            } receiveValue: { _ in }
    //            .store(in: &cancellables)
    //    }
    
    // MARK: - Test methods
    

//test
//    func deleteAccount() {
//        state = .loading
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
//            self?.state = .idle
//            DispatchQueue.main.async { [weak self] in
//                self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.accountDeletion, operationDescription:Localized.TitleOfSuccessOperationFirebase.accountDeletion, alertType: .ok)
//            }
//        }
//    }

//    // test func signUp
//    func signUp(email: String, password: String) {
//        state = .loading
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
//            self?.state = .idle
//            NotificationCenter.default.post(
//                name: .authDidSucceed,
//                object: AuthNotificationPayload(authType: .emailSignUp)
//            )
//            DispatchQueue.main.async { [weak self] in
//                self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.signUp, operationDescription:Localized.TitleOfSuccessOperationFirebase.signUp, alertType: .ok)
//            }
//        }
//    }


//test
//    func deleteAccount() {
//        state = .loading
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
//            self?.state = .idle
//            DispatchQueue.main.async { [weak self] in
//                self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.accountDeletion, operationDescription:Localized.TitleOfSuccessOperationFirebase.accountDeletion, alertType: .ok)
//            }
//        }
//    }



//        authService.authStatePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] authUser in
//                self?.isUserAnonymous = authUser?.isAnonymous ?? true
//            }
//            .store(in: &cancellables)



// MARK: - func signUp(email: String, password: String, name: String) - create user and create profile user

//@MainActor
//final class AuthorizationManager: ObservableObject {
//  
//    enum State {
//    case idle
//    case loading
//    case profileIncomplete(userId: String)
//    case success
//    case failure(AuthError)
//  }
//
//  @Published private(set) var state: State = .idle
//  private let authService: AuthorizationService
//  private var currentUserId: String?
//  private var cancellables = Set<AnyCancellable>()
//
//  init(service: AuthorizationService) {
//    self.authService = service
//  }
//
//  // Запускает flow: базовая регистрация → создание профиля
//  func signUp(email: String, password: String, name: String) {
//    state = .loading
//
//    authService.signUpBasic(email: email, password: password)
//      .flatMap { [weak self] userId -> AnyPublisher<Void, AuthError> in
//        guard let self = self else {
//          return Fail(error: .unknown).eraseToAnyPublisher()
//        }
//        self.currentUserId = userId
//        return self.authService.createProfile(name: name)
//      }
//      .sink { [weak self] completion in
//        switch completion {
//        case .failure(let err):
//          if let id = self?.currentUserId {
//            // регистрация прошла, но профиль не сохранился
//            self?.state = .profileIncomplete(userId: id)
//          } else {
//            // сама регистрация упала
//            self?.state = .failure(err)
//          }
//        case .finished:
//          // всё прошло хорошо
//          self?.authService.sendVerificationEmail()
//          self?.state = .success
//        }
//      } receiveValue: { _ in }
//      .store(in: &cancellables)
//  }
//
//  // Повторный апдейт профиля без повторной регистрации
//  func retryCreateProfile(name: String) {
//    guard let _ = currentUserId else { return }
//    state = .loading
//
//    authService.createProfile(name: name)
//      .sink { [weak self] completion in
//        switch completion {
//        case .failure:
//          self?.state = .profileIncomplete(
//            userId: self?.currentUserId ?? ""
//          )
//        case .finished:
//          self?.authService.sendVerificationEmail()
//          self?.state = .success
//        }
//      } receiveValue: { _ in }
//      .store(in: &cancellables)
//  }
//}






