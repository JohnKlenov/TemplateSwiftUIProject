//
//  GalleryModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 8.03.25.
//

import Foundation
import FirebaseFirestore

struct GalleryBook: Identifiable, Codable, Equatable, Hashable {
    

    struct LocalizedText: Codable, Equatable, Hashable {
        let en: String
        let ru: String?
        let es: String?

        func value() -> String {
            let lang = LocalizationService.shared.currentLanguage
            switch lang {
            case "ru" : return ru ?? en
            case "es": return es ?? en
            default:
                return en
            }
        }
    }
    @DocumentID var id: String?
    var title: LocalizedText
    var author: String
    var description: LocalizedText
    var urlImage: String
}

struct Item: Identifiable {
    let id: String
    let title: String
    // Добавьте нужные свойства для каждой ячейки
}

struct SectionModel: Identifiable {
    let id = UUID()
    let section: String   // "Malls", "Shops", "PopularProducts"
    let items: [Item]
}

//
//// Промежуточная модель для Encodable
//struct EncodableBook: Codable {
//    var title: BookCloud.LocalizedText
//    var author: String
//    var description: BookCloud.LocalizedText
//    var urlImage: String
//
//    init(from book: BookCloud) {
//        self.title = book.title
//        self.author = book.author
//        self.description = book.description
//        self.urlImage = book.urlImage
//    }
//}
