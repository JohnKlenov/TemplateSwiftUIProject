//
//  ToggleCellView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.04.25.
//

import SwiftUI


struct ToggleCellView: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: iconName(for: title))
                .foregroundColor(AppColors.blue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(AppColors.primary)
                .padding(.leading, 8)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle())
        }
        .padding(.vertical, 0)
    }
    
    /// Функция возвращает имя иконки для ToggleCellView по заголовку.
    private func iconName(for title: String) -> String {
        switch title {
        case "Notification":
            return "bell.fill"
        case "Dark mode":
            return "moon.fill"
        default:
            return "questionmark.circle"
        }
    }
}
