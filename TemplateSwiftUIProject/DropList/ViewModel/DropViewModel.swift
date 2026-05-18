//
//  DropViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.05.26.
//

import SwiftUI

class DropViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        self.alertManager = alertManager
    }
}
