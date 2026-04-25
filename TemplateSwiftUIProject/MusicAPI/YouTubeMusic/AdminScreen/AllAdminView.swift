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

                    if let _ = vm.foundTrackURL {
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










// MARK: - New version AdminView #1





//droplist (collection)
// └─ {playlistId}
//     ├─ playlistId: String
//     ├─ title: String
//     ├─ description: String
//     ├─ coverImageURL: String
//     ├─ trackCount: Int
//     ├─ createdAt: Timestamp
//     └─ tracks (subcollection)
//         └─ {videoId}
//             ├─ videoId: String
//             ├─ title: String
//             ├─ artist: String
//             ├─ thumbnailURL: String
//             ├─ durationISO8601: String
//             ├─ orderIndex: Int
//             ├─ createdAt: Timestamp
//
//dropTracks (collection)
// └─ {videoId}
//     ├─ videoId: String
//     ├─ title: String
//     ├─ artist: String
//     ├─ thumbnailURL: String
//     ├─ durationISO8601: String
//     ├─ playlists: [String]
//     ├─ tags: [String]
//     ├─ createdAt: Timestamp












//import Foundation
//import FirebaseFirestore
//import FirebaseFunctions
//import FirebaseStorage
//import SwiftUI
//import SafariServices
//
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
//    let orderIndex: Int
//
//    // Новое поле: теги, которые админ выбирает вручную
//    var tags: [String]
//
//    // Codable конструктор по умолчанию генерируется автоматически
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
//// MARK: - YouTube API Client (unchanged логика, но создаёт TrackMetadata с пустыми tags)
//
//final class YouTubeAPIClient {
//    private let apiKey: String
//
//    init(apiKey: String) {
//        self.apiKey = apiKey
//    }
//
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
//            title: title,
//            artist: artist,
//            thumbnailURL: item.snippet.thumbnails.high.url,
//            durationISO8601: duration,
//            orderIndex: orderIndex,
//            tags: [] // по умолчанию пустой массив тегов
//        )
//    }
//
//    func fetchDuration(videoId: String) async throws -> String {
//        let urlString =
//        "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"
//
//        let url = URL(string: urlString)!
//        let (data, _) = try await URLSession.shared.data(from: url)
//
//        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
//        guard let item = response.items.first else {
//            throw NSError(domain: "YouTubeAPI", code: 3,
//                          userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
//        }
//        return item.contentDetails.duration
//    }
//}
//
//// MARK: - Admin ViewModel (обновлённый)
//
//@MainActor
//final class AdminViewModel: ObservableObject {
//
//    // Метаданные плейлиста (зашиты в коде)
//    @Published private(set) var playlistTitle: String
//    @Published private(set) var playlistDescription: String
//    @Published private(set) var playlistImageURL: String = "" // будет заполнено после генерации
//
//    // Поля для поиска трека
//    @Published var searchArtist: String = ""
//    @Published var searchTitle: String = ""
//
//    // Найденный трек
//    @Published var foundTrack: TrackMetadata?
//    @Published var foundTrackURL: URL?
//
//    // Накопленные треки
//    @Published var tracks: [TrackMetadata] = []
//
//    // Массив thumbnailURL для генерации cover (ровно 4)
//    @Published var coverThumbnailURLs: [String] = []
//
//    // Результат генерации
//    @Published var coverImageURL: String? = nil
//
//    // Статус и доступные теги
//    @Published var status: String = ""
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
//        self.playlistImageURL = ""
//    }
//
//    // MARK: - Поиск одного трека
//    func searchTrack() async {
//        status = "Ищем трек…"
//        foundTrack = nil
//        foundTrackURL = nil
//
//        guard !searchArtist.isEmpty, !searchTitle.isEmpty else {
//            status = "Введите артиста и название трека"
//            return
//        }
//
//        do {
//            let track = try await api.searchTrack(
//                artist: searchArtist,
//                title: searchTitle,
//                orderIndex: tracks.count
//            )
//            foundTrack = track
//            foundTrackURL = URL(string: "https://www.youtube.com/watch?v=\(track.videoId)")
//            status = "Трек найден"
//        } catch {
//            status = "Ошибка поиска: \(error.localizedDescription)"
//        }
//    }
//
//    // MARK: - Добавить трек в список
//    func addFoundTrack() {
//        guard let track = foundTrack else { return }
//
//        tracks.append(track)
//        print("Добавлен трек: \(track)")
//
//        // Сброс полей поиска
//        searchArtist = ""
//        searchTitle = ""
//        foundTrack = nil
//        foundTrackURL = nil
//
//        status = "Трек добавлен в список"
//    }
//
//    // MARK: - Добавить thumbnail в массив для коллажа
//    func addThumbnailToCollage() {
//        guard let track = foundTrack else {
//            status = "Нет найденного трека для добавления"
//            return
//        }
//        guard coverThumbnailURLs.count < 4 else {
//            status = "Уже выбрано 4 thumbnail"
//            return
//        }
//        coverThumbnailURLs.append(track.thumbnailURL)
//        status = "Добавлен thumbnail (\(coverThumbnailURLs.count)/4)"
//    }
//
//    // MARK: - Генерация coverImage через Cloud Function
//    func generateCoverImage() async {
//        guard coverThumbnailURLs.count == 4 else {
//            status = "Нужно ровно 4 thumbnail"
//            return
//        }
//
//        status = "Генерируем coverImage…"
//
//        do {
//            let data: [String: Any] = [
//                "playlistId": playlistId,
//                "thumbnailURLs": coverThumbnailURLs
//            ]
//
//            let result = try await functions.httpsCallable("generatePlaylistCover").call(data)
//            if let dict = result.data as? [String: Any],
//               let url = dict["coverImageURL"] as? String {
//                self.playlistImageURL = url
//                self.coverImageURL = url
//                status = "coverImage сгенерирован"
//            } else {
//                status = "Ошибка: неверный ответ функции"
//            }
//        } catch {
//            status = "Ошибка генерации coverImage: \(error.localizedDescription)"
//        }
//    }
//
//    // MARK: - Теги: переключатель тега для конкретного трека
//    func toggleTag(forVideoId videoId: String, tag: String) {
//        guard let idx = tracks.firstIndex(where: { $0.videoId == videoId }) else { return }
//        var t = tracks[idx]
//        if t.tags.contains(tag) {
//            t.tags.removeAll { $0 == tag }
//        } else {
//            t.tags.append(tag)
//        }
//        tracks[idx] = t
//    }
//
//    // MARK: - Сохранить плейлист в Firestore (droplist) и треки в dropTracks
//    func savePlaylistToFirestore() async {
//        guard !playlistTitle.isEmpty else {
//            status = "Ошибка: заголовок пуст"
//            return
//        }
//
//        // Требуем, чтобы coverImageURL был сгенерирован
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
//            // 1) Сохраняем метаданные плейлиста (без sampleThumbnails и без curatedTags)
//            try await droplistRef.setData([
//                "playlistId": playlistId,
//                "title": playlistTitle,
//                "description": playlistDescription,
//                "coverImageURL": playlistImageURL,
//                "trackCount": tracks.count,
//                "createdAt": FieldValue.serverTimestamp()
//            ], merge: true)
//
//            // 2) Batch: сохраняем в droplist/{playlistId}/tracks и в глобальную коллекцию dropTracks
//            let batch = db.batch()
//
//            for track in tracks {
//                // a) droplist subcollection
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
//                // b) global dropTracks collection (merge playlists array) + сохраняем теги, которые админ выбрал
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
//
//// MARK: - SafariView (unchanged)
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
//// MARK: - AdminView (обновлённый UI с выбором тегов)
//
//struct AdminView: View {
//
//    @StateObject private var vm = AdminViewModel(
//        apiKey: Secrets.youtubeAPIKey,
//        playlistId: "PLQcuPcwlJLVDMqEhSBkJKiJeywzU0KP8r",
//        playlistTitle: "Droplist",
//        playlistDescription: "Super tracks"
//    )
//
//    @State private var showSafari = false
//
//    var body: some View {
//        NavigationView {
//            Form {
//
//                // Метаданные только отображаем
//                Section("Метаданные плейлиста") {
//                    Text("Title: \(vm.playlistTitle)")
//                    Text("Description: \(vm.playlistDescription)")
//                    Text("Cover URL: \(vm.playlistImageURL.isEmpty ? "— не сгенерирован" : vm.playlistImageURL)")
//                        .lineLimit(2)
//                        .font(.footnote)
//                }
//
//                Section("Добавить трек вручную") {
//                    TextField("Artist", text: $vm.searchArtist)
//                    TextField("Track Title", text: $vm.searchTitle)
//
//                    Button("Искать трек") {
//                        Task { await vm.searchTrack() }
//                    }
//
//                    if let _ = vm.foundTrackURL {
//                        Button("Открыть найденный трек в Safari") {
//                            showSafari = true
//                        }
//                    }
//
//                    if vm.foundTrack != nil {
//                        HStack {
//                            Button("Добавить трек в список") {
//                                vm.addFoundTrack()
//                            }
//                            .foregroundColor(.green)
//
//                            Spacer()
//
//                            Button("Добавить thumbnail в коллаж") {
//                                vm.addThumbnailToCollage()
//                            }
//                            .disabled(vm.coverThumbnailURLs.count >= 4)
//                        }
//                    }
//                }
//
//                Section("Выбранные thumbnail для коллажа (\(vm.coverThumbnailURLs.count)/4)") {
//                    if vm.coverThumbnailURLs.isEmpty {
//                        Text("Пока нет выбранных thumbnail")
//                            .foregroundColor(.secondary)
//                    } else {
//                        ForEach(Array(vm.coverThumbnailURLs.enumerated()), id: \.offset) { idx, url in
//                            Text("\(idx + 1). \(url)")
//                                .font(.caption2)
//                                .lineLimit(1)
//                        }
//                    }
//
//                    if vm.coverThumbnailURLs.count == 4 {
//                        Button("Собрать coverImage 2×2 (Cloud Function)") {
//                            Task { await vm.generateCoverImage() }
//                        }
//                        .foregroundColor(.blue)
//                    }
//                }
//
//                Section("Треки в плейлисте") {
//                    if vm.tracks.isEmpty {
//                        Text("Пока нет треков")
//                            .foregroundColor(.secondary)
//                    } else {
//                        List {
//                            ForEach(vm.tracks.sorted(by: { $0.orderIndex < $1.orderIndex })) { track in
//                                VStack(alignment: .leading, spacing: 6) {
//                                    HStack {
//                                        Text("\(track.orderIndex + 1).")
//                                            .foregroundColor(.secondary)
//
//                                        VStack(alignment: .leading) {
//                                            Text(track.title)
//                                                .font(.subheadline)
//                                                .lineLimit(1)
//
//                                            Text(track.artist)
//                                                .font(.caption)
//                                                .foregroundColor(.secondary)
//                                                .lineLimit(1)
//                                        }
//
//                                        Spacer()
//
//                                        // Показать текущие теги
//                                        if !track.tags.isEmpty {
//                                            Text(track.tags.joined(separator: ", "))
//                                                .font(.caption2)
//                                                .foregroundColor(.blue)
//                                                .lineLimit(1)
//                                        }
//                                    }
//
//                                    // Меню для выбора/снятия тегов
//                                    HStack {
//                                        Text("Теги:")
//                                            .font(.caption2)
//                                            .foregroundColor(.secondary)
//                                        ForEach(vm.availableTags, id: \.self) { tag in
//                                            Button(action: {
//                                                vm.toggleTag(forVideoId: track.videoId, tag: tag)
//                                            }) {
//                                                Text(tag)
//                                                    .font(.caption2)
//                                                    .padding(6)
//                                                    .background(track.tags.contains(tag) ? Color.blue.opacity(0.2) : Color.gray.opacity(0.12))
//                                                    .cornerRadius(6)
//                                            }
//                                        }
//                                    }
//                                }
//                                .padding(.vertical, 6)
//                            }
//                        }
//                        .listStyle(.plain)
//                        .frame(minHeight: 200)
//                    }
//                }
//
//                Section("Сохранение") {
//                    Button("Сохранить плейлист в Firestore (droplist + dropTracks)") {
//                        Task { await vm.savePlaylistToFirestore() }
//                    }
//                    .disabled(vm.playlistImageURL.isEmpty || vm.tracks.isEmpty)
//                    .foregroundColor(.blue)
//                }
//
//                Section("Статус") {
//                    Text(vm.status)
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
//                }
//            }
//            .sheet(isPresented: $showSafari) {
//                if let url = vm.foundTrackURL {
//                    SafariView(url: url)
//                }
//            }
//            .navigationTitle("Admin • Manual Playlist Builder")
//        }
//    }
//}











// MARK: - Cloud Function #1



/**
 * generatePlaylistCover
 * ----------------------
 * Эта Cloud Function принимает:
 *  - playlistId (строка)
 *  - thumbnailURLs (массив из 4 URL)
 *
 * Функция:
 *  1) Скачивает 4 изображения по переданным URL.
 *     Обычно это YouTube thumbnails формата "hqdefault.jpg".
 *
 *     ❗ Размеры YouTube thumbnails:
 *        - default:        120×90
 *        - medium:         320×180
 *        - high (hqdefault): **480×360** ← мы используем именно этот
 *        - standard:       640×480
 *        - maxresdefault:  1280×720 (не всегда доступен!)
 *
 *     В админке мы используем item.snippet.thumbnails.high.url,
 *     поэтому на входе почти всегда получаем **480×360 px**.
 *
 *  2) Каждое изображение приводится к квадрату 720×720 px:
 *        - обрезка по центру (fit: "cover")
 *        - ресайз до 720×720
 *
 *     Почему 720?
 *        - это оптимальный размер для Retina‑дисплеев
 *        - не слишком тяжёлый
 *        - не слишком маленький
 *
 *  3) Собирается коллаж 2×2:
 *        ┌───────────────┬───────────────┐
 *        │ 720×720        │ 720×720        │
 *        ├───────────────┼───────────────┤
 *        │ 720×720        │ 720×720        │
 *        └───────────────┴───────────────┘
 *
 *     Итоговый размер коллажа: **1440×1440 px**
 *
 *  4) Поверх всего коллажа накладывается равномерный
 *     тонирующий слой (чёрный, 15% прозрачности).
 *
 *     Зачем?
 *        - выравнивает контраст между четырьмя картинками
 *        - делает обложку более цельной и премиальной
 *        - смягчает резкие переходы
 *        - улучшает читаемость текста поверх обложки
 *
 *     Это стиль, который используют Spotify / Apple Music.
 *
 *  5) Готовое изображение сохраняется в Firebase Storage:
 *        /covers/{playlistId}.jpg
 *
 *  6) Генерируется публичный signed URL (до 2100 года)
 *
 *  7) Возвращается объект:
 *        { coverImageURL: "https://..." }
 *
 *  ❗ Важно:
 *     Функция НЕ обновляет Firestore.
 *     Это делает админка после получения URL.
 */

//const functions = require("firebase-functions");
//const admin = require("firebase-admin");
//const sharp = require("sharp");
//const fetch = require("node-fetch");
//
//admin.initializeApp();
//const storage = admin.storage();
//
//exports.generatePlaylistCover = functions.https.onCall(async (data, context) => {
//  const playlistId = data.playlistId;
//  const urls = data.thumbnailURLs;
//
//  if (!playlistId || !Array.isArray(urls) || urls.length !== 4) {
//    throw new functions.https.HttpsError(
//      "invalid-argument",
//      "playlistId и ровно 4 thumbnailURLs обязательны"
//    );
//  }
//
//  try {
//    // 1) Скачиваем изображения
//    const buffers = [];
//    for (const url of urls) {
//      const res = await fetch(url);
//      if (!res.ok) throw new Error(`Не удалось скачать thumbnail: ${url}`);
//      const arrayBuffer = await res.arrayBuffer();
//      buffers.push(Buffer.from(arrayBuffer));
//    }
//
//    // 2) Приводим к квадрату 720×720
//    const tileSize = 720;
//    const tiles = [];
//    for (const buf of buffers) {
//      const tile = await sharp(buf)
//        .resize(tileSize, tileSize, { fit: "cover", position: "centre" })
//        .toBuffer();
//      tiles.push(tile);
//    }
//
//    // 3) Собираем 2×2 коллаж 1440×1440
//    const collageWidth = tileSize * 2;
//    const collageHeight = tileSize * 2;
//
//    const base = sharp({
//      create: {
//        width: collageWidth,
//        height: collageHeight,
//        channels: 3,
//        background: { r: 10, g: 10, b: 10 }
//      }
//    });
//
//    const composite = [
//      { input: tiles[0], left: 0, top: 0 },
//      { input: tiles[1], left: tileSize, top: 0 },
//      { input: tiles[2], left: 0, top: tileSize },
//      { input: tiles[3], left: tileSize, top: tileSize }
//    ];
//
//    const collageBuffer = await base
//      .composite(composite)
//      .jpeg({ quality: 85 })
//      .toBuffer();
//
//    // 4) Равномерный тонирующий слой (чёрный 15%)
//    const tintSVG = `
//      <svg width="${collageWidth}" height="${collageHeight}">
//        <rect width="100%" height="100%" fill="black" fill-opacity="0.15"/>
//      </svg>
//    `;
//    const tintBuffer = Buffer.from(tintSVG);
//
//    // 5) Накладываем тонировку поверх коллажа
//    const finalBuffer = await sharp(collageBuffer)
//      .composite([{ input: tintBuffer, blend: "over" }])
//      .jpeg({ quality: 90 })
//      .toBuffer();
//
//    // 6) Сохраняем в Storage
//    const bucket = storage.bucket();
//    const filePath = `covers/${playlistId}.jpg`;
//    const file = bucket.file(filePath);
//
//    await file.save(finalBuffer, {
//      contentType: "image/jpeg",
//      metadata: { cacheControl: "public,max-age=31536000" }
//    });
//
//    // 7) Генерируем публичный URL
//    const [signedUrl] = await file.getSignedUrl({
//      action: "read",
//      expires: "2100-01-01"
//    });
//
//    return { coverImageURL: signedUrl };
//
//  } catch (err) {
//    console.error("generatePlaylistCover error:", err);
//    throw new functions.https.HttpsError("internal", err.message || "Ошибка генерации cover");
//  }
//});
//
































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
