//
//  MainCoordinator.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.01.25.
//

//var tabViewSwitcher = TabViewSwitcher()
//var homeCoordinator = HomeCoordinator()
//var galleryCoordinator = GalleryCoordinator()
//var accountCoordinator = AccountCoordinator()

import SwiftUI

class MainCoordinator:ObservableObject {

    var tabViewSwitcher: TabViewSwitcher
    var homeCoordinator: HomeCoordinator
    var galleryCoordinator: GalleryCoordinator
    var accountCoordinator: AccountCoordinator
    
    init(tabViewSwitcher: TabViewSwitcher = TabViewSwitcher(), homeCoordinator: HomeCoordinator = HomeCoordinator(), galleryCoordinator: GalleryCoordinator = GalleryCoordinator(), accountCoordinator: AccountCoordinator = AccountCoordinator()) {
        self.tabViewSwitcher = tabViewSwitcher
        self.homeCoordinator = homeCoordinator
        self.galleryCoordinator = galleryCoordinator
        self.accountCoordinator = accountCoordinator
        print("init MainCoordinator")
    }
    
    deinit {
        print("deinit MainCoordinator")
    }
}
