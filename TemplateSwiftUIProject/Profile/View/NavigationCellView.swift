//
//  NavigationCellView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.04.25.
//

import SwiftUI

struct NavigationCellView: View {
    let title: String
    let destination: AccountFlow
    @EnvironmentObject var accountCoordinator: AccountCoordinator

    var body: some View {
        HStack {
            Image(systemName: iconName(for: title))
                .foregroundColor(AppColors.blue) // можно настроить цвет под стиль приложения
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(AppColors.primary)
                .padding(.leading, 8)
            
            Spacer()
            
            // Стандартная стрелочка, сигнализирующая о переходе
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.gray)
                .imageScale(.small)
        }
        .padding(.vertical, 0)
        .contentShape(Rectangle())
        .onTapGesture {
            accountCoordinator.navigateTo(page: destination)
            print("onTapGesture - \(title)")
        }
    }
    

    
    /// Функция возвращает имя системной иконки для заданного заголовка.
    private func iconName(for title: String) -> String {
        switch title {
        case "Change language":
            return "globe"
        case "About Us":
            return "info.circle"
        case "Create Account":
            return "person.crop.circle.badge.plus"
        default:
            return "questionmark.circle"
        }
    }
}
