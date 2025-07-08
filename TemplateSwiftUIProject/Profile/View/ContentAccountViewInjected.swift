//
//  ContentAccountViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//

import SwiftUI

struct ContentAccountViewInjected: View {
    @StateObject private var viewModel: ContentAccountViewModel
    
    init(authorizationManager: AuthorizationManager) {
        _viewModel = StateObject(wrappedValue: ContentAccountViewModel(authorizationManager: authorizationManager))
    }
    
    var body: some View {
        ContentAccountView(viewModel: viewModel)
    }
}
