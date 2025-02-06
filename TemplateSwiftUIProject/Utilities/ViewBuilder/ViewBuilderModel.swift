//
//  ViewBuilderModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 5.02.25.
//

import SwiftUI

///В твоем коде, HomeFlow используется в качестве значения в NavigationPath, что требует соответствия протоколам Hashable и Equatable.
///NavigationPath использует хэширование для хранения и отслеживания пути. Это означает, что типы значений, передаваемые в NavigationPath, должны быть Hashable и Equatable.
///Протокол Equatable используется для сравнения экземпляров одного и того же типа. Если тип соответствует Equatable, это означает, что экземпляры этого типа можно сравнивать с помощью оператора ==.
///Протокол Hashable используется для создания хэш-кода для объекта. Если тип соответствует Hashable, это означает, что экземпляры этого типа можно хэшировать, что требуется для использования в структурах данных, таких как словари и множества.


enum HomeFlow: Hashable, Equatable {
    case home
    case bookDetails(String) // Передаем ID книги
    case someHomeView

    static func == (lhs: HomeFlow, rhs: HomeFlow) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home), (.someHomeView, .someHomeView):
            return true
        case (.bookDetails(let lhsBook), .bookDetails(let rhsBook)):
            return lhsBook == rhsBook
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine("home")
        case .someHomeView:
            hasher.combine("someHomeView")
        case .bookDetails(let bookID):
            hasher.combine(bookID)
        }
    }
}

struct SheetItem: Identifiable {
    var id = UUID()
    var content: AnyView
}

struct FullScreenItem: Identifiable {
    var id = UUID()
    var content: AnyView
}
