//
//  PlaylistToastView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 02.10.2026.
//


import SwiftUI

struct PlaylistToastView: View {

    @EnvironmentObject var localization: LocalizationService

    let toast: PlaylistToast

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .font(
                    .system(
                        size: 17,
                        weight: .semibold
                    )
                )

            Text(message.localized())
                .font(.subheadline.weight(.medium))

            Spacer(minLength: 0)
        }
        .foregroundStyle(AppColors.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(.ultraThinMaterial)
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .shadow(
            color: AppColors.black.opacity(0.18),
            radius: 12,
            x: 0,
            y: 4
        )
    }

    // MARK: - Message

    private var message: String {
        switch toast {
        case .success(let message),
             .info(let message),
             .error(let message):
            return message
        }
    }

    // MARK: - Icon

    private var iconName: String {
        switch toast {
        case .success:
            return AppIcons.Tracklist.success

        case .info:
            return AppIcons.Tracklist.info

        case .error:
            return AppIcons.Tracklist.error
        }
    }
}

// MARK: - before локализация на три языка + адаптация к AppIcons + адаптация к AppColors + добавление новых кейсова для ErrorContext

//import SwiftUI
//
//struct PlaylistToastView: View {
//
//    let toast: PlaylistToast
//
//    var body: some View {
//        HStack(spacing: 10) {
//            Image(systemName: iconName)
//                .font(
//                    .system(
//                        size: 17,
//                        weight: .semibold
//                    )
//                )
//
//            Text(message)
//                .font(
//                    .subheadline.weight(.medium)
//                )
//
//            Spacer(minLength: 0)
//        }
//        .foregroundStyle(.primary)
//        .padding(.horizontal, 16)
//        .padding(.vertical, 13)
//        .background(.ultraThinMaterial)
//        .clipShape(
//            RoundedRectangle(
//                cornerRadius: 16
//            )
//        )
//        .shadow(
//            color: .black.opacity(0.18),
//            radius: 12,
//            x: 0,
//            y: 4
//        )
//    }
//
//    private var message: String {
//        switch toast {
//        case .success(let message),
//             .info(let message),
//             .error(let message):
//            return message
//        }
//    }
//
//    private var iconName: String {
//        switch toast {
//        case .success:
//            return "checkmark.circle.fill"
//
//        case .info:
//            return "info.circle.fill"
//
//        case .error:
//            return "exclamationmark.circle.fill"
//        }
//    }
//}
