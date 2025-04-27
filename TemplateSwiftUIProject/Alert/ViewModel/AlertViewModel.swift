//
//  AlertLocalViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI

class AlertLocalViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        print("init AlertViewModel")
        self.alertManager = alertManager
    }
    
    deinit {
        print("deinit AlertLocalViewModel")
    }
}

class AlertGlobalViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        print("init AlertViewModel")
        self.alertManager = alertManager
    }
    
//    func handleRetryAction(for alertType: AlertType) {
//        if alertType == .authentication {
//            alertManager.triggerRetry()
//        }
//    }
    
    deinit {
        print("deinit AlertGlobalViewModel")
    }
}
