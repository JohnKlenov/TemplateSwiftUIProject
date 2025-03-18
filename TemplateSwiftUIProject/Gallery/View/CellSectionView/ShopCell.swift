//
//  ShopCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct ShopCell: View {
    let item: ShopItem

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Фоновое изображение, растянутое на весь размер ячейки
                WebImageView(
                    url: URL(string: item.urlImage),
                    placeholder: Image(systemName: "photo"),
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                // Текст выведется по центру ZStack (по умолчанию центрован)
                Text(item.title.value())
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding() // опционально, чтобы текст не слипался с краями
            }
        }
//        .frame(height: 200) // здесь задается фиксированная высота для MallCell, при необходимости можно изменить
    }
}


//struct ShopCell: View {
//    let item: Item
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .fill(Color.purple)
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.white)
//        }
//    }
//}
