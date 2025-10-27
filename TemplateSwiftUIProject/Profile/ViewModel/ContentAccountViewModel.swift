//
//  ContentAccountViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//

import SwiftUI
import Combine

@MainActor
class ContentAccountViewModel: ObservableObject {
    @Published var accountDeletionState: AuthorizationManager.State = .idle
    @Published private(set) var profileLoadingState: AuthorizationManager.State = .idle
    @Published var showDeleteConfirmation = false
    @Published private(set) var isUserAnonymous: Bool = true
    @Published private(set) var userProfile: UserProfile?
    
    private let authorizationManager: AuthorizationManager
    private let userInfoCellManager: UserInfoCellManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authorizationManager: AuthorizationManager,
         userInfoCellManager: UserInfoCellManager) {
        self.authorizationManager = authorizationManager
        self.userInfoCellManager = userInfoCellManager
        self.profileLoadingState = .loading 
        bindProfileManager()
        bindAuthorizationManager()
    }
    
    // MARK: - Public API
    
    func retryUserProfile() {
        /// такой return нужно логировать через crashListics
        guard !isUserAnonymous,
              let uid = authorizationManager.currentAuthUser?.uid else { return }
        userInfoCellManager.loadUserProfile(uid: uid)
    }
    
    func deleteAccount() {
        authorizationManager.deleteAccount()
        // authorizationManager.signOutAccount()
    }
    
    // MARK: - Private bindings
    
    private func bindProfileManager() {
        // Подписка на состояние загрузки
        userInfoCellManager.profileLoadingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.profileLoadingState = state
            }
            .store(in: &cancellables)
        
        // Подписка на профиль
        userInfoCellManager.userProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                self?.userProfile = profile
            }
            .store(in: &cancellables)
    }
    
    private func bindAuthorizationManager() {
        // Подписка на состояние удаления аккаунта
        authorizationManager.$state
            .handleEvents(receiveOutput: { print("→ ContentAccountViewModel подписка получила:", $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.accountDeletionState = state
            }
            .store(in: &cancellables)
        
        // Подписка на изменения авторизации
        authorizationManager.$isUserAnonymous
            .combineLatest(authorizationManager.$currentAuthUser)
            .sink { [weak self] (isAnonymous, authUser) in
                guard let self = self else { return }
                self.isUserAnonymous = isAnonymous
                self.userProfile = nil
                if !isAnonymous, let uid = authUser?.uid {
                    self.userInfoCellManager.loadUserProfile(uid: uid)
                } else {
                    self.profileLoadingState = .idle
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        /// это излишний код SwiftUI сам убират подписчиков после удаления
        cancellables.removeAll()
        print("deinit ContentAccountViewModel")
    }
}


//import SwiftUI
//import Combine
//
//@MainActor
//class ContentAccountViewModel: ObservableObject {
//    
//    @Published var accountDeletionState: AuthorizationManager.State = .idle
//    @Published private(set) var profileLoadingState: AuthorizationManager.State = .idle
//    @Published var showDeleteConfirmation = false
//    @Published private(set) var isUserAnonymous: Bool = true
//    @Published private(set) var userProfile: UserProfile?
//    
//    private let authorizationManager: AuthorizationManager
//    private let profileService: FirestoreProfileService
//    private let errorHandler: ErrorHandlerProtocol
//    private let alertManager: AlertManager
//    
//    private var profileLoadCancellable: AnyCancellable?
//    private var cancellables = Set<AnyCancellable>()
//    
//    init(authorizationManager: AuthorizationManager, profileService: FirestoreProfileService, errorHandler: ErrorHandlerProtocol, alertManager: AlertManager = .shared) {
//        print("init ContentAccountViewModel")
//        self.authorizationManager = authorizationManager
//        self.profileService = profileService
//        self.errorHandler = errorHandler
//        self.alertManager = alertManager
//        self.profileLoadingState = .loading
//        /// можно в authorizationManager завести отдельный accountDeletionState?
//        authorizationManager.$state
//            .handleEvents(receiveOutput: { print("→ ContentAccountViewModel подписка получила:", $0) })
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.accountDeletionState = state
//            }
//            .store(in: &cancellables)
//        
//        // Подписка на изменения авторизации
//        authorizationManager.$isUserAnonymous
//            .combineLatest(authorizationManager.$currentAuthUser)
//            .sink { [weak self] (isAnonymous, authUser) in
//                guard let self = self else { return }
//                
//                // 1. Обновление кнопки
//                self.isUserAnonymous = isAnonymous
//                /// если сделали signIn нужно обнулить
//                self.userProfile = nil
//                // 2. Загрузка профиля (если нужно)
//                if !isAnonymous, let uid = authUser?.uid {
//                    self.loadUserProfile(uid: uid)
//                } else {
//                    // 3. Сброс данных для анонимов
//                    // если при удалении account у нас не получится создать анонимного то тут будет nil и глобальный алерт с ретрай
////                    self.userProfile = nil
//                    self.profileLoadingState = .idle
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    func retryUserProfile() {
//        /// такой return нужно логировать через crashListics
//        guard !isUserAnonymous, let uid = authorizationManager.currentAuthUser?.uid else { return }
//        loadUserProfile(uid: uid)
////        self.profileLoadingState = .loading
////        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
////            self?.profileLoadingState = .failure
////        }
//    }
//    
//
//
//    // как не поймать ошибку в  profileService.fetchProfile(uid: uid) в момент удаления аккаунта?
//    /// Чтобы быть полностью защищённым, комбинируй два уровня: В observeUserChanges() сразу снимаешь listener. + Внутри самого listener’а проверяешь uid == currentUID.
//    private func loadUserProfile(uid: String) {
//        
//        // 1. Отменяем предыдущую загрузку профиля
//        profileLoadCancellable?.cancel()
//        profileLoadingState = .loading
//        
//        // 2. Создаем новую подписку
//        profileLoadCancellable = profileService.fetchProfile(uid: uid)
//            .receive(on: DispatchQueue.main)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    switch completion {
//                    case .finished:
//                        self?.profileLoadingState = .idle
//                    case .failure(let error):
//                        self?.profileLoadingState = .failure
//                        self?.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
//                    }
//                },
//                receiveValue: { [weak self] profile in
//                    print("loadUserProfile/receiveValue -  \(profile)")
//                    self?.userProfile = profile
//                    self?.profileLoadingState = .idle
//                }
//            )
//    }
//
//    
//    func deleteAccount() {
//        authorizationManager.deleteAccount()
//        //        authorizationManager.signOutAccount()
//    }
//    
//    private func handleError(_ error: Error, operationDescription: String) {
//        let errorMessage = errorHandler.handle(error: error)
//        alertManager.showGlobalAlert(message: errorMessage, operationDescription: operationDescription, alertType: .ok)
//    }
//    
//    deinit {
//        /// это излишний код SwiftUI сам убират подписчиков после удаления
//        cancellables.removeAll()
//        print("deinit ContentAccountViewModel")
//    }
//   }





//private func loadUserProfile(uid: String) {
//    
//    // 1. Отменяем предыдущую загрузку профиля
//    profileLoadCancellable?.cancel()
//    profileLoadingState = .loading
//    
//    // 2. Создаем новую подписку
//    profileLoadCancellable = profileService.fetchProfile(uid: uid)
//        .receive(on: DispatchQueue.main)
//        .sink(
//            receiveCompletion: { [weak self] completion in
//                switch completion {
//                case .finished:
//                    self?.profileLoadingState = .idle
//                case .failure(_):
//                    self?.profileLoadingState = .failure
//                }
//            },
//            receiveValue: { [weak self] profile in
//                print("loadUserProfile/receiveValue -  \(profile)")
//                self?.userProfile = profile
//                self?.profileLoadingState = .idle
//            }
//        )
//}

//private func loadUserProfile(uid: String) {
//    // 1. Отменяем предыдущую загрузку профиля
//    profileLoadCancellable?.cancel()
//    
//    // 2. Устанавливаем состояние загрузки
//    profileLoadingState = .loading
//    
//    // 3. Создаем новую подписку
//    profileLoadCancellable = profileService.fetchProfile(uid: uid)
//        .receive(on: DispatchQueue.main)
//        .sink(
//            receiveCompletion: { [weak self] _ in
//                self?.profileLoadingState = .idle
//            },
//            receiveValue: { [weak self] profile in
//                self?.userProfile = profile
//                self?.profileLoadingState = .idle
//            }
//        )
//}

//        authorizationManager.$isUserAnonymous
//            .map { !$0 } // инвертируем полученные данные
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] shouldShow in
//                self?.shouldShowDeleteButton = shouldShow
//            }
//            .store(in: &cancellables)


//private func loadUserProfile(uid: String) {
//    profileLoadingState = .loading
//    profileService.fetchProfile(uid: uid)
//        .receive(on: DispatchQueue.main)
//        .sink { [weak self] completion in
//            // Все ошибки уже обработаны в ProfileService
//            self?.profileLoadingState = .idle
//        } receiveValue: { [weak self] profile in
//            self?.userProfile = profile
//            self?.profileLoadingState = .idle
//        }
//        .store(in: &cancellables)
//}
