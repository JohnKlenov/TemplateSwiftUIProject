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
    }
}
