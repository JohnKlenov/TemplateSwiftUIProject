//
//  AdminViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.05.26.
//



import FirebaseFirestore
import FirebaseFunctions
import SwiftUI


@MainActor
final class AdminViewModel: ObservableObject {

    // Метаданные плейлиста
    @Published private(set) var playlistTitle: String
    @Published private(set) var playlistDescription: String
    @Published private(set) var playlistImageURL: String = ""

    // Поля поиска
    @Published var searchArtist: String = ""
    @Published var searchTitle: String = ""

    // Найденный трек
    @Published var foundTrack: TrackMetadata?
    @Published var foundTrackURL: URL?

    // Теги найденного трека (до добавления)
    @Published var foundTrackTags: Set<String> = []

    // Флаг: использовать ли thumbnail найденного трека в коллаже
    @Published var useFoundTrackThumbnailInCollage: Bool = false

    // Треки плейлиста
    @Published var tracks: [TrackMetadata] = []

    // Thumbnail для коллажа
    @Published var coverThumbnailURLs: [String] = []

    // Результат генерации
    @Published var coverImageURL: String? = nil

    // Статус
    @Published var status: String = ""
    
    @Published private(set) var isGeneratingCover = false
    private var generateCoverTask: Task<Void, Never>?

    // Добавьте это свойство в класс AdminViewModel (в начало с другими @Published)
//    @Published var youtubePlaylistId: String = "PLQcuPcwlJLVCYhAAFan-AxvLlWypVIW5v" // ID вашего YouTube плейлиста
    @Published var isImportingAllTracks: Bool = false

    let availableTags: [String] = ["Gym", "Party", "R&B"]

    private let api: YouTubeAPIClient
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    private let playlistId: String

    init(apiKey: String,
         playlistId: String,
         playlistTitle: String,
         playlistDescription: String) {

        self.api = YouTubeAPIClient(apiKey: apiKey)
        self.playlistId = playlistId
        self.playlistTitle = playlistTitle
        self.playlistDescription = playlistDescription
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
//            foundTrackURL = URL(string: "https://www.youtube.com/watch?v=\(track.videoId)")
            // Вместо обычной ссылки на YouTube
             foundTrackURL = URL(string: "https://music.youtube.com/watch?v=\(track.videoId)")
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

    // MARK: - Добавить найденный трек в список
    func addFoundTrack() {
        guard var track = foundTrack else {
            status = "Нет найденного трека"
            return
        }

        // переносим выбранные теги
        track.tags = Array(foundTrackTags)

        // при необходимости добавляем thumbnail
        if useFoundTrackThumbnailInCollage,
           coverThumbnailURLs.count < 4 {
            coverThumbnailURLs.append(track.thumbnailURL)
        }

        tracks.append(track)

        // сброс
        searchArtist = ""
        searchTitle = ""
        foundTrack = nil
        foundTrackURL = nil
        foundTrackTags = []
        useFoundTrackThumbnailInCollage = false

        status = "Трек добавлен в список"
    }

    // MARK: - Теги для треков в плейлисте
    func toggleTag(forVideoId videoId: String, tag: String) {
        guard let idx = tracks.firstIndex(where: { $0.videoId == videoId }) else { return }
        var t = tracks[idx]

        if t.tags.contains(tag) {
            t.tags.removeAll { $0 == tag }
        } else {
            t.tags.append(tag)
        }

        tracks[idx] = t
    }
    // MARK: - Генерация coverImage (упрощённая версия)

    func generateCoverImage() async {
        // Отменяем предыдущую задачу, если она запущена
        generateCoverTask?.cancel()
        
        // Создаём новую задачу
        let task = Task {
            // Защита от повторного вызова
            guard !isGeneratingCover else {
                await MainActor.run {
                    status = "Генерация уже выполняется..."
                }
                return
            }
            
            guard coverThumbnailURLs.count == 4 else {
                await MainActor.run {
                    status = "Нужно ровно 4 thumbnail"
                }
                return
            }
            
            await MainActor.run {
                isGeneratingCover = true
                status = "Генерируем coverImage..."
            }
            
            defer {
                Task { @MainActor in
                    isGeneratingCover = false
                }
            }
            
            do {
                try Task.checkCancellation()
                
                let functions = Functions.functions()
                
                let data: [String: Any] = [
                    "playlistId": playlistId,
                    "thumbnailURLs": coverThumbnailURLs
                ]
                
                print("📤 Вызываем generatePlaylistCover с данными:", data)
                
                let result = try await functions.httpsCallable("generatePlaylistCover").call(data)
                
                try Task.checkCancellation()
                
                print("📥 Получен результат:", result.data)
                
                if let dict = result.data as? [String: Any],
                   let url = dict["coverImageURL"] as? String {
                    await MainActor.run {
                        self.playlistImageURL = url
                        self.coverImageURL = url
                        self.status = "✅ coverImage сгенерирован"
                    }
                    print("✅ URL обложки:", url)
                } else {
                    await MainActor.run {
                        self.status = "Ошибка: неверный ответ функции"
                    }
                }
            } catch {
                if Task.isCancelled {
                    print("⚠️ Задача была отменена")
                    await MainActor.run {
                        self.status = "Генерация отменена"
                    }
                } else {
                    await MainActor.run {
                        print("❌ Ошибка вызова функции:", error.localizedDescription)
                        self.status = "Ошибка: \(error.localizedDescription)"
                    }
                }
            }
        }
        
        generateCoverTask = task
        await task.value
    }


    // MARK: - Сохранение
    func savePlaylistToFirestore() async {
        guard !playlistTitle.isEmpty else {
            status = "Ошибка: заголовок пуст"
            return
        }

        guard !playlistImageURL.isEmpty else {
            status = "Сначала сгенерируйте coverImage"
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

                let subRef = droplistRef.collection("tracks").document(track.videoId)
                batch.setData([
                    "videoId": track.videoId,
                    "title": track.title,
                    "artist": track.artist,
                    "thumbnailURL": track.thumbnailURL,
                    "durationISO8601": track.durationISO8601,
                    "orderIndex": track.orderIndex,
                    "createdAt": FieldValue.serverTimestamp()
                ], forDocument: subRef)

                let globalRef = db.collection("dropTracks").document(track.videoId)
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



