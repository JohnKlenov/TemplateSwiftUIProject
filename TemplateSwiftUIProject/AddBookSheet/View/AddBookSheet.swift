//
//  AddBookSheet.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.11.24.
//

import SwiftUI

struct AddBookSheet: View {
    var body: some View {
        ZStack {
            AppColors.activeColor
                .ignoresSafeArea()
            Text("NewItemView!")
                .font(.system(.largeTitle, design: .rounded, weight: .regular))
        }
        
    }
}

#Preview {
    AddBookSheet()
}

