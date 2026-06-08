//
//  DroplistModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.05.26.
//


//droplist (collection)
//└─ {playlistId}
//    ├─ playlistId: String
//    ├─ title: String
//    ├─ description: String
//    ├─ coverImageURL: String
//    ├─ trackCount: Int
//    ├─ createdAt: Timestamp
//    └─ tracks (subcollection)
//        └─ {videoId}
//            ├─ videoId: String
//            ├─ title: String
//            ├─ artist: String
//            ├─ thumbnailURL: String
//            ├─ durationISO8601: String
//            ├─ orderIndex: Int
//            ├─ createdAt: Timestamp



//dropTracks (collection)
//└─ {videoId}
//    ├─ videoId: String
//    ├─ title: String
//    ├─ artist: String
//    ├─ thumbnailURL: String
//    ├─ durationISO8601: String
//    ├─ playlists: [String]
//    ├─ tags: [String]
//    ├─ createdAt: Timestamp



//carouselItems (collection)
//└─ {docId}
//   ├─ id: String
//   ├─ title: String
//   ├─ type: String   // "droplist", "allTracks", "gym", "party", "rnb"
//   ├─ orderIndex: Int
//   ├─ createdAt: Timestamp



//topSection (collection)
//└─ {playlistId}
//   ├─ playlistId: String
//   ├─ title: String
//   ├─ description: String
//   ├─ coverImageURL: String
//   ├─ trackCount: Int
//   ├─ createdAt: Timestamp
//   ├─ orderIndex: Int
//   └─ tracks (subcollection)
//      └─ {videoId}
//         ├─ videoId: String
//         ├─ title: String
//         ├─ artist: String
//         ├─ thumbnailURL: String
//         ├─ durationISO8601: String
//         ├─ orderIndex: Int
//         ├─ createdAt: Timestamp




//     ├─ searchKeywords: [String]?         // если не используем Algolia







// MARK: - Безопасное декодирование Firestore
//
// 🔐 do-catch + compactMap + errorHandler.handle = 100% защита от крашей
//
// ЧТО ЛОВИТ catch (ошибка → логируем → пропускаем документ):
// • Поле имеет другой тип (String вместо Int)
// • Отсутствует обязательное поле (не Optional)
// • Обязательное поле = null
// • Все поля другие/повреждённые данные
//
// ЧТО НЕ ВЫЗЫВАЕТ ОШИБОК:
// • Лишние поля в Firestore → игнорируются
// • Отсутствует Optional поле → получает nil
// • Optional поле = null → получает nil
//
// ℹ️ Optional защищает только от ОТСУТСТВИЯ поля, но НЕ от неправильного типа!
//    String? при Int значении → catch, документ пропущен






// MARK: - Стратегия защиты от крашей при декодировании Firestore

