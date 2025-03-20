//
//  MallsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI


struct MallsSectionView: View {
    let items: [MallItem]
    let headerTitle: String

    @State private var computedCellHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок секции
            Text(headerTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal, 16)
            
            GeometryReader { geometry in
                let horizontalPadding: CGFloat = 16
                let cellSpacing: CGFloat = 10
                let availableWidth = geometry.size.width - 2 * horizontalPadding
                let cellWidth = availableWidth - cellSpacing
                let cellHeight = cellWidth * 0.55  // Вычисляем пропорциональную высоту

                // Помещаем прозрачный элемент, чтобы установить preference
                Color.clear
                    .preference(key: CellHeightKey.self, value: cellHeight)
                
                TabView {
                    ForEach(items) { item in
                        MallCell(item: item)
                            .frame(width: cellWidth, height: cellHeight)
                            .cornerRadius(10)
                            .padding(.horizontal, cellSpacing / 2)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: cellHeight)
                .padding(.horizontal, horizontalPadding)
            }
            .onPreferenceChange(CellHeightKey.self) { value in
                computedCellHeight = value
            }
        }
        // Общая высота секции: вычисленная cellHeight + отступы (например, 60)
        .frame(height: computedCellHeight + 60)
        .background(Color.blue.opacity(0.1))
    }
}

//struct MallsSectionView: View {
//    let items: [MallItem]
//    let headerTitle: String
//
//    var body: some View {
//        // Вычислим ширину экрана
//        let screenWidth = UIScreen.main.bounds.width
//        let horizontalPadding: CGFloat = 16
//        let cellSpacing: CGFloat = 10
//        let availableWidth = screenWidth - 2 * horizontalPadding
//        // Предположим, что у нас одна большая ячейка в карусели:
//        let cellWidth = availableWidth - cellSpacing
//        let cellHeight = cellWidth * 0.55  // соотношение сторон
//    
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, horizontalPadding)
//            
//            TabView {
//                ForEach(items) { item in
//                    MallCell(item: item)
//                        .frame(width: cellWidth, height: cellHeight)
//                        .cornerRadius(10)
//                        .padding(.horizontal, cellSpacing / 2)
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//            .frame(height: cellHeight)
//            .padding(.horizontal, horizontalPadding)
//        }
//        // Зададим общую высоту как сумму: высота текста заголовка (примерно 40) + cellHeight + дополнительные отступы (примерно 20)
//        .frame(height: cellHeight + 60)
//        .background(Color.blue.opacity(0.4))
//    }
//}


// MARK: - DeepSeek

//struct MallsSectionView: View {
//    let items: [MallItem]
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
//                let cellSpacing: CGFloat = 10
//                let availableWidth = geometry.size.width - 2 * horizontalPadding
//                let cellWidth = availableWidth - cellSpacing
//                let cellHeight = cellWidth * 0.55
//                
//                VStack {
//                    TabView {
//                        ForEach(items) { item in
//                            MallCell(item: item)
//                                .frame(width: cellWidth, height: cellHeight)
//                        }
//                    }
//                    .tabViewStyle(.page)
//                    .frame(height: cellHeight)
//                }
////                .padding(.horizontal, horizontalPadding)
////                .padding(.vertical, horizontalPadding)
//            }
//            .frame(height: calculateMallsHeight()) // Динамическая высота
//            .background(Color.blue.opacity(0.3))
//        }
//    }
//    
//    private func calculateMallsHeight() -> CGFloat {
//        let screenWidth = UIScreen.main.bounds.width
//        let cellHeight = (screenWidth - 32 - 10) * 0.55 // 32 = 16*2 padding
//        return cellHeight + 60 //  Высота табвью + заголовок + отступы
//    }
//}

