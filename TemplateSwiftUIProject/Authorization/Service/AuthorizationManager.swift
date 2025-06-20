//
//  AuthorizationManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 16.06.25.
//

// AuthorizationManager.swift
import Combine

@MainActor
final class AuthorizationManager: ObservableObject {
  
    enum State {
    case idle
    case loading
    case profileIncomplete(userId: String)
    case success
    case failure(AuthError)
  }

  @Published private(set) var state: State = .idle
  private let authService: AuthorizationService
  private var currentUserId: String?
  private var cancellables = Set<AnyCancellable>()

  init(service: AuthorizationService) {
    self.authService = service
  }

  // Запускает flow: базовая регистрация → создание профиля
  func signUp(email: String, password: String, name: String) {
    state = .loading

    authService.signUpBasic(email: email, password: password)
      .flatMap { [weak self] userId -> AnyPublisher<Void, AuthError> in
        guard let self = self else {
          return Fail(error: .unknown).eraseToAnyPublisher()
        }
        self.currentUserId = userId
        return self.authService.createProfile(name: name)
      }
      .sink { [weak self] completion in
        switch completion {
        case .failure(let err):
          if let id = self?.currentUserId {
            // регистрация прошла, но профиль не сохранился
            self?.state = .profileIncomplete(userId: id)
          } else {
            // сама регистрация упала
            self?.state = .failure(err)
          }
        case .finished:
          // всё прошло хорошо
          self?.authService.sendVerificationEmail()
          self?.state = .success
        }
      } receiveValue: { _ in }
      .store(in: &cancellables)
  }

  // Повторный апдейт профиля без повторной регистрации
  func retryCreateProfile(name: String) {
    guard let _ = currentUserId else { return }
    state = .loading

    authService.createProfile(name: name)
      .sink { [weak self] completion in
        switch completion {
        case .failure:
          self?.state = .profileIncomplete(
            userId: self?.currentUserId ?? ""
          )
        case .finished:
          self?.authService.sendVerificationEmail()
          self?.state = .success
        }
      } receiveValue: { _ in }
      .store(in: &cancellables)
  }
}






