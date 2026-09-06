//
//  SafariPlayerView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.09.2026.
//


// ============================================================
// 🎵 YOUTUBE TRACK PLAYBACK
// ============================================================
//
// Для воспроизведения YouTube-треков мы рассматривали:
//
// 1. WKWebView + YouTube /embed/
// 2. YouTube IFrame Player API
// 3. YouTube iOS Player SDK
// 4. YouTubePlayerKit
// 5. Deep Link → YouTube App
// 6. SFSafariViewController + обычный /watch URL
//
//
// ------------------------------------------------------------
// 1. WKWebView + /embed/
// ------------------------------------------------------------
//
//     WKWebView
//         ↓
//     youtube.com/embed/{videoId}
//
// Полный контроль над UI.
//
// НО:
// - YouTube сам решает, разрешено ли embedded playback.
// - Некоторые видео запрещены для embedding.
// - Может появиться:
//       "Sign in to confirm you're not a bot"
// - Авторизация внутри нашего WKWebView может не работать.
// - Самостоятельная установка Referer не гарантирует решение.
//
// ❌ Не гарантирует воспроизведение.
//
//
// ------------------------------------------------------------
// 2. YouTube IFrame Player API
// ------------------------------------------------------------
//
// Официальный API YouTube для управления embedded player.
//
// Даёт:
// - Play / Pause
// - Seek
// - состояние playback
// - fullscreen
// - события player
// - управление параметрами.
//
// НО:
// API всё равно работает как EMBEDDED YouTube PLAYER.
//
// Поэтому сохраняются ограничения YouTube:
// - video может быть запрещено для embedding;
// - может потребоваться дополнительная проверка;
// - YouTube может отказать embedded player.
//
// ❌ Не гарантирует воспроизведение.
//
//
// ------------------------------------------------------------
// 3. YouTube iOS Player SDK
// ------------------------------------------------------------
//
// Нативная iOS-обёртка вокруг YouTube embedded player.
//
// Лучше самописного WKWebView,
// но всё равно зависит от embedded playback.
//
// Дополнительно официальный youtube-ios-player-helper
// больше не является хорошей основой для нового проекта.
//
// ⚠️ Не гарантирует воспроизведение.
//
//
// ------------------------------------------------------------
// 4. YouTubePlayerKit
// ------------------------------------------------------------
//
// Современная Swift Package обёртка над YouTube
// IFrame Player API.
//
// Даёт намного более удобную интеграцию:
//
//     SwiftUI
//        ↓
//     YouTubePlayerKit
//        ↓
//     YouTube IFrame API
//
// Плюсы:
// - готовый SwiftUI YouTubePlayerView;
// - async/await API;
// - Play / Pause / Seek;
// - playback state;
// - fullscreen;
// - события;
// - обработка ошибок;
// - управление параметрами player;
// - намного меньше собственного WebKit-кода.
//
// ВАЖНО:
// YouTubePlayerKit всё равно использует
// YouTube IFrame / embedded player.
//
// Поэтому он НЕ гарантирует воспроизведение всех видео
// и теоретически может столкнуться с той же
// YouTube anti-bot / embedded restriction проблемой.
//
// ⭐ Лучший вариант для КАЧЕСТВЕННОГО EMBEDDED PLAYER.
//
// ❌ Но не 100% гарантия.
//
//
// ------------------------------------------------------------
// 5. Deep Link → YouTube App
// ------------------------------------------------------------
//
//     youtube://watch?v={videoId}
//
// Если установлен YouTube App,
// видео открывается непосредственно в нём.
//
// ✅ Очень высокая надежность.
//
// НО:
// ❌ пользователь покидает наше приложение.
// ❌ мы не контролируем UI YouTube.
//
// Используем только как дополнительный вариант,
// если пользователь явно хочет открыть YouTube.
//
//
// ------------------------------------------------------------
// 6. SFSafariViewController + /watch
// ------------------------------------------------------------
//
//     SFSafariViewController
//             ↓
//     https://www.youtube.com/watch?v={videoId}
//
// Это выбранный НАДЁЖНЫЙ вариант для нашего приложения.
//
// В отличие от /embed:
// мы открываем обычную YouTube web-страницу,
// а не embedded player.
//
// SFSafariViewController предоставляет системный
// Safari web-контекст внутри нашего приложения.
//
// Поэтому YouTube получает нормальный web-сценарий:
//
//     youtube.com/watch
//
// вместо:
//
//     youtube.com/embed
//
// Плюсы:
// - остаёмся внутри нашего приложения;
// - обычный YouTube watch URL;
// - намного выше совместимость;
// - пользователь может взаимодействовать
//   с обычной YouTube web-страницей;
// - при необходимости пользователь может
//   авторизоваться в YouTube прямо внутри Safari View;
// - не нужно самостоятельно управлять WKWebView;
// - не нужно вручную создавать Referer;
// - не нужно самостоятельно реализовывать YouTube IFrame API.
//
// ВАЖНО:
// SFSafariViewController тоже НЕ даёт абсолютной гарантии.
//
// Видео всё равно может быть недоступно, если:
//
// - видео удалено;
// - видео private;
// - видео запрещено в регионе;
// - требуется возрастная авторизация;
// - видео недоступно конкретному пользователю;
// - YouTube временно требует дополнительную проверку;
// - YouTube блокирует доступ по другой причине.
//
// Если YouTube покажет обычную страницу авторизации,
// пользователь может взаимодействовать с ней внутри
// SFSafariViewController.
//
// Но нельзя гарантировать, что любой anti-bot challenge
// YouTube обязательно будет успешно пройден.
//
//
// ============================================================
// 🏆 ТЕКУЩАЯ АРХИТЕКТУРА
// ============================================================
//
// ОСНОВНОЙ ВАРИАНТ:
//
//     Track
//       ↓
//     TracklistContentView
//       ↓
//     selectedTrack
//       ↓
//     .sheet
//       ↓
//     SafariPlayerView
//       ↓
//     SFSafariViewController
//       ↓
//     youtube.com/watch?v={videoId}
//
//
// EMBEDDED ВАРИАНТ ДЛЯ ТЕСТИРОВАНИЯ:
//
//     Track
//       ↓
//     YouTubePlayerKit
//       ↓
//     YouTube IFrame Player API
//
// YouTubePlayerKit лучше нашего самописного WKWebView,
// но он не является гарантированным решением
// YouTube embedded / anti-bot ограничений.
//
// Поэтому SFSafariViewController остаётся нашим
// надёжным fallback / основным вариантом.
//
//
// ============================================================
// 🎬 SHEET PRESENTATION
// ============================================================
//
// Используем:
//
//     .presentationDetents([.medium, .large])
//
// Это настройка SwiftUI Sheet,
// а НЕ настройка Safari.
//
// .medium:
// - Sheet открывается снизу примерно на среднюю высоту.
//
// .large:
// - Sheet можно развернуть практически на весь экран.
//
// Поэтому:
//
//     [.medium, .large]
//
// даёт нужный нам UX:
//
//     Tracklist
//         ↓
//     Player появляется снизу
//         ↓
//     пользователь видит часть Tracklist
//         ↓
//     Sheet можно потянуть вверх
//         ↓
//     Player становится большим.
//
// БЕЗ presentationDetents мы получаем другое
// стандартное поведение модального представления,
// которое нам визуально не подходит.
//
// Поэтому:
//
//     .presentationDetents([.medium, .large])
//
// ОСТАВЛЯЕМ ОБЯЗАТЕЛЬНО.
//
// Дополнительно доступны, например:
//
//     .presentationDetents([.large])
//     .presentationDetents([.medium])
//     .presentationDetents([.height(300), .large])
//     .presentationDetents([.fraction(0.4), .large])
//
// Также можно управлять индикатором:
//
//     .presentationDragIndicator(.visible)
//
//
//
// ============================================================
// 🧩 PlayerViews WRAPPER
// ============================================================
//
// Дополнительная обёртка:
//
//     PlayerViews
//         ↓
//     SafariPlayerView
//
// сейчас НЕ нужна.
//
// Используем напрямую:
//
//     SafariPlayerView(videoId: track.id)
//
// PlayerViews имеет смысл только если в будущем
// появится единая точка выбора разных player:
//
//     PlayerViews
//         ↓
//     YouTubePlayer
//     LocalPlayer
//     SpotifyPlayer
//
// Сейчас это лишний уровень абстракции.
//
// ============================================================




import SwiftUI
import SafariServices

struct SafariPlayerView: UIViewControllerRepresentable {

    let videoId: String

    func makeUIViewController(
        context: Context
    ) -> SFSafariViewController {

        let url = URL(
            string: "https://www.youtube.com/watch?v=\(videoId)"
        )!

        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false
        configuration.barCollapsingEnabled = true

        let controller = SFSafariViewController(
            url: url,
            configuration: configuration
        )

        controller.dismissButtonStyle = .close

        return controller
    }

    func updateUIViewController(
        _ uiViewController: SFSafariViewController,
        context: Context
    ) {}
}



struct PlayerViews: View {
    let videoId: String

    var body: some View {
        SafariPlayerView(videoId: videoId)
    }
}



// deeplink
struct YouTubeAppPlayer {
    static func open(videoId: String) {
        let appURL = URL(string: "youtube://\(videoId)")!
        let webURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!

        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}



//            PlayerViews(videoId: track.id)
//                    .presentationDetents([.medium, .large])
//            YouTubePlayerView(videoId: track.id)
//                .edgesIgnoringSafeArea(.all)
