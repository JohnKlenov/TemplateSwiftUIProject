//
//  AllAdminView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 25.03.26.
//



/*
==============================================================
FIRESTORE SECURITY — ADMIN ROLE (CUSTOM CLAIMS)
==============================================================

В продакшене запись в Firestore должна быть ограничена
только для админов. Для этого используется механизм
"custom claims" в Firebase Authentication.

--------------------------------------------------------------
1. ЧТО ТАКОЕ CUSTOM CLAIMS
--------------------------------------------------------------
Custom claims — это дополнительные поля в токене
пользователя (request.auth.token), которые задаются
ТОЛЬКО через Firebase Admin SDK (на бэкенде).

Пример:
- обычный пользователь: role = "user"
- админ: role = "admin"

Клиентское iOS‑приложение НЕ может само себе выдать
роль admin — это делает только доверенный сервер.

--------------------------------------------------------------
2. ПРАВИЛА FIRESTORE ДЛЯ ADMIN
--------------------------------------------------------------

// Пример правил:
match /{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null
               && request.auth.token.role == "admin";
}

Вариант для конкретной коллекции playlists:

match /playlists/{playlistId}/tracks/{trackId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null
               && request.auth.token.role == "admin";
}

ИТОГ:
- читать могут все авторизованные пользователи
- писать (создавать/обновлять/удалять) могут только админы

--------------------------------------------------------------
3. КАК ВЫДАТЬ РОЛЬ ADMIN
--------------------------------------------------------------
Роль admin назначается через Firebase Admin SDK
(Cloud Functions, Node.js, любой бэкенд).

Пример на Node.js:

  const admin = require("firebase-admin");

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  async function setAdminRole(uid: string) {
    await admin.auth().setCustomUserClaims(uid, { role: "admin" });
    console.log("Admin role set for:", uid);
  }

После этого:
- у пользователя с этим UID в токене будет role = "admin"
- Firestore начнёт разрешать ему запись
- пользователю нужно перелогиниться, чтобы получить новый токен

--------------------------------------------------------------
4. ПОЧЕМУ ЭТО ПОДХОДИТ ДЛЯ ПРОДАКШЕНА
--------------------------------------------------------------
- Роль admin нельзя подделать с клиента
- Все проверки прав выполняются на стороне Firestore
- Обычные пользователи не могут писать в критичные коллекции
- Админ‑панель может быть встроена в то же приложение,
  но защищена на уровне правил Firestore

==============================================================
*/



//
// MARK: - API Key Security Summary
//
// 1. Firebase API Key (из GoogleService-Info.plist) НЕ является секретом.
//    Google официально разрешает хранить его в Git и в клиентском приложении.
//    Этот ключ нужен только для идентификации проекта, а не для доступа к данным.
//
// 2. YouTube API Key — приватный ключ. Его НЕЛЬЗЯ хранить в Git или в бинарнике.
//    Если ключ скомпрометирован, злоумышленник может сжечь квоту или заблокировать проект.
//
// 3. .gitignore защищает только те файлы, которые ещё НЕ отслеживаются Git.
//    Поэтому Secrets.swift должен создаваться ПОСЛЕ коммита .gitignore.
//
// 4. Проблема ключей, зашитых в приложение:
//    - их нельзя заменить без обновления приложения;
//    - если ключ скомпрометирован, все старые версии приложения останутся с ним;
//    - это критично для приватных ключей.
//
// 5. Как делают профессиональные команды:
//    - Хранят приватные ключи на backend и выдают приложению по запросу;
//    - Или используют Remote Config (Firebase, AWS AppConfig, LaunchDarkly);
//    - Или проксируют запросы через свой сервер;
//    - Публичные ключи (Firebase API Key) оставляют в Git.
//
// 6. Лучший вариант для YouTube API Key:
//    - хранить на сервере;
//    - или проксировать запросы через backend;
//    - или ограничить ключ по bundle ID и квотам, если backend отсутствует.
//
// 7. Текущая конфигурация проекта корректна:
//    - Secrets.swift игнорируется Git;
//    - GoogleService-Info.plist можно оставлять в Git;
//    - приватные ключи защищены;
//    - публичные ключи безопасны.
//