/*
 
 🔐 ПОЛНАЯ ЗАЩИТА ОТ КРАШЕЙ ПРИ ДЕКОДИРОВАНИИ FIRESTORE ДАННЫХ
 
 Текущая схема: do-catch + compactMap + errorHandler.handle
 Гарантирует: 100% защиту от крашей при ЛЮБЫХ проблемах с данными
 
 ═══════════════════════════════════════════════════════════
 ЧТО ЗАЩИЩАЕТ do-catch (ВСЕГДА попадает в catch, краша нет):
 ═══════════════════════════════════════════════════════════
 
 ✅ Неправильный тип поля
    Пример: trackCount: String вместо Int
    → DecodingError.typeMismatch → catch → логируем → пропускаем документ
 
 ✅ Отсутствует обязательное (не опциональное) поле
    Пример: нет поля playlistId, которое объявлено как String (не String?)
    → DecodingError.keyNotFound → catch → логируем → пропускаем документ
 
 ✅ Поле имеет значение null, но объявлено как не опциональное
    Пример: title: nil в Firestore, а в модели let title: String
    → DecodingError.valueNotFound → catch → логируем → пропускаем документ
 
 ✅ Документ имеет совершенно другую структуру
    Пример: все поля называются по-другому, другой набор полей
    → DecodingError.keyNotFound (по первому обязательному полю) → catch → логируем → пропускаем
 
 ✅ Повреждённые/невалидные данные
    Пример: поле createdAt содержит строку "вчера" вместо Timestamp
    → DecodingError.dataCorrupted → catch → логируем → пропускаем документ
 
 ✅ Вложенные объекты с ошибками
    Пример: поле-словарь внутри документа имеет неправильный тип
    → DecodingError.typeMismatch → catch → логируем → пропускаем документ
 
 ✅ Массивы с неправильными типами элементов
    Пример: tags: [String] приходит как [Int]
    → DecodingError.typeMismatch → catch → логируем → пропускаем документ
 
 
 ═══════════════════════════════════════════════════════════
 ЧТО НЕ ВЫЗЫВАЕТ ОШИБОК (документ успешно декодируется):
 ═══════════════════════════════════════════════════════════
 
 ✅ Документ имеет ЛИШНИЕ поля (которых нет в DTO модели)
    Пример: в Firestore есть поле internalNotes: "test", а в DTO такого поля нет
    → Лишние поля молча ИГНОРИРУЮТСЯ
    → Документ считается валидным
 
 ✅ Отсутствует ОПЦИОНАЛЬНОЕ поле (объявлено как Type?)
    Пример: нет поля description, а в DTO оно let description: String?
    → Поле получает значение nil
    → Документ считается валидным
 
 ✅ Опциональное поле имеет значение null в Firestore
    Пример: description: nil, а в DTO оно let description: String?
    → Поле получает значение nil
    → Документ считается валидным
 
 
 ═══════════════════════════════════════════════════════════
 СМЫСЛ ОПЦИОНАЛЬНЫХ ПОЛЕЙ (Type?) В DTO МОДЕЛЯХ:
 ═══════════════════════════════════════════════════════════
 
 Назначение: указать, что поле МОЖЕТ ОТСУТСТВОВАТЬ в Firestore
           и это НОРМАЛЬНАЯ ситуация, а не ошибка
 
 ❗️ ВАЖНО: Optional защищает ТОЛЬКО от ОТСУТСТВИЯ поля
           Optional НЕ защищает от НЕПРАВИЛЬНОГО ТИПА поля
 
 Когда делать поле опциональным:
 
 1️⃣ Поле не критично для UI
    Пример: coverImageURL: String?
    → Если картинки нет, показываем плейсхолдер
    → Плейлист всё равно показываем пользователю
 
 2️⃣ Поле добавлено недавно, есть старые документы без него
    Пример: createdAt: Date?
    → Старые плейлисты создавались без этого поля
    → Новые имеют дату, старые показываем без неё
 
 3️⃣ Поле по бизнес-логике не обязательно
    Пример: description: String?
    → Админ может не заполнять описание плейлиста
    → Это нормально, показываем без описания
 
 4️⃣ Поле может быть удалено админом в будущем
    Пример: tags: [String]?
    → Если админ решит убрать теги из схемы
    → Старые документы с тегами и новые без — работают
 
 Когда делать поле ОБЯЗАТЕЛЬНЫМ (не опциональным):
 
 1️⃣ Поле критично для идентификации
    Пример: let playlistId: String
    → Без ID плейлист бесполезен, его нельзя открыть
    → Лучше не показывать такой плейлист вообще
 
 2️⃣ Поле критично для UI
    Пример: let title: String
    → Без названия нечего показывать пользователю
    → Лучше пропустить такой плейлист
 
 3️⃣ Поле гарантированно есть во всех документах
    Пример: let orderIndex: Int
    → Админ всегда заполняет это поле
    → Если его нет — это ошибка админа, документ битый
 
 
 ═══════════════════════════════════════════════════════════
 ПРИМЕРЫ ПОВЕДЕНИЯ:
 ═══════════════════════════════════════════════════════════
 
 Модель:
 struct PlaylistDoc: Codable {
     let playlistId: String       // обязательное
     let title: String            // обязательное
     let description: String?     // опциональное
     let trackCount: Int          // обязательное
     let createdAt: Date?         // опциональное
 }
 
 Документ в Firestore: {
   playlistId: "abc123",
   title: "My Playlist",
   description: null,        ← ок, опциональное = nil
   trackCount: "десять",     ← ОШИБКА! String вместо Int → catch
   extraField: "something"   ← ок, лишнее поле игнорируется
 }
 Результат: ❌ Документ попадает в catch, НЕ показывается
 Причина: trackCount имеет неправильный тип
 
 Документ в Firestore: {
   playlistId: "abc123",
   title: "My Playlist",
   trackCount: 10,
   extraField: "something"   ← ок, лишнее поле игнорируется
   // description отсутствует ← ок, опциональное = nil
   // createdAt отсутствует   ← ок, опциональное = nil
 }
 Результат: ✅ Документ успешно декодируется, показывается
 
 Документ в Firestore: {
   // playlistId отсутствует  ← ОШИБКА! Обязательное поле → catch
   title: "My Playlist",
   trackCount: 10
 }
 Результат: ❌ Документ попадает в catch, НЕ показывается
 Причина: отсутствует обязательное поле playlistId
 
 Документ в Firestore: {
   playlistId: "abc123",
   title: null,              ← ОШИБКА! Обязательное поле = null → catch
   trackCount: 10
 }
 Результат: ❌ Документ попадает в catch, НЕ показывается
 Причина: обязательное поле title имеет значение null
 
 
 ═══════════════════════════════════════════════════════════
 СТРАТЕГИЯ ПОЛНОЙ ЗАЩИТЫ:
 ═══════════════════════════════════════════════════════════
 
 1. Всегда используем do-catch + compactMap
    → Ни один документ не вызовет краш
    → Битые документы логируются и пропускаются
 
 2. Критичные поля делаем обязательными
    → Без них документ не имеет смысла
    → Пользователь не увидит "сломанный" контент
 
 3. Некритичные поля делаем опциональными
    → Документ показывается даже без них
    → UI использует fallback значения (плейсхолдеры)
 
 4. Все ошибки логируются через errorHandler
    → Администратор видит проблемные документы
    → Можно быстро найти и исправить битые данные
 
 5. При КАЖДОМ декодировании указываем контекст
    → Понятно в каком методе и какой документ сломан
    → Легко дебажить в продакшене
 
 
 ═══════════════════════════════════════════════════════════
 ИТОГО:
 ═══════════════════════════════════════════════════════════
 
 ✅ do-catch защищает от ВСЕХ возможных несоответствий типов и структуры
 ✅ Optional поля позволяют документу быть валидным без необязательных полей
 ✅ Лишние поля в Firestore игнорируются и не вызывают ошибок
 ✅ Ни при каких обстоятельствах не будет краша из-за данных из Firestore
 ✅ Пользователь видит только полностью валидный контент
 ✅ Администратор получает логи обо всех проблемных документах
 
 */




