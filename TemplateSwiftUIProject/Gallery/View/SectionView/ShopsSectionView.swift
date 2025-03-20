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
                            ShopCell(item: item)
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
        .frame(height: computedCellSize + 60)
        .background(Color.green.opacity(0.1))
    }
}


//struct ShopsSectionView: View {
//    let items: [ShopItem]
//    let headerTitle: String
//
//    var body: some View {
//        let screenWidth = UIScreen.main.bounds.width
//        let horizontalPadding: CGFloat = 16
//        let spacing: CGFloat = 10
//        let availableWidth = screenWidth - 2 * horizontalPadding
//        // Допустим, хотим 5 ячеек на экран:
//        let cellSize = (availableWidth - (4 * spacing)) / 5.0
//    
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, horizontalPadding)
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: spacing) {
//                    ForEach(items) { item in
//                        ShopCell(item: item)
//                            .frame(width: cellSize, height: cellSize)
//                            .cornerRadius(8)
//                    }
//                }
//                .padding(.horizontal, horizontalPadding)
//            }
//        }
//        // Общая высота секции: высота заголовка (40) + cellSize + некоторый дополнительный отступ (например, 20)
//        .frame(height: cellSize + 60)
//        .background(Color.green.opacity(0.4))
//    }
//}


// MARK: - DeepSeek

//struct ShopsSectionView: View {
//    let items: [ShopItem]
//    let headerTitle: String
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//            
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 16) {
//                    ForEach(items) { item in
//                        ShopCell(item: item)
//                            .frame(width: 80, height: 80)
//                    }
//                }
//                .padding(.horizontal, 16)
//            }
//        }
//        .frame(height: 140) // Заголовок + ячейки + отступы
//        .background(Color.green.opacity(0.3))
//    }
//}
//struct ShopsSectionView: View {
//    let items: [ShopItem]
//    let headerTitle: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//            
//            // Используем GeometryReader для динамического расчёта ячеек
//            GeometryReader { geometry in
//                let horizontalPadding: CGFloat = 16
//                let spacing: CGFloat = 10
//                let availableWidth = geometry.size.width - 2 * horizontalPadding
//                // Предположим, что мы хотим 5 ячеек на экране
//                let cellSize = (availableWidth - (4 * spacing)) / 5.0
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: spacing) {
//                        ForEach(items) { item in
//                            ShopCell(item: item)
//                                .frame(width: cellSize, height: cellSize)
//                                .cornerRadius(8)
//                        }
//                    }
//                    .padding(.horizontal, horizontalPadding)
//                }
//            }
//            // Высота контейнера равна размеру ячейки плюс возможные небольшие отступы
//            .frame(height: UIScreen.main.bounds.width / 5) // динамический расчет
//        }
//        .padding(.vertical)
//        .background(Color.green.opacity(0.1))
//    }
//}

//struct ShopsSectionView: View {
//    let items: [ShopItem]
//    let headerTitle: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//            
//            GeometryReader { geometry in
//                let horizontalPadding: CGFloat = 16
//                let spacing: CGFloat = 10
//                let availableWidth = geometry.size.width - 2 * horizontalPadding
//                // допустим, хотим 5 ячеек на экран:
//                let cellSize = (availableWidth - (4 * spacing)) / 5.0
//                
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: spacing) {
//                        ForEach(items) { item in
//                            ShopCell(item: item)
//                                .frame(width: cellSize, height: cellSize)
//                                .cornerRadius(8)
//                        }
//                    }
//                    .padding(.horizontal, horizontalPadding)
//                }
//            }
//            .frame(height: 100) // высота, соответствующая ячейкам (100 точек или подберите по дизайну)
//        }
//        .background(Color.green)
//    }
//}



/// Секция Магазинов (Shops)
//struct ShopsSectionView: View {
//    let items: [ShopItem]
//    let headerTitle: String
//    
//    // Вычисляем размер так, чтобы ширина ячейки была 1/5 от ширины экрана
//    let cellSize = UIScreen.main.bounds.width / 5
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal)
//            
//            // Горизонтальный ScrollView для непрерывной прокрутки
//            ScrollView(.horizontal, showsIndicators: false) {
//                HStack(spacing: 10) {
//                    ForEach(items) { item in
//                        ShopCell(item: item)
//                            .frame(width: cellSize, height: cellSize)
//                            .cornerRadius(8)
//                    }
//                }
//                .padding(.horizontal)
//            }
//        }
//    }
//}
