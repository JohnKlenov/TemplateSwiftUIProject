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

final class MainCoordinator: ObservableObject {

    // MARK: - Coordinators

    var tabViewSwitcher: TabViewSwitcher
    var homeCoordinator: HomeCoordinator
    var galleryCoordinator: GalleryCoordinator
    var accountCoordinator: AccountCoordinator
    var droplistCoordinator: DroplistCoordinator
    var libraryCoordinator: LibraryCoordinator

    // MARK: - Initialization

    init(
        tabViewSwitcher: TabViewSwitcher = TabViewSwitcher(),
        homeCoordinator: HomeCoordinator = HomeCoordinator(),
        galleryCoordinator: GalleryCoordinator = GalleryCoordinator(),
        accountCoordinator: AccountCoordinator = AccountCoordinator(),
        droplistCoordinator: DroplistCoordinator = DroplistCoordinator(),
        libraryCoordinator: LibraryCoordinator = LibraryCoordinator()
    ) {
        self.tabViewSwitcher = tabViewSwitcher
        self.homeCoordinator = homeCoordinator // test
        self.galleryCoordinator = galleryCoordinator // test
        self.accountCoordinator = accountCoordinator
        self.droplistCoordinator = droplistCoordinator
        self.libraryCoordinator = libraryCoordinator

        print("init MainCoordinator")
    }

    // MARK: - Deinitialization

    deinit {
        print("deinit MainCoordinator")
    }
}


//import SwiftUI
//
//class MainCoordinator:ObservableObject {
//
//    var tabViewSwitcher: TabViewSwitcher
//    var homeCoordinator: HomeCoordinator
//    var galleryCoordinator: GalleryCoordinator
//    var accountCoordinator: AccountCoordinator
//    var droplistCoordinator: DroplistCoordinator
//    
//    init(tabViewSwitcher: TabViewSwitcher = TabViewSwitcher(), homeCoordinator: HomeCoordinator = HomeCoordinator(), galleryCoordinator: GalleryCoordinator = GalleryCoordinator(), accountCoordinator: AccountCoordinator = AccountCoordinator(), droplistCoordinator:DroplistCoordinator = DroplistCoordinator()) {
//        self.tabViewSwitcher = tabViewSwitcher
//        self.homeCoordinator = homeCoordinator
//        self.galleryCoordinator = galleryCoordinator
//        self.accountCoordinator = accountCoordinator
//        self.droplistCoordinator = droplistCoordinator
//        print("init MainCoordinator")
//    }
//    
//    deinit {
//        print("deinit MainCoordinator")
//    }
//}
