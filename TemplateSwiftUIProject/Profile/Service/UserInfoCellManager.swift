//
//  UserInfoCellManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.10.25.
//

import Combine
import FirebaseFirestore

/// Менеджер для работы с профилем пользователя.
/// Инкапсулирует бизнес-логику загрузки профиля и обработки ошибок.
/// Отдаёт наружу паблишеры для ViewModel.
final class UserInfoCellManager {
    private let profileService: FirestoreProfileService
    private let errorHandler: ErrorHandlerProtocol
    
    // Publisher'ы для связи с ViewModel
    let profileLoadingState = CurrentValueSubject<AuthorizationManager.State, Never>(.idle)
    let userProfile = CurrentValueSubject<UserProfile?, Never>(nil)
    
    private var profileLoadCancellable: AnyCancellable?
    
    init(profileService: FirestoreProfileService,
         errorHandler: ErrorHandlerProtocol) {
        self.profileService = profileService
        self.errorHandler = errorHandler
    }
    
    /// Загружает профиль пользователя по UID.
    /// - Обновляет состояние загрузки.
    /// - В случае успеха публикует профиль.
    /// - В случае ошибки публикует `.failure` и вызывает глобальный алерт.
    func loadUserProfile(uid: String) {
        profileLoadCancellable?.cancel()
        profileLoadingState.send(.loading)
        
        profileLoadCancellable = profileService.fetchProfile(uid: uid)
            .sink(
                receiveCompletion: { [weak self] completion in
                    switch completion {
                    case .finished:
                        self?.profileLoadingState.send(.idle)
                    case .failure(let error):
                        self?.profileLoadingState.send(.failure)
                        self?.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile.send(profile)
                    self?.profileLoadingState.send(.idle)
                }
            )
    }
    
    private func handleError(_ error: Error, operationDescription: String) {
        let errorMessage = errorHandler.handle(error: error)
        AlertManager.shared.showGlobalAlert(
            message: errorMessage,
            operationDescription: operationDescription,
            alertType: .ok
        )
    }
}

