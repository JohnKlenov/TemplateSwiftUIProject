//
//  UserInfoEditView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//


import SwiftUI

// MARK: - Фокусируемые поля
enum FieldToFocusProfileEdit: Hashable, CaseIterable {
    case nameField, lastNameField
}


struct UserInfoEditView: View {
    
    @ObservedObject var viewModel: UserInfoEditViewModel
    @EnvironmentObject var accountCoordinator: AccountCoordinator
    @FocusState var isFieldFocus: FieldToFocusProfileEdit?
    
    var body: some View {
        let _ = Self._printChanges()
            
            Form {
                // MARK: Avatar + Edit Button
                Section {
                    VStack(spacing: 12) {
                        avatarButton
                        
                        Text("Edit Photo")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                if !viewModel.isAvatarLoading {
                                    viewModel.showImageOptions = true
                                }
                            }
                            .contentShape(Rectangle()) // чёткая hit-область
                            .disabled(viewModel.isAvatarLoading) // Блокируем нажатие
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // MARK: Name
                Section(header: Text("Name")) {
                    TextField("Name", text: $viewModel.name)
                        .submitLabel(.next)
                        .focused($isFieldFocus, equals: .nameField)
                        .onSubmit { focusNextField() }
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .clearButton(text: $viewModel.name, isFocused: focusBinding(.nameField))
                }
                
                // MARK: LastName
                Section(header: Text("LastName")) {
                    TextField("LastName", text: $viewModel.lastName)
                        .submitLabel(.done)
                        .focused($isFieldFocus, equals: .lastNameField)
                        .onSubmit { focusNextField() }
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .clearButton(text: $viewModel.lastName, isFocused: focusBinding(.lastNameField))
                }
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.updateProfile()
                        accountCoordinator.popToRoot()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .confirmationDialog("Edit Photo", isPresented: $viewModel.showImageOptions, titleVisibility: .visible) {
                Button("Choose from Library") { viewModel.chooseFromLibrary() }
                Button("Take Photo") { viewModel.takePhoto() }
                if viewModel.initialPhotoURL != nil {
                    Button("Delete Photo", role: .destructive) { viewModel.deletePhoto() }
                }
            }
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoPickerView { result in
                    switch result {
                    case .success(let image):
                        print("UserInfoEditView Выбор фото подтвержден")
                        // Успешно получили UIImage
                        self.viewModel.handlePickedImage(image)

                    case .failure(let error):
                        // Ошибка — можно показать alert или лог
                        print("UserInfoEditView Ошибка выбора фото: \(error.localizedDescription)")
                        self.viewModel.handlePickedImageError(error, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)

                    case .cancelled:
                        // Пользователь закрыл пикер без выбора
                        print("UserInfoEditView Выбор фото отменён")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                Text("Camera View Placeholder")
            }
            .alert(isPresented: $viewModel.showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text("Failed to save profile."),
                    dismissButton: .default(Text("OK"))
                )
            }
    }
    
    // MARK: - Helpers
    
    private func focusNextField() {
        switch isFieldFocus {
        case .nameField:
            isFieldFocus = .lastNameField
        case .lastNameField:
            isFieldFocus = nil
        default:
            isFieldFocus = nil
        }
    }
    
    
    //При вызове focusBinding(.nameField) — отрабатывает только get, потому что ты создаёшь Binding<Bool>, но не используешь его ещё.
    ///Ты вызываешь focusBinding(.nameField) → создаётся Binding<Bool>.
    ///set будет вызван только когда кто-то изменит значение Binding<Bool>, например:
    ///Пользователь тапает по TextField, и SwiftUI хочет сфокусировать его → set(true)
    ///Ты вручную снимаешь фокус → set(false)
    private func focusBinding(_ field: FieldToFocusProfileEdit) -> Binding<Bool> {
        Binding(
            get: { isFieldFocus == field },
            set: { newValue in
                isFieldFocus = newValue ? field : nil
            }
        )
    }
    
    // MARK: - Subviews
    
    private var avatarButton: some View {
        Button {
            print("Avatar tapped")
        } label: {
            ZStack {
                avatarContent
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())

                if viewModel.isAvatarLoading {
                    Circle()
                        .fill(Color.black.opacity(0.3)) // затемнение фона
                        .frame(width: 120, height: 120)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .transition(.opacity.combined(with: .scale)) // анимация появления
                        .animation(.easeInOut(duration: 0.3), value: viewModel.isAvatarLoading)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .disabled(viewModel.isAvatarLoading)
    }
    
    @ViewBuilder
    private var avatarContent: some View {
        if let img = viewModel.avatarImage {
            Image(uiImage: img).resizable()
        } else if let url = viewModel.initialPhotoURL {
            ///AsyncImage был создан как минималистичный способ загрузки изображений по URL в SwiftUI
            ///AsyncImage не кэширует изображение
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable()
                } else if phase.error != nil {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                } else {
                    ProgressView()
                }
            }
        } else {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .foregroundColor(.gray)
        }
    }
}


//    private var avatarButton: some View {
//        Button {
//            print("Avatar tapped")
//        } label: {
//            avatarContent
//                .scaledToFill()
//                .frame(width: 120, height: 120)
//                .clipShape(Circle()) // обрезает картинку по кругу
//        }
//        .buttonStyle(.plain)
//        .contentShape(Circle()) // ограничивает зону нажатия кругом
//    }


// MARK: - after

//import SwiftUI
//
//// MARK: - Фокусируемые поля
//enum FieldToFocusProfileEdit: Hashable, CaseIterable {
//    case nameField, lastNameField
//}
//
//
//struct UserInfoEditView: View {
//    
//    @ObservedObject var viewModel: UserInfoEditViewModel
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//    @FocusState var isFieldFocus: FieldToFocusProfileEdit?
//    
//    var body: some View {
//        let _ = Self._printChanges()
//            
//            Form {
//                // MARK: Avatar + Edit Button
//                Section {
//                    VStack(spacing: 12) {
//                        avatarButton
//                        
//                        Text("Edit Photo")
//                            .foregroundColor(.blue)
//                            .onTapGesture {
//                                if !(viewModel.infoEditState == .loading) {
//                                    viewModel.showImageOptions = true
//                                }
//                            }
//                            .contentShape(Rectangle()) // чёткая hit-область
//                            .disabled(viewModel.infoEditState == .loading) // Блокируем нажатие
//                    }
//                    .frame(maxWidth: .infinity, alignment: .center)
//                }
//                
//                // MARK: Name
//                Section(header: Text("Name")) {
//                    TextField("Name", text: $viewModel.name)
//                        .submitLabel(.next)
//                        .focused($isFieldFocus, equals: .nameField)
//                        .onSubmit { focusNextField() }
//                        .disableAutocorrection(true)
//                        .autocapitalization(.none)
//                        .clearButton(text: $viewModel.name, isFocused: focusBinding(.nameField))
//                }
//                
//                // MARK: LastName
//                Section(header: Text("LastName")) {
//                    TextField("LastName", text: $viewModel.lastName)
//                        .submitLabel(.done)
//                        .focused($isFieldFocus, equals: .lastNameField)
//                        .onSubmit { focusNextField() }
//                        .keyboardType(.default)
//                        .disableAutocorrection(true)
//                        .autocapitalization(.none)
//                        .clearButton(text: $viewModel.lastName, isFocused: focusBinding(.lastNameField))
//                }
//            }
//            .navigationTitle("Edit Profile")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Done") {
//                        viewModel.updateProfile()
//                        accountCoordinator.popToRoot()
//                    }
//                    .disabled(!viewModel.canSave)
//                }
//            }
//            .confirmationDialog("Edit Photo", isPresented: $viewModel.showImageOptions, titleVisibility: .visible) {
//                Button("Choose from Library") { viewModel.chooseFromLibrary() }
//                Button("Take Photo") { viewModel.takePhoto() }
//                if viewModel.initialPhotoURL != nil {
//                    Button("Delete Photo", role: .destructive) { viewModel.deletePhoto() }
//                }
//            }
//            .sheet(isPresented: $viewModel.showPhotoPicker) {
//                PhotoPickerView { result in
//                    switch result {
//                    case .success(let image):
//                        print("UserInfoEditView Выбор фото подтвержден")
//                        // Успешно получили UIImage
//                        self.viewModel.handlePickedImage(image)
//
//                    case .failure(let error):
//                        // Ошибка — можно показать alert или лог
//                        print("UserInfoEditView Ошибка выбора фото: \(error.localizedDescription)")
//                        self.viewModel.handlePickedImageError(error, operationDescription: Localized.TitleOfFailedOperationPickingImage.pickingImage)
//
//                    case .cancelled:
//                        // Пользователь закрыл пикер без выбора
//                        print("UserInfoEditView Выбор фото отменён")
//                    }
//                }
//            }
//            .sheet(isPresented: $viewModel.showCamera) {
//                Text("Camera View Placeholder")
//            }
//            .alert(isPresented: $viewModel.showErrorAlert) {
//                Alert(
//                    title: Text("Error"),
//                    message: Text("Failed to save profile."),
//                    dismissButton: .default(Text("OK"))
//                )
//            }
//    }
//    
//    // MARK: - Helpers
//    
//    private func focusNextField() {
//        switch isFieldFocus {
//        case .nameField:
//            isFieldFocus = .lastNameField
//        case .lastNameField:
//            isFieldFocus = nil
//        default:
//            isFieldFocus = nil
//        }
//    }
//    
//    
//    //При вызове focusBinding(.nameField) — отрабатывает только get, потому что ты создаёшь Binding<Bool>, но не используешь его ещё.
//    ///Ты вызываешь focusBinding(.nameField) → создаётся Binding<Bool>.
//    ///set будет вызван только когда кто-то изменит значение Binding<Bool>, например:
//    ///Пользователь тапает по TextField, и SwiftUI хочет сфокусировать его → set(true)
//    ///Ты вручную снимаешь фокус → set(false)
//    private func focusBinding(_ field: FieldToFocusProfileEdit) -> Binding<Bool> {
//        Binding(
//            get: { isFieldFocus == field },
//            set: { newValue in
//                isFieldFocus = newValue ? field : nil
//            }
//        )
//    }
//    
//    // MARK: - Subviews
//    
//    private var avatarButton: some View {
//        Button {
//            print("Avatar tapped")
//        } label: {
//            ZStack {
//                avatarContent
//                    .scaledToFill()
//                    .frame(width: 120, height: 120)
//                    .clipShape(Circle())
//
//                if viewModel.infoEditState == .loading {
//                    Circle()
//                        .fill(Color.black.opacity(0.3)) // затемнение фона
//                        .frame(width: 120, height: 120)
//
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle())
//                        .scaleEffect(1.5)
//                        .transition(.opacity.combined(with: .scale)) // анимация появления
//                        .animation(.easeInOut(duration: 0.3), value: viewModel.infoEditState == .loading)
//                }
//            }
//        }
//        .buttonStyle(.plain)
//        .contentShape(Circle())
//        .disabled(viewModel.infoEditState == .loading)
//    }
//    
//    @ViewBuilder
//    private var avatarContent: some View {
//        if let img = viewModel.avatarImage {
//            Image(uiImage: img).resizable()
//        } else if let url = viewModel.initialPhotoURL {
//            ///AsyncImage был создан как минималистичный способ загрузки изображений по URL в SwiftUI
//            ///AsyncImage не кэширует изображение
//            AsyncImage(url: url) { phase in
//                if let image = phase.image {
//                    image.resizable()
//                } else if phase.error != nil {
//                    Image(systemName: "person.crop.circle.fill")
//                        .resizable()
//                        .foregroundColor(.gray)
//                } else {
//                    ProgressView()
//                }
//            }
//        } else {
//            Image(systemName: "person.crop.circle.fill")
//                .resizable()
//                .foregroundColor(.gray)
//        }
//    }
//}










// MARK: - before button from TextField


//import SwiftUI
//
///// MARK: - Фокусируемые поля
//enum FieldToFocusProfileEdit: Hashable, CaseIterable {
//    case nameField, lastNameField
//}
//
//struct UserInfoEditView: View {
//    
//    @ObservedObject var viewModel: UserInfoEditViewModel
//    @EnvironmentObject var accountCoordinator: AccountCoordinator
//    @FocusState var isFieldFocus: FieldToFocusProfileEdit?
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        
//        Form {
//            // MARK: Avatar + Edit Button
//            Section {
//                VStack(spacing: 12) {
//                    // 1) Аватар: кликается отдельно, вызывает print
//                    Button(action: {
//                        print("Avatar tapped")
//                    }) {
//                        avatarContent
//                            .scaledToFill()
//                            .frame(width: 120, height: 120)
//                            .clipShape(Circle()) // обрезает картинку по кругу
//                    }
//                    .buttonStyle(.plain)
//                    .contentShape(Circle()) // ограничивает зону нажатия кругом
//                    
//                    // 2) Кнопка Edit Photo: простой текст, вызывает confirmationDialog
//                    Text("Edit Photo")
//                        .foregroundColor(.blue)
//                        .onTapGesture {
//                            viewModel.showImageOptions = true
//                        }
//                        .contentShape(Rectangle()) // чёткая hit-область
//                }
//                .frame(maxWidth: .infinity, alignment: .center)
//            }
//            
//            // MARK: Name & Email
//            Section(header: Text("Name")) {
//                TextField("Name", text: $viewModel.name)
//                    .submitLabel(.next)
//                    .focused($isFieldFocus, equals: .nameField)
//                    .onSubmit { focusNextField() }
////                    .keyboardType(.)
//                    .disableAutocorrection(true)
//                    .autocapitalization(.none)
//            }
//            Section(header: Text("LastName")) {
//                TextField("LastName", text: $viewModel.lastName)
//                    .submitLabel(.done)
//                    .focused($isFieldFocus, equals: .lastNameField)
//                    .onSubmit { focusNextField() }
//                    .keyboardType(.default)
//                    .disableAutocorrection(true)
//                    .autocapitalization(.none)
//            }
//        }
//        .navigationTitle("Edit Profile")
//        .toolbar {
//            ToolbarItem(placement: .confirmationAction) {
//                Button("Done") {
//                    viewModel.updateProfile()
//                    accountCoordinator.popToRoot()
//                }
//                .disabled(!viewModel.canSave)
//            }
//        }
//        // Только кнопка Edit Photo меняет showImageOptions
//        .confirmationDialog("Edit Photo", isPresented: $viewModel.showImageOptions, titleVisibility: .visible) {
//            Button("Choose from Library") { viewModel.chooseFromLibrary() }
//            Button("Take Photo") { viewModel.takePhoto() }
//            Button("Delete Photo", role: .destructive) { viewModel.deletePhoto() }
//        }
//        .sheet(isPresented: $viewModel.showPhotoPicker) {
//            Text("Photo Picker Placeholder")
//        }
//        .sheet(isPresented: $viewModel.showCamera) {
//            Text("Camera View Placeholder")
//        }
//        .alert(isPresented: $viewModel.showErrorAlert) {
//            Alert(
//                title: Text("Error"),
//                message: Text("Failed to save profile."),
//                dismissButton: .default(Text("OK"))
//            )
//        }
//        .simultaneousGesture(
//            TapGesture().onEnded {
//                hideKeyboard()
//            }
//        )
//    }
//    
//    
//    // MARK: helpe methods
//    
//    private func focusNextField() {
//        switch isFieldFocus {
//        case .nameField:
//            isFieldFocus = .lastNameField
//        case .lastNameField:
//            isFieldFocus = nil
//        default:
//            isFieldFocus = nil
//        }
//    }
//    
//    // MARK: - Subviews
//    
//    // Аватар: отдельная кнопка без изменения showImageOptions
//    private var avatarButton: some View {
//        Button {
//            print("Avatar tapped")
//        } label: {
//            avatarContent
//                .scaledToFill()
//                .frame(width: 120, height: 120)
//                .clipShape(Circle())
//        }
//        .buttonStyle(.plain)
//        // Не раскрываем hit-область за границы изображения
//        .contentShape(Circle())
//    }
//    
//    // MARK: Avatar rendering logic
//    @ViewBuilder
//    private var avatarContent: some View {
//        if let img = viewModel.avatarImage {
//            Image(uiImage: img).resizable()
//        } else if let url = viewModel.initialPhotoURL {
//            /AsyncImage был создан как минималистичный способ загрузки изображений по URL в SwiftUI
//            /AsyncImage не кэширует изображение
//            AsyncImage(url: url) { phase in
//                if let image = phase.image {
//                    image.resizable()
//                } else if phase.error != nil {
//                    Image(systemName: "person.crop.circle.fill")
//                        .resizable()
//                        .foregroundColor(.gray)
//                } else {
//                    ProgressView()
//                }
//            }
//        } else {
//            Image(systemName: "person.crop.circle.fill")
//                .resizable()
//                .foregroundColor(.gray)
//        }
//    }
//}

