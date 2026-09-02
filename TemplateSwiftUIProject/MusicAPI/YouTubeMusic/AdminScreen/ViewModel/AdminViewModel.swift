//
//  AdminViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.05.26.
//


/// YouTube thumbnail variants:
/// ---------------------------
/// YouTube генерирует несколько стандартных превью для каждого видео:
///
/// • maxresdefault (1280×720) — HD‑версия. Доступна только если автор загрузил кастомный thumbnail.
///   Лучший вариант: чистое изображение, без боковых шумов, подходит для качественного ресайза.
///
/// • sddefault (640×480) — ровная и чистая версия без градиентов по бокам.
///   Второй лучший вариант, часто выглядит лучше чем hqdefault.
///
/// • hqdefault (480×360) — стандартный thumbnail из API.
///   Может содержать боковые шумы, тёмные зоны и градиенты — самый проблемный вариант.
///
/// • mqdefault (320×180) и default (120×90) — маленькие версии, не подходят для UI.
///
/// Дополнительные кадры:
/// • 0.jpg, 1.jpg, 2.jpg, 3.jpg (120×90) — авто‑кадры из видео (0%, 25%, 50%, 75%).
///   Используются редко, качество низкое.
///
/// Итог:
/// • Лучший источник — maxresdefault (если доступен).
/// • Второй лучший — sddefault.
/// • hqdefault используем только как fallback.
/// • Авто‑кадры (0–3.jpg) не применяются в UI.



import FirebaseFirestore
import FirebaseFunctions
import SwiftUI

@MainActor
final class AdminViewModel: ObservableObject {
    // MARK: - Метаданные плейлиста

    @Published private(set) var playlistTitle: String
    @Published private(set) var playlistDescription: String
    @Published private(set) var playlistImageURL: String = ""

    // MARK: - Поля поиска

    @Published var searchArtist: String = ""
    @Published var searchTitle: String = ""

    // MARK: - Найденный трек

    @Published var foundTrack: TrackMetadata?
    @Published var foundTrackURL: URL?

    // MARK: - Теги найденного трека

    @Published var foundTrackTags: Set<String> = []

    // MARK: - Thumbnail найденного трека

    @Published var useFoundTrackThumbnailInCollage: Bool = false

    // MARK: - Треки

    @Published var tracks: [TrackMetadata] = []

    // MARK: - Thumbnail для коллажа

    @Published var coverThumbnailURLs: [String] = []

    // MARK: - Результат генерации

    @Published var coverImageURL: String? = nil

    // MARK: - Статус

    @Published var status: String = ""

    // MARK: - Состояние генерации cover

    @Published private(set) var isGeneratingCover = false

    // MARK: - Состояние обработки thumbnail

    @Published private(set) var isProcessingTrackThumbnail = false

    // MARK: - Импорт

    @Published var isImportingAllTracks = false

    // MARK: - Private

    private var generateCoverTask: Task<Void, Never>?

    private let api: YouTubeAPIClient
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private let playlistId: String

    let availableTags: [String] = ["Gym", "Party", "R&B"]

    init(
        apiKey: String,
        playlistId: String,
        playlistTitle: String,
        playlistDescription: String
    ) {
        self.api = YouTubeAPIClient(apiKey: apiKey)
        self.playlistId = playlistId
        self.playlistTitle = playlistTitle
        self.playlistDescription = playlistDescription
    }

    // MARK: - Обработка thumbnail трека

    private func processTrackThumbnail(
        videoId: String,
        thumbnailURL: String
    ) async throws -> String {
        let data: [String: Any] = [
            "videoId": videoId,
            "thumbnailURL": thumbnailURL
        ]

        print("📤 Обрабатываем thumbnail:")
        print("   videoId:", videoId)
        print("   source:", thumbnailURL)

        let result = try await functions
            .httpsCallable("processTrackThumbnail")
            .call(data)

        guard
            let dict = result.data as? [String: Any],
            let processedURL = dict["thumbnailURL"] as? String,
            !processedURL.isEmpty
        else {
            throw NSError(
                domain: "ThumbnailProcessing",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Cloud Function не вернула обработанный thumbnailURL"
                ]
            )
        }

        print("✅ Processed thumbnail:", processedURL)

