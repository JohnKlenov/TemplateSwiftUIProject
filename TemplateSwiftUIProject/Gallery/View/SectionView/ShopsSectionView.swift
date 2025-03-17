//
//  ShopsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

/// Секция Магазинов (Shops)
struct ShopsSectionView: View {
    let items: [Item]
    let headerTitle: String
    
    // Вычисляем размер так, чтобы ширина ячейки была 1/5 от ширины экрана
    let cellSize = UIScreen.main.bounds.width / 5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок
            Text(headerTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            // Горизонтальный ScrollView для непрерывной прокрутки
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(items) { item in
                        MallCell(item: item)
                            .frame(width: cellSize, height: cellSize)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
