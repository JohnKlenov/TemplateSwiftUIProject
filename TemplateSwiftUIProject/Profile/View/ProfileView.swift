//
//  ProfileView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 18.10.24.
//

import SwiftUI

struct ProfileView: View {
    
    // Получаем сервис локализации через EnvironmentObject
    @EnvironmentObject var localization: LocalizationService
    
    // Список поддерживаемых языков
    let supportedLanguages = ["en", "ru", "es"]
    
    var body: some View {
        List(supportedLanguages, id: \.self) { code in
            Button(action: {
                // Устанавливаем выбранный язык
                localization.setLanguage(code)
            }) {
                HStack {
                    // Отображаем название языка
                    Text(languageName(for: code))
                    Spacer()
                    // Показываем галочку для текущего языка
                    if code == localization.currentLanguage {
                        Image(systemName: "checkmark")
                    }
                }
            }
        }
        .onAppear{
            print("GalleryView onAppear")
        }
    }
    
    // Метод для получения названия языка
    private func languageName(for code: String) -> String {
        Locale.current.localizedString(forLanguageCode: code) ?? code.uppercased()
    }
}

//struct ProfileView: View {
//    
//    @State private var searchText = ""
//    let items = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grape"]
//    var filteredItems: [String] {
//        if searchText.isEmpty {
//            return items
//        } else {
//            return items.filter { $0.contains(searchText) }
//        }
//    }
//    
//    init() {
//        print("ProfileView init")
//    }
//    var body: some View {
//        
//        NavigationStack {
//            List(filteredItems, id: \.self) { item in
//                Text(item)
//            }
//            .navigationTitle("Fruits")
//            .searchable(text: $searchText, prompt: "Search fruits")
//        }
//    }
//}

//#Preview {
//    ProfileView()
//}
