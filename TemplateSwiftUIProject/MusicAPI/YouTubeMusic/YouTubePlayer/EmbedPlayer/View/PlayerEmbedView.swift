//
//  PlayerEmbedView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.04.26.
//




//  Главный экран плеера с видео и плейлистом (кнопка Play по центру)


//┌─────────────────────────────────┐
//│                                 │
//│                                 │
//│       Kodak Black - Keys...     │  ← По центру (25% экрана)
//│       Kodak Black               │
//│                                 │
//│                                 │
//├─────────────────────────────────┤
//│                                 │
//│        Видео (280pt)            │
//│        [▶] кнопка Play          │
//│                                 │
//├─────────────────────────────────┤
//│  Плейлист           7 треков    │
//├─────────────────────────────────┤
//│  • Трек 1                       │
//│  • Трек 2                       │  ← Занимает всё оставшееся место
//│  • Трек 3                       │     (показывает максимум треков)
//│  • Трек 4                       │
//│  • Трек 5                       │
//│  • ...                          │
//└─────────────────────────────────┘



import SwiftUI


struct PlayerEmbedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerVM: PlayerViewModel

    let tracks: [Track]
    let initialTrack: Track

    init(tracks: [Track], initialTrack: Track) {
        self.tracks = tracks
        self.initialTrack = initialTrack
        _playerVM = StateObject(
            wrappedValue: PlayerViewModel(
                tracks: tracks,
                initialTrack: initialTrack
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Верхний блок
                VStack(spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    Spacer(minLength: 0)

                    VStack(spacing: 8) {
                        Text(playerVM.currentTrack.title)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        Text(playerVM.currentTrack.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)

                    Spacer(minLength: 0)
                }
//                .frame(height: geometry.size.height * 0.25)
                .frame(height: geometry.size.height * 0.30) // ← НОВОЕ ЗНАЧЕНИЕ

                // Видео
                EmbedPlayer(videoId: playerVM.currentTrack.videoId)
                    .frame(height: 280)
                    .background(Color.black)
                    .cornerRadius(12)
                    .padding(.horizontal, 8)

                // Плейлист
                VStack(spacing: 0) {
                    HStack {
                        Text("Плейлист")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(playerVM.tracks.count) треков")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(playerVM.tracks) { track in
                                PlaylistTrackRow(
                                    track: track,
                                    isCurrentlyPlaying: playerVM.currentTrack.id == track.id
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        playerVM.selectTrack(track)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground).ignoresSafeArea())
        }
    }
}


//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        GeometryReader { geometry in
//            VStack(spacing: 0) {
//                // Верхний блок: пустота + информация по центру
//                VStack(spacing: 0) {
//                    Spacer(minLength: 0)
//                    
//                    VStack(spacing: 8) {
//                        Text(playerVM.currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                            .foregroundColor(.primary)
//                        
//                        Text(playerVM.currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    
//                    Spacer(minLength: 0)
//                }
//                .frame(height: geometry.size.height * 0.25)
//                
//                // Видео плеер
//                EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                    .frame(height: 280)
//                    .background(Color.black)
//                    .cornerRadius(12)
//                    .padding(.horizontal, 8)
//                
//                // Плейлист
//                VStack(spacing: 0) {
//                    HStack {
//                        Text("Плейлист")
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                        
//                        Spacer()
//                        
//                        Text("\(playerVM.tracks.count) треков")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.top, 16)
//                    .padding(.bottom, 8)
//                    
//                    ScrollView {
//                        LazyVStack(spacing: 4) {
//                            ForEach(playerVM.tracks) { track in
//                                PlaylistTrackRow(
//                                    track: track,
//                                    isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                ) {
//                                    withAnimation(.easeInOut(duration: 0.2)) {
//                                        playerVM.selectTrack(track)
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.vertical, 8)
//                    }
//                }
//                .frame(maxHeight: .infinity)
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(Color(.systemBackground)) // ✅ Только один .systemBackground
//        }
//        // ✅ Убрали лишние модификаторы:
//        // - presentationDragIndicator (не нужен для fullScreenCover)
//        // - presentationDetents (не нужен для fullScreenCover)
//        // - лишний .background
//    }
//}










//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    @Environment(\.colorScheme) private var colorScheme
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        GeometryReader { geometry in
//            VStack(spacing: 0) {
//                // Верхний блок: пустота + информация по центру
//                VStack(spacing: 0) {
//                    Spacer(minLength: 0)
//                    
//                    VStack(spacing: 8) {
//                        Text(playerVM.currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                            .foregroundColor(.primary)
//                        
//                        Text(playerVM.currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    
//                    Spacer(minLength: 0)
//                }
//                .frame(height: geometry.size.height * 0.25)
//                
//                // Видео плеер
//                EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                    .frame(height: 280)
//                    .background(Color.black)
//                    .cornerRadius(12)
//                    .padding(.horizontal, 8)
//                
//                // Плейлист
//                VStack(spacing: 0) {
//                    HStack {
//                        Text("Плейлист")
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                        
//                        Spacer()
//                        
//                        Text("\(playerVM.tracks.count) треков")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.top, 16)
//                    .padding(.bottom, 8)
//                    
//                    ScrollView {
//                        LazyVStack(spacing: 4) {
//                            ForEach(playerVM.tracks) { track in
//                                PlaylistTrackRow(
//                                    track: track,
//                                    isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                ) {
//                                    withAnimation(.easeInOut(duration: 0.2)) {
//                                        playerVM.selectTrack(track)
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.vertical, 8)
//                    }
//                }
//                .frame(maxHeight: .infinity)
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(Color(.systemBackground)) // Системный фон
//        }
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//        .background(Color(.systemBackground)) // Дополнительный фон для модального окна
//    }
//}


//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    @Environment(\.colorScheme) private var colorScheme
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        // ✅ Используем NavigationStack вместо NavigationView (iOS 16+)
//        NavigationStack {
//            GeometryReader { geometry in
//                VStack(spacing: 0) {
//                    // Верхний блок: пустота + информация по центру
//                    VStack(spacing: 0) {
//                        Spacer(minLength: 0)
//                        
//                        VStack(spacing: 8) {
//                            Text(playerVM.currentTrack.title)
//                                .font(.title3)
//                                .fontWeight(.semibold)
//                                .multilineTextAlignment(.center)
//                                .lineLimit(2)
//                                .foregroundColor(.primary)
//                            
//                            Text(playerVM.currentTrack.artist)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        
//                        Spacer(minLength: 0)
//                    }
//                    .frame(height: geometry.size.height * 0.25)
//                    
//                    // Видео плеер
//                    EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 8)
//                    
//                    // Плейлист
//                    VStack(spacing: 0) {
//                        HStack {
//                            Text("Плейлист")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                            
//                            Spacer()
//                            
//                            Text("\(playerVM.tracks.count) треков")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//                        .padding(.bottom, 8)
//                        
//                        ScrollView {
//                            LazyVStack(spacing: 4) {
//                                ForEach(playerVM.tracks) { track in
//                                    PlaylistTrackRow(
//                                        track: track,
//                                        isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                    ) {
//                                        withAnimation(.easeInOut(duration: 0.2)) {
//                                            playerVM.selectTrack(track)
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                    }
//                    .frame(maxHeight: .infinity)
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color(.systemBackground))
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//            // Принудительно устанавливаем фон для навигационного бара
//            configureNavigationBarBackground()
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//    
//    private func configureNavigationBarBackground() {
//        // Настройка внешнего вида навигационного бара
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = UIColor.systemBackground
//        appearance.shadowColor = .clear
//        
//        UINavigationBar.appearance().standardAppearance = appearance
//        UINavigationBar.appearance().scrollEdgeAppearance = appearance
//    }
//}

