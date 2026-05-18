//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

import SwiftUI

struct DroplistViewInjected: View {
    
    @StateObject private var viewModel: DroplistViewModel
    
    init(sessionManager: AppSessionManager) {
        
        _viewModel = StateObject(
            wrappedValue: DroplistViewModel(
                sessionManager: sessionManager)
        )
    }
    
    var body: some View {
        let _ = Self._printChanges()
        DroplistContentView(viewModel: viewModel)
    }
}
