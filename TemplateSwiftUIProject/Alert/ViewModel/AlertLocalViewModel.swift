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
        self.alertManager = alertManager
    }
}
