//
//  GalleryCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct GalleryCompositView:View {
    
    let data: [SectionModel]
    let refreshAction: () async -> Void // Асинхронное замыкание
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(data) { section in
                    switch section.section {
                    case "Malls":
                        MallsSectionView(items: section.items,
                                         headerTitle: "Торговые Центры")
                    case "Shops":
                        ShopsSectionView(items: section.items,
                                         headerTitle: "Магазины")
                    case "PopularProducts":
                        PopularProductsSectionView(items: section.items,
                                                   headerTitle: "Популярные товары")
                    default:
                        // Если тип секции не распознан, по умолчанию показываем malls
                        //                        MallsSectionView(items: section.items,
                        //                                         headerTitle: "Торговые Центры")
                        EmptyView()
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            // Явное обновление данных при pull-to-refresh
            await refreshAction()
        }
    }
}
