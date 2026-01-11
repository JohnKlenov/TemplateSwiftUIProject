//
//  LocalizationService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 26.02.25.
//



/*
 MARK: - Как iOS выбирает язык интерфейса приложения при запуске

 При запуске приложения iOS определяет, какой язык использовать для локализации интерфейса, основываясь на системных предпочтениях пользователя и доступных локализациях в приложении.

 1. iOS использует список предпочтительных языков пользователя: Locale.preferredLanguages
    - Этот список формируется в настройках "Язык и регион" и содержит языки в порядке приоритета.
    - Пример: ["fr", "zh-Hans", "ru"]

 2. Система по порядку проверяет, есть ли соответствующая локализация (.lproj) в Bundle.main.localizations
    - Это список всех языков, для которых в приложении есть локализованные ресурсы (например: ["en", "ru", "es"])
    - Языки, отсутствующие в этом списке, считаются неподдерживаемыми

 3. Первый язык из Locale.preferredLanguages, который поддерживается приложением, становится языком интерфейса
    - Если "fr" и "zh-Hans" отсутствуют в .lproj, но "ru" есть → используется "ru"
    - Если ни один язык из предпочтений не поддерживается → используется первый доступный из Bundle.main.localizations (например, "en")

 4. Значение Locale.current.language.languageCode?.identifier отражает не системный язык, а фактический язык, выбранный системой для интерфейса приложения
    - Это может быть "ru", даже если системный язык — "fr", если "ru" — первый поддерживаемый язык из предпочтений
    - Если в списке предпочтений только неподдерживаемые языки → будет fallback на "en"

 5. Если пользователь вручную выбрал язык для конкретного приложения (iOS 13+), он имеет приоритет над системными настройками

 🔍 Для получения:
 - Фактически выбранного языка приложения → Locale.current.language.languageCode?.identifier
 - Реального системного языка пользователя → Locale.preferredLanguages.first?.prefix(2)

 Это поведение встроено в iOS и не зависит от логики приложения или кода LocalizationService.
*/





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
            
        }
    }
    
    // Инициализация: загружаем язык из UserDefaults или используем системный
    private init() {
        // Удаляем сохранённый язык при первом запуске (опционально)
        //            UserDefaults.standard.removeObject(forKey: "selectedLanguage")
        
        // Получаем системный язык
        let systemLanguage: String
        if #available(iOS 16.0, *) {
            systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            systemLanguage = Locale.current.languageCode ?? "en"
        }
        
        // Получаем список доступных локализаций из .lproj
        let supportedLanguages = Bundle.main.localizations
        
        // Проверяем сохранённый язык
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
        
        // Выбираем язык:
        // 1. Если сохранён — используем
        // 2. Если системный поддерживается — используем
        // 3. Иначе — fallback на английский
        if let saved = savedLanguage {
            currentLanguage = saved
        } else if supportedLanguages.contains(systemLanguage) {
            currentLanguage = systemLanguage
        } else {
            currentLanguage = "en"
        }
    }
    
    func setLanguage(_ code: String) {
        let supported = Bundle.main.localizations
        currentLanguage = supported.contains(code) ? code : "en"
    }
    
    // Возвращает список всех локализаций, доступных в приложении (.lproj), исключая Base
    /// Возвращает список доступных локализаций приложения.
    /// Фильтруем "Base", так как это техническая локализация Xcode для UI‑ресурсов,
    /// она не предназначена для выбора пользователем и может появиться в проекте автоматически.
    func availableLanguages() -> [String] {
        Bundle.main.localizations.filter { $0 != "Base" }
    }
    
}



//Это расширение позволяет использовать метод .localized() для получения перевода.
extension String {
    func localized() -> String {
        // Получаем путь к файлу локализации для текущего языка
        guard let path = Bundle.main.path(
            forResource: LocalizationService.shared.currentLanguage,
            ofType: "lproj"
        ), let bundle = Bundle(path: path) else {
            print("⚠️ Fallback: no .lproj for \(LocalizationService.shared.currentLanguage)")
            // Если файл не найден, используем стандартную локализацию
            return NSLocalizedString(self, comment: "")
        }
        // Возвращаем перевод из нужного файла
        return bundle.localizedString(forKey: self, value: nil, table: nil)
    }
}



