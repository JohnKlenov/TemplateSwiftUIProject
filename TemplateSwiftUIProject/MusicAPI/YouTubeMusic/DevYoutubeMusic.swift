//
//  DevYoutubeMusic.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 24.03.26.
//




/*
==============================================================
АРХИТЕКТУРА: YouTube Data API + Firestore + SwiftUI
==============================================================

1) YouTube Music API не существует.
Единственный легальный способ получать данные о треках — YouTube Data API v3.

2) Рабочий процесс:
- Разработчик находит трек в YouTube Music.
- Через YouTube Data API получает videoId, title, artist, thumbnails, duration.
- Сохраняет эти данные в Firestore (playlists/{id}/tracks/{id}).
- Клиентское приложение загружает данные из Firestore.
- Для воспроизведения используется YouTube IFrame Player (loadVideoById).

3) SDK:
- FirebaseCore, FirebaseFirestore, FirebaseAuth.
- REST-запросы к YouTube Data API (через URLSession).

4) Firestore хранит:
videoId, title, artist, thumbnail, duration, plays, playlistId.

5) Приложение НЕ обращается к YouTube API напрямую при каждом запуске.
Все данные приходят из Firestore → быстро, стабильно, дешево.

==============================================================
*/



/*
==============================================================
ADMIN-FLOW: КАК МЫ НАПОЛНЯЕМ FIRESTORE ДАННЫМИ ИЗ YOUTUBE
==============================================================

1) Пользовательское приложение НИКОГДА не ходит в YouTube Data API.
Оно читает только из Cloud Firestore.

2) Данные (videoId, title, artist, thumbnail, duration и т.д.)
в Firestore наполняет РАЗРАБОТЧИК через отдельный admin-flow:

- Разработчик вводит название трека/артиста.
- Admin-инструмент делает запрос к YouTube Data API (search + videos).
- Получает videoId и метаданные.
- Сохраняет документ в Firestore:
  playlists/{playlistId}/tracks/{trackId}.

3) Admin-инструмент может быть:
- отдельным macOS/CLI-проектом,
- скриптом (Node/Python),
- временным скрытым экраном внутри iOS-приложения (только для разработчика).

4) Продакшен-приложение:
- загружает треки из Firestore,
- отображает их во view,
- передаёт videoId в YouTube IFrame Player для воспроизведения.

==============================================================
*/








