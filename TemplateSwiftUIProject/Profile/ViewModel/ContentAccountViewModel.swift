//
//  ContentAccountViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//

import SwiftUI
import Combine

@MainActor
class ContentAccountViewModel: ObservableObject {
    
    @Published var accountDeletionState: AuthorizationManager.State = .idle
    @Published var showDeleteConfirmation = false
    
    private let authorizationManager: AuthorizationManager
    private var cancellables = Set<AnyCancellable>()
    
    init(authorizationManager: AuthorizationManager) {
        self.authorizationManager = authorizationManager
        
        authorizationManager.$state
            .handleEvents(receiveOutput: { print("→ ContentAccountViewModel подписка получила:", $0) })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.accountDeletionState = state
            }
            .store(in: &cancellables)
        
    }
    
    func deleteAccount() {
        authorizationManager.deleteAccount()
    }
    
    deinit {
        cancellables.removeAll()
        print("deinit ContentAccountViewModel")
    }
}
