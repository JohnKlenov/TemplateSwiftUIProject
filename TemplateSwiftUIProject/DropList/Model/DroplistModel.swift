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
//
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







//topSections (collection)
//└─ {docId}                         // Firestore document ID
//   ├─ id: String                   // идентификатор секции
//   ├─ title: String                // название секции
//   ├─ description: String?         // опциональное описание секции
//   ├─ coverImageURL: String?       // картинка для секции
//   ├─ orderIndex: Int              // порядок отображения
//   ├─ createdAt: Timestamp         // дата создания
//   └─ tracks (subcollection)       // треки внутри секции
//      └─ {videoId}
//         ├─ videoId: String
//         ├─ title: String
//         ├─ artist: String?
//         ├─ thumbnailURL: String?
//         ├─ durationISO8601: String?
//         ├─ orderIndex: Int
//         ├─ createdAt: Timestamp





//playlists (collection)
// └─ {firestorePlaylistDocId} (document)
//     ├─ playlistId: String                // YouTube playlist ID (обязательно)
//     ├─ title: String
//     ├─ description: String?
//     ├─ curatedTags: [String]?            // категории плейлиста (опционально)
//     ├─ coverImageURL: String?            // URL на Storage (генерируется)
//     ├─ sampleThumbnails: [String]?       // первые 4 thumbnailURL (кэш)
//     ├─ trackCount: Int                   // количество треков
//     ├─ createdAt: Timestamp              // сортировка плейлистов
//     └─ tracks (subcollection)
//         └─ {videoId} (document)
//             ├─ videoId: String
//             ├─ title: String
//             ├─ artist: String
//             ├─ thumbnailURL: String
//             ├─ durationISO8601: String
//             ├─ orderIndex: Int           // порядок в плейлисте
//             ├─ createdAt: Timestamp      // сортировка внутри плейлиста
//


//tracks (collection)
// └─ {videoId} (document)
//     ├─ videoId: String
//     ├─ title: String
//     ├─ artist: String
//     ├─ thumbnailURL: String
//     ├─ durationISO8601: String
//     ├─ tags: [String]                    // ["gym","party","rnb"]
//     ├─ playlists: [String]               // список YouTube playlistId
//     ├─ createdAt: Timestamp              // сортировка и пагинация
//     ├─ searchKeywords: [String]?         // если не используем Algolia





//ROOT
//├── playlists
//│    └── {firestorePlaylistDocId}
//│         ├── playlistId (YouTube)
//│         ├── title
//│         ├── description
//│         ├── curatedTags
//│         ├── coverImageURL
//│         ├── trackCount
//│         ├── createdAt
//│         └── tracks
//│              └── {videoId}
//│                   ├── videoId
//│                   ├── title
//│                   ├── artist
//│                   ├── thumbnailURL
//│                   ├── durationISO8601
//│                   ├── orderIndex
//│                   └── createdAt
//│
//└── tracks
//     └── {videoId}
//          ├── videoId
//          ├── title
//          ├── artist
//          ├── thumbnailURL
//          ├── durationISO8601
//          ├── tags
//          ├── playlists
//          ├── createdAt
//          └── searchKeywords?






// LowerItem
//нет поля durationISO8601 ???
//  let sampleThumbnails: [URL]        // для плейлистов - у нас вообще небудет такого поля есть только coverImageURL


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

// MARK: PlaylistDoc — документ плейлиста (droplist/{playlistId})

struct PlaylistDoc: Codable, Identifiable {
    let id: String                 // Firestore document ID
    let playlistId: String         // YouTube playlist ID
    let title: String
    let description: String?
    let coverImageURL: String?
    let trackCount: Int
    let createdAt: Date
}

// MARK: PlaylistTrackDoc — документ трека внутри плейлиста (droplist/{playlistId}/tracks/{videoId})

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

// MARK: TrackDoc — глобальный трек (dropTracks/{videoId})

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

struct CarouselDoc: Codable, Identifiable {
    let id: String
    let title: String
    let type: CarouselItemType
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

// MARK: - 3. DropData — данные для DroplistCompositView

struct DropData {
    let topSections: [TopSectionModel]
    let carouselItems: [CarouselItem]
    let initialLowerSection: LowerSectionPage
}

// MARK: - 4. LowerSectionPage — страница пагинации

struct LowerSectionPage {
    let items: [LowerItem]
    let lastDocumentSnapshot: DocumentSnapshot?
    let hasMore: Bool
}

// MARK: - 5. CarouselItem — элементы средней секции

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

// MARK: - 6. TopSectionModel — верхняя секция

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


