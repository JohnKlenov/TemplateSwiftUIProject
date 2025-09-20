//
//  ValidationString.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.05.25.
//

///Если валидаторы по сути представляют собой чистые функции, которые преобразуют входной текст в результат валидации, расширение удобно и прозрачно.
///Если валидация станет значительно сложнее, например, потребуется взаимодействие с сервером или учитывание контекстных данных (например, пользовательских настроек, локализации, динамических правил), то имеет смысл вынести логику в отдельный валидатор или сервис.
///Отдельный сервис можно внедрять в зависимости (например, через DI-контейнер), что улучшает модульность и упрощает тестирование, особенно если потребуется смена локализации динамически.

///Если пользователь вводит «обычный» корректный email, вероятность того, что метод вернет false, крайне мала.
///Для повышения надежности можно использовать более сложное регулярное выражение или специализированные библиотеки, учитывающие все крайние случаи, если требуется абсолютная точность.
///Под «более мощным методом» я подразумеваю подход, который надёжнее охватывает все корректные варианты формата email, согласно стандартам (RFC 5322, например), а не только типичные варианты вроде "user@example.com".

//ValidationString.swift

import Foundation


enum ValidationResult: Equatable {
    case success
    case failure(String)
}


extension String {
    
    var isValidEmail: Bool {
        // Простое регулярное выражение для проверки email.
        // В продакшене можно использовать и более сложное выражение или NSDataDetector.
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
    
    func validatePassword() -> ValidationResult {
        if self.isEmpty {
            return .failure(Localized.ValidSignUp.passwordEmpty)
        }
        if self.count < 8 {
            return .failure(Localized.ValidSignUp.passwordTooShort)
        }
        if self.rangeOfCharacter(from: .decimalDigits) == nil {
            return .failure(Localized.ValidSignUp.passwordNoDigit)
        }
        if self.rangeOfCharacter(from: .lowercaseLetters) == nil {
            return .failure(Localized.ValidSignUp.passwordNoLowercase)
        }
        if self.rangeOfCharacter(from: .uppercaseLetters) == nil {
            return .failure(Localized.ValidSignUp.passwordNoUppercase)
        }
        return .success
    }
    
    // Генерирует уникальный путь для аватара пользователя.
    // - Parameter uid: Идентификатор пользователя.
    // - Returns: Строка вида "avatars/{uid}/avatar_{timestamp}.jpg"
    static func avatarPath(for uid: String) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "avatars/\(uid)/avatar_\(timestamp).jpg"
    }
    
    // Проверка email с использованием NSDataDetector
//        var isValidEmail: Bool {
//            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//            let range = NSRange(location: 0, length: self.utf16.count)
//            let matches = detector?.matches(in: self, options: [], range: range) ?? []
//            return matches.count == 1 && matches.first?.url?.scheme == "mailto"
//        }
}
