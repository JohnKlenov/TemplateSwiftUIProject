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
    private let initialLastName: String
    let initialPhotoURL: URL?
//    private let profileService: ProfileServiceProtocol

    // Публикуемые свойства для View
    @Published var name: String
    @Published var lastName: String
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
        self.initialLastName = profile.lastName ?? ""
        self.initialPhotoURL = profile.photoURL
        //        self.profileService = profileService
        self.name = profile.name ?? ""
        self.lastName = profile.lastName ?? ""
        self.authorizationManager = authorizationManager
        setupBindings()
    }

    private func setupBindings() {
        // Save активируется, когда хотя бы одно строковое поле непустое или изменилось
        /// даем максимальную свободу в имени/фамилии - хоть один символ, может содержать любые пробелы(но строка из пробелов это не имя).
        ///Каждый раз, когда любая из них ($name, $email) меняется, CombineLatest выдаёт обновлённую пару значений (name, email)
        ///let isNameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty - Он проверяет, что строка name содержит хотя бы один видимый символ, кроме пробелов, табов и переносов. не позволить сохранить пустую строку, даже если она состоит из пробелов или переносов. Но при этом сохранять оригинальную строку, если она содержит хоть один видимый символ.
        ///name.trimmingCharacters(in: .whitespacesAndNewlines) - Удаляет все пробельные символы в начале и в конце строки name (обычные пробелы + табуляции "\t" + переносы строк "\n" + возвраты каретки "\r")
        ///notEmpty - хотя бы одно поле не пустое
        ///Финальная логика: Поля не пустые + Есть изменения + Сейчас не идёт процесс сохранения (isSaving == false)
        ///сли всё это выполнено → canSave = true
        Publishers
            .CombineLatest($name, $lastName)
            .map { [weak self] name, lastName in
                guard let self else { return false }
                
                // Проверка на содержимое — но сохраняем оригинал
                let isNameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                let isLastNameValid = !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                
                let notEmpty = isNameValid || isLastNameValid
                let changed = name != self.initialName || lastName != self.initialLastName
                
                return notEmpty && changed && !self.isSaving
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] canSave in
                self?.canSave = canSave
            }
            .store(in: &cancellables)
    }

    func saveProfile()  {
//        profileService.updateProfile(
//            uid: uid,
//            name: name,
//            email: lastName
//        )
    }

    // MARK: - Image actions

    func chooseFromLibrary() { showPhotoPicker = true }
    func takePhoto() { showCamera = true }
    func deletePhoto() { avatarImage = nil }

    deinit {
        cancellables.removeAll()
        print("deinit UserInfoEditViewModel")
    }
}

extension String {
    func normalizedWhitespace() -> String {
        self
            .trimmingCharacters(in: .whitespacesAndNewlines) // удаляет пробелы и переносы в начале и конце
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression) // заменяет любые подряд идущие пробелы на один
    }
}


//                let trimmedName = name.trimmingCharacters(in: .whitespaces)
//                let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)

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
