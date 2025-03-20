//
//  PopularProductsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct PopularProductsSectionView: View {
    let items: [ProductItem]
    let headerTitle: String
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
    
        VStack(alignment: .leading, spacing: 10) {
            Text(headerTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal, 16)
                .padding(.top, 10)
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(items) { item in
                    ProductCell(item: item)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(Color.yellow)
        .padding(.bottom, 10)
    }
}



/// Секция Популярных товаров (PopularProducts)
//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Определяем 2 колонки для grid layout
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок. Для "прилипания" заголовка можно рассмотреть Section в List или
//            // новые возможности pinnedViews (iOS 16+)
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 10) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .padding(.bottom, 10)
//    }
//}