//
// MARK: - API Key Architecture (Production-Ready)
//
// 1. Приватные ключи (например, YouTube API Key) нельзя хранить в Git или в бинарнике.
//    Их нужно получать с сервера при запуске приложения.
//
// 2. Firebase позволяет хранить ключи тремя способами:
//    A) Cloud Functions — самый безопасный вариант (ключ не хранится в клиенте).
//    B) Firestore — ключ хранится в документе, приложение запрашивает его при запуске.
//    C) Remote Config — подходит для публичных ключей и конфигурации.
//
// 3. Ротация ключей:
//    - Меняем ключ на сервере (Functions / Firestore / Remote Config).
//    - Приложение автоматически получает новый ключ без обновления в App Store.
//    - Старый ключ можно отключить.
//
// 4. Как делают крупные компании:
//    - Spotify: все ключи только на backend.
//    - TikTok: ключи обфусцированы и ротируются через сервер.
//    - Instagram: клиент никогда не видит приватных ключей.
//
// 5. Рекомендация для проекта:
//    - Хранить YouTube API Key в Cloud Functions или Firestore.
//    - Сохранять ключ в Keychain после получения.
//    - Firebase API Key из GoogleService-Info.plist можно оставлять в Git.
//


/// LEGAL SUMMARY (YouTube + YouTube Music)
///
/// • В приложении можно легально проигрывать видео по videoId через YouTube embed.
/// • Видимость плейлиста (public / unlisted / private) НЕ влияет на доступность видео.
///   Важно только, чтобы само видео на канале артиста было публичным.
///
/// • Private-плейлист нельзя открыть по диплинку.
///   Если нужен доступ по ссылке — используй Unlisted (доступ по ссылке).
///
/// • Если артист удалит или изменит видео, это автоматически изменится и в твоём плейлисте.
///   Плейлист хранит ссылки, а не копии контента.
///
/// • Такой подход полностью соответствует YouTube Terms и App Store Review:
///   - контент не скачивается и не кэшируется,
///   - используется официальный YouTube iframe,
///   - UI YouTube не скрывается,
///   - воспроизведение идёт только через YouTube.
///
/// Итог: проигрывать видео по videoId из своих плейлистов, хранить метаданные в Firestore
/// и открывать плейлисты по диплинку (если они Unlisted) — полностью легально.




import Foundation
import FirebaseFirestore
import SwiftUI
import SafariServices









// MARK: -  поиск трека внутри YouTube‑плейлиста


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
}

// MARK: - Playlist Metadata

struct PlaylistMetadata: Identifiable, Codable {
    var id: String { playlistId }

    let playlistId: String
    let title: String
    let description: String
    let imageURL: String
}

// MARK: - YouTube Video Duration Response

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

// MARK: - YouTube API Client

final class YouTubeAPIClient {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // Поиск одного видео по артисту и названию трека
    func searchTrack(artist: String, title: String, orderIndex: Int) async throws -> TrackMetadata {
        let query = "\(artist) \(title)"
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        let urlString =
        "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=\(encoded)&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw NSError(domain: "YouTubeAPI", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Неверный URL поиска"])
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        struct SearchResponse: Decodable {
            struct Item: Decodable {
                struct Id: Decodable { let videoId: String }
                struct Snippet: Decodable {
                    struct Thumbnails: Decodable {
                        struct Thumb: Decodable { let url: String }
                        let high: Thumb
                    }
                    let thumbnails: Thumbnails
                }
                let id: Id
                let snippet: Snippet
            }
            let items: [Item]
        }

        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        guard let item = response.items.first else {
            throw NSError(domain: "YouTubeAPI", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Видео не найдено"])
        }

        let duration = try await fetchDuration(videoId: item.id.videoId)

        return TrackMetadata(
            videoId: item.id.videoId,
            title: title,               // ← ВАЖНО: из ввода пользователя
            artist: artist,             // ← ВАЖНО: из ввода пользователя
            thumbnailURL: item.snippet.thumbnails.high.url,
            durationISO8601: duration,
            orderIndex: orderIndex
        )
    }

    // Поиск одного видео по артисту и названию трека
