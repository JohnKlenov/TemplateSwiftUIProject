//
//  MallCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct MallCell: View {
    @EnvironmentObject var localization: LocalizationService
    
    let item: MallItem
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack(alignment: .topLeading) { // Устанавливаем выравнивание ZStack
            WebImageView(
                url: URL(string: item.urlImage),
                placeholderColor: AppColors.secondarySystemBackground,
                displayStyle: .fixedFrame(width: width, height: height)
            )
            AppColors.black.opacity(0.6)
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
                .foregroundColor(AppColors.primary)
                .multilineTextAlignment(.leading) // Текст остаётся выровненным по левому краю
                .padding(EdgeInsets(top: 10, leading: 10, bottom: 0, trailing: 0)) // Отступы сверху и слева
        }
        .frame(width: width, height: height) // Устанавливаем размеры ZStack
    }
}

