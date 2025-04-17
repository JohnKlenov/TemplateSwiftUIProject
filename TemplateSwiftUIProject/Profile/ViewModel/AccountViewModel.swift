//
//  AccountViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.04.25.
//

import SwiftUI

class AccountViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        self.alertManager = alertManager
    }
}