//    func searchTrack(artist: String, title: String, orderIndex: Int) async throws -> TrackMetadata {
//        let query = "\(artist) \(title)"
//        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
//
//        let urlString =
//        "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=\(encoded)&key=\(apiKey)"
//
//        guard let url = URL(string: urlString) else {
//            throw NSError(domain: "YouTubeAPI", code: 1,
//                          userInfo: [NSLocalizedDescriptionKey: "Неверный URL поиска"])
//        }
//
//        let (data, _) = try await URLSession.shared.data(from: url)
//
//        struct SearchResponse: Decodable {
//            struct Item: Decodable {
//                struct Id: Decodable { let videoId: String }
//                struct Snippet: Decodable {
//                    let title: String
//                    let channelTitle: String
//                    struct Thumbnails: Decodable {
//                        struct Thumb: Decodable { let url: String }
//                        let high: Thumb
//                    }
//                    let thumbnails: Thumbnails
//                }
//                let id: Id
//                let snippet: Snippet
//            }
//            let items: [Item]
//        }
//
//        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
//        guard let item = response.items.first else {
//            throw NSError(domain: "YouTubeAPI", code: 2,
//                          userInfo: [NSLocalizedDescriptionKey: "Видео не найдено"])
//        }
//
//        let duration = try await fetchDuration(videoId: item.id.videoId)
//
//        return TrackMetadata(
//            videoId: item.id.videoId,
//            title: item.snippet.title,
//            artist: item.snippet.channelTitle,
//            thumbnailURL: item.snippet.thumbnails.high.url,
//            durationISO8601: duration,
//            orderIndex: orderIndex
//        )
//    }

    // Получить длительность видео
    func fetchDuration(videoId: String) async throws -> String {
        let urlString =
        "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"

        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
        guard let item = response.items.first else {
            throw NSError(domain: "YouTubeAPI", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
        }
        return item.contentDetails.duration
    }
}

// MARK: - Admin ViewModel

@MainActor
final class AdminViewModel: ObservableObject {

    // Метаданные плейлиста ЗАШИТЫ В КОД
    @Published private(set) var playlistTitle: String
    @Published private(set) var playlistDescription: String
    @Published private(set) var playlistImageURL: String

    // Поля для поиска трека
    @Published var searchArtist: String = ""
    @Published var searchTitle: String = ""

    // Найденный трек
    @Published var foundTrack: TrackMetadata?
    @Published var foundTrackURL: URL?

    // Накопленные треки
    @Published var tracks: [TrackMetadata] = []

    @Published var status: String = ""

    private let api: YouTubeAPIClient
    private let db = Firestore.firestore()
    private let playlistId: String

    init(apiKey: String,
         playlistId: String,
         playlistTitle: String,
         playlistDescription: String,
         playlistImageURL: String) {

        self.api = YouTubeAPIClient(apiKey: apiKey)
        self.playlistId = playlistId
        self.playlistTitle = playlistTitle
        self.playlistDescription = playlistDescription
        self.playlistImageURL = playlistImageURL
    }

    // MARK: - Поиск одного трека
    func searchTrack() async {
        status = "Ищем трек…"
        foundTrack = nil
        foundTrackURL = nil

        guard !searchArtist.isEmpty, !searchTitle.isEmpty else {
            status = "Введите артиста и название трека"
            return
        }

        do {
            let track = try await api.searchTrack(
                artist: searchArtist,
                title: searchTitle,
                orderIndex: tracks.count
            )
            foundTrack = track
            foundTrackURL = URL(string: "https://www.youtube.com/watch?v=\(track.videoId)")
            status = "Трек найден"
        } catch {
            status = "Ошибка поиска: \(error.localizedDescription)"
        }
    }

