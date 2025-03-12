//
//  ProductCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI

struct ProductCell: View {
    let item: Item
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green)
            Text(item.title)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .frame(height: 100)
    }
}
