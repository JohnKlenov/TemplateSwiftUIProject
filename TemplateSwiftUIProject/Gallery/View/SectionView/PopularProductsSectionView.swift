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
    
    // Храним вычисленную высоту всех ячеек
    @State private var computedCellHeight: CGFloat = 0
    
    // Определяем две колонки с гибким распределением
    var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Заголовок секции
                Text(headerTitle)
                    .font(.title2)
                    .bold()
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                
                // Один GeometryReader для вычисления доступной ширины и ожидаемой высоты ячейки
                GeometryReader { geometry in
                    // Предположим, горизонтальные отступы по 16 слева и справа
                    let totalHorizontalPadding: CGFloat = 16 * 2
                    // Промежуток между двумя колонками (задаем фиксированное значение, например, 15)
                    let totalSpacing: CGFloat = 15
                    // Вычисляем ширину каждой ячейки
                    let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
                    // Высота изображения по соотношению 3:2 (2/3 ≈ 0.66)
                    let imageHeight = cellWidth * 0.66
                    // Дополнительная высота для текстовой части и отступов
                    let textAndPadding: CGFloat = 100
                    // Итоговая ожидаемая высота ячейки
                    let cellHeightEstimate = imageHeight + textAndPadding
                    
                    // Передаём вычисленную высоту через preference
                    Color.clear
                        .preference(key: CellHeightKey.self, value: cellHeightEstimate)
                    
                    // LazyVGrid для размещения ячеек
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(items) { item in
                            ProductCell(
                                item: item,
                                width: cellWidth,
                                height: computedCellHeight == 0 ? cellHeightEstimate : computedCellHeight
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                // Получаем вычисленное значение высоты из preference
                .onPreferenceChange(CellHeightKey.self) { newHeight in
                    computedCellHeight = newHeight
                }
            }
            .frame(height: computedCellHeight > 0 ? computedCellHeight * CGFloat(items.count/2 ) : nil)

        }
    }
}


//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Используем две колонки с гибкой шириной
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 10) {
//                Text(headerTitle)
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal, 16)
//                    .padding(.top, 10)
//                
//                // Оборачиваем нашу сетку в GeometryReader, чтобы вычислить размеры
//                GeometryReader { geometry in
//                    let totalHorizontalPadding: CGFloat = 16 * 2  // 16 прямая и 16 правая
//                    let totalSpacing: CGFloat = 15                // пространство между колонками
//                    // Вычисляем ширину одной ячейки
//                    let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
//                    // Высота для изображения по соотношению 3:2 (0.66 = 2/3)
//                    let imageHeight = cellWidth * 0.66
//                    // Предположим, что высота текстовой секции плюс отступы составляет примерно 100 пунктов
//                    let textAndPadding: CGFloat = 100
//                    let cellHeight = imageHeight + textAndPadding
//                    
//                    LazyVGrid(columns: columns, spacing: 15) {
//                        ForEach(items) { item in
//                            ProductCell(item: item, width: cellWidth, height: cellHeight)
//                        }
//                    }
//                    .padding(.horizontal, 16)
//                }
//                // GeometryReader внутри ScrollView требует заданной высоты, чтобы правильно отобразиться.
//                // Здесь можно задать примерное значение или вычислить его по содержимому.
//                .frame(height: 600)
//            }
//        }
//    }
//}


//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 15) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .background(Color.green.opacity(0.4))
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal, 16)
//        }
//    }
//}
                  
//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//    
//    var body: some View {
//    
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 10) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal, 16)
//        }
//        .background(Color.yellow)
//        .padding(.bottom, 10)
//    }
//}



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
