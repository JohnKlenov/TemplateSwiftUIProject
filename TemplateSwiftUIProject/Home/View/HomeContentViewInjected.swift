//
//  HomeContentViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.01.26.
//

import SwiftUI

struct HomeContentViewInjected: View {
    
    @StateObject private var viewModel: HomeContentViewModel
    
    init(managerCRUDS: CRUDSManager,
         homeManager: HomeManager) {
        
        _viewModel = StateObject(
            wrappedValue: HomeContentViewModel(
                homeManager: homeManager,
                managerCRUDS: managerCRUDS
            )
        )
    }
    
    var body: some View {
        let _ = Self._printChanges()
        HomeContentView(viewModel: viewModel)
    }
}