//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    @Environment(\.colorScheme) private var colorScheme
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometry in
//                VStack(spacing: 0) {
//                    // Верхний блок: пустота + информация по центру
//                    VStack(spacing: 0) {
//                        Spacer(minLength: 0)
//                        
//                        // Информация о треке
//                        VStack(spacing: 8) {
//                            Text(playerVM.currentTrack.title)
//                                .font(.title3)
//                                .fontWeight(.semibold)
//                                .multilineTextAlignment(.center)
//                                .lineLimit(2)
//                                .foregroundColor(.primary) // системный цвет текста
//                            
//                            Text(playerVM.currentTrack.artist)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary) // системный вторичный цвет
//                        }
//                        .padding(.horizontal, 16)
//                        
//                        Spacer(minLength: 0)
//                    }
//                    .frame(height: geometry.size.height * 0.25)
//                    
//                    // Видео плеер
//                    EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 8)
//                    
//                    // Плейлист
//                    VStack(spacing: 0) {
//                        // Заголовок плейлиста
//                        HStack {
//                            Text("Плейлист")
//                                .font(.headline)
//                                .foregroundColor(.secondary) // системный вторичный цвет
//                            
//                            Spacer()
//                            
//                            Text("\(playerVM.tracks.count) треков")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//                        .padding(.bottom, 8)
//                        
//                        // Список треков
//                        ScrollView {
//                            LazyVStack(spacing: 4) {
//                                ForEach(playerVM.tracks) { track in
//                                    PlaylistTrackRow(
//                                        track: track,
//                                        isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                    ) {
//                                        withAnimation(.easeInOut(duration: 0.2)) {
//                                            playerVM.selectTrack(track)
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                    }
//                    .frame(maxHeight: .infinity)
//                }
//                .background(
//                    // ✅ Системный фон (адаптируется под тему)
//                    Color(.systemBackground)
//                        .ignoresSafeArea()
//                )
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//}








