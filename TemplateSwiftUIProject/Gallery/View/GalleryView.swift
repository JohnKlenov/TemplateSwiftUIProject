//
//  GalleryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI

struct GalleryView: View {
    var body: some View {
        ZStack {
            Color.pink
                .ignoresSafeArea()
            Text("I'm Gallery")
                .font(.system(.largeTitle, design: .default, weight: .regular))
        }
        
    }
}

#Preview {
    GalleryView()
}
