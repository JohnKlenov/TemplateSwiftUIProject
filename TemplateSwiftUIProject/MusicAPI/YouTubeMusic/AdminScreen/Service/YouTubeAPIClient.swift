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
            
            // 🔥 ИСПРАВЛЕНО: Проверяем, содержит ли videoTitle НАШ searchTitle
            if videoTitle == searchTitle {
                score += 100  // Полное совпадение
            } else if videoTitle.contains(searchTitle) {
                score += 50   // Видео содержит наш поисковый запрос
            } else if searchTitle.contains(videoTitle) {
                score += 30   // Наш запрос содержит название видео (частичное совпадение)
            }
            
            // Проверка по артисту
            if videoChannel == searchArtist {
                score += 40
            } else if videoChannel.contains(searchArtist) {
                score += 20
            }
            
            // Дополнительный бонус: если название начинается с поискового запроса
            if videoTitle.hasPrefix(searchTitle) {
                score += 25
            }
            
            print("   📊 \(item.snippet.title) — баллы: \(score)")
            
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
        
        print("✅ Найден videoId: \(item.snippet.resourceId.videoId) (баллы: \(bestMatchScore))")
        
        let duration = try await fetchDuration(videoId: item.snippet.resourceId.videoId)
        
        return TrackMetadata(
            videoId: item.snippet.resourceId.videoId,
            title: title,      // то, что ввёл пользователь
            artist: artist,    // то, что ввёл пользователь
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