//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    @Environment(\.colorScheme) private var colorScheme
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometry in
//                VStack(spacing: 0) {
//                    // ✅ ВЕРХНИЙ БЛОК: пустота + информация по центру
//                    VStack(spacing: 0) {
//                        Spacer(minLength: 0)
//                        
//                        // Информация о треке (по центру вертикально)
//                        VStack(spacing: 8) {
//                            Text(playerVM.currentTrack.title)
//                                .font(.title3)
//                                .fontWeight(.semibold)
//                                .multilineTextAlignment(.center)
//                                .lineLimit(2)
//                            
//                            Text(playerVM.currentTrack.artist)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        
//                        Spacer(minLength: 0)
//                    }
//                    .frame(height: geometry.size.height * 0.25) // 25% экрана под информацию + пустоту
//                    
//                    // Видео плеер
//                    EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 8)
//                    
//                    // Плейлист (прижат к низу, на всю оставшуюся высоту)
//                    VStack(spacing: 0) {
//                        // Заголовок плейлиста
//                        HStack {
//                            Text("Плейлист")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                            
//                            Spacer()
//                            
//                            Text("\(playerVM.tracks.count) треков")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//                        .padding(.bottom, 8)
//                        
//                        // Список треков (занимает всё доступное место)
//                        ScrollView {
//                            LazyVStack(spacing: 4) {
//                                ForEach(playerVM.tracks) { track in
//                                    PlaylistTrackRow(
//                                        track: track,
//                                        isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                    ) {
//                                        withAnimation(.easeInOut(duration: 0.2)) {
//                                            playerVM.selectTrack(track)
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                    }
//                    .frame(maxHeight: .infinity) // Растягивается на всю оставшуюся высоту
//                }
//                .background(
//                    // Динамический фон (меняется при смене темы)
//                    Color(.systemBackground)
//                        .ignoresSafeArea()
//                )
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//}








