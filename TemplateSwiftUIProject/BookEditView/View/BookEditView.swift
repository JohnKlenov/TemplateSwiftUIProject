//
//  BookEditView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.11.24.
//

import SwiftUI

/// вот это нам нужно что бы общаться с DetailView для его удаления из стека navView при удалении Book из BookEditView?
/// В struct BookEditView - > var completionHandler: ((Result<Action, Error>) -> Void)?
//enum Action {
//  case delete
//  case done
//  case cancel
//}

enum Mode {
    case new
    case edit
}

enum FocusedField:Hashable {
    case title, description, pathImage, author
}


struct BookEditView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: BookViewModel
    @FocusState var focus:FocusedField?
    
    var mode: Mode = .new
    @State var presentActionSheet = false
    
    var cancelButton: some View {
        Button("Cancel") {
            self.handleCancelTapped()
        }
    }
    
    var saveButton: some View {
        Button(mode == .new ? "Done" : "Save") {
            self.handleDoneTapped()
        }
        .disabled(!viewModel.modified)
    }
    
    init(viewModel:BookViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Book")) {
                    customTextField("Title", text: $viewModel.book.title, field: .title)
                    customTextField("Description", text: $viewModel.book.description, field: .description)
                    customTextField("PathImage", text: $viewModel.book.pathImage, field: .pathImage)
                }
                Section(header: Text("Author")) {
                    customTextField("Author", text: $viewModel.book.author, field: .author)
                }
                
                if mode == .edit {
                    Button("Delete book", role: .destructive) {
                        self.presentActionSheet.toggle()
                    }
                }
            }
            .navigationTitle(mode == .new ? "New book" : viewModel.book.title)
            .navigationBarTitleDisplayMode(mode == .new ? .inline : .large)
            .onTapGesture {
                print(".onTapGesture")
                focus = nil
            }
            .toolbar{
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
            }
            .confirmationDialog("Are you sure?", isPresented: $presentActionSheet) {
                Button("Delete book", role: .destructive) {
                    self.handleDeleteTapped()
                }
                Button("Cancel", role: .cancel) {
                    self.handleCancelTapped()
                }
            }
        }
    }
    
    private func customTextField(_ title: String, text: Binding<String>, field: FocusedField) -> some View {
        TextField(title, text: text) .keyboardType(.default)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .focused($focus, equals: field)
            .onSubmit {
                switch field {
                case .title: 
                    focus = .description
                case .description: 
                    focus = .pathImage
                case .pathImage: 
                    focus = .author
                case .author: 
                    focus = nil
                }
            }
    }
    
    private func handleCancelTapped() {
        print("did tap Cancel")
        dismiss()
    }
    
    private func handleDoneTapped() {
        print("did tap Done")
    }
    
    private func handleDeleteTapped() {
        print("did tap Delete")
    }
    
}

//#Preview {
//    BookEditView()
//}





// MARK: - Trash


//                Section {
//                    customTextField("Title", text: $viewModel.book.title)
//                        .focused($focus, equals: .title)
//                    customTextField("Description", text: $viewModel.book.description)
//                        .focused($focus, equals: .description)
//                    customTextField("PathImage", text: $viewModel.book.pathImage)
//                        .focused($focus, equals: .pathImage)
//                } header: {
//                    Text("Book")
//                }
//
//                Section {
//                    customTextField("Author", text: $viewModel.book.author)
//                        .focused($focus, equals: .author)
//                } header: {
//                    Text("Author")
//                }

//    private func customTextField(_ title: String, text: Binding<String>) -> some View {
//        TextField(title, text: text)
//            .keyboardType(.default)
//            .autocapitalization(.none)
//            .disableAutocorrection(true)
//            .onSubmit {
//                switch focus {
//                case .title:
//                    focus = .description
//                case .description:
//                    focus = .pathImage
//                case .pathImage:
//                    focus = .author
//                case .author:
//                    focus = nil
//                case nil:
//                    break
//                }
//            }
//    }
