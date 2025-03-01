//
//  LocalizationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 26.02.25.
//

import Foundation
import SwiftUI

//Этот класс управляет текущим языком приложения и уведомляет о его изменении.

final class LocalizationService: ObservableObject {
    // Singleton для доступа к сервису из любого места
    static let shared = LocalizationService()
    
    // Текущий язык приложения
    @Published var currentLanguage: String {
        didSet {
            // Сохраняем выбранный язык в UserDefaults
            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
            print("currentLanguage - \(currentLanguage)")
        }
    }
    
    // Инициализация: загружаем язык из UserDefaults или используем системный
    private init() {
        if #available(iOS 16.0, *) {
            currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
            ?? Locale.current.language.languageCode?.identifier
            ?? "en"
            
        } else {
            currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
            ?? Locale.current.languageCode
            ?? "en"
        }
    }

    
    // Метод для смены языка
    func setLanguage(_ code: String) {
        currentLanguage = code
        // Отправляем уведомление об изменении языка
//        NotificationCenter.default.post(name: .languageChanged, object: nil)
    }
}

//// Расширение для Notification.Name
//extension Notification.Name {
//    static let languageChanged = Notification.Name("LanguageChanged")
//}

//Это расширение позволяет использовать метод .localized() для получения перевода.
extension String {
    func localized() -> String {
        // Получаем путь к файлу локализации для текущего языка
        guard let path = Bundle.main.path(
            forResource: LocalizationService.shared.currentLanguage,
            ofType: "lproj"
        ), let bundle = Bundle(path: path) else {
            // Если файл не найден, используем стандартную локализацию
            return NSLocalizedString(self, comment: "")
        }
        // Возвращаем перевод из нужного файла
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}