//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometry in
//                VStack(spacing: 0) {
//                    // ✅ ВЕРХНЯЯ ПУСТОТА + ИНФОРМАЦИЯ О ТРЕКЕ
//                    VStack(spacing: 12) {
//                        // Пустота (смещает контент вниз)
//                        Spacer()
//                            .frame(height: geometry.size.height * 0.12)
//                        
//                        // Информация о текущем треке (теперь здесь)
//                        VStack(spacing: 8) {
//                            Text(playerVM.currentTrack.title)
//                                .font(.title3)
//                                .fontWeight(.semibold)
//                                .multilineTextAlignment(.center)
//                                .lineLimit(2)
//                            
//                            Text(playerVM.currentTrack.artist)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        
//                        Spacer()
//                            .frame(height: 8)
//                    }
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                    
//                    // Видео плеер
//                    EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 8)
//                    
//                    // Плейлист (сразу под видео)
//                    VStack(spacing: 0) {
//                        // Заголовок плейлиста (без Divider)
//                        HStack {
//                            Text("Плейлист")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                            
//                            Spacer()
//                            
//                            Text("\(playerVM.tracks.count) треков")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 16)
//                        .padding(.bottom, 8)
//                        
//                        // Список треков
//                        ScrollView {
//                            LazyVStack(spacing: 4) {
//                                ForEach(playerVM.tracks) { track in
//                                    PlaylistTrackRow(
//                                        track: track,
//                                        isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                    ) {
//                                        withAnimation(.easeInOut(duration: 0.2)) {
//                                            playerVM.selectTrack(track)
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                        .frame(height: calculatePlaylistHeight(for: playerVM.tracks.count))
//                    }
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//    
//    // MARK: - Helper
//    private func calculatePlaylistHeight(for trackCount: Int) -> CGFloat {
//        let rowsToShow = min(trackCount, 3)
//        let rowHeight: CGFloat = 68
//        return CGFloat(rowsToShow) * rowHeight
//    }
//}








//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometry in
//                VStack(spacing: 0) {
//                    // ✅ ВСЯ ПУСТОТА СВЕРХУ (смещает видео вниз)
//                    // Здесь будет всё свободное пространство
//                    Spacer()
//                        .frame(height: geometry.size.height * 0.2) // 20% от высоты экрана
//                    
//                    // Видео плеер
//                    EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 8)
//                    
//                    // Информация о текущем треке
//                    VStack(spacing: 8) {
//                        Text(playerVM.currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                        
//                        Text(playerVM.currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                    
//                    // ❌ УБРАЛИ ГИБКИЙ SPACER
//                    // Теперь плейлист идёт сразу после информации о треке
//                    
//                    Divider()
//                        .padding(.horizontal, 16)
//                    
//                    // Заголовок плейлиста
//                    HStack {
//                        Text("Плейлист")
//                            .font(.headline)
//                            .foregroundColor(.secondary)
//                        
//                        Spacer()
//                        
//                        Text("\(playerVM.tracks.count) треков")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.top, 12)
//                    .padding(.bottom, 8)
//                    
//                    // Список треков
//                    ScrollView {
//                        LazyVStack(spacing: 4) {
//                            ForEach(playerVM.tracks) { track in
//                                PlaylistTrackRow(
//                                    track: track,
//                                    isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                ) {
//                                    withAnimation(.easeInOut(duration: 0.2)) {
//                                        playerVM.selectTrack(track)
//                                    }
//                                }
//                            }
//                        }
//                        .padding(.vertical, 8)
//                    }
//                    .frame(height: calculatePlaylistHeight(for: playerVM.tracks.count))
//                    
//                    // Небольшой отступ снизу для красоты
//                    Spacer()
//                        .frame(height: 8)
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//    
//    // MARK: - Helper
//    private func calculatePlaylistHeight(for trackCount: Int) -> CGFloat {
//        let rowsToShow = min(trackCount, 3)
//        let rowHeight: CGFloat = 68
//        return CGFloat(rowsToShow) * rowHeight
//    }
//}



