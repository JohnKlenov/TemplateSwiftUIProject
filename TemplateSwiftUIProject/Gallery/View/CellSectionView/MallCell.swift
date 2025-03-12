//
//  MallCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct MallCell: View {
    let item: Item
    var body: some View {
        ZStack {
            // Можно заменить на изображение или другой контент
            Rectangle()
                .fill(Color.blue)
            Text(item.title)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