/*
==============================================================
ADMIN-FLOW: МИНИ-ИНСТРУМЕНТ ВНУТРИ iOS-ПРИЛОЖЕНИЯ
YouTube Data API v3 → Firestore
==============================================================

ЭТОТ КОММЕНТАРИЙ СОДЕРЖИТ ВСЮ БАЗОВУЮ КОДОВУЮ СХЕМУ:
- Модель трека для Firestore/UI
- Модели для парсинга YouTube JSON
- Клиент YouTube Data API (search + videos)
- ViewModel admin-экрана (YouTube + Firestore)
- Пример SwiftUI-экрана AdminView

Ты можешь:
- Вынести каждый блок в свой файл,
- Или временно положить всё в один файл и раскидать позже.

==============================================================
1. МОДЕЛЬ ТРЕКА ДЛЯ FIRESTORE / UI
==============================================================

struct TrackMetadata: Identifiable, Codable {
    var id: String { videoId }

    let videoId: String
    let title: String
    let artist: String
    let thumbnailURL: String
    let durationISO8601: String
}

==============================================================
2. МОДЕЛИ ДЛЯ ПАРСИНГА ОТВЕТОВ YOUTUBE DATA API
==============================================================

struct YouTubeSearchResponse: Decodable {
    struct Item: Decodable {
        struct Id: Decodable {
            let videoId: String?
        }
        struct Snippet: Decodable {
            let title: String
            let channelTitle: String
            struct Thumbnails: Decodable {
                struct Thumb: Decodable {
                    let url: String
                }
                let high: Thumb
            }
            let thumbnails: Thumbnails
        }
        let id: Id
        let snippet: Snippet
    }
    let items: [Item]
}

struct YouTubeVideosResponse: Decodable {
    struct Item: Decodable {
        struct ContentDetails: Decodable {
            let duration: String // ISO8601, например "PT1M57S"
        }
        let id: String
        let contentDetails: ContentDetails
    }
    let items: [Item]
}

==============================================================
3. КЛИЕНТ YOUTUBE DATA API (SEARCH + VIDEOS)
==============================================================

final class YouTubeAPIClient {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // Ищем первое видео по запросу (артист + трек)
    func searchFirstVideo(query: String) async throws -> (videoId: String, title: String, channelTitle: String, thumbnailURL: String) {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&maxResults=1&q=\(q)&key=\(apiKey)"
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
        guard let item = response.items.first,
              let videoId = item.id.videoId else {
            throw NSError(domain: "YouTubeAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Видео не найдено"])
        }
        return (
            videoId: videoId,
            title: item.snippet.title,
            channelTitle: item.snippet.channelTitle,
            thumbnailURL: item.snippet.thumbnails.high.url
        )
    }

    // Получаем длительность видео
    func fetchDuration(videoId: String) async throws -> String {
        let urlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails&id=\(videoId)&key=\(apiKey)"
        let url = URL(string: urlString)!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(YouTubeVideosResponse.self, from: data)
        guard let item = response.items.first else {
            throw NSError(domain: "YouTubeAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "Длительность не найдена"])
        }
        return item.contentDetails.duration
    }
}

==============================================================
4. VIEWMODEL ADMIN-ЭКРАНА (YOUTUBE → FIRESTORE)
==============================================================

import FirebaseFirestore

@MainActor
final class AdminViewModel: ObservableObject {
    @Published var artist: String = ""
    @Published var trackTitle: String = ""
    @Published var playlistId: String = ""
    @Published var status: String = ""

    private let api: YouTubeAPIClient
    private let db = Firestore.firestore()

    init(apiKey: String) {
        self.api = YouTubeAPIClient(apiKey: apiKey)
    }

    func fetchAndSaveTrack() async {
        status = "Ищем трек в YouTube…"
        do {
            let query = "\(artist) \(trackTitle)"
            let searchResult = try await api.searchFirstVideo(query: query)
            let duration = try await api.fetchDuration(videoId: searchResult.videoId)

            let track = TrackMetadata(
                videoId: searchResult.videoId,
                title: searchResult.title,
                artist: searchResult.channelTitle, // или artist, если хочешь своё поле
                thumbnailURL: searchResult.thumbnailURL,
                durationISO8601: duration
            )

            try await saveTrackToFirestore(track: track)
            status = "Успех: трек сохранён в Firestore"
        } catch {
            status = "Ошибка: \(error.localizedDescription)"
        }
    }

    private func saveTrackToFirestore(track: TrackMetadata) async throws {
        guard !playlistId.isEmpty else {
            throw NSError(domain: "Admin", code: 3, userInfo: [NSLocalizedDescriptionKey: "playlistId пуст"])
        }

        let docRef = db
            .collection("playlists")
            .document(playlistId)
            .collection("tracks")
            .document(track.videoId)

        try await docRef.setData([
            "videoId": track.videoId,
            "title": track.title,
            "artist": track.artist,
            "thumbnailURL": track.thumbnailURL,
            "durationISO8601": track.durationISO8601
        ], merge: true)
    }
}

==============================================================
5. ВРЕМЕННЫЙ ADMIN-ЭКРАН В SWIFTUI
==============================================================

import SwiftUI

struct AdminView: View {
    @StateObject private var vm = AdminViewModel(apiKey: "YOUR_API_KEY_HERE")

    var body: some View {
        NavigationView {
            Form {
                Section("Плейлист") {
                    TextField("playlistId (например narcos)", text: $vm.playlistId)
                }

                Section("Трек") {
                    TextField("Артист", text: $vm.artist)
                    TextField("Название трека", text: $vm.trackTitle)
                }

                Section {
                    Button("Найти в YouTube и сохранить в Firestore") {
                        Task {
                            await vm.fetchAndSaveTrack()
                        }
                    }
                }

                Section("Статус") {
                    Text(vm.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
            .navigationTitle("Admin • YouTube → Firestore")
        }
    }
}

==============================================================
6. КРАТКОЕ ОБЪЯСНЕНИЕ FLOW
==============================================================

- Ты (как разработчик) открываешь AdminView (например, только в Debug).
- Вводишь:
  - playlistId (идентификатор плейлиста в Firestore),
  - артиста,
  - название трека.
- Нажимаешь кнопку:
  - делается запрос к YouTube Data API (search),
  - берётся первое видео, вытаскивается videoId, title, channelTitle, thumbnail,
  - вторым запросом берётся duration (videos),
  - всё это сохраняется в Firestore в:
    playlists/{playlistId}/tracks/{videoId}.

Пользовательское приложение потом:
- читает данные только из Firestore,
- показывает их во view,
- передаёт videoId в YouTube IFrame Player для воспроизведения.

==============================================================
КОНЕЦ БАЗОВОЙ КОДОВОЙ СХЕМЫ ДЛЯ ADMIN-FLOW
==============================================================
*/







