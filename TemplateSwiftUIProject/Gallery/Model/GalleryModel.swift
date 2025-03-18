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

struct SectionModel: Identifiable {
    let id = UUID()
    let section: String   // "Malls", "Shops", "PopularProducts"
    let items: [Item]
}

struct Item: Identifiable, Codable, Equatable, Hashable {
    

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
    var id: String?
    var title: LocalizedText?
    var author: String?
    var description: LocalizedText?
    var urlImage: String?
}

// MARK: - different models from GalleryView

struct ShopItem: Identifiable, Codable, Equatable, Hashable {
    
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
    
    var id: String
    var title: LocalizedText
    var urlImage: String
}

struct MallItem: Identifiable, Codable, Equatable, Hashable {
    
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
    
    var id: String
    var title: LocalizedText
    var urlImage: String
}

struct ProductItem: Identifiable, Codable, Equatable, Hashable {
    

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
    var id: String
    var title: LocalizedText
    var author: String
    var description: LocalizedText
    var urlImage: String
}

struct MallSectionModel: Identifiable {
    let id = UUID()
    let header: String  // "Торговые Центры"
    let items: [MallItem]
}

struct ShopSectionModel: Identifiable {
    let id = UUID()
    let header: String  // "Магазины"
    let items: [ShopItem]
}

struct PopularProductsSectionModel: Identifiable {
    let id = UUID()
    let header: String  // "Популярные товары"
    let items: [ProductItem]
}

enum UnifiedSectionModel: Identifiable {
    case malls(MallSectionModel)
    case shops(ShopSectionModel)
    case popularProducts(PopularProductsSectionModel)
    
    var id: UUID {
        switch self {
        case .malls(let model):
            return model.id
        case .shops(let model):
            return model.id
        case .popularProducts(let model):
            return model.id
        }
    }
    
    var header: String {
        switch self {
        case .malls(let model):
            return model.header
        case .shops(let model):
            return model.header
        case .popularProducts(let model):
            return model.header
        }
    }
}






// MARK: - save data from CloudFirestore

//let serviceFB = PostDataCloudFirestore()
//Task {
//    do {
//        try await serviceFB.saveSampleData()
//        print("All data successfully saved to Firestore.")
//    }catch {
//        print("Failed to save data: \(error.localizedDescription)")
//        
//    }
//}


