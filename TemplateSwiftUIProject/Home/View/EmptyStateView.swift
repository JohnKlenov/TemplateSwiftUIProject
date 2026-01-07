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
    @EnvironmentObject var localization: LocalizationService
    var imageName: String = "doc.plaintext"

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.gray)
            Text(Localized.Home.EmptyStateView.title.localized())
                .font(.headline)
                .foregroundColor(AppColors.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
    }
}


