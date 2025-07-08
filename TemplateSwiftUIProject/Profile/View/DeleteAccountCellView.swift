//
//  DeleteAccountCellView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//

import SwiftUI

struct DeleteAccountCellView: View {
    let accountDeletionState: AuthorizationManager.State
    
    var body: some View {
        HStack {
            Image(systemName: "trash")
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
            
            Text("Delete Account")
                .foregroundColor(.red)
                .padding(.leading, 8)
            
            Spacer()
            
            if accountDeletionState == .loading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
            }
        }
        .contentShape(Rectangle())
    }
}

//struct DeleteAccountCellView: View {
//    var body: some View {
//        HStack {
//            Image(systemName: "trash") // Иконка корзины
//                .foregroundColor(.red) // Красный цвет для иконки
//                .frame(width: 24, height: 24)
//            
//            Text("Delete Account")
//                .foregroundColor(.red) // Красный цвет для текста
//                .padding(.leading, 8)
//            
//            Spacer()
//        }
//    }
//}

