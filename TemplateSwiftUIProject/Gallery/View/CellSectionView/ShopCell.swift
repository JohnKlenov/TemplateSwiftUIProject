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
    }
}