/*
==============================================================
НАСТРОЙКА GOOGLE CLOUD ДЛЯ YOUTUBE DATA API + OAUTH + FIRESTORE
Полная выжимка для Xcode
==============================================================

ЭТА ВЫЖИМКА — ПОЛНЫЙ РОУДМАП НАСТРОЙКИ ПРОЕКТА В GOOGLE CLOUD,
НЕОБХОДИМЫЙ ДЛЯ РАБОТЫ С YOUTUBE DATA API, FIRESTORE И OAUTH 2.0.

==============================================================
1. СОЗДАНИЕ ПРОЕКТА (ГОТОВО)
--------------------------------------------------------------
Ты уже создал проект:
TemplateSwiftUI

Ничего больше делать не нужно.

==============================================================
2. ВКЛЮЧЕНИЕ YOUTUBE DATA API v3
--------------------------------------------------------------
Google Cloud Console →
APIs & Services → Library →
YouTube Data API v3 → ENABLE

Это включает доступ к:
- search (поиск видео)
- videos (метаданные, длительность)
- playlists (если понадобится)
- channels (если понадобится)

==============================================================
3. СОЗДАНИЕ API KEY (ДЛЯ ЗАПРОСОВ К YOUTUBE DATA API)
--------------------------------------------------------------
APIs & Services → Credentials →
Create Credentials → API Key

ОБЯЗАТЕЛЬНО:
- открыть API Key → Edit
- включить Restrict Key
- выбрать YouTube Data API v3

API Key используется ТОЛЬКО для:
- поиска треков
- получения videoId
- получения метаданных

==============================================================
4. НАСТРОЙКА OAUTH CONSENT SCREEN (ОБЯЗАТЕЛЬНО)
--------------------------------------------------------------
APIs & Services → OAuth consent screen →
Тип: External

Заполнить:
- App name
- User support email
- Developer contact email

Scopes пока можно не добавлять (добавим позже).

Сохранить.

==============================================================
5. СОЗДАНИЕ OAUTH 2.0 CLIENT ID (ДЛЯ АВТОРИЗАЦИИ ПОЛЬЗОВАТЕЛЯ)
--------------------------------------------------------------
APIs & Services → Credentials →
Create Credentials → OAuth Client ID →
Тип: iOS

Указать:
- Bundle ID приложения (например: com.evgeny.TemplateSwiftUI)

После создания получаем:
- Client ID (нужен в Xcode)
- Client Secret (для iOS не используется)

OAuth нужен для:
- входа пользователя через Google
- доступа к его YouTube аккаунту
- добавления треков в его плейлисты (если он разрешит)

==============================================================
6. ДОБАВЛЕНИЕ YOUTUBE SCOPES ДЛЯ OAUTH
--------------------------------------------------------------
OAuth consent screen → Scopes →
Add or Remove Scopes →

Добавить:
https://www.googleapis.com/auth/youtube
https://www.googleapis.com/auth/youtube.force-ssl

Эти Scopes дают доступ к:
- чтению/созданию плейлистов пользователя
- добавлению треков в плейлисты
- управлению YouTube-аккаунтом (в рамках разрешений)

==============================================================
7. НАСТРОЙКА FIRESTORE
--------------------------------------------------------------
Firestore Database → Create database →
Production mode → выбрать регион.

Создать коллекции:
playlists
users
tracks (вложенные)

Пример структуры:
playlists/{playlistId}/tracks/{videoId}

==============================================================
8. НАСТРОЙКА FIREBASE В XCODE
--------------------------------------------------------------
Swift Package Manager →
добавить Firebase SDK:
- FirebaseCore
- FirebaseFirestore
- FirebaseAuth

В AppDelegate:
FirebaseApp.configure()

==============================================================
9. ИТОГОВАЯ АРХИТЕКТУРА
--------------------------------------------------------------
1) Разработчик через admin-flow получает данные из YouTube Data API.
2) Сохраняет их в Firestore.
3) Клиентское приложение читает данные из Firestore.
4) Для воспроизведения передаёт videoId в YouTube IFrame Player.
5) Пользователь может авторизоваться через OAuth и добавлять треки
   в свои YouTube плейлисты (через YouTube API + OAuth Scopes).

==============================================================
ГОТОВО: ПРОЕКТ ПОЛНОСТЬЮ НАСТРОЕН ДЛЯ РАБОТЫ С YOUTUBE + FIREBASE
==============================================================
*/
