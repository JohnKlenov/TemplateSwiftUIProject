//
//  MallCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct MallCell: View {
    let item: MallItem
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) { // Устанавливаем выравнивание ZStack
            WebImageView(
                url: URL(string: item.urlImage),
                placeholderColor: AppColors.secondaryBackground,
                displayStyle: .fixedFrame(width: width, height: height)
            )
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholderColor: AppColors.secondaryBackground,
//                width: width,
//                height: height
//            )
            Color.black.opacity(0.6)
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 10) // Формируем границы
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.blue]), // Цвета градиента
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1 // Толщина границы
                        )
                )
            Text(item.title.value())
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading) // Текст остаётся выровненным по левому краю
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0)) // Отступы сверху и слева
        }
        .frame(width: width, height: height) // Устанавливаем размеры ZStack
    }
}

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
//            Color.black.opacity(0.6)
//                .frame(width: width, height: height)
//            Text(item.title.value())
//                .font(.headline)
//                .foregroundColor(.white)
//                .multilineTextAlignment(.center)
//                .padding()
//        }
//    }
//}



//struct MallCell: View {
//    let item: MallItem
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
