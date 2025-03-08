//
//  Book.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 3.11.24.
//

import Foundation
import FirebaseFirestore

///При добавлении нового документа с помощью addDocument(from:), Firestore автоматически генерирует уникальный идентификатор для этого документа(он же будет передан в качестве @DocumentID var id при получении данных).
///Когда вы запрашиваете документы из коллекции books, каждый документ будет содержать поле @DocumentID var id, которое будет заполнено значением сгенерированного идентификатора.
///Если вы задаёте собственный идентификатор для документа при его сохранении, то при последующем получении документа из базы данных, поле @DocumentID var id будет содержать этот идентификатор.


//struct BookRealtime: Identifiable, Codable {
//    var id: String?
//    var title: String
//    var author: String
//    var description: String
//    var pathImage: String
//    
////    enum CodingKeys: String, CodingKey {
////        case id
////        case title
////        case author
////        case numberOfPages = "pages"
////      }
//}
//
struct BookCloud: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var title: String
    var author: String
    var description: String
    var urlImage: String
}

// Реализация метода для соответствия протоколу Equatable
//    static func == (lhs: BookCloud, rhs: BookCloud) -> Bool {
//        return lhs.id == rhs.id
//    }

// Промежуточная модель для кодирования
struct EncodableBook: Codable {
    var title: String
    var author: String
    var description: String
    var urlImage: String

    init(from book: BookCloud) {
        self.title = book.title
        self.author = book.author
        self.description = book.description
        self.urlImage = book.urlImage
    }
}


// MARK: - Localization data from CloudFirestore

//struct BookCloud: Identifiable, Codable, Equatable, Hashable {
//    
//    struct LocalizedText: Codable, Equatable, Hashable {
//        let en: String
//        let ru: String?
//        let es: String?
//        
//        func value() -> String {
//            let lang = LocalizationService.shared.currentLanguage
//            switch lang {
//            case "ru" : return ru ?? en
//            case "es": return es ?? en
//            default:
//                return en
//            }
//        }
//    }
//    @DocumentID var id: String?
//    var title: LocalizedText
//    var author: String
//    var description: LocalizedText
//    var urlImage: String
//}
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
