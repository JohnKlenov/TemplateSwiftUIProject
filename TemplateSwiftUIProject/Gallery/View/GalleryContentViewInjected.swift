//
//  GalleryContentViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 22.01.26.
//


import SwiftUI

struct GalleryContentViewInjected: View {
    
    @StateObject private var viewModel: GalleryContentViewModel
    
    init(galleryManager: GalleryManager) {
        _viewModel = StateObject(
            wrappedValue: GalleryContentViewModel(galleryManager: galleryManager)
        )
    }
    
    var body: some View {
        GalleryContentView(viewModel: viewModel)
    }
}


//import SwiftUI
//
//struct LibraryContentViewInjected: View {
//
//    @StateObject private var viewModel: LibraryContentViewModel
//    
//    init(dropListDataSource: DropListDataSource) {
//        _viewModel = StateObject(
//            wrappedValue: LibraryContentViewModel(dropListDataSource: dropListDataSource)
//        )
//    }
//    
//    var body: some View {
//        LibraryContentView(viewModel: viewModel)
//    }
//}
//
//import SwiftUI
//
//struct LibraryContentView: View {
//    
//    @EnvironmentObject var localization: LocalizationService
//    @ObservedObject var viewModel: LibraryContentViewModel
//
//    var body: some View {
// ....
//    }
//
//}
//
//import SwiftUI
//
//class LibraryViewModel:ObservableObject {
//    var alertManager:AlertManager
//    
//    init(alertManager:AlertManager) {
//        self.alertManager = alertManager
//    }
//}
