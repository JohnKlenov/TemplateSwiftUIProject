//
//  ChangeLanguageViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 29.11.25.
//

import Foundation


final class ChangeLanguageViewModel: ObservableObject {
    @Published var selectedLanguage: String
    let availableLanguages: [String]
    
    private let localizationService: LocalizationService
    
    init(localizationService: LocalizationService) {
        print("init ChangeLanguageViewModel")
        self.localizationService = localizationService
        self.selectedLanguage = localizationService.currentLanguage
        self.availableLanguages = localizationService.availableLanguages()
    }
    
    func selectLanguage(_ code: String) {
        guard availableLanguages.contains(code) else { return }
        localizationService.setLanguage(code)
        selectedLanguage = code
    }
    
    /// Возвращает читаемое название языка по его коду.
    /// ВАЖНО: название формируется системой iOS через Locale.current.localizedString(forLanguageCode:),
    /// а не задаётся вручную в коде. Например, "ru" → "Русский" или "Russian" в зависимости от локали.
    /// Если язык неизвестен системе, возвращается сам код в верхнем регистре как fallback.
    func displayName(for code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
    }

    
    deinit {
        print("deinit ChangeLanguageViewModel")
    }
}