// MARK: - локализация внутри CloudFunction

//struct GalleryBook: Identifiable, Codable, Equatable, Hashable {
//    
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







import Foundation
import FirebaseFirestore


// MARK: - MyTrackCloud (users/{userId}/myTracks/{docId})

struct MyTrackCloud: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    let videoId: String
    let title: String
    let artist: String?
    let thumbnailURL: String?
    let durationISO8601: String?
    let tags: [String]?
    let playlists: [String]?
    let createdAt: Date
}

// MARK: - 1. Firestore DTO (Data Transfer Objects)

//  PlaylistDoc — документ плейлиста (droplist/{playlistId})

struct PlaylistDoc: Codable {
    let playlistId: String
    let title: String
    let description: String?
    let coverImageURL: String?
    let trackCount: Int
    let createdAt: Date?
}

//  PlaylistTrackDoc — документ трека внутри плейлиста (droplist/{playlistId}/tracks/{videoId})

struct PlaylistTrackDoc: Codable, Identifiable {
    let id: String                 // videoId
    let videoId: String
    let title: String
    let artist: String?
    let thumbnailURL: String?
    let durationISO8601: String?
    let orderIndex: Int
    let createdAt: Date
}

// TrackDoc — глобальный трек (dropTracks/{videoId})

struct TrackDoc: Codable, Identifiable {
    let id: String                 // videoId
    let videoId: String
    let title: String
    let artist: String?
    let thumbnailURL: String?
    let durationISO8601: String?
    let tags: [String]?
    let playlists: [String]?
    let createdAt: Date
    let searchKeywords: [String]?
}

//  CarouselDoc — документ плейлиста (carouselItems/{docId})

struct CarouselDoc: Codable, Identifiable {
    let id: String
    let title: String
    let type: CarouselItemType
    let orderIndex: Int
    let createdAt: Date?
}


//  TopSectionDoc — документ плейлиста (topSections/{playlistId})

struct TopSectionDoc: Codable {
    let playlistId: String      // Критично → обязательное
    let title: String           // Критично → обязательное
    let description: String?    // Не критично → опциональное
    let coverImageURL: String?  // Не критично → опциональное
    let trackCount: Int         // Критично → обязательное
    let createdAt: Date?        // Может отсутствовать → опциональное
    let orderIndex: Int         // Критично → обязательное
}

// TopSectionTrackDoc — трек (topSections/tracks (subcollection)/{videoId})