    // MARK: - Добавить трек в список
    func addFoundTrack() {
        guard let track = foundTrack else { return }

        tracks.append(track)
        print("Добавлен трек: \(track)")

        searchArtist = ""
        searchTitle = ""
        foundTrack = nil
        foundTrackURL = nil

        status = "Трек добавлен в список"
    }

    // MARK: - Сохранить плейлист в Firestore
    func savePlaylistToFirestore() async {
        guard !playlistTitle.isEmpty else {
            status = "Ошибка: заголовок пуст"
            return
        }

        status = "Сохраняем…"

        do {
            let playlistRef = db.collection("playlists").document(playlistId)

            // Метаданные
            try await playlistRef.setData([
                "playlistId": playlistId,
                "title": playlistTitle,
                "description": playlistDescription,
                "imageURL": playlistImageURL
            ], merge: true)

            // Треки
            let batch = db.batch()

            for track in tracks {
                let ref = playlistRef.collection("tracks").document(track.videoId)
                batch.setData([
                    "videoId": track.videoId,
                    "title": track.title,
                    "artist": track.artist,
                    "thumbnailURL": track.thumbnailURL,
                    "durationISO8601": track.durationISO8601,
                    "orderIndex": track.orderIndex
                ], forDocument: ref)
            }

            try await batch.commit()
            status = "Плейлист сохранён"

        } catch {
            status = "Ошибка сохранения: \(error.localizedDescription)"
        }
    }
}

// MARK: - SafariView

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - AdminView

struct AdminView: View {

    @StateObject private var vm = AdminViewModel(
        apiKey: Secrets.youtubeAPIKey,
        playlistId: "PLQcuPcwlJLVDMqEhSBkJKiJeywzU0KP8r",
        playlistTitle: "Droplist",           // ЗАШИТО В КОДЕ
        playlistDescription: "Super tracks",
        playlistImageURL: "playlistImageURL"
    )

    @State private var showSafari = false

