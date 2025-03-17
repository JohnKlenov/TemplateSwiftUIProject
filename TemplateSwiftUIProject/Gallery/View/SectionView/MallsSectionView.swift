//
//  MallsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

/// Секция Торговых Центров (Malls)
struct MallsSectionView: View {
    let items: [Item]
    let headerTitle: String

    var body: some View {
        GeometryReader { geometry in
            let horizontalPadding: CGFloat = 16
            let cellSpacing: CGFloat = 10
            let cellWidth = geometry.size.width - 2 * horizontalPadding - cellSpacing

            VStack(alignment: .leading, spacing: 10) {
                // Заголовок с одинаковыми отступами, как и в другой секции
                Text(headerTitle)
                    .font(.title2)
                    .bold()
                    .padding(.horizontal, horizontalPadding)
                
                // TabView с каруселью и внутренними отступами
                TabView {
                    ForEach(items) { item in
                        MallCell(item: item)
                            .frame(width: cellWidth, height: cellWidth * 0.55)
                            .cornerRadius(10)
                            .padding(.horizontal, cellSpacing / 2)  // Добавляем отступы между ячейками
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: cellWidth * 0.55)
                .padding(.horizontal, horizontalPadding)
            }
        }
        .frame(height: 250) // Подберите это значение под ваш контент
    }
}

