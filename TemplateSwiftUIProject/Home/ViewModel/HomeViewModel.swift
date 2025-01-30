//
//  HomeViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI

class HomeViewModel:ObservableObject {
    var sheetManager: SheetManager
    var alertManager:AlertManager
//    @Published var isTestProperty:Bool = false
    
    init(sheetManager: SheetManager, alertManager:AlertManager) {
        self.sheetManager = sheetManager
        self.alertManager = alertManager
    }
}

// MARK: - before pattern Coordinator

//import SwiftUI
//
//class HomeViewModel:ObservableObject {
//    var sheetManager: SheetManager
//    var alertManager:AlertManager
////    @Published var isTestProperty:Bool = false
//    
//    init(sheetManager: SheetManager, alertManager:AlertManager) {
//        self.sheetManager = sheetManager
//        self.alertManager = alertManager
//    }
//}
