//
//  PlayerEmbedView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.04.26.
//



//  Модальное окно плеера: видео сверху, плейлист снизу


import SwiftUI

struct PlayerEmbedView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerVM: PlayerViewModel
    
    let tracks: [Track]
    let initialTrack: Track
    
    init(tracks: [Track], initialTrack: Track) {
        self.tracks = tracks
        self.initialTrack = initialTrack
        _playerVM = StateObject(wrappedValue: PlayerViewModel(tracks: tracks, initialTrack: initialTrack))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Видео плеер (фиксированная высота)
//                EmbedPlayer(videoId: .constant(playerVM.currentTrack.videoId))
//                    .frame(height: 280)
//                    .background(Color.black)
                // Вместо текущего EmbedPlayer
                EmbedPlayer(videoId: playerVM.currentTrack.videoId)
                    .frame(height: 280)
                    .background(Color.black)
//                    .cornerRadius(12)  // опционально: скругление углов
                
                // Информация о текущем треке
                VStack(spacing: 8) {
                    Text(playerVM.currentTrack.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(playerVM.currentTrack.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Заголовок плейлиста
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
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Список треков
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
            .navigationBarHidden(true)
        }
        .onAppear{
            print(".onAppear PlayerEmbedView")
        }
        .interactiveDismissDisabled(false)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }
}



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
