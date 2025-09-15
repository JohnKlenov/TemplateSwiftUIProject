//
//  UserInfoViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//



//    @Published var infoEditState: UserInfoEditManager.State = .idle



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
    var initialPhotoURL: URL?

    // Публикуемые свойства для View
    @Published var name: String
    @Published var lastName: String
    @Published var avatarImage: UIImage?
    @Published var showImageOptions = false
    @Published var showPhotoPicker = false
    @Published var showCamera = false
    @Published var showErrorAlert = false
    @Published private(set) var canSave = false
    @Published var isAvatarLoading = false

    private var isSaving = false
    private let editManager: UserInfoEditManager
    
    private var cancellables = Set<AnyCancellable>()

    init(editManager: UserInfoEditManager, profile: UserProfile) {
        print("init UserInfoEditViewModel")
        self.uid = profile.uid
        self.initialName = profile.name ?? ""
        self.initialLastName = profile.lastName ?? ""
        self.initialPhotoURL = profile.photoURL
        self.name = profile.name ?? ""
        self.lastName = profile.lastName ?? ""
        self.editManager = editManager
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
                ///это синтаксический сахар, доступный с Swift 5.7+
                guard let self else { return false }
                
                let changed = name != self.initialName || lastName != self.initialLastName
                
                return changed
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] canSave in
                self?.canSave = canSave
            }
            .store(in: &cancellables)
        
        editManager.state = .idle
        editManager.$state
            .handleEvents(receiveOutput: { print("→ UserInfoEditViewModel подписка получила:", $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                
                self?.isAvatarLoading = (state == .loading)
                
                switch state {
                case .avatarUploadSuccess(url: let url):
                    ///  если мы добавили новый аватар но плохая сеть ушли затем вернулись у нас старая картинка и вдруг приходит url тогда у нас не отобразится новый аватар так как initialPhotoURL не паблишер а может нужно принудительно self?.avatarImage = nil ?
                    self?.initialPhotoURL = url
                case .avatarDeleteSuccess:
                    self?.avatarImage = nil
                    self?.initialPhotoURL = nil
                case .avatarUploadFailure:
                    /// если initialPhotoURL был то он должен отобразится в UI
                    self?.avatarImage = nil
                case .avatarDeleteFailure:
                    break
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    // если сохраняем текст updateTextProfile() то в photoURL передаем nil
    // если сохраняем image updateImageProfile() то в name: nil, lastName: nil
    // Ты можешь обновить только одно поле через setData(from:merge:true), если в закодированной модели присутствует только это поле. Для этого передай модель, в которой все остальные опционалы равны nil — тогда синтезированный Encodable просто не закодирует их.
    func updateProfile()  {
        editManager.updateProfile(UserProfile(uid: uid, name: name, lastName: lastName, photoURL: nil), operationDescription: Localized.TitleOfFailedOperationFirebase.editingProfileFields, shouldDeletePhotoURL: false)
    }
    
    func handlePickedImage(_ image: UIImage) {
        self.avatarImage = image
        editManager.uploadAvatarAndTrack(for: uid, image: image)
    }

    
  func handlePickedImageError(_ error: Error, operationDescription:String) {
      editManager.handleError(error, operationDescription: operationDescription)
    }

    // MARK: - Image actions

    func chooseFromLibrary() { showPhotoPicker = true }
    func takePhoto() { showCamera = true }
    
    func deletePhoto() {
        guard let photoURL = initialPhotoURL else { return }
        editManager.deleteAvatarAndTrack(for: uid, photoURL: photoURL, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
    }

    deinit {
        cancellables.removeAll()
        print("deinit UserInfoEditViewModel")
    }
}


//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
//            self?.isAvatarLoading = false
//            self?.avatarImage = nil
//        }


//    func deletePhoto() {
//
//        guard let photoURL = initialPhotoURL else { return }
//        self.isAvatarLoading = true
//
//        editManager.deleteAvatar(for: uid, photoURL: photoURL, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                self?.isAvatarLoading = false
//                if case .failure(let error) = completion {
//                    print("Ошибка удаления аватара: \(error.localizedDescription)")
//                }
//            } receiveValue: { [weak self] in
//                self?.avatarImage = nil
//                self?.initialPhotoURL = nil
//            }
//            .store(in: &cancellables)
//    }


// before
//    func handlePickedImage(_ image: UIImage) {
//        self.avatarImage = image
//        self.isAvatarLoading = true
//
//        editManager.uploadAvatar(for: uid, image: image)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                self?.isAvatarLoading = false
//                if case .failure(let error) = completion {
//                    print("Ошибка загрузки/обновления аватара: \(error.localizedDescription)")
//                    self?.avatarImage = nil
//                }
//            } receiveValue: { [weak self] newURL in
//                print("editManager.uploadAvatar success newURL -  \(newURL)")
//                self?.initialPhotoURL = newURL // сохраняем новый URL
//            }
//            .store(in: &cancellables)
//    }

//    func handlePickedImage(_ image: UIImage) {
//
//        self.avatarImage = image
//        self.isAvatarLoading = true
//
//        editManager.uploadAvatar(for: uid, image: image)
//            .receive(on: DispatchQueue.main) // UI-эффекты на главном потоке
//            .sink { [weak self] completion in
//                self?.isAvatarLoading = false
//                switch completion {
//                case .finished:
//                    print("Аватар успешно обновлён в Firestore")
//                    break // Ничего не делаем, но явно фиксируем успешное завершение
//                case .failure(let error):
//                    // ВАЖНО: алерты уже показаны в сервисах. Здесь — только лог.
//                    print("Ошибка загрузки/обновления аватара: \(error.localizedDescription)")
//                    self?.avatarImage = nil
//                }
//            } receiveValue: { _ in
//                // Паблишер возвращает Void — UI-логика не требуется
//            }
//            .store(in: &cancellables)
//    }
//func handlePickedImage(_ image: UIImage)

// или что бы не иметь проболем можно вызвать editManager.uploadAvatar по нажатию на кнопу Done???
// когда мы добавляем картинку то лучше обнулять initialPhotoURL в nil
/// это делается для того что бы для сценария когда мы удачно добавили картинку
/// затем начали еще раз добавлять новую картинку в этом же UserInfoEditView и это прошло не успешно
/// нам прилетает avatarImage = nil и мы попадаем на загрузку самой первой initialPhotoURL
/// хотя ее уже может и не быть на сервере после первой удачно сохраненной
/// поэтому лучше сразу затерать ее и тогда пользователь не будет в заблуждении


//        profileService.updateProfile(UserProfile(uid: uid, name: nil, lastName: nil, photoURL: URL(string: "https://firebasestorage.googleapis.com/v0/b/templateswiftui.appspot.com/o/TestImage%2F3-e1bc007b39c5a8b930833e35963b9914.jpeg?alt=media&token=345fe1d8-93d8-4824-8ee5-a58d4763918a")))

extension String {
    var nilIfOnlyWhitespace: String? {
        // Удаляем все пробельные символы (пробелы, табы, переносы и т.д.)
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Если после удаления осталась пустая строка — значит, была только "пустота"
        return trimmed.isEmpty ? nil : self
    }
}




//func updateProfile()  {
//        _ = editManager.firestoreService.updateProfile(UserProfile(uid: uid, name: name, lastName: lastName, photoURL: nil))
//            .sink(receiveCompletion: { _ in }, receiveValue: { })
//}



//    func handlePickedImage(_ image: UIImage?) {
//        guard let image = image else { return }
//        // Здесь можно оптимизировать размер
//        self.avatarImage = image
//        // Загружаем в Storage/Firestore — например, асинхронно
////        Task {
////            do {
////                try await profileService.uploadAvatar(for: uid, image: image)
////            } catch {
////                self.showErrorAlert = true
////            }
////        }
//    }


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


// profileService.updateProfile(UserProfile(uid: uid, name: name.nilIfOnlyWhitespace, lastName: lastName.nilIfOnlyWhitespace, photoURL: nil))

//    .map { [weak self] name, lastName in
//        guard let self else { return false }
//        
//        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
//        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        let isNameValid = !trimmedName.isEmpty
//        let isLastNameValid = !trimmedLastName.isEmpty
//
//        let notEmpty = isNameValid || isLastNameValid
//        let changed = trimmedName != self.initialName.trimmingCharacters(in: .whitespacesAndNewlines)
//                   || trimmedLastName != self.initialLastName.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        return notEmpty && changed
//    }
