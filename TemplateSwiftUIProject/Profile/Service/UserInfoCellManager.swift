//
//  UserInfoCellManager.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 27.10.25.
//

// при удалении аккаунта мы теряем права на листенерах прошлого пользователя
// что может вызвать в блоке addSnapshotListener ошибку (FirestoreProfileService.fetchProfile + HomeManager.observeBooks().firestoreService.observeCollection(at: path) )
// в HomeManager эта ошибка мелькнет на табе и тут же смениться состояние но success при новом успешном подключении листенера (лог уходит в крашлистик)
//
// при удалении аккаунта (перманентный -> анон) в FirestoreProfileService.fetchProfile хендлер алерта не срабатывает на UI так как мы успеваем в UserInfoCellManager.observeUserChanges() userListenerCancellable = userProvider.currentUserPublisher отписаться и не вызываем хендлер с алертом!
// но FirestoreProfileService fetchProfile error отрабатывает в блоке принтом
// видимо по тому что profileListener в FirestoreProfileService для func fetchProfile(uid: String) все еще живет в памяти! ведь этот объект FirestoreProfileService  не удаляется а для анонимного юзера повторного вызова func fetchProfile(uid: String) не происходит автоматически



import Combine
import FirebaseFirestore

/// Менеджер для работы с профилем пользователя.
/// Инкапсулирует бизнес-логику загрузки профиля и обработки ошибок.
/// Отдаёт наружу паблишеры для ViewModel.
final class UserInfoCellManager {
    private let profileService: FirestoreProfileService
    private let userProvider: CurrentUserProvider
    private let errorHandler: ErrorDiagnosticsProtocol
    
    // Publisher'ы для связи с ViewModel
    let profileLoadingState = CurrentValueSubject<AuthorizationManager.State, Never>(.idle)
    let userProfile = CurrentValueSubject<UserProfile?, Never>(nil)
    
    private var profileLoadCancellable: AnyCancellable?
    private var userListenerCancellable: AnyCancellable?
    
    private var currentUID: String?
    
    init(profileService: FirestoreProfileService, userProvider: CurrentUserProvider,
         errorHandler: ErrorDiagnosticsProtocol) {
        self.profileService = profileService
        self.userProvider = userProvider
        self.errorHandler = errorHandler
        self.observeUserChanges()
    }
    
    private func observeUserChanges() {
        userListenerCancellable = userProvider.currentUserPublisher
            .sink { [weak self] authUser in
                guard let self = self else { return }
                let newUID = authUser?.uid
                if self.currentUID != newUID {
                    print("🔄 UserInfoCellManager получил нового пользователя: \(String(describing: self.currentUID)) → \(String(describing: newUID))")
                    self.profileLoadCancellable?.cancel()
                    self.profileLoadCancellable = nil
                    
                    self.profileService.cancelProfileListener()
                    self.currentUID = newUID
                }
            }
    }

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
                        self?.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData, context: ErrorContext.UserInfoCellManager_loadUserProfile_profileService_fetchProfile.rawValue)
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile.send(profile)
                    self?.profileLoadingState.send(.idle)
                }
            )
    }
    
    private func handleError(_ error: Error, operationDescription: String, context: String) {
        let errorMessage = errorHandler.handle(
            error: error,
            context: context
        )
        
        AlertManager.shared.showGlobalAlert(
            message: errorMessage,
            operationDescription: operationDescription,
            alertType: .ok
        )
    }

}




// MARK: - before .profileService.cancelProfileListener()
//
//import Combine
//import FirebaseFirestore
//
///// Менеджер для работы с профилем пользователя.
///// Инкапсулирует бизнес-логику загрузки профиля и обработки ошибок.
///// Отдаёт наружу паблишеры для ViewModel.
//final class UserInfoCellManager {
//    private let profileService: FirestoreProfileService
//    private let userProvider: CurrentUserProvider
//    private let errorHandler: ErrorDiagnosticsProtocol
//    
//    // Publisher'ы для связи с ViewModel
//    let profileLoadingState = CurrentValueSubject<AuthorizationManager.State, Never>(.idle)
//    let userProfile = CurrentValueSubject<UserProfile?, Never>(nil)
//    
//    private var profileLoadCancellable: AnyCancellable?
//    private var userListenerCancellable: AnyCancellable?
//    
//    private var currentUID: String?
//    
//    init(profileService: FirestoreProfileService, userProvider: CurrentUserProvider,
//         errorHandler: ErrorDiagnosticsProtocol) {
//        self.profileService = profileService
//        self.userProvider = userProvider
//        self.errorHandler = errorHandler
//        self.observeUserChanges()
//    }
//    
//    private func observeUserChanges() {
//        userListenerCancellable = userProvider.currentUserPublisher
//            .sink { [weak self] authUser in
//                guard let self = self else { return }
//                let newUID = authUser?.uid
//                if self.currentUID != newUID {
//                    print("🔄 UserInfoCellManager получил нового пользователя: \(String(describing: self.currentUID)) → \(String(describing: newUID))")
//                    self.profileLoadCancellable?.cancel()
//                    self.currentUID = newUID
//                }
//            }
//    }
//
//    func loadUserProfile(uid: String) {
//        profileLoadCancellable?.cancel()
//        profileLoadingState.send(.loading)
//        
//        profileLoadCancellable = profileService.fetchProfile(uid: uid)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    
//                    switch completion {
//                    case .finished:
//                        self?.profileLoadingState.send(.idle)
//                    case .failure(let error):
//                        self?.profileLoadingState.send(.failure)
//                        self?.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData, context: ErrorContext.UserInfoCellManager_loadUserProfile_profileService_fetchProfile.rawValue)
//                    }
//                },
//                receiveValue: { [weak self] profile in
//                    self?.userProfile.send(profile)
//                    self?.profileLoadingState.send(.idle)
//                }
//            )
//    }
//    
//    private func handleError(_ error: Error, operationDescription: String, context: String) {
//        let errorMessage = errorHandler.handle(
//            error: error,
//            context: context
//        )
//        
//        AlertManager.shared.showGlobalAlert(
//            message: errorMessage,
//            operationDescription: operationDescription,
//            alertType: .ok
//        )
//    }
//
//}



