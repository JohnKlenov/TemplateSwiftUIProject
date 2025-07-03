//
//  AuthorizationManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.06.25.
//

// AuthorizationManager мы будем использовать в нескольких View из разных навигационных стеков
// у нас есть возможность не дождавшись ответа от сервера покинуть View (и если бы не было единого AuthorizationManager мы не смогли бы дождаться ответа) если есть ошибка она будет выбрашена через глобальный алерт если success то мы будем оповещены алертом глобальным
// если мы введем данные в SignUp и нажмем кнопку регистрации и не дождавшись ответа перейдем на экран SignIn то так как AuthorizationManager общий с общей state машиной мы и на экране SignIn увидим что идет загрузка и не сможем перегруждать сервер различными операциями авторизации пока не дождемся последовательного выполнения каждого из них


import Combine
import SwiftUI
//@MainActor
final class AuthorizationManager: ObservableObject {
  
    enum State {
        case idle
        case loading
        case success
        case failure
    }

  @Published private(set) var state: State = .idle
//    @Published var state: State = .idle
    var alertManager:AlertManager
    private let authService: AuthorizationService
    private let errorHandler: ErrorHandlerProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: AuthorizationService, errorHandler: ErrorHandlerProtocol, alertManager: AlertManager = AlertManager.shared) {
        self.authService = service
        self.errorHandler = errorHandler
        self.alertManager = alertManager
    }

    private func handleAuthenticationError(_ error: Error, operationDescription:String) {
        let errorMessage = errorHandler.handle(error: error)
        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
    }

    func signUp(email: String, password: String) {
        state = .loading
        
        authService.signUpBasic(email: email, password: password)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let err):
                    self?.handleAuthenticationError(err, operationDescription: Localized.TitleOfFailedOperationFirebase.signUp)
                    self?.state = .idle
                case .finished:
                    self?.state = .idle
                    NotificationCenter.default.post(
                                    name: .authDidSucceed,
                                    object: AuthNotificationPayload(authType: .emailSignUp)
                                )
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                            self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.signUp, operationDescription:Localized.TitleOfSuccessOperationFirebase.signUp, alertType: .ok)
                        }
                    self?.authService.sendVerificationEmail()
                    
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    // test func signUp
//    func signUp(email: String, password: String) {
//        state = .loading
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
//            self?.state = .idle
//            NotificationCenter.default.post(
//                name: .authDidSucceed,
//                object: AuthNotificationPayload(authType: .emailSignUp)
//            )
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//                self?.alertManager.showGlobalAlert(message:Localized.MessageOfSuccessOperationFirebase.signUp, operationDescription:Localized.TitleOfSuccessOperationFirebase.signUp, alertType: .ok)
//            }
//        }
//    }

  // Повторный апдейт профиля без повторной регистрации
  func createProfile(name: String) {
    state = .loading

    authService.createProfile(name: name)
      .sink { [weak self] completion in
        switch completion {
        case .failure(let err):
          self?.state = .failure
        case .finished:
          self?.state = .success
        }
      } receiveValue: { _ in }
      .store(in: &cancellables)
  }
}



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






