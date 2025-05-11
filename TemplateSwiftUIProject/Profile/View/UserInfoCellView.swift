//
//  UserInfoCellView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.04.25.
//

import SwiftUI

struct UserInfoCellView: View {
    @EnvironmentObject var accountCoordinator: AccountCoordinator
    
    var body: some View {
        HStack(spacing: 16) {
            WebImageView(
                url: URL(string: "https://firebasestorage.googleapis.com/v0/b/templateswiftui.appspot.com/o/GalleryShop%2FBooks-A-Million.jpeg?alt=media&token=12c59f38-9e1f-42ff-9c81-3074f9f229bf"),
                placeholderColor: .gray,
                displayStyle: .fixedFrame(width: 60, height: 60)
            )
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Константин")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("example@example.com")
                    .font(.subheadline)
                    .foregroundColor(AppColors.gray)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            // Chevron справа
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.gray)
                .imageScale(.small)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            print("onTapGesture - UserInfoCellView")
            accountCoordinator.navigateTo(page: .userInfo)
        }
    }
}



