//
//  GalleryCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct GalleryCompositView: View {
    
    @EnvironmentObject var localization: LocalizationService 
    
    let data: [UnifiedSectionModel]
    let refreshAction: () async -> Void // Асинхронное замыкание
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) { // Используем LazyVStack
                ForEach(data) { section in
                    switch section {
                    case .malls(let mallSection):
                        MallsSectionView(items: mallSection.items, headerTitle: mallSection.header.localized())
                    
                    case .shops(let shopSection):
                        ShopsSectionView(items: shopSection.items, headerTitle: shopSection.header.localized())
                    
                    case .popularProducts(let productSection):
                        PopularProductsSectionView(items: productSection.items, headerTitle: productSection.header.localized())
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable { await refreshAction() }
    }
}

