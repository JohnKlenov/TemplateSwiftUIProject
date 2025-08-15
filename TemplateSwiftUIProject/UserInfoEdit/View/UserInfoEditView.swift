//
//  UserInfoEditView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//


import SwiftUI

/// MARK: - Фокусируемые поля
enum FieldToFocusProfileEdit: Hashable, CaseIterable {
    case nameField, lastNameField
}

struct UserInfoEditView: View {
    @ObservedObject var viewModel: UserInfoEditViewModel
    @FocusState var isFieldFocus: FieldToFocusProfileEdit?
    
    var body: some View {
        let _ = Self._printChanges()
        
        Form {
            // MARK: Avatar + Edit Button
            Section {
                VStack(spacing: 12) {
                    // 1) Аватар: кликается отдельно, вызывает print
                    Button(action: {
                        print("Avatar tapped")
                    }) {
                        avatarContent
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle()) // обрезает картинку по кругу
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle()) // ограничивает зону нажатия кругом
                    
                    // 2) Кнопка Edit Photo: простой текст, вызывает confirmationDialog
                    Text("Edit Photo")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            viewModel.showImageOptions = true
                        }
                        .contentShape(Rectangle()) // чёткая hit-область
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // MARK: Name & Email
            Section(header: Text("Name")) {
                TextField("Name", text: $viewModel.name)
                    .submitLabel(.next)
                    .focused($isFieldFocus, equals: .nameField)
                    .onSubmit { focusNextField() }
//                    .keyboardType(.)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
            Section(header: Text("LastName")) {
                TextField("LastName", text: $viewModel.lastName)
                    .submitLabel(.done)
                    .focused($isFieldFocus, equals: .lastNameField)
                    .onSubmit { focusNextField() }
                    .keyboardType(.default)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    // Task { await viewModel.saveProfile(); dismiss() }
                }
                .disabled(!viewModel.canSave)
            }
        }
        // Только кнопка Edit Photo меняет showImageOptions
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
        .simultaneousGesture(
            TapGesture().onEnded {
                hideKeyboard()
            }
        )
    }
    
    
    // MARK: helpe methods
    
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
    
    // MARK: - Subviews
    
    // Аватар: отдельная кнопка без изменения showImageOptions
    private var avatarButton: some View {
        Button {
            print("Avatar tapped")
        } label: {
            avatarContent
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        // Не раскрываем hit-область за границы изображения
        .contentShape(Circle())
    }
    
    // MARK: Avatar rendering logic
    @ViewBuilder
    private var avatarContent: some View {
        if let img = viewModel.avatarImage {
            Image(uiImage: img).resizable()
        } else if let url = viewModel.initialPhotoURL {
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

