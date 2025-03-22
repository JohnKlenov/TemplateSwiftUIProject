//
//  MallCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI


//struct MallCell: View {
//    let item: MallItem
//    let width: CGFloat
//    let height: CGFloat
//
//    var body: some View {
//        ZStack {
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholder: Image(systemName: "photo"),
//                width: width,
//                height: height
//            )
//            Text(item.title.value())
//                .font(.headline)
//                .foregroundColor(.white)
//                .multilineTextAlignment(.center)
//                .padding()
//        }
//    }
//}



struct MallCell: View {
    let item: MallItem

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
    }
}

// MARK: - DeepSeek

//struct MallCell: View {
//    let item: MallItem
//
//    var body: some View {
//        GeometryReader { proxy in
//            ZStack {
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholder: Image(systemName: "photo"),
//                    width: proxy.size.width,
//                    height: proxy.size.height
//                )
//                Text(item.title.value())
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                    .padding()
//            }
//            .background(AppColors.background)
//        }
//    }
//}


//        .frame(height: 200) // здесь задается фиксированная высота для MallCell, при необходимости можно изменить
