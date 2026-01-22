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

