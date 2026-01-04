//
//  DeleteAccountCellView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.07.25.
//



import SwiftUI

/// как получается так что при изменение accountDeletionState извне DeleteAccountCellView перерисовывается?
/// ведь let accountDeletionState не State не Binding?

struct DeleteAccountCellView: View {
    
    @EnvironmentObject var localization: LocalizationService
    
    let accountDeletionState: AuthorizationManager.State
    let title: AccountRowTitle = .deleteAccount
    
    var body: some View {
        HStack {
            Image(systemName: title.iconName)
                .foregroundColor(.red)
                .frame(width: 24, height: 24)
            
            Text(title.localizedKey.localized())
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
//    let accountDeletionState: AuthorizationManager.State
//    @EnvironmentObject var localization: LocalizationService
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "trash")
//                .foregroundColor(.red)
//                .frame(width: 24, height: 24)
//            
//            Text(Localized.Profile.DeleteAccountCellView.deleteAccount.localized())
//                .foregroundColor(.red)
//                .padding(.leading, 8)
//            
//            Spacer()
//            
//            if accountDeletionState == .loading {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
//            }
//        }
//        .contentShape(Rectangle())
//    }
//}


// MARK: - before AccountRowTitle

//struct DeleteAccountCellView: View {
//    let accountDeletionState: AuthorizationManager.State
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "trash")
//                .foregroundColor(.red)
//                .frame(width: 24, height: 24)
//            
//            Text("Delete Account")
//                .foregroundColor(.red)
//                .padding(.leading, 8)
//            
//            Spacer()
//            
//            if accountDeletionState == .loading {
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
//            }
//        }
//        .contentShape(Rectangle())
//    }
//}




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