//struct MallsSectionView: View {
//    let items: [MallItem]
//    let headerTitle: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//            
//            GeometryReader { geometry in
//                let horizontalPadding: CGFloat = 16
//                let cellSpacing: CGFloat = 10
//                let availableWidth = geometry.size.width - 2 * horizontalPadding
//                let cellWidth = availableWidth - cellSpacing
//                let cellHeight = cellWidth * 0.55  // Это вычисляемая высота ячейки
//     
//                TabView {
//                    ForEach(items) { item in
//                        MallCell(item: item)
//                            .frame(width: cellWidth, height: cellHeight)
//                            .cornerRadius(10)
//                            .padding(.horizontal, cellSpacing / 2)
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                // Пользуемся вычисленным значением для TabView
//                .frame(height: cellHeight)
//                .padding(.horizontal, horizontalPadding)
//            }
//            // Вместо жесткого .frame(height: 250), можно не задавать его вовсе,
//            // или, если хочется добавить дополнительный отступ, использовать вычисленное значение:
//            //.frame(height: calculatedHeight)
//        }
//        .background(Color.blue.opacity(0.1))
//    }
//}


//struct MallsSectionView: View {
//    let items: [MallItem]
//    let headerTitle: String
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//            
//            // Используем GeometryReader для расчёта размеров секции
//            GeometryReader { geometry in
//                let horizontalPadding: CGFloat = 16
//                let cellSpacing: CGFloat = 10
//                let availableWidth = geometry.size.width - 2 * horizontalPadding
//                let cellWidth = availableWidth - cellSpacing
//                // Вычисляем высоту на основе пропорционального соотношения (например, 0.55)
//                let cellHeight = cellWidth * 0.55
//                
//                TabView {
//                    ForEach(items) { item in
//                        MallCell(item: item)
//                            .frame(width: cellWidth, height: cellHeight)
//                            .cornerRadius(10)
//                            .padding(.horizontal, cellSpacing / 2)
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                // Задаем высоту TabView согласно рассчитанной высоте
//                .frame(height: cellHeight)
//                .padding(.horizontal, horizontalPadding)
//            }
//            // Вместо жесткого фиксированного размера наружного контейнера,
//            // можно задать пропорциональную высоту или использовать GeometryReader на уровне GalleryContentView.
//        }
//        .padding(.vertical)
//        .background(Color.blue.opacity(0.1))
//    }
//}

//struct MallsSectionView: View {
//    let items: [MallItem]
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
//                // Вычисляем доступную ширину с учётом отступов:
//                let horizontalPadding: CGFloat = 16
//                let cellSpacing: CGFloat = 10
//                let availableWidth = geometry.size.width - 2 * horizontalPadding
//                // Вычитаем spacing между ячейками (в данном случае, предположим, что в карусели одна ячейка, поэтому просто availableWidth минус spacing):
//                let cellWidth = availableWidth - cellSpacing
//                let cellHeight = cellWidth * 0.55
//                
//                TabView {
//                    ForEach(items) { item in
//                        MallCell(item: item)
//                            .frame(width: cellWidth, height: cellHeight)
//                            .cornerRadius(10)
//                            .padding(.horizontal, cellSpacing / 2)
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                .frame(height: cellHeight)
//                .padding(.horizontal, horizontalPadding)
//            }
//            .frame(height: 200) // Фиксированная высота для секции (можно регулировать)
//        }
//        .background(Color.blue)
//    }
//}


/// Секция Торговых Центров (Malls)
//struct MallsSectionView: View {
//    let items: [MallItem]
//    let headerTitle: String
//
//    var body: some View {
//        GeometryReader { geometry in
//            let horizontalPadding: CGFloat = 16
//            let cellSpacing: CGFloat = 10
//            let cellWidth = geometry.size.width - 2 * horizontalPadding - cellSpacing
//
//            VStack(alignment: .leading, spacing: 10) {
//                // Заголовок с одинаковыми отступами, как и в другой секции
//                Text(headerTitle)
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal, horizontalPadding)
//                
//                // TabView с каруселью и внутренними отступами
//                TabView {
//                    ForEach(items) { item in
//                        MallCell(item: item)
//                            .frame(width: cellWidth, height: cellWidth * 0.55)
//                            .cornerRadius(10)
//                            .padding(.horizontal, cellSpacing / 2)  // Добавляем отступы между ячейками
//                    }
//                }
//                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
//                .frame(height: cellWidth * 0.55)
//                .padding(.horizontal, horizontalPadding)
//            }
//        }
//        .frame(height: 250) // Подберите это значение под ваш контент
//    }
//}

