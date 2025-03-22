//
//  GalleryCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct GalleryCompositView: View {
    let data: [UnifiedSectionModel]
    let refreshAction: () async -> Void // Асинхронное замыкание
    
    var body: some View {
        ScrollView {
//            LazyVStack(spacing: 10) {
            VStack(spacing: 10) { // Используем LazyVStack
                ForEach(data) { section in
                    switch section {
                    case .malls(let mallSection):
                        MallsSectionView(items: mallSection.items, headerTitle: mallSection.header)
                    
                    case .shops(let shopSection):
                        ShopsSectionView(items: shopSection.items, headerTitle: shopSection.header)
                    
                    case .popularProducts(let productSection):
                        PopularProductsSectionView(items: productSection.items, headerTitle: productSection.header)
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable { await refreshAction() }
    }
}






//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                ForEach(data) { section in
//                    switch section {
//                    case .malls(let mallSection):
//                        MallsSectionView(items: mallSection.items, headerTitle: mallSection.header)
//                    case .shops(let shopSection):
//                        ShopsSectionView(items: shopSection.items, headerTitle: shopSection.header)
//                    case .popularProducts(let productSection):
//                        PopularProductsSectionView(items: productSection.items, headerTitle: productSection.header)
//                    }
//                }
//            }
//            .padding(.vertical)
//        }
//        .refreshable {
//            // Явное обновление данных при pull-to-refresh
//            await refreshAction()
//        }
//    }

// MARK: - old models

//struct GalleryCompositView:View {
//    
//    let data: [SectionModel]
//    let refreshAction: () async -> Void // Асинхронное замыкание
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                ForEach(data) { section in
//                    switch section.section {
//                    case "Malls":
//                        MallsSectionView(items: section.items,
//                                         headerTitle: "Торговые Центры")
//                    case "Shops":
//                        ShopsSectionView(items: section.items,
//                                         headerTitle: "Магазины")
//                    case "PopularProducts":
//                        PopularProductsSectionView(items: section.items,
//                                                   headerTitle: "Популярные товары")
//                    default:
//                        // Если тип секции не распознан
//                        EmptyView()
//                    }
//                }
//            }
//            .padding(.vertical)
//        }
//        .refreshable {
//            // Явное обновление данных при pull-to-refresh
//            await refreshAction()
//        }
//    }
//}

