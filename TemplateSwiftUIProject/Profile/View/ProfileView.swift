//
//  ProfileView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        
        ZStack {
            Color.black
                .ignoresSafeArea()
            Text("I'm Profile")
                .font(.system(.title, design: .rounded, weight: .heavy))
                .foregroundStyle(.purple)
        }
    }
}

#Preview {
    ProfileView()
}
