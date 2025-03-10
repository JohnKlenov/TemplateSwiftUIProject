//
//  GalleryViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.03.25.
//

import SwiftUI

class GalleryViewModel:ObservableObject {
    var alertManager:AlertManager
    
    init(alertManager:AlertManager) {
        self.alertManager = alertManager
    }
}
