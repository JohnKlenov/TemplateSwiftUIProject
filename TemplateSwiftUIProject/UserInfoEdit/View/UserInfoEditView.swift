//
//  UserInfoEditView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.08.25.
//

import SwiftUI

struct UserInfoEditView: View {
    @ObservedObject var viewModel: UserInfoEditViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = Self._printChanges()
        Form {
            // MARK: Avatar + Edit Button
            Section {
                VStack(spacing: 12) {
                    Button(action: { viewModel.showImageOptions = true }) {
                        avatarContent
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .onTapGesture {
                        print("Avatar tapped")
                    }

                    Button("Edit Photo") {
                        viewModel.showImageOptions = true
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // MARK: Name & Email
            Section(header: Text("Name")) {
                TextField("Name", text: $viewModel.name)
            }
            Section(header: Text("Email")) {
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
//                    Task {
//                        await viewModel.saveProfile()
//                        dismiss()
//                    }
                }
                .disabled(!viewModel.canSave)
            }
        }
        // MARK: ActionSheet for image options
        .actionSheet(isPresented: $viewModel.showImageOptions) {
            ActionSheet(
                title: Text("Edit Photo"),
                buttons: [
                    .default(Text("Choose from Library"), action: viewModel.chooseFromLibrary),
                    .default(Text("Take Photo"), action: viewModel.takePhoto),
                    .destructive(Text("Delete Photo"), action: viewModel.deletePhoto),
                    .cancel()
                ]
            )
        }
        // MARK: Photo & Camera pickers (с заглушками)
        .sheet(isPresented: $viewModel.showPhotoPicker) {
            Text("Photo Picker Placeholder")
        }
        .sheet(isPresented: $viewModel.showCamera) {
            Text("Camera View Placeholder")
        }
        // MARK: Error alert
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text("Failed to save profile."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: Avatar rendering logic
    @ViewBuilder
    private var avatarContent: some View {
        if let img = viewModel.avatarImage {
            Image(uiImage: img)
                .resizable()
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
