//
//  MainCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.01.25.
//

import SwiftUI

class MainCoordinator:ObservableObject {
    var tabViewSwitcher = TabViewSwitcher()
    var homeCoordinator = HomeCoordinator()
    var galleryCoordinator = GalleryCoordinator()
    var accountCoordinator = AccountCoordinator()
}
