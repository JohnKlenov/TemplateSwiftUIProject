//
//  ContentViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.01.25.
//

import SwiftUI

class ContentViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        self.alertManager = alertManager
        print("init ContentViewModel")
    }
    
    deinit {
        print("deinit ContentView + ContentViewModel")
    }
}


// MARK: - before pattern Coordinator

//import SwiftUI
//
//class ContentViewModel:ObservableObject {
//    var alertManager:AlertManager
//    
//    init(alertManager:AlertManager) {
//        self.alertManager = alertManager
//    }
//}

