//
//  GalleryView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI

struct ModalView:View {
    var body: some View {
        ZStack {
            Color.green
                .ignoresSafeArea()
            Text("I'm ModalView")
                .font(.system(.largeTitle, design: .default, weight: .regular))
        }
    }
}

struct GalleryView: View {
    
    @State var isShowModal:Bool = false
    init() {
        print("GalleryView init")
    }
    var body: some View {
        ZStack {
            Color.pink
                .ignoresSafeArea()
            VStack(spacing:20) {
                Text("I'm Gallery")
                    .font(.system(.largeTitle, design: .default, weight: .regular))
                Button("AddModal", role: .none) {
                    isShowModal.toggle()
                }
            }
            
        }
        .onAppear(perform: {
            print("GalleryView onAppear")
        })
        .sheet(isPresented: $isShowModal) {
            ModalView()
        }
    }
}

#Preview {
    GalleryView()
}

