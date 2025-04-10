//
//  ShopsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI


struct ShopsSectionView: View {
    let items: [ShopItem]
    let headerTitle: String
    
    @State private var computedCellSize: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headerTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal, 16)
            
            GeometryReader { geometry in
                let horizontalPadding: CGFloat = 16
                let spacing: CGFloat = 10
                let availableWidth = geometry.size.width - 2 * horizontalPadding
                // Допустим, хотим 5 ячеек на экран:
                let cellSize = (availableWidth - (4 * spacing)) / 5.0
                
                Color.clear
                    .preference(key: CellHeightKey.self, value: cellSize)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(items) { item in
                            ShopCell(item: item, width: cellSize, height: cellSize)
                                .frame(width: cellSize, height: cellSize)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
            }
            .onPreferenceChange(CellHeightKey.self) { value in
                computedCellSize = value
            }
        }
        .frame(height: computedCellSize + 40)
//        .background(Color.green.opacity(0.1))
    }
}



