//
//  AdminModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.05.26.
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



import Foundation



// MARK: - Track Protocol

protocol TrackProtocol {
   var videoId: String { get }
   var title: String { get }
   var artist: String { get }
   var thumbnailURL: String { get }
   var durationISO8601: String { get }
}



// MARK: - Track Model

struct TrackMetadata: Identifiable, Codable, TrackProtocol {
   var id: String { videoId }

   let videoId: String
   let title: String
   let artist: String
   let thumbnailURL: String
   let durationISO8601: String
   let orderIndex: Int

   // Новое поле: теги, которые админ выбирает вручную
   var tags: [String]

   // Codable конструктор по умолчанию генерируется автоматически
}



// MARK: - YouTube Response Models

struct YouTubeVideosResponse: Decodable {
    struct Item: Decodable {
        struct ContentDetails: Decodable {
            let duration: String
        }
        let id: String
        let contentDetails: ContentDetails
    }
    let items: [Item]
}

struct YouTubePlaylistItemsResponse: Decodable {
    struct Item: Decodable {
        struct Snippet: Decodable {
            struct Thumbnails: Decodable {
                struct Thumb: Decodable {
                    let url: String
                }
                let high: Thumb
            }
            struct ResourceId: Decodable {
                let videoId: String
            }
            let title: String
            let videoOwnerChannelTitle: String?
            let thumbnails: Thumbnails
            let resourceId: ResourceId
        }
        let snippet: Snippet
    }
    let items: [Item]
}




//// MARK: - YouTube Video Duration Response
//
//struct YouTubeVideosResponse: Decodable {
//    struct Item: Decodable {
//        struct ContentDetails: Decodable {
//            let duration: String
//        }
//        let id: String
//        let contentDetails: ContentDetails
//    }
//    let items: [Item]
//}
//
//
//
//// MARK: - YouTube Playlist Items Response
//
//struct YouTubePlaylistItemsResponse: Decodable {
//    struct Item: Decodable {
//        struct Snippet: Decodable {
//            struct Thumbnails: Decodable {
//                struct Thumb: Decodable {
//                    let url: String
//                }
//                let high: Thumb
//            }
//            struct ResourceId: Decodable {
//                let videoId: String
//            }
//            let title: String
//            let videoOwnerChannelTitle: String?
//            let thumbnails: Thumbnails
//            let resourceId: ResourceId
//        }
//        let snippet: Snippet
//    }
//    let items: [Item]
//}
//


//// MARK: - YouTube Search Response (для searchFirstVideo)
//
//struct YouTubeSearchResponse: Decodable {
//    struct Item: Decodable {
//        struct Id: Decodable {
//            let videoId: String?
//        }
//        struct Snippet: Decodable {
//            struct Thumbnails: Decodable {
//                struct Thumb: Decodable {
//                    let url: String
//                }
//                let high: Thumb
//            }
//            let title: String
//            let channelTitle: String
//            let thumbnails: Thumbnails
//        }
//        let id: Id
//        let snippet: Snippet
//    }
//    let items: [Item]
//}