//print("currentLanguage - \(currentLanguage)")
//print("Locale.current.language.languageCode?.identifier - \(String(describing: Locale.current.language.languageCode?.identifier))")
//print("Locale.current.languageCode")
//
//
//print("systemLanguage = \(systemLanguage)")
//print("supportedLanguages = \(supportedLanguages)")
//print("selected currentLanguage = \(currentLanguage)")




//import Foundation
//import SwiftUI
//
//final class LocalizationService: ObservableObject {
//    static let shared = LocalizationService()
//    
//    @Published var currentLanguage: String {
//        didSet {
//            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
//            print("currentLanguage - \(currentLanguage)")
//        }
//    }
//    
//    private init() {
//        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
//        
//        let systemLanguage: String
//        if #available(iOS 16.0, *) {
//            systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"
//        } else {
//            systemLanguage = Locale.current.languageCode ?? "en"
//        }
//        
//        let supportedLanguages = availableLanguages()
//        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
//        
//        if let saved = savedLanguage {
//            currentLanguage = saved
//        } else if supportedLanguages.contains(systemLanguage) {
//            currentLanguage = systemLanguage
//        } else {
//            currentLanguage = "en"
//        }
//        
//        print("systemLanguage = \(systemLanguage)")
//        print("supportedLanguages = \(supportedLanguages)")
//        print("selected currentLanguage = \(currentLanguage)")
//    }
//    
//    func setLanguage(_ code: String) {
//        currentLanguage = code
//    }
//    
//    /// Возвращает список всех локализаций, доступных в приложении (.lproj)
//    func availableLanguages() -> [String] {
//        Bundle.main.localizations.filter { $0 != "Base" }
//    }
//    
//    /// Проверяет, поддерживается ли указанный язык приложением
//    func isSupported(language code: String) -> Bool {
//        availableLanguages().contains(code)
//    }
//}


//LocalizationService.shared.availableLanguages()
//// → ["en", "ru", "es"]
//
//LocalizationService.shared.isSupported(language: "fr")
//// → false




// MARK: - before "en" как fallback



//import Foundation
//import SwiftUI
//
////Этот класс управляет текущим языком приложения и уведомляет о его изменении.
//
//final class LocalizationService: ObservableObject {
//    // Singleton для доступа к сервису из любого места
//    static let shared = LocalizationService()
//    
//    // Текущий язык приложения
//    @Published var currentLanguage: String {
//        didSet {
//            // Сохраняем выбранный язык в UserDefaults
//            UserDefaults.standard.set(currentLanguage, forKey: "selectedLanguage")
//            print("currentLanguage - \(currentLanguage)")
//        }
//    }
//    
//    // Инициализация: загружаем язык из UserDefaults или используем системный
//    private init() {
//        // что бы использовать текущий язык ios нужно обнулить при первом старте UserDefaults
//        // при первом старте приложения мы всегда ставим язык системы
//        // затем все время берем язык из UserDefaults.standard.string(forKey: "selectedLanguage") или меняем руками из приложения
//        UserDefaults.standard.removeObject(forKey: "selectedLanguage")
//        print("languageCode -  \(String(describing: Locale.current.language.languageCode?.identifier)) ")
//        if #available(iOS 16.0, *) {
//            currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
//            ?? Locale.current.language.languageCode?.identifier
//            ?? "en"
//            
//        } else {
//            currentLanguage = UserDefaults.standard.string(forKey: "selectedLanguage")
//            ?? Locale.current.languageCode
//            ?? "en"
//        }
//    }
//    
//    // Метод для смены языка
//    func setLanguage(_ code: String) {
//        currentLanguage = code
//    }
//}
//
////Это расширение позволяет использовать метод .localized() для получения перевода.
//extension String {
//    func localized() -> String {
//        // Получаем путь к файлу локализации для текущего языка
//        guard let path = Bundle.main.path(
//            forResource: LocalizationService.shared.currentLanguage,
//            ofType: "lproj"
//        ), let bundle = Bundle(path: path) else {
//            // Если файл не найден, используем стандартную локализацию
//            return NSLocalizedString(self, comment: "")
//        }
//        // Возвращаем перевод из нужного файла
//        return bundle.localizedString(forKey: self, value: nil, table: nil)
//    }
//}
