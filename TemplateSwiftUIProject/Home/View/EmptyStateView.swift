//
//  EmptyStateView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 15.04.25.
//

import SwiftUI

struct EmptyStateView: View {
    // Опционально можно сделать параметризуемым,
    // например, передавать название изображения и текст.
    var imageName: String = "doc.plaintext"
    var title: String = "Пусто. Добавьте новые записи!"

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}