struct TopSectionTrackDoc: Codable, Identifiable {
    let id: String
    let videoId: String
    let title: String
    let artist: String?
    let thumbnailURL: String?
    let durationISO8601: String?
    let orderIndex: Int
    let createdAt: Date
}





// MARK: - 2. Domain Models (UI‑модели)

// LowerItem — универсальная модель нижней секции
// Адаптирована под реальную структуру Firestore:
// - У плейлистов НЕТ sampleThumbnails → удалено
// - У треков thumbnail один → thumbnailURL
// - durationISO8601 добавлено для треков

struct LowerItem: Identifiable {
    let id: String                     // playlistId или videoId
    let title: String
    let subtitle: String?              // description (playlist) или artist (track)
    let coverImageURL: URL?            // только для плейлистов
    let thumbnailURL: URL?             // только для треков
    let durationISO8601: String?       // только для треков
    let trackCount: Int?               // только для плейлистов
    let isTrack: Bool                  // true → трек, false → плейлист
}

//  3. DropData — данные для DroplistCompositView

//struct DropData {
//    let topSection: TopSectionModel
//    let carouselItems: [CarouselItem]
//    let initialLowerSection: LowerSectionPage
//}

struct DropData {
    let topSection: TopSectionModel
    let carouselItems: [CarouselItem]
    let initialLowerSection: LowerSectionPage
    let selectedItem: CarouselItem   // ← добавили
}

//  4. LowerSectionPage — страница пагинации

struct LowerSectionPage {
    let items: [LowerItem]
    let lastDocumentSnapshot: DocumentSnapshot?
    let hasMore: Bool
}

//  5. CarouselItem — элементы средней секции

enum CarouselItemType: String, Codable {
    case droplist
    case allTracks
    case gym
    case party
    case rnb
}

struct CarouselItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let type: CarouselItemType
}

//  TopSectionModel — верхняя секция

struct TopSectionModel: Identifiable {
    let id: String
    let title: String
    let items: [TopItem]
}

struct TopItem: Identifiable {
    let id: String
    let title: String
    let imageURL: URL?
}






//struct PlaylistDoc: Codable, Identifiable {
//    let id: String                 // Firestore document ID
//    let playlistId: String         // YouTube playlist ID
//    let title: String
//    let description: String?
//    let coverImageURL: String?
//    let trackCount: Int
//    let createdAt: Date
//}


//struct TopSectionDoc: Codable, Identifiable {
//    let id: String
//    let playlistId: String
//    let title: String
//    let description: String?
//    let coverImageURL: String?
//    let trackCount: Int
//    @ServerTimestamp var createdAt: Date?
//    let orderIndex: Int
//}

//struct TopSectionDoc: Codable, Identifiable {
//    let id: String
//    let playlistId: String
//    let title: String
//    let description: String?
//    let coverImageURL: String?
//    let trackCount: Int
//    let createdAt: Date
//    let orderIndex: Int
//}




// MARK: - before adaption models


