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





/*
==============================================================
ДВА ПОТОКА АВТОРИЗАЦИИ В ПРИЛОЖЕНИИ
==============================================================

1) Firebase Auth Client ID (auto-created)
-----------------------------------------
Используется для:
- входа пользователя через Google
- авторизации Firebase
- получения Firebase credential

Код:
let clientID = FirebaseApp.app()?.options.clientID

Этот Client ID НЕ подходит для YouTube API.

--------------------------------------------------------------

2) YouTube OAuth Client ID (создан вручную)
-------------------------------------------
Используется для:
- YouTube OAuth Scopes
- доступа к YouTube API от имени пользователя
- добавления треков в плейлисты YouTube Music
- получения accessToken + refreshToken

Код:
let config = GIDConfiguration(clientID: "ТВОЙ_НОВЫЙ_CLIENT_ID")

Scopes:
https://www.googleapis.com/auth/youtube
https://www.googleapis.com/auth/youtube.force-ssl

--------------------------------------------------------------

ОБА Client ID МОГУТ ИСПОЛЬЗОВАТЬСЯ ОДНОВРЕМЕННО.
Это нормальная архитектура:
- Firebase Auth → для входа
- YouTube OAuth → для работы с YouTube API

==============================================================
*/







/*
==============================================================
YOUTUBE OAUTH 2.0 — ПОЛНАЯ КОДОВАЯ БАЗА ДЛЯ iOS (Swift)
==============================================================

ЭТОТ КОММЕНТАРИЙ СОДЕРЖИТ:
1) Второй поток авторизации (YouTube OAuth)
2) Получение accessToken / refreshToken
3) Добавление трека в плейлист YouTube Music
4) Объяснение, зачем нужны два Client ID

==============================================================
1. ДВА CLIENT ID — ЗАЧЕМ?
--------------------------------------------------------------
A) Firebase Client ID (auto-created)
   - используется для входа через Google в FirebaseAuth
   - НЕ подходит для YouTube API
   - используется твоим текущим кодом

B) YouTube OAuth Client ID (создан вручную)
   - используется для YouTube OAuth Scopes
   - даёт доступ к YouTube API от имени пользователя
   - нужен для добавления треков в YouTube Music

ОБА Client ID МОГУТ ИСПОЛЬЗОВАТЬСЯ ОДНОВРЕМЕННО.
Это нормальная архитектура.

==============================================================
2. YOUTUBE OAUTH — ВТОРОЙ ПОТОК АВТОРИЗАЦИИ
--------------------------------------------------------------

import GoogleSignIn

final class YouTubeAuthService {

    static let shared = YouTubeAuthService()

    // ВСТАВЬ СВОЙ НОВЫЙ OAuth Client ID
    private let clientID = "YOUR_NEW_OAUTH_CLIENT_ID"

    // Scopes для работы с YouTube API
    private let scopes = [
        "https://www.googleapis.com/auth/youtube",
        "https://www.googleapis.com/auth/youtube.force-ssl"
    ]

    // Авторизация YouTube
    func signInForYouTube(
        presentingVC: UIViewController,
        completion: @escaping (Result<GIDGoogleUser, Error>) -> Void
    ) {
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingVC,
            hint: nil,
            additionalScopes: scopes
        ) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "YouTubeAuth", code: -1)))
                return
            }
            completion(.success(user))
        }
    }
}

==============================================================
3. ПОЛУЧЕНИЕ ACCESS TOKEN / REFRESH TOKEN
--------------------------------------------------------------

YouTubeAuthService.shared.signInForYouTube(presentingVC: vc) { result in
    switch result {
    case .success(let user):
        let accessToken = user.accessToken.tokenString
        let refreshToken = user.refreshToken

        print("YouTube access token:", accessToken)
        print("YouTube refresh token:", refreshToken)

    case .failure(let error):
        print("Error:", error)
    }
}

==============================================================
4. СОЗДАНИЕ ПЛЕЙЛИСТА В YOUTUBE MUSIC
--------------------------------------------------------------

func createPlaylist(accessToken: String, title: String) async throws -> String {
    let url = URL(string: "https://www.googleapis.com/youtube/v3/playlists?part=snippet,status")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "snippet": [
            "title": title,
            "description": "Created from TemplateSwiftUI app"
        ],
        "status": [
            "privacyStatus": "private"
        ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

    return (json["id"] as? String) ?? ""
}

==============================================================
5. ДОБАВЛЕНИЕ ТРЕКА В ПЛЕЙЛИСТ YOUTUBE MUSIC
--------------------------------------------------------------

func addTrackToPlaylist(accessToken: String, playlistId: String, videoId: String) async throws {
    let url = URL(string: "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "snippet": [
            "playlistId": playlistId,
            "resourceId": [
                "kind": "youtube#video",
                "videoId": videoId
            ]
        ]
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let _ = try await URLSession.shared.data(for: request)
}

==============================================================
6. ИТОГ
--------------------------------------------------------------
- Новый OAuth Client ID нужен ТОЛЬКО для YouTube OAuth.
- Для AdminView (парсинг треков) он НЕ нужен.
- Firebase Client ID остаётся для входа в Firebase.
- YouTube OAuth Client ID используется для:
    • signInForYouTube()
    • получения accessToken
    • работы с YouTube API
    • добавления треков в YouTube Music

==============================================================
*/