    var body: some View {
        NavigationView {
            Form {

                // Метаданные только отображаем
                Section("Метаданные плейлиста") {
                    Text("Title: \(vm.playlistTitle)")
                    Text("Description: \(vm.playlistDescription)")
                    Text("Image URL: \(vm.playlistImageURL)")
                        .lineLimit(2)
                        .font(.footnote)
                }

                Section("Добавить трек вручную") {
                    TextField("Artist", text: $vm.searchArtist)
                    TextField("Track Title", text: $vm.searchTitle)

                    Button("Искать трек") {
                        Task { await vm.searchTrack() }
                    }

                    if let url = vm.foundTrackURL {
                        Button("Открыть найденный трек в Safari") {
                            showSafari = true
                        }
                    }

                    if vm.foundTrack != nil {
                        Button("Добавить трек в список") {
                            vm.addFoundTrack()
                        }
                        .foregroundColor(.green)
                    }
                }
                Section("Треки в плейлисте") {
                    if vm.tracks.isEmpty {
                        Text("Пока нет треков")
                            .foregroundColor(.secondary)
                    } else {
                        List(vm.tracks.sorted(by: { $0.orderIndex < $1.orderIndex })) { track in
                            HStack {
                                Text("\(track.orderIndex + 1).")
                                    .foregroundColor(.secondary)

                                VStack(alignment: .leading) {
                                    Text(track.title)
                                        .font(.subheadline)
                                        .lineLimit(1)

                                    Text(track.artist)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4) // компактно
                        }
                        .listStyle(.plain)
                        .frame(minHeight: 200)
                    }
                }

//                Section("Треки в плейлисте") {
//                    if vm.tracks.isEmpty {
//                        Text("Пока нет треков")
//                            .foregroundColor(.secondary)
//                    } else {
//                        List(vm.tracks.sorted(by: { $0.orderIndex < $1.orderIndex })) { track in
//                            VStack(alignment: .leading) {
//                                Text("\(track.orderIndex + 1). \(track.title)")
//                                    .fontWeight(.semibold)
//                                Text(track.artist)
//                                    .font(.footnote)
//                                    .foregroundColor(.secondary)
//                            }
//                        }
//                        .frame(minHeight: 200)
//                    }
//                }

                Section("Сохранение") {
                    Button("Сохранить плейлист в Firestore") {
                        Task { await vm.savePlaylistToFirestore() }
                    }
                    .foregroundColor(.blue)
                }

                Section("Статус") {
                    Text(vm.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = vm.foundTrackURL {
                    SafariView(url: url)
                }
            }
            .navigationTitle("Admin • Manual Playlist Builder")
        }
    }
}


//// MARK: - Track Protocol
//
//protocol TrackProtocol {
//    var videoId: String { get }
//    var title: String { get }
//    var artist: String { get }
//    var thumbnailURL: String { get }
//    var durationISO8601: String { get }
//}
//
//// MARK: - Track Model
//
//struct TrackMetadata: Identifiable, Codable, TrackProtocol {
//    var id: String { videoId }
//
//    let videoId: String
//    let title: String
//    let artist: String
//    let thumbnailURL: String
//    let durationISO8601: String
//}
//
//// MARK: - YouTube PlaylistItems Response
//
//struct YouTubePlaylistItemsResponse: Decodable {
//    struct Item: Decodable {
//        struct Snippet: Decodable {
//            let title: String
//            let channelTitle: String
//
//            struct ResourceId: Decodable {
//                let videoId: String
//            }
//            let resourceId: ResourceId
//
//            struct Thumbnails: Decodable {
//                struct Thumb: Decodable {
//                    let url: String
//                }
//                let high: Thumb
//            }
//            let thumbnails: Thumbnails
//        }
//        let snippet: Snippet
//    }
//    let items: [Item]
//}
//
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
//// MARK: - YouTube API Client
//
//final class YouTubeAPIClient {
//    private let apiKey: String
//
//    init(apiKey: String) {
//        self.apiKey = apiKey
//    }
//
//    // 1. Получить все видео из плейлиста
//    func fetchPlaylistVideos(playlistId: String) async throws -> [YouTubePlaylistItemsResponse.Item] {
//        let urlString =
//        "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&maxResults=50&playlistId=\(playlistId)&key=\(apiKey)"
//
//        let url = URL(string: urlString)!
//        let (data, _) = try await URLSession.shared.data(from: url)
//
//        let response = try JSONDecoder().decode(YouTubePlaylistItemsResponse.self, from: data)
//        return response.items
//    }
//
//    // 2. Получить длительность видео
//    func fetchDuration(videoId: String) async throws -> String {
//        let urlString =
//        "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"
//
//        let url = URL(string: urlString)!
//        let (data, _) = try await URLSession.shared.data(from: url)
//
//        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
//        guard let item = response.items.first else {
//            throw NSError(domain: "YouTubeAPI", code: 2,
//                          userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
//        }
//        return item.contentDetails.duration
//    }
//}
//
//// MARK: - Поиск совпадения внутри плейлиста
//
//extension Array where Element == YouTubePlaylistItemsResponse.Item {
//    func findMatchingTrack(artist: String, title: String) -> YouTubePlaylistItemsResponse.Item? {
//        let a = artist.lowercased()
//        let t = title.lowercased()
//
//        return self.first { item in
//            let name = item.snippet.title.lowercased()
//            return name.contains(a) && name.contains(t)
//        }
//    }
//}
//
//// MARK: - Admin ViewModel
//
//@MainActor
//final class AdminViewModel: ObservableObject {
//    @Published var artist: String = ""
//    @Published var trackTitle: String = ""
//    @Published var playlistId: String = ""
//    @Published var status: String = ""
//
//    @Published var previewVideoId: String?
//    @Published var foundTrack: TrackMetadata?
//
//    private let api: YouTubeAPIClient
//    private let db = Firestore.firestore()
//
//    init(apiKey: String) {
//        self.api = YouTubeAPIClient(apiKey: apiKey)
//    }
//
//    // Новый поиск — только внутри плейлиста
//    func searchTrack() async {
//        status = "Загружаем плейлист…"
//        foundTrack = nil
//        previewVideoId = nil
//
//        do {
//            // 1. Получаем все видео из плейлиста
//            let items = try await api.fetchPlaylistVideos(playlistId: playlistId)
//
//            // 2. Ищем совпадение
//            guard let match = items.findMatchingTrack(artist: artist, title: trackTitle) else {
//                status = "Трек не найден в плейлисте"
//                return
//            }
//
//            let videoId = match.snippet.resourceId.videoId
//            previewVideoId = videoId
//
//            // 3. Получаем длительность
//            let duration = try await api.fetchDuration(videoId: videoId)
//
//            // 4. Формируем TrackMetadata
//            foundTrack = TrackMetadata(
//                videoId: videoId,
//                title: trackTitle,
//                artist: artist,
//                thumbnailURL: match.snippet.thumbnails.high.url,
//                durationISO8601: duration
//            )
//
//            status = "Видео найдено. Проверь перед сохранением."
//
//        } catch {
//            status = "Ошибка: \(error.localizedDescription)"
//        }
//    }
//
//    // Сохранение в Firestore
//    func saveFoundTrack() async {
//        guard let track = foundTrack else {
//            status = "Ошибка: нет трека для сохранения"
//            return
//        }
//
//        do {
//            try await saveTrackToFirestore(track: track)
//            status = "Успех: трек сохранён в Firestore"
//        } catch {
//            status = "Ошибка сохранения: \(error.localizedDescription)"
//        }
//    }
//
//    private func saveTrackToFirestore(track: TrackMetadata) async throws {
//        guard !playlistId.isEmpty else {
//            throw NSError(domain: "Admin", code: 3,
//                          userInfo: [NSLocalizedDescriptionKey: "playlistId пуст"])
//        }
//
//        let docRef = db
//            .collection("playlists")
//            .document(playlistId)
//            .collection("tracks")
//            .document(track.videoId)
//
//        try await docRef.setData([
//            "videoId": track.videoId,
//            "title": track.title,
//            "artist": track.artist,
//            "thumbnailURL": track.thumbnailURL,
//            "durationISO8601": track.durationISO8601
//        ], merge: true)
//    }
//}
//
//// MARK: - SafariView
//
//struct SafariView: UIViewControllerRepresentable {
//    let url: URL
//
//    func makeUIViewController(context: Context) -> SFSafariViewController {
//        SFSafariViewController(url: url)
//    }
//
//    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
//}
//
//// MARK: - AdminView
//
//struct AdminView: View {
//    @StateObject private var vm = AdminViewModel(apiKey: Secrets.youtubeAPIKey)
//    @State private var showPreview = false
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section("Плейлист") {
//                    TextField("playlistId (например PLxxxx)", text: $vm.playlistId)
//                }
//
//                Section("Трек") {
//                    TextField("Артист", text: $vm.artist)
//                    TextField("Название трека", text: $vm.trackTitle)
//                }
//
//                Section {
//                    Button("Найти видео в плейлисте") {
//                        Task { await vm.searchTrack() }
//                    }
//
//                    if let videoId = vm.previewVideoId {
//                        Button("Просмотр видео") {
//                            showPreview = true
//                        }
//                    }
//
//                    if vm.foundTrack != nil {
//                        Button("Сохранить трек в Firestore") {
//                            Task { await vm.saveFoundTrack() }
//                        }
//                        .foregroundColor(.green)
//                    }
//                }
//
//                Section("Статус") {
//                    Text(vm.status)
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .sheet(isPresented: $showPreview) {
//                if let videoId = vm.previewVideoId,
//                   let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)") {
//                    SafariView(url: url)
//                }
//            }
//            .navigationTitle("Admin • Playlist → Firestore")
//        }
//    }
//}
//
//





// MARK: -  поиск трека во всем YouTube



//protocol TrackProtocol {
//    var videoId: String { get }
//    var title: String { get }
//    var artist: String { get }
//    var thumbnailURL: String { get }
//    var durationISO8601: String { get }
//}
//
//
//// MARK: - Модель трека
//
//struct TrackMetadata: Identifiable, Codable, TrackProtocol {
//    var id: String { videoId }
//
//    let videoId: String
//    let title: String
//    let artist: String
//    let thumbnailURL: String
//    let durationISO8601: String
//}
//
//
//// MARK: - Модели для парсинга YouTube JSON
//
//struct YouTubeSearchResponse: Decodable {
//    struct Item: Decodable {
//        struct Id: Decodable {
//            let videoId: String?
//        }
//        struct Snippet: Decodable {
//            let title: String
//            let channelTitle: String
//            struct Thumbnails: Decodable {
//                struct Thumb: Decodable {
//                    let url: String
//                }
//                let high: Thumb
//            }
//            let thumbnails: Thumbnails
//        }
//        let id: Id
//        let snippet: Snippet
//    }
//    let items: [Item]
//}
//
//struct YouTubeVideosResponse: Decodable {
//    struct Item: Decodable {
//        struct ContentDetails: Decodable {
//            let duration: String // ISO8601, например "PT1M57S"
//        }
//        let id: String
//        let contentDetails: ContentDetails
//    }
//    let items: [Item]
//}
//
//// MARK: - YouTube API Client
//
//final class YouTubeAPIClient {
//    private let apiKey: String
//
//    init(apiKey: String) {
//        self.apiKey = apiKey
//    }
//
//    func searchFirstVideo(query: String) async throws -> (videoId: String, title: String, channelTitle: String, thumbnailURL: String) {
//        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
//        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=5&q=\(q)&key=\(apiKey)"
//        let url = URL(string: urlString)!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        print("RAW JSON:", String(data: data, encoding: .utf8) ?? "nil")
//        let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
//
//        // Печатаем все найденные видео
//        print("🔍 YouTube Search Items:")
//        response.items.forEach { item in
//            print("• \(item.snippet.title) — \(item.id.videoId ?? "NO ID")")
//        }
//
//        guard let item = response.items.first,
//              let videoId = item.id.videoId else {
//            throw NSError(domain: "YouTubeAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Видео не найдено"])
//        }
//        return (
//            videoId: videoId,
//            title: item.snippet.title,
//            channelTitle: item.snippet.channelTitle,
//            thumbnailURL: item.snippet.thumbnails.high.url
//        )
//    }
//
//    func fetchDuration(videoId: String) async throws -> String {
//        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"
//        let url = URL(string: urlString)!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
//        guard let item = response.items.first else {
//            throw NSError(domain: "YouTubeAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
//        }
//        return item.contentDetails.duration
//    }
//}
//
//// MARK: - ViewModel admin‑экрана
//
//@MainActor
//final class AdminViewModel: ObservableObject {
//    @Published var artist: String = ""
//    @Published var trackTitle: String = ""
//    @Published var playlistId: String = ""
//    @Published var status: String = ""
//
//    @Published var previewVideoId: String?
//    @Published var foundTrack: TrackMetadata?   // найденный, но ещё не сохранённый трек
//
//    private let api: YouTubeAPIClient
//    private let db = Firestore.firestore()
//
//    init(apiKey: String) {
//        
//
//        print("API KEY:", Secrets.youtubeAPIKey)
//        self.api = YouTubeAPIClient(apiKey: apiKey)
//    }
//
//    // Только поиск, без сохранения
//    func searchTrack() async {
//        status = "Ищем трек в YouTube…"
//        foundTrack = nil
//        previewVideoId = nil
//
//        do {
//            let query = "\(artist) \(trackTitle)"
//            let searchResult = try await api.searchFirstVideo(query: query)
//
//            previewVideoId = searchResult.videoId
//
//            let duration = try await api.fetchDuration(videoId: searchResult.videoId)
//
//            foundTrack = TrackMetadata(
//                videoId: searchResult.videoId,
//                title: searchResult.title,
//                artist: searchResult.channelTitle, // или artist, если хочешь своё поле
//                thumbnailURL: searchResult.thumbnailURL,
//                durationISO8601: duration
//            )
//
//            status = "Видео найдено. Проверь перед сохранением."
//        } catch {
//            status = "Ошибка: \(error.localizedDescription)"
//            print("Ошибка: \(error)")
//        }
//    }
//
//    // Сохранение найденного трека
//    func saveFoundTrack() async {
//        guard let track = foundTrack else {
//            status = "Ошибка: нет трека для сохранения"
//            return
//        }
//
//        do {
//            try await saveTrackToFirestore(track: track)
//            status = "Успех: трек сохранён в Firestore"
//        } catch {
//            status = "Ошибка сохранения: \(error.localizedDescription)"
//        }
//    }
//
//    private func saveTrackToFirestore(track: TrackMetadata) async throws {
//        guard !playlistId.isEmpty else {
//            throw NSError(domain: "Admin", code: 3, userInfo: [NSLocalizedDescriptionKey: "playlistId пуст"])
//        }
//
//        let docRef = db
//            .collection("playlists")
//            .document(playlistId)
//            .collection("tracks")
//            .document(track.videoId)
//
//        try await docRef.setData([
//            "videoId": track.videoId,
//            "title": track.title,
//            "artist": track.artist,
//            "thumbnailURL": track.thumbnailURL,
//            "durationISO8601": track.durationISO8601
//        ], merge: true)
//    }
//}
//
//// MARK: - SafariView для предпросмотра YouTube
//
//struct SafariView: UIViewControllerRepresentable {
//    let url: URL
//
//    func makeUIViewController(context: Context) -> SFSafariViewController {
//        SFSafariViewController(url: url)
//    }
//
//    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
//}
//
//// MARK: - AdminView
//
//struct AdminView: View {
//    @StateObject private var vm = AdminViewModel(apiKey: Secrets.youtubeAPIKey)
//    @State private var showPreview = false
//
//    var body: some View {
//        NavigationView {
//            Form {
//                Section("Плейлист") {
//                    TextField("playlistId (например narcos)", text: $vm.playlistId)
//                }
//
//                Section("Трек") {
//                    TextField("Артист", text: $vm.artist)
//                    TextField("Название трека", text: $vm.trackTitle)
//                }
//
//                Section {
//                    Button("Найти видео в YouTube") {
//                        Task { await vm.searchTrack() }
//                    }
//
//                    if let videoId = vm.previewVideoId {
//                        Button("Просмотр видео") {
//                            showPreview = true
//                        }
//                    }
//
//                    if vm.foundTrack != nil {
//                        Button("Сохранить трек в Firestore") {
//                            Task { await vm.saveFoundTrack() }
//                        }
//                        .foregroundColor(.green)
//                    }
//                }
//
//                Section("Статус") {
//                    Text(vm.status)
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.leading)
//                }
//            }
//            .sheet(isPresented: $showPreview) {
//                if let videoId = vm.previewVideoId,
//                   let url = URL(string: "https://www.youtube.com/watch?v=\(videoId)") {
//                    SafariView(url: url)
//                }
//            }
//            .navigationTitle("Admin • YouTube → Firestore")
//        }
//    }
//}