        return processedURL
    }

    // MARK: - Обработка массива thumbnail

    private func processTrackThumbnails(
        _ sourceTracks: [TrackMetadata]
    ) async throws -> [TrackMetadata] {
        var processedTracks: [TrackMetadata] = []
        processedTracks.reserveCapacity(sourceTracks.count)

        isProcessingTrackThumbnail = true
        defer { isProcessingTrackThumbnail = false }

        for track in sourceTracks {
            let processedURL = try await processTrackThumbnail(
                videoId: track.videoId,
                thumbnailURL: track.thumbnailURL
            )

            let processedTrack = TrackMetadata(
                videoId: track.videoId,
                title: track.title,
                artist: track.artist,
                thumbnailURL: processedURL,
                durationISO8601: track.durationISO8601,
                orderIndex: track.orderIndex,
                tags: track.tags
            )

            processedTracks.append(processedTrack)
        }

        return processedTracks
    }

    // MARK: - Поиск трека

    func searchTrack() async {
        status = "Ищем трек в плейлисте..."
        foundTrack = nil
        foundTrackURL = nil
        foundTrackTags = []
        useFoundTrackThumbnailInCollage = false

        guard !searchArtist.isEmpty, !searchTitle.isEmpty else {
            status = "Введите артиста и название трека"
            return
        }

        do {
            let track = try await api.searchTrackInPlaylist(
                artist: searchArtist,
                title: searchTitle,
                playlistId: playlistId,
                orderIndex: tracks.count
            )

            foundTrack = track

            foundTrackURL = URL(
                string: "https://music.youtube.com/watch?v=\(track.videoId)"
            )

            status = "✅ Трек найден в плейлисте"

        } catch {
            status = "❌ Ошибка поиска: \(error.localizedDescription)"
        }
    }

    // MARK: - Теги найденного трека

    func toggleFoundTrackTag(_ tag: String) {
        if foundTrackTags.contains(tag) {
            foundTrackTags.remove(tag)
        } else {
            foundTrackTags.insert(tag)
        }
    }

    // MARK: - Добавить найденный трек

    func addFoundTrack() async {
        guard let foundTrack else {
            status = "Нет найденного трека"
            return
        }

        status = "Обрабатываем thumbnail..."

        do {
            let processedURL = try await processTrackThumbnail(
                videoId: foundTrack.videoId,
                thumbnailURL: foundTrack.thumbnailURL
            )

            var processedTrack = TrackMetadata(
                videoId: foundTrack.videoId,
                title: foundTrack.title,
                artist: foundTrack.artist,
                thumbnailURL: processedURL,
                durationISO8601: foundTrack.durationISO8601,
                orderIndex: foundTrack.orderIndex,
                tags: Array(foundTrackTags)
            )

            if useFoundTrackThumbnailInCollage,
               coverThumbnailURLs.count < 4 {
                coverThumbnailURLs.append(foundTrack.thumbnailURL)
            }

            tracks.append(processedTrack)

            searchArtist = ""
            searchTitle = ""
            self.foundTrack = nil
            foundTrackURL = nil
            foundTrackTags = []
            useFoundTrackThumbnailInCollage = false

            status = "✅ Трек добавлен с обработанным thumbnail"

        } catch {
            status = "❌ Ошибка обработки thumbnail: \(error.localizedDescription)"
        }
    }
