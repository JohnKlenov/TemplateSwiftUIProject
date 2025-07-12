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
    @Published var showDeleteConfirmation = false
    /// можно сделать shouldShowDeleteButton как isUserAnonymous а в ContentAccountView изменить на  if !viewModel.isUserAnonymous
//    @Published private(set) var shouldShowDeleteButton: Bool = false
    @Published private(set) var isUserAnonymous: Bool = false
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var profileLoadingState: AuthorizationManager.State = .idle
    
    private let authorizationManager: AuthorizationManager
    private let profileService: FirestoreProfileService
    private var cancellables = Set<AnyCancellable>()
    
    init(authorizationManager: AuthorizationManager, profileService: FirestoreProfileService) {
        print("init ContentAccountViewModel")
        self.authorizationManager = authorizationManager
        self.profileService = profileService
        
        /// можно в authorizationManager завести отдельный accountDeletionState?
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
                
                // 1. Обновление кнопки
//                self.shouldShowDeleteButton = !isAnonymous
                self.isUserAnonymous = isAnonymous
                
                // 2. Загрузка профиля (если нужно)
                if !isAnonymous, let uid = authUser?.uid {
                    self.loadUserProfile(uid: uid)
                } else {
                    // 3. Сброс данных для анонимов
                    self.userProfile = nil
                    self.profileLoadingState = .idle
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadUserProfile(uid: String) {
        profileLoadingState = .loading
        profileService.fetchProfile(uid: uid)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(_) = completion {
                    self?.profileLoadingState = .idle
                }
            } receiveValue: { [weak self] profile in
                self?.userProfile = profile
                self?.profileLoadingState = .idle
            }
            .store(in: &cancellables)
    }
    
    func deleteAccount() {
        authorizationManager.deleteAccount()
    }
    
    deinit {
        /// это излишний код SwiftUI сам убират подписчиков после удаления
        cancellables.removeAll()
        print("deinit ContentAccountViewModel")
    }
}

//        authorizationManager.$isUserAnonymous
//            .map { !$0 } // инвертируем полученные данные
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] shouldShow in
//                self?.shouldShowDeleteButton = shouldShow
//            }
//            .store(in: &cancellables)