//import Foundation
//import FirebaseFirestore
//
//
//struct MyTrackCloud: Identifiable, Codable, Equatable, Hashable {
//    @DocumentID var id: String?
//    let videoId: String
//    let title: String
//    let artist: String?
//    let thumbnailURL: String?
//    let durationISO8601: String?
//    let tags: [String]?
//    let playlists: [String]?           // YouTube playlist IDs
//    let createdAt: Date
//}
//
//// MARK: - 1. Firestore DTO (Data Transfer Objects)
//
//
////PlaylistDoc — документ плейлиста
//
//
//struct PlaylistDoc: Codable, Identifiable {
//   let id: String                     // Firestore document ID (заполняется вручную после decode)
//   let playlistId: String             // YouTube playlist ID
//   let title: String
//   let description: String?
//   let curatedTags: [String]?
//   let coverImageURL: String?
//   let sampleThumbnails: [String]?
//   let trackCount: Int
//   let createdAt: Date
//}
//
//
//
//
////PlaylistTrackDoc — документ трека внутри плейлиста
//
//struct PlaylistTrackDoc: Codable, Identifiable {
//   let id: String                     // videoId (Firestore doc ID)
//   let videoId: String
//   let title: String
//   let artist: String?
//   let thumbnailURL: String?
//   let durationISO8601: String?
//   let orderIndex: Int
//   let createdAt: Date
//}
//
//
////TrackDoc — глобальный трек (коллекция tracks)
//
//struct TrackDoc: Codable, Identifiable {
//   let id: String                     // videoId (Firestore doc ID)
//   let videoId: String
//   let title: String
//   let artist: String?
//   let thumbnailURL: String?
//   let durationISO8601: String?
//   let tags: [String]?
//   let playlists: [String]?           // YouTube playlist IDs
//   let createdAt: Date
//   let searchKeywords: [String]?      // optional (если не используем Algolia)
//}
//
//
//
//// MARK: - 2. Domain Models (UI‑модели)
//
////нет поля durationISO8601 ???
////  let sampleThumbnails: [URL]        // для плейлистов - у нас вообще небудет такого поля есть только coverImageURL
//
////LowerItem — универсальная модель нижней секции
//
//
//struct LowerItem: Identifiable {
//   let id: String                     // playlistId или videoId
//   let title: String
//   let subtitle: String?
//   let coverImageURL: URL?            // для плейлистов
//   let sampleThumbnails: [URL]        // для плейлистов
//   let trackCount: Int?               // для плейлистов
//   let isTrack: Bool                  // true → трек, false → плейлист
//}
//
//
////Плейлист → LowerItem
//
////LowerItem(
////   id: playlistDoc.playlistId,
////   title: playlistDoc.title,
////   subtitle: playlistDoc.description,
////   coverImageURL: URL(string: playlistDoc.coverImageURL ?? ""),
////   sampleThumbnails: playlistDoc.sampleThumbnails?.compactMap { URL(string: $0) } ?? [],
////   trackCount: playlistDoc.trackCount,
////   isTrack: false
////)
//
//
//
////Трек → LowerItem
//
////LowerItem(
////   id: trackDoc.videoId,
////   title: trackDoc.title,
////   subtitle: trackDoc.artist,
////   coverImageURL: nil,
////   sampleThumbnails: [URL(string: trackDoc.thumbnailURL ?? "")].compactMap { $0 },
////   trackCount: nil,
////   isTrack: true
////)
//
//
//
//
//
//// MARK: - 3. DropData — данные для DroplistCompositView
//
//
//
//struct DropData {
//   let topSections: [TopSectionModel]        // верхняя секция
//   let carouselItems: [CarouselItem]         // средняя секция
//   let initialLowerSection: LowerSectionPage // первая страница нижней секции
//}
//
//
//
//// MARK: - 4. LowerSectionPage — страница пагинации
//
//
//struct LowerSectionPage {
//   let items: [LowerItem]
//   let lastDocumentSnapshot: DocumentSnapshot?
//   let hasMore: Bool
//}
//
//
//
//// MARK: - 5. CarouselItem — элементы средней секции
//
//enum CarouselItemType: String, Codable {
//   case droplist
//   case allTracks
//   case gym
//   case party
//   case rnb
//   // можно расширять
//}
//
//struct CarouselItem: Identifiable, Codable, Equatable {
//   let id: String
//   let title: String
//   let type: CarouselItemType
//}
//
//
//
//
//
//// MARK: - 6. TopSectionModel — верхняя секция (как в GalleryCompositView)
//
//struct TopSectionModel: Identifiable {
//   let id: String
//   let title: String
//   let items: [TopItem]
//}
//
//struct TopItem: Identifiable {
//   let id: String
//   let title: String
//   let imageURL: URL?
//}
//
//
//
//






















// MARK: - Old version



//// Общая модель, которую будет принимать DroplistCompositView
//struct DropData {
//    let topSections: [TopSectionModel]        // верхняя секция (небольшой объём)
//    let carouselItems: [CarouselItem]         // средняя секция (категории)
//    let initialLowerSection: LowerSectionPage // первая порция для дефолтного carousel item
//}
//
//// Верхняя секция
//struct TopSectionModel: Identifiable {
//    let id: String
//    let title: String
//    let items: [TopItem]
//}
//
//struct TopItem: Identifiable, Decodable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//}
//
//// Элемент карусели (категория)
//struct CarouselItem: Identifiable, Decodable, Equatable {
//    let id: String
//    let title: String
//    let type: CarouselItemType
//}
//
//enum CarouselItemType: String, Decodable {
//    case droplist
//    case allTracks
//    case gym
//    case party
//    case rnb
//    // ... другие типы
//}
//
//// Нижняя секция — одна страница результатов + курсор для следующей
//struct LowerSectionPage {
//    let items: [LowerItem]
//    let lastDocumentSnapshot: DocumentSnapshot? // Firestore cursor
//    let hasMore: Bool
//}
//
//struct LowerItem: Identifiable, Decodable {
//    let id: String
//    let title: String
//    let subtitle: String?
//    let imageURL: URL?
//    // другие поля
//}