//struct ShopItem1: Identifiable, Codable, Equatable, Hashable {
//    
//    struct LocalizedText: Codable, Equatable, Hashable {
//        let en: String
//        let ru: String?
//        let es: String?
//        
//        func value() -> String {
//            let lang = LocalizationService.shared.currentLanguage
//            switch lang {
//            case "ru": return ru ?? en
//            case "es": return es ?? en
//            default: return en
//            }
//        }
//    }
//    
//    var title: LocalizedText
//    var urlImage: String
//    
//    // Вычисляемое свойство id – используется значение английского названия
//    var id: String { title.en }
//}
//
//struct ProductItem1: Identifiable, Codable, Equatable, Hashable {
//    
//    struct LocalizedText: Codable, Equatable, Hashable {
//        let en: String
//        let ru: String?
//        let es: String?
//        
//        func value() -> String {
//            let lang = LocalizationService.shared.currentLanguage
//            switch lang {
//            case "ru": return ru ?? en
//            case "es": return es ?? en
//            default: return en
//            }
//        }
//    }
//    
//    // Здесь id оставляем как хранимое, если вы решите его генерировать на стороне клиента,
//    // но если на сервере id будет именно название (title.en), то можно убрать и использовать вычисляемое свойство.
//    var id: String
//    var title: LocalizedText
//    var author: String
//    var description: LocalizedText
//    var urlImage: String
//}
//
//struct DataCloudFirestore {
//    
//    static let sampleBookstores: [ShopItem1] = [
//        ShopItem1(
//            title: .init(en: "Barnes & Noble", ru: "Барнс энд Нобл", es: "Barnes & Noble"),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/7/76/Barnes_%26_Noble_logo.svg.jpeg" // пример ссылки, замените на рабочую
//        ),
//        ShopItem1(
//            title: .init(en: "Waterstones", ru: "Уотерстоунс", es: "Waterstones"),
//            urlImage: "https://upload.wikimedia.org/wikipedia/en/9/9b/Waterstones_logo.png" // пример ссылки
//        ),
//        ShopItem1(
//            title: .init(en: "Foyles", ru: "Фойлс", es: "Foyles"),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/9/9a/Foyles_logo.jpg" // пример ссылки
//        ),
//        ShopItem1(
//            title: .init(en: "Kinokuniya", ru: "Кинокунья", es: "Kinokuniya"),
//            urlImage: "https://upload.wikimedia.org/wikipedia/en/a/ac/Kinokuniya_Logo.png" // пример ссылки
//        ),
//        ShopItem1(
//            title: .init(en: "Books-A-Million", ru: "Букс-Эй-Миллион", es: "Books-A-Million"),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/2/2c/Books-A-Million_logo.png" // пример ссылки
//        ),
//        ShopItem1(
//            title: .init(en: "El Ateneo Grand Splendid", ru: "Эль Атенео Гранд Сплендид", es: "El Ateneo Grand Splendid"),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/2/2b/El_Ateneo_Grand_Splendid.jpg" // пример ссылки
//        )
//    ]
//    
//    static let sampleBooks: [ProductItem1] = [
//        ProductItem1(
//            id: "1",
//            title: .init(en: "To Kill a Mockingbird", ru: "Убить пересмешника", es: "Matar a un ruiseñor"),
//            author: "Harper Lee",
//            description: .init(en: "A novel about racial injustice in the Deep South.",
//                               ru: "Роман об расовой несправедливости на Юге Америки.",
//                               es: "Una novela sobre la injusticia racial en el sur profundo."),
//            urlImage: "https://upload.wikimedia.org/wikipedia/en/7/79/To_Kill_a_Mockingbird.JPG" // пример ссылки
//        ),
//        ProductItem1(
//            id: "2",
//            title: .init(en: "1984", ru: "1984", es: "1984"),
//            author: "George Orwell",
//            description: .init(en: "A dystopian novel about totalitarianism.",
//                               ru: "Антиутопический роман о тоталитаризме.",
//                               es: "Una novela distópica sobre el totalitarismo."),
//            urlImage: "https://upload.wikimedia.org/wikipedia/en/c/c3/1984first.jpg" // пример ссылки
//        ),
//        ProductItem1(
//            id: "3",
//            title: .init(en: "Pride and Prejudice", ru: "Гордость и предубеждение", es: "Orgullo y prejuicio"),
//            author: "Jane Austen",
//            description: .init(en: "A classic novel of manners and romance.",
//                               ru: "Классический роман о манерах и любви.",
//                               es: "Una novela clásica de modales y romance."),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/8/8e/PrideAndPrejudiceTitlePage.jpg" // пример ссылки
//        ),
//        ProductItem1(
//            id: "4",
//            title: .init(en: "The Great Gatsby", ru: "Великий Гэтсби", es: "El gran Gatsby"),
//            author: "F. Scott Fitzgerald",
//            description: .init(en: "A novel about the American dream and tragedy.",
//                               ru: "Роман о американской мечте и трагедии.",
//                               es: "Una novela sobre el sueño americano y la tragedia."),
//            urlImage: "https://upload.wikimedia.org/wikipedia/en/f/f7/TheGreatGatsby_1925jacket.jpeg" // пример ссылки
//        ),
//        ProductItem1(
//            id: "5",
//            title: .init(en: "The Hobbit", ru: "Хоббит", es: "El hobbit"),
//            author: "J.R.R. Tolkien",
//            description: .init(en: "A fantasy novel about the journey of Bilbo Baggins.",
//                               ru: "Фэнтезийный роман о путешествии Бильбо Бэггинса.",
//                               es: "Una novela de fantasía acerca del viaje de Bilbo Bolsón."),
//            urlImage: "https://upload.wikimedia.org/wikipedia/en/4/4a/TheHobbit_FirstEdition.jpg" // пример ссылки
//        ),
//        ProductItem1(
//            id: "6",
//            title: .init(en: "Moby Dick", ru: "Моби Дик", es: "Moby Dick"),
//            author: "Herman Melville",
//            description: .init(en: "A novel about the obsessive quest of Ahab for revenge on Moby Dick.",
//                               ru: "Роман о навязчивой мести Ахава Моби Дику.",
//                               es: "Una novela sobre la búsqueda obsesiva de Ahab de venganza contra Moby Dick."),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/4/41/Moby-Dick_FE_title_page.jpg" // пример ссылки
//        )
//    ]
//    
//    static let sampleMalls: [ShopItem1] = [
//        ShopItem1(
//            title: .init(
//                en: "Westfield London",
//                ru: "Вестфилд Лондон",
//                es: "Westfield Londres"
//            ),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/2/21/Westfield_London_-_Exterior.jpg"
//        ),
//        ShopItem1(
//            title: .init(
//                en: "Mall of America",
//                ru: "Молл оф Америка",
//                es: "Mall of America"
//            ),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/e/e4/Mall_of_America.jpg"
//        ),
//        ShopItem1(
//            title: .init(
//                en: "Dubai Mall",
//                ru: "Дубай Молл",
//                es: "Dubai Mall"
//            ),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/6/65/Dubai_Mall_-_Exterior.jpg"
//        ),
//        ShopItem1(
//            title: .init(
//                en: "SM Mall of Asia",
//                ru: "SM Молл оф Азия",
//                es: "SM Mall of Asia"
//            ),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/1/14/SM_Mall_of_Asia.jpg"
//        ),
//        ShopItem1(
//            title: .init(
//                en: "King of Prussia Mall",
//                ru: "Молл King of Prussia",
//                es: "King of Prussia Mall"
//            ),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/8/8c/King_of_Prussia_Mall_exterior.jpg"
//        ),
//        ShopItem1(
//            title: .init(
//                en: "Istanbul Cevahir",
//                ru: "Стамбульский Cevahir",
//                es: "Istanbul Cevahir"
//            ),
//            urlImage: "https://upload.wikimedia.org/wikipedia/commons/6/6c/Istanbul_Cevahir_Mall.jpg"
//        )
//    ]
//
//}
//
//class PostDataCloudFirestore {
//    
//    
//
//    func saveSampleData() async throws {
//        let db = Firestore.firestore()
//        
//        // Сохраняем книжные магазины в коллекцию "Bookstores"
//        for shop in DataCloudFirestore.sampleBookstores {
//            let docID = shop.title.en  // Используем английский заголовок как идентификатор
//            let shopData: [String: Any] = [
//                "title": [
//                    "en": shop.title.en,
//                    "ru": shop.title.ru ?? "",
//                    "es": shop.title.es ?? ""
//                ],
//                "urlImage": shop.urlImage
//            ]
//            try await db.collection("BookStores").document(docID).setData(shopData)
//            print("Saved shop with doc id: \(docID)")
//        }
//        
//        for shop in DataCloudFirestore.sampleMalls {
//            let docID = shop.title.en  // Используем английский заголовок как идентификатор
//            let shopData: [String: Any] = [
//                "title": [
//                    "en": shop.title.en,
//                    "ru": shop.title.ru ?? "",
//                    "es": shop.title.es ?? ""
//                ],
//                "urlImage": shop.urlImage
//            ]
//            try await db.collection("MallCenters").document(docID).setData(shopData)
//            print("Saved shop with doc id: \(docID)")
//        }
//        
//        // Сохраняем книги в коллекцию "books"
//        for book in DataCloudFirestore.sampleBooks {
//            let docID = book.title.en  // Используем английское название книги как идентификатор
//            let bookData: [String: Any] = [
//                "title": [
//                    "en": book.title.en,
//                    "ru": book.title.ru ?? "",
//                    "es": book.title.es ?? ""
//                ],
//                "author": book.author,
//                "description": [
//                    "en": book.description.en,
//                    "ru": book.description.ru ?? "",
//                    "es": book.description.es ?? ""
//                ],
//                "urlImage": book.urlImage
//            ]
//            try await db.collection("books").document(docID).setData(bookData)
//            print("Saved book with doc id: \(docID)")
//        }
//    }
//
//}












//struct Item: Identifiable {
//    let id: String
//    let title: String
//    // Добавьте нужные свойства для каждой ячейки
//}
//
//struct SectionModel: Identifiable {
//    let id = UUID()
//    let section: String   // "Malls", "Shops", "PopularProducts"
//    let items: [Item]
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
