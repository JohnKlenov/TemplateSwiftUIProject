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
            alignment: .center,
            spacing: 4
        ) {
//            Text("Albums:")
//                .font(.headline)
//                .foregroundColor(.secondary)

            ForEach(
                details.indices,
                id: \.self
            ) { index in
                Text(details[index])
                    .font(.subheadline)
                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
        .padding(16)
        .background(AppColors.background)
        .cornerRadius(12)
//        .shadow(
//            color: AppColors.primary.opacity(0.15),
//            radius: 8,
//            x: 0,
//            y: 0
//        )
//        .padding(.horizontal)
//        .padding(.vertical)
    }
}

//import SwiftUI
//
//struct PlaylistDetailsView: View {
//    let details: [String]
//
//    var body: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 8
//        ) {
//            ForEach(
//                Array(details.enumerated()),
//                id: \.offset
//            ) { _, detail in
//                Text(detail)
//                    .font(.subheadline)
//                    .foregroundStyle(.primary)
//                    .frame(
//                        maxWidth: .infinity,
//                        alignment: .leading
//                    )
//            }
//        }
//        .padding()
//        .background(
//            AppColors.background
//        )
//        .cornerRadius(12)
//        .shadow(
//            color: AppColors.primary.opacity(0.15),
//            radius: 8,
//            x: 0,
//            y: 4
//        )
//        .padding(.horizontal)
//    }
//}