// MARK: - before ErrorDiagnosticsProtocol


//import Combine
//import FirebaseFirestore
//
///// Менеджер для работы с профилем пользователя.
///// Инкапсулирует бизнес-логику загрузки профиля и обработки ошибок.
///// Отдаёт наружу паблишеры для ViewModel.
//final class UserInfoCellManager {
//    private let profileService: FirestoreProfileService
//    private let userProvider: CurrentUserProvider
//    private let errorHandler: ErrorHandlerProtocol
//    
//    // Publisher'ы для связи с ViewModel
//    let profileLoadingState = CurrentValueSubject<AuthorizationManager.State, Never>(.idle)
//    let userProfile = CurrentValueSubject<UserProfile?, Never>(nil)
//    
//    private var profileLoadCancellable: AnyCancellable?
//    private var userListenerCancellable: AnyCancellable?
//    
//    private var currentUID: String?
//    
//    init(profileService: FirestoreProfileService, userProvider: CurrentUserProvider,
//         errorHandler: ErrorHandlerProtocol) {
//        self.profileService = profileService
//        self.userProvider = userProvider
//        self.errorHandler = errorHandler
//        self.observeUserChanges()
//    }
//    
//    private func observeUserChanges() {
//        userListenerCancellable = userProvider.currentUserPublisher
//            .sink { [weak self] authUser in
//                guard let self = self else { return }
//                let newUID = authUser?.uid
//                if self.currentUID != newUID {
//                    print("🔄 UserInfoCellManager получил нового пользователя: \(String(describing: self.currentUID)) → \(String(describing: newUID))")
//                    self.profileLoadCancellable?.cancel()
//                    self.currentUID = newUID
//                }
//            }
//    }
//
//    func loadUserProfile(uid: String) {
//        profileLoadCancellable?.cancel()
//        profileLoadingState.send(.loading)
//        
//        profileLoadCancellable = profileService.fetchProfile(uid: uid)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    
//                    switch completion {
//                    case .finished:
//                        self?.profileLoadingState.send(.idle)
//                    case .failure(let error):
//                        self?.profileLoadingState.send(.failure)
//                        self?.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
//                    }
//                },
//                receiveValue: { [weak self] profile in
//                    self?.userProfile.send(profile)
//                    self?.profileLoadingState.send(.idle)
//                }
//            )
//    }
//    
//    private func handleError(_ error: Error, operationDescription: String) {
//        let errorMessage = errorHandler.handle(error: error)
//        AlertManager.shared.showGlobalAlert(
//            message: errorMessage,
//            operationDescription: operationDescription,
//            alertType: .ok
//        )
//    }
//}



//print("UserInfoCellManager func loadUserProfile(uid: String) - \(uid)")

//    func loadUserProfile(uid: String) {
//        profileLoadCancellable?.cancel()
//        profileLoadingState.send(.loading)
//
//        profileLoadCancellable = profileService.fetchProfile(uid: uid)
//            .sink(
//                receiveCompletion: { [weak self] completion in
//                    guard let self = self else { return }
//                    guard self.currentUID == uid else {
//                        print("⚠️ Игнорируем completion: uid изменился")
//                        return
//                    }
//                    switch completion {
//                    case .finished:
//                        self.profileLoadingState.send(.idle)
//                    case .failure(let error):
//                        self.profileLoadingState.send(.failure)
//                        self.handleError(error, operationDescription: Localized.TitleOfFailedOperationFirebase.fetchingProfileData)
//                    }
//                },
//                receiveValue: { [weak self] profile in
//                    guard let self = self else { return }
//                    guard self.currentUID == uid else {
//                        print("⚠️ Игнорируем результат: uid изменился")
//                        return
//                    }
//                    self.userProfile.send(profile)
//                    self.profileLoadingState.send(.idle)
//                }
//            )
//    }
