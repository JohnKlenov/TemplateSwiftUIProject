//
//  YouTubeAPIClient.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.05.26.
//

import Foundation
import FirebaseFirestore
import FirebaseFunctions
import FirebaseStorage



// MARK: - YouTube API Client (Упрощённая версия)

final class YouTubeAPIClient {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - 1. Получить все видео из плейлиста

    func fetchPlaylistVideos(playlistId: String) async throws -> [YouTubePlaylistItemsResponse.Item] {
        var allItems: [YouTubePlaylistItemsResponse.Item] = []
        var nextPageToken: String?
        
        repeat {
            var urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=\(playlistId)&key=\(apiKey)"
            
            if let token = nextPageToken {
                urlString += "&pageToken=\(token)"
            }
            
            guard let url = URL(string: urlString) else {
                throw NSError(domain: "YouTubeAPI", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            struct Response: Decodable {
                let items: [YouTubePlaylistItemsResponse.Item]
                let nextPageToken: String?
            }
            
            let response = try JSONDecoder().decode(Response.self, from: data)
            allItems.append(contentsOf: response.items)
            nextPageToken = response.nextPageToken
            
        } while nextPageToken != nil
        
        print("📋 Загружено \(allItems.count) видео из плейлиста")
        return allItems
    }

    // MARK: - 2. Получить длительность видео

    func fetchDuration(videoId: String) async throws -> String {
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "YouTubeAPI", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Неверный URL длительности"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
        
        guard let item = response.items.first else {
            throw NSError(domain: "YouTubeAPI", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
        }
        return item.contentDetails.duration
    }

    // MARK: - 3. Поиск трека в плейлисте (возвращает videoId и thumbnail)

    func searchTrackInPlaylist(
        artist: String,
        title: String,
        playlistId: String,
        orderIndex: Int
    ) async throws -> TrackMetadata {
        
        let playlistItems = try await fetchPlaylistVideos(playlistId: playlistId)
        
        print("🔍 Ищем в плейлисте среди \(playlistItems.count) видео")
        print("🎯 Ищем: \(artist) - \(title)")
        
        var matchedItem: YouTubePlaylistItemsResponse.Item?
        var bestMatchScore = 0
        let searchArtist = artist.lowercased()
        let searchTitle = title.lowercased()
        
        for item in playlistItems {
            let videoTitle = item.snippet.title.lowercased()
            let videoChannel = item.snippet.videoOwnerChannelTitle?.lowercased() ?? ""
            
            var score = 0
            
            if videoTitle == searchTitle {
                score += 10
            } else if videoTitle.contains(searchTitle) {
                score += 5
            }
            
            if videoChannel == searchArtist {
                score += 8
            } else if videoChannel.contains(searchArtist) {
                score += 4
            }
            
            if score > bestMatchScore {
                bestMatchScore = score
                matchedItem = item
            }
        }
        
        guard let item = matchedItem, bestMatchScore > 0 else {
            throw NSError(
                domain: "YouTubeAPI",
                code: 4,
                userInfo: [NSLocalizedDescriptionKey: "Трек \"\(artist) - \(title)\" не найден в плейлисте"]
            )
        }
        
        print("✅ Найден videoId: \(item.snippet.resourceId.videoId)")
        
        let duration = try await fetchDuration(videoId: item.snippet.resourceId.videoId)
        
        // ✅ ИСПОЛЬЗУЕМ ТО, ЧТО ВВЁЛ ПОЛЬЗОВАТЕЛЬ
        return TrackMetadata(
            videoId: item.snippet.resourceId.videoId,
            title: title,                    // ← то, что ввёл пользователь
            artist: artist,                  // ← то, что ввёл пользователь
            thumbnailURL: item.snippet.thumbnails.high.url,
            durationISO8601: duration,
            orderIndex: orderIndex,
            tags: []
        )
    }
    
    // MARK: - 4. Получить все треки из плейлиста (с названиями из API)

    func fetchAllTracksFromPlaylist(
        playlistId: String,
        startOrderIndex: Int = 0
    ) async throws -> [TrackMetadata] {
        
        let playlistItems = try await fetchPlaylistVideos(playlistId: playlistId)
        var tracks: [TrackMetadata] = []
        
        for (index, item) in playlistItems.enumerated() {
            do {
                let duration = try await fetchDuration(videoId: item.snippet.resourceId.videoId)
                
                let track = TrackMetadata(
                    videoId: item.snippet.resourceId.videoId,
                    title: item.snippet.title,  // ← из API (для массового импорта)
                    artist: item.snippet.videoOwnerChannelTitle ?? "Unknown Artist",
                    thumbnailURL: item.snippet.thumbnails.high.url,
                    durationISO8601: duration,
                    orderIndex: startOrderIndex + index,
                    tags: []
                )
                tracks.append(track)
                print("✅ Добавлен: \(track.title)")
            } catch {
                print("⚠️ Ошибка для: \(item.snippet.title)")
            }
        }
        return tracks
    }
}





//// MARK: - YouTube API Client
//
//final class YouTubeAPIClient {
//    private let apiKey: String
//
//    init(apiKey: String) {
//        self.apiKey = apiKey
//    }
//
//    // MARK: - 1. Получить все видео из плейлиста
//
//    func fetchPlaylistVideos(playlistId: String) async throws -> [YouTubePlaylistItemsResponse.Item] {
//        var allItems: [YouTubePlaylistItemsResponse.Item] = []
//        var nextPageToken: String?
//        
//        repeat {
//            var urlString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=\(playlistId)&key=\(apiKey)"
//            
//            if let token = nextPageToken {
//                urlString += "&pageToken=\(token)"
//            }
//            
//            guard let url = URL(string: urlString) else {
//                throw NSError(domain: "YouTubeAPI", code: 1,
//                              userInfo: [NSLocalizedDescriptionKey: "Неверный URL"])
//            }
//            
//            let (data, _) = try await URLSession.shared.data(from: url)
//            
//            struct Response: Decodable {
//                let items: [YouTubePlaylistItemsResponse.Item]
//                let nextPageToken: String?
//            }
//            
//            let response = try JSONDecoder().decode(Response.self, from: data)
//            allItems.append(contentsOf: response.items)
//            nextPageToken = response.nextPageToken
//            
//        } while nextPageToken != nil
//        
//        print("📋 Загружено \(allItems.count) видео из плейлиста")
//        return allItems
//    }
//
//    // MARK: - 2. Получить длительность видео
//
//    func fetchDuration(videoId: String) async throws -> String {
//        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"
//        
//        guard let url = URL(string: urlString) else {
//            throw NSError(domain: "YouTubeAPI", code: 2,
//                          userInfo: [NSLocalizedDescriptionKey: "Неверный URL длительности"])
//        }
//        
//        let (data, _) = try await URLSession.shared.data(from: url)
//        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
//        
//        guard let item = response.items.first else {
//            throw NSError(domain: "YouTubeAPI", code: 3,
//                          userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
//        }
//        return item.contentDetails.duration
//    }
//
//
//    // MARK: - Поиск трека ТОЛЬКО в указанном плейлисте
//
//    func searchTrackInPlaylist(
//        artist: String,
//        title: String,
//        playlistId: String,
//        orderIndex: Int
//    ) async throws -> TrackMetadata {
//        
//        let playlistItems = try await fetchPlaylistVideos(playlistId: playlistId)
//        
//        print("🔍 Ищем в плейлисте среди \(playlistItems.count) видео")
//        print("🎯 Ищем: \(artist) - \(title)")
//        
//        var matchedItem: YouTubePlaylistItemsResponse.Item?
//        var bestMatchScore = 0
//        
//        for item in playlistItems {
//            let videoTitle = item.snippet.title.lowercased()
//            let videoChannel = item.snippet.videoOwnerChannelTitle?.lowercased() ?? ""
//            
//            let searchArtist = artist.lowercased()
//            let searchTitle = title.lowercased()
//            
//            var score = 0
//            
//            if videoTitle == searchTitle {
//                score += 10
//            } else if videoTitle.contains(searchTitle) {
//                score += 5
//            }
//            
//            if videoChannel == searchArtist {
//                score += 8
//            } else if videoChannel.contains(searchArtist) {
//                score += 4
//            }
//            
//            if videoTitle.hasPrefix(searchTitle) {
//                score += 3
//            }
//            
//            if score > bestMatchScore {
//                bestMatchScore = score
//                matchedItem = item
//            }
//        }
//        
//        guard let item = matchedItem, bestMatchScore > 0 else {
//            throw NSError(
//                domain: "YouTubeAPI",
//                code: 4,
//                userInfo: [NSLocalizedDescriptionKey: "Трек \"\(artist) - \(title)\" не найден в плейлисте"]
//            )
//        }
//        
//        print("✅ Найден трек: \(item.snippet.title)")
//        
//        let duration = try await fetchDuration(videoId: item.snippet.resourceId.videoId)
//        
//        // 🔧 ИСПРАВЛЕНО: Удаляем ТОЛЬКО служебные метки, НО сохраняем feat.
//        var cleanTitle = item.snippet.title
//        
//        // Список того, что действительно нужно удалить
//        let suffixesToRemove = [
//            "(Official Music Video)",
//            "(Official Video)",
//            "(Official Audio)",
//            "(Official)",
//            "(Lyrics Video)",
//            "(Lyrics)",
//            "(Audio)",
//            "(Music Video)",
//            "[Official Music Video]",
//            "[Official Video]",
//            "[Official]",
//            "(Explicit)",
//            "(Clean Version)",
//            "(Album Version)",
//            "(Live)",
//            "| Official Video",
//            "| Official Audio",
//            "| Official Music Video"
//        ]
//        
//        for suffix in suffixesToRemove {
//            if let range = cleanTitle.range(of: suffix, options: .caseInsensitive) {
//                cleanTitle = String(cleanTitle[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
//            }
//        }
//        
//        // Удаляем двойные пробелы
//        cleanTitle = cleanTitle.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespaces)
//        
//        // Если название стало пустым, используем оригинал
//        if cleanTitle.isEmpty {
//            cleanTitle = item.snippet.title
//        }
//        
//        print("📝 Оригинал: \(item.snippet.title)")
//        print("📝 После очистки: \(cleanTitle)")
//        
//        return TrackMetadata(
//            videoId: item.snippet.resourceId.videoId,
//            title: cleanTitle,  // ← теперь сохраняет feat.
//            artist: item.snippet.videoOwnerChannelTitle ?? artist,
//            thumbnailURL: item.snippet.thumbnails.high.url,
//            durationISO8601: duration,
//            orderIndex: orderIndex,
//            tags: []
//        )
//    }
//
//    
//    // MARK: - 4. Альтернативный метод: получить все треки из плейлиста сразу
//
//    func fetchAllTracksFromPlaylist(
//        playlistId: String,
//        startOrderIndex: Int = 0
//    ) async throws -> [TrackMetadata] {
//        
//        let playlistItems = try await fetchPlaylistVideos(playlistId: playlistId)
//        var tracks: [TrackMetadata] = []
//        
//        for (index, item) in playlistItems.enumerated() {
//            do {
//                let duration = try await fetchDuration(videoId: item.snippet.resourceId.videoId)
//                
//                var trackTitle = item.snippet.title
//                // Очищаем название от лишних меток
//                let suffixesToRemove = ["(Official", "(Official Music Video", "(Lyrics", "(Audio)", "[Official", "(Music Video)"]
//                for suffix in suffixesToRemove {
//                    if let range = trackTitle.range(of: suffix, options: .caseInsensitive) {
//                        trackTitle = String(trackTitle[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
//                    }
//                }
//                
//                let track = TrackMetadata(
//                    videoId: item.snippet.resourceId.videoId,
//                    title: trackTitle,
//                    artist: item.snippet.videoOwnerChannelTitle ?? "Unknown Artist",
//                    thumbnailURL: item.snippet.thumbnails.high.url,
//                    durationISO8601: duration,
//                    orderIndex: startOrderIndex + index,
//                    tags: []
//                )
//                tracks.append(track)
//                print("✅ Добавлен: \(track.title) - \(track.artist)")
//            } catch {
//                print("⚠️ Ошибка получения длительности для: \(item.snippet.title)")
//            }
//        }
//        return tracks
//    }
//}




// MARK: - Trash



//// MARK: - Добавьте этот метод в класс YouTubeAPIClient
//
//func searchFirstVideo(query: String) async throws -> (videoId: String, title: String, channelTitle: String, thumbnailURL: String) {
//    let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
//    let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=\(q)&key=\(apiKey)"
//    let url = URL(string: urlString)!
//    let (data, _) = try await URLSession.shared.data(from: url)
//    
//    let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
//    
//    print("🔍 YouTube Search Items:")
//    response.items.forEach { item in
//        print("• \(item.snippet.title) — \(item.id.videoId ?? "NO ID")")
//    }
//    
//    guard let item = response.items.first,
//          let videoId = item.id.videoId else {
//        throw NSError(domain: "YouTubeAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Видео не найдено"])
//    }
//    
//    return (
//        videoId: videoId,
//        title: item.snippet.title,
//        channelTitle: item.snippet.channelTitle,
//        thumbnailURL: item.snippet.thumbnails.high.url
//    )
//}
//
//// MARK: - НОВЫЙ МЕТОД: Поиск трека с приоритетом по videoId
//
//func searchTrackWithPriority(
//    artist: String,
//    title: String,
//    playlistId: String,
//    orderIndex: Int
//) async throws -> TrackMetadata {
//    
//    // Шаг 1: Загружаем плейлист и находим видео по videoId
//    let playlistItems = try await fetchPlaylistVideos(playlistId: playlistId)
//    
//    print("🔍 Ищем в плейлисте среди \(playlistItems.count) видео")
//    print("🎯 Ищем: \(artist) - \(title)")
//    
//    var matchedItem: YouTubePlaylistItemsResponse.Item?
//    var bestMatchScore = 0
//    var matchedVideoId: String?
//    
//    // Поиск в плейлисте (по названию и артисту)
//    for item in playlistItems {
//        let videoTitle = item.snippet.title.lowercased()
//        let videoChannel = item.snippet.videoOwnerChannelTitle?.lowercased() ?? ""
//        
//        let searchArtist = artist.lowercased()
//        let searchTitle = title.lowercased()
//        
//        var score = 0
//        
//        if videoTitle == searchTitle {
//            score += 10
//        } else if videoTitle.contains(searchTitle) {
//            score += 5
//        }
//        
//        if videoChannel == searchArtist {
//            score += 8
//        } else if videoChannel.contains(searchArtist) {
//            score += 4
//        }
//        
//        if videoTitle.hasPrefix(searchTitle) {
//            score += 3
//        }
//        
//        if score > bestMatchScore {
//            bestMatchScore = score
//            matchedItem = item
//            matchedVideoId = item.snippet.resourceId.videoId
//        }
//    }
//    
//    guard let item = matchedItem, let videoId = matchedVideoId, bestMatchScore > 0 else {
//        throw NSError(
//            domain: "YouTubeAPI",
//            code: 4,
//            userInfo: [NSLocalizedDescriptionKey: "Трек \"\(artist) - \(title)\" не найден в плейлисте"]
//        )
//    }
//    
//    print("✅ Найден трек в плейлисте: \(item.snippet.title)")
//    
//    // Шаг 2: Получаем "красивое" название через поиск по запросу
//    let query = "\(artist) \(title)"
//    var prettyTitle = item.snippet.title
//    var prettyArtist = item.snippet.videoOwnerChannelTitle ?? artist
//    
//    do {
//        print("🔍 Ищем красивое название через поиск: \(query)")
//        let searchResult = try await searchFirstVideo(query: query)
//        
//        // Проверяем, что найденное видео соответствует нашему videoId
//        if searchResult.videoId == videoId {
//            prettyTitle = searchResult.title
//            prettyArtist = searchResult.channelTitle
//            print("✅ Найдено красивое название: \(prettyTitle)")
//        } else {
//            print("⚠️ Поиск вернул другое видео, используем название из плейлиста")
//        }
//    } catch {
//        print("⚠️ Не удалось получить красивое название: \(error.localizedDescription)")
//    }
//    
//    let duration = try await fetchDuration(videoId: videoId)
//    
//    // Очищаем название от явных маркеров (Explicit, Clean и т.д.)
//    var finalTitle = prettyTitle
//    let cleanMarkers = ["(Explicit)", "(Clean)", "(Explicit Version)", "(Clean Version)"]
//    for marker in cleanMarkers {
//        finalTitle = finalTitle.replacingOccurrences(of: marker, with: "", options: .caseInsensitive)
//    }
//    finalTitle = finalTitle.trimmingCharacters(in: .whitespaces)
//    
//    if finalTitle.isEmpty {
//        finalTitle = prettyTitle
//    }
//    
//    print("📝 Финальное название: \(finalTitle)")
//    
//    return TrackMetadata(
//        videoId: videoId,
//        title: finalTitle,
//        artist: prettyArtist,
//        thumbnailURL: item.snippet.thumbnails.high.url,
//        durationISO8601: duration,
//        orderIndex: orderIndex,
//        tags: []
//    )
//}
//
//





//// MARK: - 5. Старый метод (оставлен для совместимости, но не рекомендуется)
//
//func searchTrack(artist: String, title: String, orderIndex: Int) async throws -> TrackMetadata {
//    let query = "\(artist) \(title)"
//    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
//
//    let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=\(encoded)&key=\(apiKey)"
//
//    guard let url = URL(string: urlString) else {
//        throw NSError(domain: "YouTubeAPI", code: 1,
//                      userInfo: [NSLocalizedDescriptionKey: "Неверный URL поиска"])
//    }
//
//    let (data, _) = try await URLSession.shared.data(from: url)
//
//    struct SearchResponse: Decodable {
//        struct Item: Decodable {
//            struct Id: Decodable { let videoId: String }
//            struct Snippet: Decodable {
//                struct Thumbnails: Decodable {
//                    struct Thumb: Decodable { let url: String }
//                    let high: Thumb
//                }
//                let thumbnails: Thumbnails
//            }
//            let id: Id
//            let snippet: Snippet
//        }
//        let items: [Item]
//    }
//
//    let response = try JSONDecoder().decode(SearchResponse.self, from: data)
//    guard let item = response.items.first else {
//        throw NSError(domain: "YouTubeAPI", code: 2,
//                      userInfo: [NSLocalizedDescriptionKey: "Видео не найдено"])
//    }
//
//    let duration = try await fetchDuration(videoId: item.id.videoId)
//
//    return TrackMetadata(
//        videoId: item.id.videoId,
//        title: title,
//        artist: artist,
//        thumbnailURL: item.snippet.thumbnails.high.url,
//        durationISO8601: duration,
//        orderIndex: orderIndex,
//        tags: []
//    )
//}
//


//    func searchTrackInPlaylist(
//        artist: String,
//        title: String,
//        playlistId: String,
//        orderIndex: Int
//    ) async throws -> TrackMetadata {
//
//        // Получаем все видео из плейлиста
//        let playlistItems = try await fetchPlaylistVideos(playlistId: playlistId)
//
//        print("🔍 Ищем в плейлисте среди \(playlistItems.count) видео")
//        print("🎯 Ищем: \(artist) - \(title)")
//
//        // Поиск с рейтингом совпадений
//        var matchedItem: YouTubePlaylistItemsResponse.Item?
//        var bestMatchScore = 0
//
//        for item in playlistItems {
//            let videoTitle = item.snippet.title.lowercased()
//            let videoChannel = item.snippet.videoOwnerChannelTitle?.lowercased() ?? ""
//
//            let searchArtist = artist.lowercased()
//            let searchTitle = title.lowercased()
//
//            var score = 0
//
//            // Совпадение по названию
//            if videoTitle == searchTitle {
//                score += 10
//            } else if videoTitle.contains(searchTitle) {
//                score += 5
//            }
//
//            // Совпадение по артисту (канал)
//            if videoChannel == searchArtist {
//                score += 8
//            } else if videoChannel.contains(searchArtist) {
//                score += 4
//            }
//
//            // Название трека обычно начинается с названия песни
//            if videoTitle.hasPrefix(searchTitle) {
//                score += 3
//            }
//
//            if score > bestMatchScore {
//                bestMatchScore = score
//                matchedItem = item
//            }
//        }
//
//        guard let item = matchedItem, bestMatchScore > 0 else {
//            throw NSError(
//                domain: "YouTubeAPI",
//                code: 4,
//                userInfo: [NSLocalizedDescriptionKey: "Трек \"\(artist) - \(title)\" не найден в плейлисте"]
//            )
//        }
//
//        print("✅ Найден трек с рейтингом \(bestMatchScore): \(item.snippet.title)")
//
//        // Получаем длительность
//        let duration = try await fetchDuration(videoId: item.snippet.resourceId.videoId)
//
//        // Формируем название трека (очищаем от лишнего)
//        var cleanTitle = item.snippet.title
//        if let range = cleanTitle.range(of: "(Official", options: .caseInsensitive) {
//            cleanTitle = String(cleanTitle[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
//        }
//        if let range = cleanTitle.range(of: "[Official", options: .caseInsensitive) {
//            cleanTitle = String(cleanTitle[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
//        }
//        if let range = cleanTitle.range(of: "(Lyrics", options: .caseInsensitive) {
//            cleanTitle = String(cleanTitle[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
//        }
//
//        return TrackMetadata(
//            videoId: item.snippet.resourceId.videoId,
//            title: cleanTitle,
//            artist: item.snippet.videoOwnerChannelTitle ?? artist,
//            thumbnailURL: item.snippet.thumbnails.high.url,
//            durationISO8601: duration,
//            orderIndex: orderIndex,
//            tags: []
//        )
//    }