//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            GeometryReader { geometry in
//                VStack(spacing: 0) {
//                    // ✅ ВЕРХНЯЯ ПУСТОТА (смещает видео вниз, чтобы кнопка Play была по центру)
//                    Spacer()
//                        .frame(height: geometry.size.height * 0.12) // 12% от высоты экрана
//                    
//                    // Видео плеер
//                    EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .cornerRadius(12)
//                        .padding(.horizontal, 8)
//                    
//                    // Информация о текущем треке
//                    VStack(spacing: 8) {
//                        Text(playerVM.currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                        
//                        Text(playerVM.currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                    
//                    // ✅ ГИБКИЙ SPACER (занимает всё доступное пространство между информацией и плейлистом)
//                    // Это и есть то пустое пространство, которое мы переместили вверх!
//                    Spacer(minLength: 0)
//                    
//                    // Плейлист (прижат к низу)
//                    VStack(spacing: 0) {
//                        Divider()
//                            .padding(.horizontal, 16)
//                        
//                        HStack {
//                            Text("Плейлист")
//                                .font(.headline)
//                                .foregroundColor(.secondary)
//                            
//                            Spacer()
//                            
//                            Text("\(playerVM.tracks.count) треков")
//                                .font(.caption)
//                                .foregroundColor(.secondary)
//                        }
//                        .padding(.horizontal, 16)
//                        .padding(.top, 12)
//                        .padding(.bottom, 8)
//                        
//                        // Список треков
//                        ScrollView {
//                            LazyVStack(spacing: 4) {
//                                ForEach(playerVM.tracks) { track in
//                                    PlaylistTrackRow(
//                                        track: track,
//                                        isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                                    ) {
//                                        withAnimation(.easeInOut(duration: 0.2)) {
//                                            playerVM.selectTrack(track)
//                                        }
//                                    }
//                                }
//                            }
//                            .padding(.vertical, 8)
//                        }
//                        .frame(height: calculatePlaylistHeight(for: playerVM.tracks.count))
//                    }
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//    
//    // MARK: - Helper
//    private func calculatePlaylistHeight(for trackCount: Int) -> CGFloat {
//        let rowsToShow = min(trackCount, 3)
//        let rowHeight: CGFloat = 68
//        return CGFloat(rowsToShow) * rowHeight
//    }
//}









//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    
//    let tracks: [Track]
//    let initialTrack: Track
//    
//    init(tracks: [Track], initialTrack: Track) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Видео плеер (фиксированная высота)
//                EmbedPlayer(videoId: playerVM.currentTrack.videoId)
//                    .frame(height: 280)
//                    .background(Color.black)
//                
//                // Информация о текущем треке
//                VStack(spacing: 8) {
//                    Text(playerVM.currentTrack.title)
//                        .font(.title3)
//                        .fontWeight(.semibold)
//                        .multilineTextAlignment(.center)
//                        .lineLimit(2)
//                    
//                    Text(playerVM.currentTrack.artist)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 16)
//                .padding(.vertical, 12)
//                .frame(maxWidth: .infinity)
//                .background(Color(.systemBackground))
//                
//                Divider()
//                    .padding(.horizontal, 16)
//                
//                // Заголовок плейлиста
//                HStack {
//                    Text("Плейлист")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Text("\(playerVM.tracks.count) треков")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 16)
//                .padding(.top, 12)
//                .padding(.bottom, 8)
//                
//                // Список треков
//                ScrollView {
//                    LazyVStack(spacing: 4) {
//                        ForEach(playerVM.tracks) { track in
//                            PlaylistTrackRow(
//                                track: track,
//                                isCurrentlyPlaying: playerVM.currentTrack.id == track.id
//                            ) {
//                                withAnimation(.easeInOut(duration: 0.2)) {
//                                    playerVM.selectTrack(track)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear{
//            print(".onAppear PlayerEmbedView")
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//}
















//                EmbedPlayer(videoId: .constant(playerVM.currentTrack.videoId))
//                    .frame(height: 280)
//                    .background(Color.black)
                // Вместо текущего EmbedPlayer

