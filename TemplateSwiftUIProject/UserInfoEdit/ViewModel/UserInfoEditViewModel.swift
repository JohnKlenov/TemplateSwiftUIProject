//
//  UserInfoViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//

import SwiftUI
import Combine

@MainActor
class UserInfoEditViewModel: ObservableObject {
    // Входные данные из UserProfile
    private let uid: String
    private let initialName: String
    private let initialEmail: String
    let initialPhotoURL: URL?
//    private let profileService: ProfileServiceProtocol

    // Публикуемые свойства для View
    @Published var name: String
    @Published var email: String
    @Published var avatarImage: UIImage?
    @Published var showImageOptions = false
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showErrorAlert = false
    @Published private(set) var isSaving = false
    @Published private(set) var canSave = false

    private let authorizationManager: AuthorizationManager
    
    private var cancellables = Set<AnyCancellable>()

    init(authorizationManager: AuthorizationManager, profile: UserProfile) {
        print("init UserInfoEditViewModel")
        self.uid = profile.uid
        self.initialName = profile.name ?? ""
        self.initialEmail = profile.email ?? ""
        self.initialPhotoURL = profile.photoURL
        //        self.profileService = profileService
        self.name = profile.name ?? ""
        self.email = profile.email ?? ""
        self.authorizationManager = authorizationManager
        setupBindings()
    }

    private func setupBindings() {
        // Save активируется, когда поля непустые и изменились
        Publishers
            .CombineLatest($name, $email)
            .map { [unowned self] name, email in
                let trimmedName = name.trimmingCharacters(in: .whitespaces)
                let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                let notEmpty = !trimmedName.isEmpty && !trimmedEmail.isEmpty
                let changed = trimmedName != initialName || trimmedEmail != initialEmail
                return notEmpty && changed && !isSaving
            }
            .receive(on: RunLoop.main)
            .assign(to: \.canSave, on: self)
            .store(in: &cancellables)
    }

    func saveProfile()  {
        //func saveProfile() async {
//        guard canSave else { return }
//        isSaving = true
//
//        do {
//            try await profileService.updateProfile(
//                uid: uid,
//                name: name,
//                email: email,
//                avatarImage: avatarImage
//            )
//            isSaving = false
//        } catch {
//            isSaving = false
//            showErrorAlert = true
//        }
    }

    // MARK: - Image actions

    func chooseFromLibrary() { showPhotoPicker = true }
    func takePhoto() { showCamera = true }
    func deletePhoto() { avatarImage = nil }

    deinit {
        cancellables.removeAll()
    }
}

