//
//  ClearButtonModifier.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.08.25.
//

import Foundation
import SwiftUI

//ClearButtonModifier — это компактная переиспользуемая обёртка, которая целенаправленно добавляет кнопку очистки к любому TextField, не смешивая эту логику напрямую с остальным UI.
///ViewModifier -  Обёртка над другим View, расширяющая его поведение
///Модификатор — это не просто способ «изменить стиль», он может обернуть, расширить, добавить или заменить части интерфейса, к которому применяется.
///Modifier в SwiftUI — это объект, который принимает исходный View, модифицирует его каким-то образом и возвращает новый View. (в отличии от view ViewModifier Не рендерится сам по себе, а приклеивается к другим элементам через .modifier или кастомные аксессоры.)
///@Binding var text: String — двусторонняя привязка к содержимому TextField.
///@Binding var isFocused: Bool — флаг, указывающий, в фокусе ли сейчас поле.
///body(content:) - SwiftUI передаёт сюда исходный View (тот, к которому вы применили modifier) как content.
///Мы добавляем к нему отступ справа (.padding(.trailing, 28)), чтобы освободить место под кнопку “крестик”.
///С помощью .overlay(alignment: .trailing) поверх поля рисуем условный блок. (Если поле находится в фокусе И текст не пустой огда рисуем Button, стилизованную иконкой “xmark.circle.fill”.
///func clearButton - Расширение для удобства)
private struct ClearButtonModifier: ViewModifier {
    @Binding var text: String
    @Binding var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .padding(.trailing, 28)
            .overlay(alignment: .trailing) {
                if isFocused && !text.isEmpty {
                    Button {
                        print("dit tap ClearButtonModifier")
                        withAnimation(.easeInOut(duration: 0.15)) {
                            text = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .opacity(0.9)
                            .contentShape(Rectangle())
                    }
                    .padding(.trailing, 4)
                    .transition(.opacity) // .transition(.opacity) — для анимации появления/исчезновения (В данном случае — плавное затухание (fade in/out) + Работает в паре с withAnimation(...), иначе не будет эффекта.SwiftUI проверяет, какие элементы исчезают, и применяет .transition(.opacity).)
                }
            }
    }
}

extension View {
    func clearButton(text: Binding<String>, isFocused: Binding<Bool>) -> some View {
        modifier(ClearButtonModifier(text: text, isFocused: isFocused))
    }
}
