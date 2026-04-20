//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

//import SwiftUI
//
//struct DroplistViewInjected: View {
//    
//    @StateObject private var viewModel: HomeContentViewModel
//    
//    init(managerCRUDS: CRUDSManager,
//         homeManager: HomeManager) {
//        
//        _viewModel = StateObject(
//            wrappedValue: HomeContentViewModel(
//                homeManager: homeManager,
//                managerCRUDS: managerCRUDS
//            )
//        )
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        HomeContentView(viewModel: viewModel)
//    }
//}