//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM = PlayerViewModel()
//    @State private var isInitialized = false
//    
//    let tracks: [Track]
//    let initialTrack: Track?
//    
//    init(tracks: [Track], initialTrack: Track? = nil) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        print("📱 PlayerEmbedView init: tracks.count = \(tracks.count), initialTrack = \(initialTrack?.title ?? "nil")")
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Видео плеер (фиксированная высота)
//                if let currentTrack = playerVM.currentTrack {
//                    EmbedPlayer(videoId: .constant(currentTrack.videoId))
//                        .frame(height: 280)
//                        .background(Color.black)
////                        .overlay(alignment: .bottomTrailing) {
////                            Button(action: { dismiss() }) {
////                                Image(systemName: "xmark.circle.fill")
////                                    .font(.title2)
////                                    .foregroundColor(.white)
////                                    .shadow(radius: 2)
////                            }
////                            .padding(12)
////                        }
//                } else {
//                    Rectangle()
//                        .fill(Color.black.opacity(0.8))
//                        .frame(height: 280)
//                        .overlay {
//                            ProgressView()
//                                .tint(.white)
//                        }
//                }
//                
//                // Информация о текущем треке
//                if let currentTrack = playerVM.currentTrack {
//                    VStack(spacing: 8) {
//                        Text(currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                        
//                        Text(currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                }
//                
//                Divider()
//                    .padding(.horizontal, 16)
//                
//                // Заголовок плейлиста
//                HStack {
//                    Text("Плейлист")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Text("\(playerVM.tracks.count) треков")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 16)
//                .padding(.top, 12)
//                .padding(.bottom, 8)
//                
//                // Список треков
//                ScrollView {
//                    LazyVStack(spacing: 4) {
//                        ForEach(playerVM.tracks) { track in
//                            PlaylistTrackRow(
//                                track: track,
//                                isCurrentlyPlaying: playerVM.currentTrack?.id == track.id
//                            ) {
//                                withAnimation(.easeInOut(duration: 0.2)) {
//                                    playerVM.selectTrack(track)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            print(".onAppear PlayerEmbedView")
//            // Принудительно загружаем данные при каждом появлении
//            if !isInitialized {
//                print("📱 onAppear: загружаем \(tracks.count) треков")
//                playerVM.loadTracks(tracks)
//                if let initialTrack = initialTrack {
//                    playerVM.selectTrack(initialTrack)
//                }
//                isInitialized = true
//            }
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//}

