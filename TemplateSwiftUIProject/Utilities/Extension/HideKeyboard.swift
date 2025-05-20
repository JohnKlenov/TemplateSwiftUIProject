//
//  HideKeyboard.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.05.25.
//

import SwiftUI

//Скрытие клавиатуры по тапу на фон.
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}
