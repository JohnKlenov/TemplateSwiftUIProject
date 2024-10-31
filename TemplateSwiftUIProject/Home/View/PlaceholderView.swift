//
//  PlaceholderView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.10.24.
//

import SwiftUI

struct PlaceholderView: View {
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundStyle(.orange)
            Text("Oops! Something went wrong!")
                .font(.headline)
                .padding()
            Spacer()
        }
        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.red.opacity(0.5))
        .edgesIgnoringSafeArea(.all)
        //        .padding()
        //        .background(Color.red.opacity(0.5))
    }
}


