//
//  AlertLocalViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 7.01.25.
//

import SwiftUI

class AlertViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        print("init AlertViewModel")
        self.alertManager = alertManager
    }
    
    deinit {
        print("deinit AlertViewModel")
    }
}
