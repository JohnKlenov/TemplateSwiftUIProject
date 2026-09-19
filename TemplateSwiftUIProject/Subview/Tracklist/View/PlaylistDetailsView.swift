//
//  PlaylistDetailsView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 19.09.2026.
//

import SwiftUI

struct PlaylistDetailsView: View {
    let details: [String]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(
                Array(details.enumerated()),
                id: \.offset
            ) { _, detail in
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
        }
        .padding()
        .background(
            AppColors.background
        )
        .cornerRadius(12)
        .shadow(
            color: AppColors.primary.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal)
    }
}
