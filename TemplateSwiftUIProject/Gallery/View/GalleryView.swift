//
//  GalleryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI

struct GalleryView: View {
    init() {
        print("GalleryView init")
    }
    var body: some View {
        ZStack {
            Color.pink
                .ignoresSafeArea()
            Text("I'm Gallery")
                .font(.system(.largeTitle, design: .default, weight: .regular))
        }
        .onAppear(perform: {
            print("GalleryView onAppear")
        })
        
    }
}

#Preview {
    GalleryView()
}

