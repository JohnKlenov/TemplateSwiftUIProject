//
//  BookEditView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 4.11.24.
//

import SwiftUI

enum Mode {
    case new
    case edit
}


struct BookEditView: View {
    
    @StateObject var viewModel: BookViewModel
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
                Section {
                    TextField("Title", text: $viewModel.book.title)
                    TextField("Description", text: $viewModel.book.description)
                    TextField("PathImage", text: $viewModel.book.pathImage)
                } header: {
                    Text("Book")
                }
                
                Section {
                    TextField("Author", text: $viewModel.book.author)
                } header: {
                    Text("Author")
                }
                
                if mode == .edit {
                    Button("Delete book", role: .destructive) {
                        self.presentActionSheet.toggle()
                    }
                }
            }
            .navigationTitle(mode == .new ? "New book" : viewModel.book.title)
            .navigationBarTitleDisplayMode(mode == .new ? .inline : .large)
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
    
    private func handleCancelTapped() {
     print("did tap Cancel")
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
