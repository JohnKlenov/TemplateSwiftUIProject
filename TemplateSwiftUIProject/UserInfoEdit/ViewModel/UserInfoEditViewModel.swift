//
//  UserInfoViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//

import SwiftUI
import Combine

///@MainActor гарантирует, что все методы и свойства внутри класса будут выполняться на главном потоке (DispatchQueue.main).
///если убрать @MainActor Придётся вручную писать DispatchQueue.main.async { ... } в каждом месте
@MainActor
class UserInfoEditViewModel: ObservableObject {
    // Входные данные из UserProfile
    private let uid: String
    private let initialName: String
    private let initialLastName: String
    let initialPhotoURL: URL?

    // Публикуемые свойства для View
    @Published var name: String
    @Published var lastName: String
    @Published var avatarImage: UIImage?
    @Published var showImageOptions = false
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showErrorAlert = false
    @Published private(set) var canSave = false

    private var isSaving = false
    private let authorizationManager: AuthorizationManager
    private let profileService: FirestoreProfileService
    
    private var cancellables = Set<AnyCancellable>()

    init(authorizationManager: AuthorizationManager, profileService: FirestoreProfileService, profile: UserProfile) {
        print("init UserInfoEditViewModel")
        self.uid = profile.uid
        self.initialName = profile.name ?? ""
        self.initialLastName = profile.lastName ?? ""
        self.initialPhotoURL = profile.photoURL
        self.name = profile.name ?? ""
        self.lastName = profile.lastName ?? ""
        self.authorizationManager = authorizationManager
        self.profileService = profileService
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
                
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

                let isNameValid = !trimmedName.isEmpty
                let isLastNameValid = !trimmedLastName.isEmpty

                let notEmpty = isNameValid || isLastNameValid
                let changed = trimmedName != self.initialName.trimmingCharacters(in: .whitespacesAndNewlines)
                           || trimmedLastName != self.initialLastName.trimmingCharacters(in: .whitespacesAndNewlines)

                return notEmpty && changed
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] canSave in
                self?.canSave = canSave
            }
            .store(in: &cancellables)
    }

    // если сохраняем текст updateTextProfile() то в photoURL передаем nil
    // если сохраняем image updateImageProfile() то в name: nil, lastName: nil
    // Ты можешь обновить только одно поле через setData(from:merge:true), если в закодированной модели присутствует только это поле. Для этого передай модель, в которой все остальные опционалы равны nil — тогда синтезированный Encodable просто не закодирует их.
    func updateProfile()  {
        profileService.updateProfile(UserProfile(uid: uid, name: name.nilIfOnlyWhitespace, lastName: lastName.nilIfOnlyWhitespace, photoURL: nil))
    }
    
    //        profileService.updateProfile(UserProfile(uid: uid, name: nil, lastName: nil, photoURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/templateswiftui.appspot.com/o/TestImage%2F3-e1bc007b39c5a8b930833e35963b9914.jpeg?alt=media&token=345fe1d8-93d8-4824-8ee5-a58d4763918a")))

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
    var nilIfOnlyWhitespace: String? {
        // Удаляем все пробельные символы (пробелы, табы, переносы и т.д.)
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Если после удаления осталась пустая строка — значит, была только "пустота"
        return trimmed.isEmpty ? nil : self
    }
}



// в данной логике если при первом переходе хоть одно поле было заполнено
// то даже пробел в новой строке активирует кнопку done
// во всем остальном он хорошо работает

//            .map { [weak self] name, lastName in
//                guard let self else { return false }
//
//                // Проверка на содержимое — но сохраняем оригинал
//                let isNameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//                let isLastNameValid = !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//
//                let notEmpty = isNameValid || isLastNameValid
//                let changed = name != self.initialName || lastName != self.initialLastName
//
//                return notEmpty && changed
//            }