//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM: PlayerViewModel
//    
//    let tracks: [Track]
//    let initialTrack: Track?
//    
//    init(tracks: [Track], initialTrack: Track? = nil) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//        // Инициализируем ViewModel сразу с треками
//        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Видео плеер (фиксированная высота)
//                if let currentTrack = playerVM.currentTrack {
//                    EmbedPlayer(videoId: .constant(currentTrack.videoId))
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .overlay(alignment: .bottomTrailing) {
//                            Button(action: { dismiss() }) {
//                                Image(systemName: "xmark.circle.fill")
//                                    .font(.title2)
//                                    .foregroundColor(.white)
//                                    .shadow(radius: 2)
//                            }
//                            .padding(12)
//                        }
//                } else {
//                    Rectangle()
//                        .fill(Color.black.opacity(0.8))
//                        .frame(height: 280)
//                        .overlay {
//                            ProgressView()
//                                .tint(.white)
//                        }
//                }
//                
//                // Информация о текущем треке
//                if let currentTrack = playerVM.currentTrack {
//                    VStack(spacing: 8) {
//                        Text(currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                        
//                        Text(currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                }
//                
//                Divider()
//                    .padding(.horizontal, 16)
//                
//                // Заголовок плейлиста
//                HStack {
//                    Text("Плейлист")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Text("\(playerVM.tracks.count) треков")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 16)
//                .padding(.top, 12)
//                .padding(.bottom, 8)
//                
//                // Список треков
//                ScrollView {
//                    LazyVStack(spacing: 4) {
//                        ForEach(playerVM.tracks) { track in
//                            PlaylistTrackRow(
//                                track: track,
//                                isCurrentlyPlaying: playerVM.currentTrack?.id == track.id
//                            ) {
//                                withAnimation(.easeInOut(duration: 0.2)) {
//                                    playerVM.selectTrack(track)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large])
//    }
//}





//
//import SwiftUI
//
//struct PlayerEmbedView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var playerVM = PlayerViewModel()
//    
//    let tracks: [Track]
//    let initialTrack: Track?
//    
//    init(tracks: [Track], initialTrack: Track? = nil) {
//        self.tracks = tracks
//        self.initialTrack = initialTrack
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 0) {
//                // Видео плеер (фиксированная высота)
//                if let currentTrack = playerVM.currentTrack {
//                    EmbedPlayer(videoId: .constant(currentTrack.videoId))
//                        .frame(height: 280)
//                        .background(Color.black)
//                        .overlay(alignment: .bottomTrailing) {
//                            // Кнопка "Свернуть" поверх видео
//                            Button(action: { dismiss() }) {
//                                Image(systemName: "xmark.circle.fill")
//                                    .font(.title2)
//                                    .foregroundColor(.white)
//                                    .shadow(radius: 2)
//                            }
//                            .padding(12)
//                        }
//                } else {
//                    // Placeholder если нет трека
//                    Rectangle()
//                        .fill(Color.black.opacity(0.8))
//                        .frame(height: 280)
//                        .overlay {
//                            ProgressView()
//                                .tint(.white)
//                        }
//                }
//                
//                // Информация о текущем треке
//                if let currentTrack = playerVM.currentTrack {
//                    VStack(spacing: 8) {
//                        Text(currentTrack.title)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .multilineTextAlignment(.center)
//                            .lineLimit(2)
//                        
//                        Text(currentTrack.artist)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 12)
//                    .frame(maxWidth: .infinity)
//                    .background(Color(.systemBackground))
//                }
//                
//                // Разделитель
//                Divider()
//                    .padding(.horizontal, 16)
//                
//                // Заголовок плейлиста
//                HStack {
//                    Text("Плейлист")
//                        .font(.headline)
//                        .foregroundColor(.secondary)
//                    
//                    Spacer()
//                    
//                    Text("\(playerVM.tracks.count) треков")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.horizontal, 16)
//                .padding(.top, 12)
//                .padding(.bottom, 8)
//                
//                // Список треков
//                ScrollView {
//                    LazyVStack(spacing: 4) {
//                        ForEach(playerVM.tracks) { track in
//                            PlaylistTrackRow(
//                                track: track,
//                                isCurrentlyPlaying: playerVM.currentTrack?.id == track.id
//                            ) {
//                                withAnimation(.easeInOut(duration: 0.2)) {
//                                    playerVM.selectTrack(track)
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//            .navigationBarHidden(true)
//        }
//        .onAppear {
//            playerVM.loadTracks(tracks)
//            // Если передан начальный трек - выбираем его, иначе первый
//            if let initialTrack = initialTrack {
//                playerVM.selectTrack(initialTrack)
//            }
//            
//        }
//        .interactiveDismissDisabled(false)
//        .presentationDragIndicator(.visible)
//        .presentationDetents([.large]) // Полноэкранный режим
//    }
//}

//// MARK: - Preview
//#Preview {
//    PlayerSheetView(
//        tracks: [
//            Track(id: "1", title: "Test Track 1", artist: "Artist 1", thumbnailURL: "", videoId: "dQw4w9WgXcQ", durationISO8601: "PT3M45S"),
//            Track(id: "2", title: "Test Track 2", artist: "Artist 2", thumbnailURL: "", videoId: "dQw4w9WgXcQ", durationISO8601: "PT4M20S")
//        ],
//        initialTrack: nil
//    )
//}
