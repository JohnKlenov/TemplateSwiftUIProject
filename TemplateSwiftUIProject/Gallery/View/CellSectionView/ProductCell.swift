//
//  ProductCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct ProductCell: View {
    let item: ProductItem

    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 8) {
                // Рассчитываем размеры изображения равными ширине ячейки и пропорциональной высотой
                let cellWidth = geo.size.width
                let imageHeight = cellWidth * (9 / 16)
                WebImageView(
                    url: URL(string: item.urlImage),
                    placeholderColor: AppColors.secondaryBackground,
                    width: cellWidth,
                    height: imageHeight
                )
                .cornerRadius(8)
                .clipped()
                
                Text(item.title.value())
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(item.description.value())
                    .font(.body)
                    .lineLimit(3)
            }
            .padding(4)
            .background(AppColors.background)
        }
        .frame(height: 300) // Определяем высоту ячейки; можно экспериментировать с этим значением
    }
}



//struct ProductCell: View {
//    let item: ProductItem
//    
//    var body: some View {
//        Group {
//            // Вычисляем ширину изображения с учётом горизонтальных отступов (например, 16 с обеих сторон)
//            let imageWidth: CGFloat = UIScreen.main.bounds.width - 32
//            // Задаём соотношение сторон, например, 16:9 (высота = ширина * (9/16))
//            let imageHeight: CGFloat = imageWidth * (9 / 16)
//            
//            VStack(alignment: .leading, spacing: 10) {
//                // Изображение с динамической высотой
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholder: Image(systemName: "photo"),
//                    width: imageWidth,
//                    height: imageHeight
//                )
//                .cornerRadius(8)
//                .clipped()
//                
//                // Заголовок (title)
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                
//                // Автор (author)
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                // Описание (description)
//                Text(item.description.value())
//                    .font(.body)
//                    .lineLimit(3)
//            }
//            .padding()
//        }
//    }
//}

//struct ProductCell: View {
//    let item: ProductItem
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.green)
//            Text(item.title.value())
//                .font(.subheadline)
//                .foregroundColor(.white)
//        }
//        .frame(height: 100)
//    }
//}
