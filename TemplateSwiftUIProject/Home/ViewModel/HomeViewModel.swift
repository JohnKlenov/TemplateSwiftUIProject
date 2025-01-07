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
    
    init(sheetManager: SheetManager, alertManager:AlertManager) {
        self.sheetManager = sheetManager
        self.alertManager = alertManager
    }
}