//    func addFoundTrack() async {
//        guard let foundTrack else {
//            status = "Нет найденного трека"
//            return
//        }
//
//        status = "Обрабатываем thumbnail..."
//
//        do {
//            let processedURL = try await processTrackThumbnail(
//                videoId: foundTrack.videoId,
//                thumbnailURL: foundTrack.thumbnailURL
//            )
//
//            var processedTrack = TrackMetadata(
//                videoId: foundTrack.videoId,
//                title: foundTrack.title,
//                artist: foundTrack.artist,
//                thumbnailURL: processedURL,
//                durationISO8601: foundTrack.durationISO8601,
//                orderIndex: foundTrack.orderIndex,
//                tags: Array(foundTrackTags)
//            )
//
//            if useFoundTrackThumbnailInCollage,
//               coverThumbnailURLs.count < 4 {
//                coverThumbnailURLs.append(processedURL)
//            }
//
//            tracks.append(processedTrack)
//
//            searchArtist = ""
//            searchTitle = ""
//            self.foundTrack = nil
//            foundTrackURL = nil
//            foundTrackTags = []
//            useFoundTrackThumbnailInCollage = false
//
//            status = "✅ Трек добавлен с обработанным thumbnail"
//
//        } catch {
//            status = "❌ Ошибка обработки thumbnail: \(error.localizedDescription)"
//        }
//    }

    // MARK: - Теги для треков

    func toggleTag(forVideoId videoId: String, tag: String) {
        guard let idx = tracks.firstIndex(where: { $0.videoId == videoId }) else {
            return
        }

        var track = tracks[idx]

        if track.tags.contains(tag) {
            track.tags.removeAll { $0 == tag }
        } else {
            track.tags.append(tag)
        }

        tracks[idx] = track
    }

    // MARK: - Импорт всех треков

    func importAllTracks() async {
        guard !isImportingAllTracks else {
            return
        }

        isImportingAllTracks = true
        status = "Получаем треки из YouTube..."

        defer {
            isImportingAllTracks = false
        }

        do {
            let sourceTracks = try await api.fetchAllTracksFromPlaylist(
                playlistId: playlistId
            )

            status = "Обрабатываем thumbnail для \(sourceTracks.count) треков..."

            // ВАЖНО:
            // Пока хотя бы один thumbnail не обработан,
            // tracks не изменяем.
            //
            // Поэтому в Firestore никогда не попадёт
            // частично обработанный список.

            let processedTracks = try await processTrackThumbnails(
                sourceTracks
            )

            tracks = processedTracks

            status = "✅ Импортировано \(processedTracks.count) треков"

        } catch {
            tracks = []
            status = "❌ Ошибка импорта: \(error.localizedDescription)"
        }
    }

    // MARK: - Генерация coverImage

    func generateCoverImage() async {
        generateCoverTask?.cancel()

        let task = Task {
            guard !isGeneratingCover else {
                status = "Генерация уже выполняется..."
                return
            }

            guard coverThumbnailURLs.count == 4 else {
                status = "Нужно ровно 4 thumbnail"
                return
            }

            guard !isProcessingTrackThumbnail else {
                status = "Дождитесь обработки thumbnail..."
                return
            }

            isGeneratingCover = true
            status = "Генерируем coverImage..."

            defer {
                isGeneratingCover = false
            }

            do {
                try Task.checkCancellation()

                let data: [String: Any] = [
                    "playlistId": playlistId,
                    "thumbnailURLs": coverThumbnailURLs
                ]

                print("📤 Вызываем generatePlaylistCover")
                print("📤 thumbnailURLs:", coverThumbnailURLs)

                let result = try await functions
                    .httpsCallable("generatePlaylistCover")
                    .call(data)

                try Task.checkCancellation()

                print("📥 Получен результат:", result.data)

                guard
                    let dict = result.data as? [String: Any],
                    let url = dict["coverImageURL"] as? String
                else {
                    status = "Ошибка: неверный ответ функции"
                    return
                }

                playlistImageURL = url
                coverImageURL = url
                status = "✅ coverImage сгенерирован"

                print("✅ URL обложки:", url)

            } catch {
                if Task.isCancelled {
                    status = "Генерация отменена"
                } else {
                    print("❌ Ошибка вызова функции:", error.localizedDescription)
                    status = "Ошибка: \(error.localizedDescription)"
                }
            }
        }

        generateCoverTask = task

        await task.value
    }


    // MARK: - Сохранение в Firestore

    func savePlaylistToFirestore() async {
        guard !playlistTitle.isEmpty else {
            status = "Ошибка: заголовок пуст"
            return
        }

        guard !playlistImageURL.isEmpty else {
            status = "Сначала сгенерируйте coverImage"
            return
        }

        guard !tracks.isEmpty else {
            status = "Нет треков для сохранения"
            return
        }

        guard tracks.allSatisfy({ !$0.thumbnailURL.isEmpty }) else {
            status = "Не все thumbnail треков обработаны"
            return
        }

        status = "Сохраняем плейлист и треки…"

        do {
            let droplistRef = db.collection("droplist").document(playlistId)

            try await droplistRef.setData([
                "playlistId": playlistId,
                "title": playlistTitle,
                "description": playlistDescription,
                "coverImageURL": playlistImageURL,
                "trackCount": tracks.count,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)

            let batch = db.batch()

            for track in tracks {
                let subRef = droplistRef
                    .collection("tracks")
                    .document(track.videoId)

                batch.setData([
                    "videoId": track.videoId,
                    "title": track.title,
                    "artist": track.artist,
                    "thumbnailURL": track.thumbnailURL,
                    "durationISO8601": track.durationISO8601,
                    "orderIndex": track.orderIndex,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: subRef)

                let globalRef = db
                    .collection("dropTracks")
                    .document(track.videoId)

                batch.setData([
                    "videoId": track.videoId,
                    "title": track.title,
                    "artist": track.artist,
                    "thumbnailURL": track.thumbnailURL,
                    "durationISO8601": track.durationISO8601,
                    "playlists": FieldValue.arrayUnion([playlistId]),
                    "tags": track.tags,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: globalRef)
            }

            try await batch.commit()

            status = "Плейлист и треки сохранены"
        } catch {
            status = "Ошибка сохранения: \(error.localizedDescription)"
        }
    }
}




// save topSection

//func savePlaylistToFirestore() async {
//    guard !playlistTitle.isEmpty else {
//        status = "Ошибка: заголовок пуст"
//        return
//    }
//
//    guard !playlistImageURL.isEmpty else {
//        status = "Сначала сгенерируйте coverImage"
//        return
//    }
//
//    guard !tracks.isEmpty else {
//        status = "Добавьте хотя бы один трек"
//        return
//    }
//
//    guard !isGeneratingCover else {
//        status = "Дождитесь завершения генерации coverImage"
//        return
//    }
//
//    guard !isProcessingTrackThumbnail else {
//        status = "Дождитесь обработки thumbnail треков"
//        return
//    }
//
//    guard !isImportingAllTracks else {
//        status = "Дождитесь завершения импорта"
//        return
//    }
//
//    status = "Сохраняем плейлист и треки…"
//
//    do {
//        let droplistRef = db
//            .collection("topSection")
//            .document(playlistId)
//
//        try await droplistRef.setData([
//            "playlistId": playlistId,
//            "title": playlistTitle,
//            "description": playlistDescription,
//            "coverImageURL": playlistImageURL,
//            "trackCount": tracks.count,
//            "orderIndex": 3,
//            "createdAt": FieldValue.serverTimestamp()
//        ], merge: true)
//
//        let batch = db.batch()
//
//        for track in tracks {
//            let subRef = droplistRef
//                .collection("tracks")
//                .document(track.videoId)
//
//            batch.setData([
//                "videoId": track.videoId,
//                "title": track.title,
//                "artist": track.artist,
//
//                // ВАЖНО:
//                // Здесь теперь уже НЕ YouTube URL.
//                // Здесь Firebase URL обработанного thumbnail.
//                "thumbnailURL": track.thumbnailURL,
//
//                "durationISO8601": track.durationISO8601,
//                "orderIndex": track.orderIndex,
//                "tags": track.tags,
//                "createdAt": FieldValue.serverTimestamp()
//            ], forDocument: subRef)
//        }
//
//        try await batch.commit()
//
//        status = "✅ Плейлист и треки сохранены"
//
//    } catch {
//        status = "❌ Ошибка сохранения: \(error.localizedDescription)"
//    }
//}




// MARK: - before processTrackThumbnail

//import FirebaseFirestore
//import FirebaseFunctions
//import SwiftUI
//
//
//@MainActor
//final class AdminViewModel: ObservableObject {
//
//    // Метаданные плейлиста
//    @Published private(set) var playlistTitle: String
//    @Published private(set) var playlistDescription: String
//    @Published private(set) var playlistImageURL: String = ""
//
//    // Поля поиска
//    @Published var searchArtist: String = ""
//    @Published var searchTitle: String = ""
//
//    // Найденный трек
//    @Published var foundTrack: TrackMetadata?
//    @Published var foundTrackURL: URL?
//
//    // Теги найденного трека (до добавления)
//    @Published var foundTrackTags: Set<String> = []
//
//    // Флаг: использовать ли thumbnail найденного трека в коллаже
//    @Published var useFoundTrackThumbnailInCollage: Bool = false
//
//    // Треки плейлиста
//    @Published var tracks: [TrackMetadata] = []
//
//    // Thumbnail для коллажа
//    @Published var coverThumbnailURLs: [String] = []
//
//    // Результат генерации
//    @Published var coverImageURL: String? = nil
//
//    // Статус
//    @Published var status: String = ""
//    
//    @Published private(set) var isGeneratingCover = false
//    private var generateCoverTask: Task<Void, Never>?
//
//    // Добавьте это свойство в класс AdminViewModel (в начало с другими @Published)
////    @Published var youtubePlaylistId: String = "PLQcuPcwlJLVCYhAAFan-AxvLlWypVIW5v" // ID вашего YouTube плейлиста
//    @Published var isImportingAllTracks: Bool = false
//
//    let availableTags: [String] = ["Gym", "Party", "R&B"]
//
//    private let api: YouTubeAPIClient
//    private let db = Firestore.firestore()
//    private let functions = Functions.functions()
//    private let playlistId: String
//
//    init(apiKey: String,
//         playlistId: String,
//         playlistTitle: String,
//         playlistDescription: String) {
//
//        self.api = YouTubeAPIClient(apiKey: apiKey)
//        self.playlistId = playlistId
//        self.playlistTitle = playlistTitle
//        self.playlistDescription = playlistDescription
//    }
//
//    // MARK: - Поиск трека
//
//    func searchTrack() async {
//        status = "Ищем трек в плейлисте..."
//        foundTrack = nil
//        foundTrackURL = nil
//        foundTrackTags = []
//        useFoundTrackThumbnailInCollage = false
//
//        guard !searchArtist.isEmpty, !searchTitle.isEmpty else {
//            status = "Введите артиста и название трека"
//            return
//        }
//
//        do {
//            let track = try await api.searchTrackInPlaylist(
//                artist: searchArtist,
//                title: searchTitle,
//                playlistId: playlistId,
//                orderIndex: tracks.count
//            )
//            foundTrack = track
////            foundTrackURL = URL(string: "https://www.youtube.com/watch?v=\(track.videoId)")
//            // Вместо обычной ссылки на YouTube
//             foundTrackURL = URL(string: "https://music.youtube.com/watch?v=\(track.videoId)")
//            status = "✅ Трек найден в плейлисте"
//        } catch {
//            status = "❌ Ошибка поиска: \(error.localizedDescription)"
//        }
//    }
//
//
//    // MARK: - Теги найденного трека
//    func toggleFoundTrackTag(_ tag: String) {
//        if foundTrackTags.contains(tag) {
//            foundTrackTags.remove(tag)
//        } else {
//            foundTrackTags.insert(tag)
//        }
//    }
//
//    // MARK: - Добавить найденный трек в список
//    func addFoundTrack() {
//        guard var track = foundTrack else {
//            status = "Нет найденного трека"
//            return
//        }
//
//        // переносим выбранные теги
//        track.tags = Array(foundTrackTags)
//
//        // при необходимости добавляем thumbnail
//        if useFoundTrackThumbnailInCollage,
//           coverThumbnailURLs.count < 4 {
//            coverThumbnailURLs.append(track.thumbnailURL)
//        }
//
//        tracks.append(track)
//
//        // сброс
//        searchArtist = ""
//        searchTitle = ""
//        foundTrack = nil
//        foundTrackURL = nil
//        foundTrackTags = []
//        useFoundTrackThumbnailInCollage = false
//
//        status = "Трек добавлен в список"
//    }
//
//    // MARK: - Теги для треков в плейлисте
//    func toggleTag(forVideoId videoId: String, tag: String) {
//        guard let idx = tracks.firstIndex(where: { $0.videoId == videoId }) else { return }
//        var t = tracks[idx]
//
//        if t.tags.contains(tag) {
//            t.tags.removeAll { $0 == tag }
//        } else {
//            t.tags.append(tag)
//        }
//
//        tracks[idx] = t
//    }
//    // MARK: - Генерация coverImage (упрощённая версия)
//
//    func generateCoverImage() async {
//        // Отменяем предыдущую задачу, если она запущена
//        generateCoverTask?.cancel()
//        
//        // Создаём новую задачу
//        let task = Task {
//            // Защита от повторного вызова
//            guard !isGeneratingCover else {
//                await MainActor.run {
//                    status = "Генерация уже выполняется..."
//                }
//                return
//            }
//            
//            guard coverThumbnailURLs.count == 4 else {
//                await MainActor.run {
//                    status = "Нужно ровно 4 thumbnail"
//                }
//                return
//            }
//            
//            await MainActor.run {
//                isGeneratingCover = true
//                status = "Генерируем coverImage..."
//            }
//            
//            defer {
//                Task { @MainActor in
//                    isGeneratingCover = false
//                }
//            }
//            
//            do {
//                try Task.checkCancellation()
//                
//                let functions = Functions.functions()
//                
//                let data: [String: Any] = [
//                    "playlistId": playlistId,
//                    "thumbnailURLs": coverThumbnailURLs
//                ]
//                
//                print("📤 Вызываем generatePlaylistCover с данными:", data)
//                
//                let result = try await functions.httpsCallable("generatePlaylistCover").call(data)
//                
//                try Task.checkCancellation()
//                
//                print("📥 Получен результат:", result.data)
//                
//                if let dict = result.data as? [String: Any],
//                   let url = dict["coverImageURL"] as? String {
//                    await MainActor.run {
//                        self.playlistImageURL = url
//                        self.coverImageURL = url
//                        self.status = "✅ coverImage сгенерирован"
//                    }
//                    print("✅ URL обложки:", url)
//                } else {
//                    await MainActor.run {
//                        self.status = "Ошибка: неверный ответ функции"
//                    }
//                }
//            } catch {
//                if Task.isCancelled {
//                    print("⚠️ Задача была отменена")
//                    await MainActor.run {
//                        self.status = "Генерация отменена"
//                    }
//                } else {
//                    await MainActor.run {
//                        print("❌ Ошибка вызова функции:", error.localizedDescription)
//                        self.status = "Ошибка: \(error.localizedDescription)"
//                    }
//                }
//            }
//        }
//        
//        generateCoverTask = task
//        await task.value
//    }
//
//    // MARK: - Сохранение для topSection
//    func savePlaylistToFirestore() async {
//        guard !playlistTitle.isEmpty else {
//            status = "Ошибка: заголовок пуст"
//            return
//        }
//
//        guard !playlistImageURL.isEmpty else {
//            status = "Сначала сгенерируйте coverImage"
//            return
//        }
//
//        status = "Сохраняем плейлист и треки…"
//
//        do {
//            let droplistRef = db.collection("topSection").document(playlistId)
//
//            try await droplistRef.setData([
//                "playlistId": playlistId,
//                "title": playlistTitle,
//                "description": playlistDescription,
//                "coverImageURL": playlistImageURL,
//                "trackCount": tracks.count,
//                "orderIndex": 3,
//                "createdAt": FieldValue.serverTimestamp()
//            ], merge: true)
//
//            let batch = db.batch()
//
//            for track in tracks {
//
//                let subRef = droplistRef.collection("tracks").document(track.videoId)
//                batch.setData([
//                    "videoId": track.videoId,
//                    "title": track.title,
//                    "artist": track.artist,
//                    "thumbnailURL": track.thumbnailURL,
//                    "durationISO8601": track.durationISO8601,
//                    "orderIndex": track.orderIndex,
//                    "createdAt": FieldValue.serverTimestamp()
//                ], forDocument: subRef)
//            }
//
//            try await batch.commit()
//            status = "Плейлист и треки сохранены"
//        } catch {
//            status = "Ошибка сохранения: \(error.localizedDescription)"
//        }
//    }







//    // MARK: - Сохранение для droplist
//    func savePlaylistToFirestore() async {
//        guard !playlistTitle.isEmpty else {
//            status = "Ошибка: заголовок пуст"
//            return
//        }
//
//        guard !playlistImageURL.isEmpty else {
//            status = "Сначала сгенерируйте coverImage"
//            return
//        }
//
//        status = "Сохраняем плейлист и треки…"
//
//        do {
//            let droplistRef = db.collection("droplist").document(playlistId)
//
//            try await droplistRef.setData([
//                "playlistId": playlistId,
//                "title": playlistTitle,
//                "description": playlistDescription,
//                "coverImageURL": playlistImageURL,
//                "trackCount": tracks.count,
//                "createdAt": FieldValue.serverTimestamp()
//            ], merge: true)
//
//            let batch = db.batch()
//
//            for track in tracks {
//
//                let subRef = droplistRef.collection("tracks").document(track.videoId)
//                batch.setData([
//                    "videoId": track.videoId,
//                    "title": track.title,
//                    "artist": track.artist,
//                    "thumbnailURL": track.thumbnailURL,
//                    "durationISO8601": track.durationISO8601,
//                    "orderIndex": track.orderIndex,
//                    "createdAt": FieldValue.serverTimestamp()
//                ], forDocument: subRef)
//
//                let globalRef = db.collection("dropTracks").document(track.videoId)
//                batch.setData([
//                    "videoId": track.videoId,
//                    "title": track.title,
//                    "artist": track.artist,
//                    "thumbnailURL": track.thumbnailURL,
//                    "durationISO8601": track.durationISO8601,
//                    "playlists": FieldValue.arrayUnion([playlistId]),
//                    "tags": track.tags,
//                    "createdAt": FieldValue.serverTimestamp()
//                ], forDocument: globalRef)
//            }
//
//            try await batch.commit()
//            status = "Плейлист и треки сохранены"
//        } catch {
//            status = "Ошибка сохранения: \(error.localizedDescription)"
//        }
//    }
//}