/*
==============================================================
GOOGLE OAUTH — НАСТРОЙКА AUDIENCE (TEST USERS)
==============================================================

Этот раздел относится к настройке OAuth Consent Screen в Google Cloud.

Ты уже успешно создал:
- OAuth Consent Screen
- OAuth Client ID
- App Branding

Теперь в разделе "Audience" нужно выполнить только одну задачу.

--------------------------------------------------------------
1. ЧТО ТАКОЕ AUDIENCE?
--------------------------------------------------------------
Audience — это список пользователей, которым разрешено
тестировать OAuth авторизацию, пока приложение находится
в статусе "Testing".

Google блокирует доступ всем остальным пользователям,
пока приложение не опубликовано и не прошло верификацию.

--------------------------------------------------------------
2. ЧТО НУЖНО СДЕЛАТЬ?
--------------------------------------------------------------
В разделе:
Google Auth Platform → Audience

Нужно нажать:
+ Add users

И добавить:
- свой Gmail (обязательно)
- любые другие аккаунты, с которых ты будешь тестировать

Пример:
klenovminsk@gmail.com

--------------------------------------------------------------
3. ПОЧЕМУ ЭТО ВАЖНО?
--------------------------------------------------------------
Без добавления Test Users Google НЕ позволит:
- войти через YouTube OAuth
- получить accessToken
- получить refreshToken
- работать с YouTube API от имени пользователя

Ты увидишь ошибку:
"Access blocked: This app is not authorized"

Добавление Test Users решает это.

--------------------------------------------------------------
4. ЧТО НЕ НУЖНО ДЕЛАТЬ?
--------------------------------------------------------------
- НЕ нажимать "Publish app"
- НЕ менять User type
- НЕ проходить Verification
- НЕ добавлять домены

Это всё нужно только для публичных приложений.
Для разработки достаточно режима Testing.

--------------------------------------------------------------
5. ИТОГ
--------------------------------------------------------------
✔ OAuth Consent Screen создан
✔ OAuth Client ID создан
✔ Осталось только добавить Test Users
✔ После этого YouTube OAuth будет работать

==============================================================
*/




/*
==============================================================
GOOGLE OAUTH — YOUTUBE SCOPES (ОБНОВЛЁННАЯ ИНФОРМАЦИЯ)
==============================================================

Google обновил список OAuth‑разрешений для YouTube API.

Раньше требовались два Scopes:
1) .../auth/youtube
2) .../auth/youtube.force-ssl

НО:
- В новом интерфейсе Google Auth Platform
- Scope "youtube.force-ssl" больше НЕ отображается
- Его функциональность объединена в основной Scope "youtube"

--------------------------------------------------------------
ЧТО НУЖНО ВЫБРАТЬ СЕЙЧАС
--------------------------------------------------------------

✔ Обязательно:
https://www.googleapis.com/auth/youtube

Этот Scope даёт:
- управление плейлистами
- добавление треков
- создание плейлистов
- доступ к приватным данным YouTube

✔ Опционально:
https://www.googleapis.com/auth/youtube.readonly

--------------------------------------------------------------
ЧТО НЕ НУЖНО ДЕЛАТЬ
--------------------------------------------------------------

✘ Не искать "youtube.force-ssl" — его больше нет
✘ Не добавлять Scopes вручную через текстовое поле

--------------------------------------------------------------
ИТОГ
--------------------------------------------------------------

Твой OAuth Client ID полностью готов для:
- YouTube OAuth авторизации
- получения accessToken / refreshToken
- работы с YouTube Music API

==============================================================
*/




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



