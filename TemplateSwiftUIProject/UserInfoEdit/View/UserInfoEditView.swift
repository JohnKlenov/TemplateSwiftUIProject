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


//ClearButtonModifier — это компактная переиспользуемая обёртка, которая целенаправленно добавляет кнопку очистки к любому TextField, не смешивая эту логику напрямую с остальным UI.
///ViewModifier -  Обёртка над другим View, расширяющая его поведение
///Модификатор — это не просто способ «изменить стиль», он может обернуть, расширить, добавить или заменить части интерфейса, к которому применяется.
///Modifier в SwiftUI — это объект, который принимает исходный View, модифицирует его каким-то образом и возвращает новый View. (в отличии от view ViewModifier Не рендерится сам по себе, а приклеивается к другим элементам через .modifier или кастомные аксессоры.)
///@Binding var text: String — двусторонняя привязка к содержимому TextField.
///@Binding var isFocused: Bool — флаг, указывающий, в фокусе ли сейчас поле.
///body(content:) - SwiftUI передаёт сюда исходный View (тот, к которому вы применили modifier) как content.
///Мы добавляем к нему отступ справа (.padding(.trailing, 28)), чтобы освободить место под кнопку “крестик”.
///С помощью .overlay(alignment: .trailing) поверх поля рисуем условный блок. (Если поле находится в фокусе И текст не пустой огда рисуем Button, стилизованную иконкой “xmark.circle.fill”.
///func clearButton - Расширение для удобства)
private struct ClearButtonModifier: ViewModifier {
    @Binding var text: String
    @Binding var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.trailing, 28)
            .overlay(alignment: .trailing) {
                if isFocused && !text.isEmpty {
                    Button {
                        print("dit tap ClearButtonModifier")
                        withAnimation(.easeInOut(duration: 0.15)) {
                            text = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .opacity(0.9)
                            .contentShape(Rectangle())
                    }
                    .padding(.trailing, 4)
                    .transition(.opacity) // .transition(.opacity) — для анимации появления/исчезновения (В данном случае — плавное затухание (fade in/out) + Работает в паре с withAnimation(...), иначе не будет эффекта.SwiftUI проверяет, какие элементы исчезают, и применяет .transition(.opacity).)
                }
            }
    }
}

private extension View {
    func clearButton(text: Binding<String>, isFocused: Binding<Bool>) -> some View {
        modifier(ClearButtonModifier(text: text, isFocused: isFocused))
    }
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
                                viewModel.showImageOptions = true
                            }
                            .contentShape(Rectangle()) // чёткая hit-область
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
                Button("Delete Photo", role: .destructive) { viewModel.deletePhoto() }
            }
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                Text("Photo Picker Placeholder")
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
            avatarContent
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle()) // обрезает картинку по кругу
        }
        .buttonStyle(.plain)
        .contentShape(Circle()) // ограничивает зону нажатия кругом
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

