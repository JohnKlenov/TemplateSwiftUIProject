//
//  ShopCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct ShopCell: View {
    let item: ShopItem
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        WebImageView(
            url: URL(string: item.urlImage),
            placeholderColor: AppColors.secondaryBackground,
            displayStyle: .fixedFrame(width: width, height: height)
        )

//        WebImageView(
//            url: URL(string: item.urlImage),
//            placeholderColor: AppColors.secondaryBackground,
//            width: width,
//            height: height
//        )
    }
}

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

//struct ShopCell: View {
//    let item: ShopItem
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
// MARK: - DeepSeek

//struct ShopCell: View {
//    let item: ShopItem
//    
//    var body: some View {
//        VStack {
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholder: Image(systemName: "photo"),
//                width: 60,
//                height: 60)
//                .aspectRatio(contentMode: .fit)
////                .frame(width: 60, height: 60)
//            
//            Text(item.title.value())
//                .font(.caption)
//                .multilineTextAlignment(.center)
//        }
//        .frame(width: 80, height: 80)
//    }
//}



//struct ShopCell: View {
//    let item: ShopItem
//
//    var body: some View {
//        GeometryReader { proxy in
//            ZStack {
//                // Фоновое изображение, растянутое на весь размер ячейки
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholder: Image(systemName: "photo"),
//                    width: proxy.size.width,
//                    height: proxy.size.height
//                )
//                // Текст выведется по центру ZStack (по умолчанию центрован)
//                Text(item.title.value())
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                    .padding() // опционально, чтобы текст не слипался с краями
//            }
//        }
//    }
//}

//        .frame(height: 200) // здесь задается фиксированная высота для MallCell, при необходимости можно изменить

//struct ShopCell: View {
//    let item: ShopItem
//    var body: some View {
//        ZStack {
//            Rectangle()
//                .fill(Color.purple)
//            Text(item.title.value())
//                .font(.subheadline)
//                .foregroundColor(.white)
//        }
//    }
//}
