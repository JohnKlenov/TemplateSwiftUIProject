//
//  PlaylistTrackRow.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.04.26.
//


//  Строка трека в плейлисте с индикацией воспроизведения




import SwiftUI

struct PlaylistTrackRow: View {
    let track: Track
    let isCurrentlyPlaying: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Обложка трека
                ZStack {
                    AsyncImage(url: URL(string: track.thumbnailURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray5)) // системный серый
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.secondary)
                                )
                        @unknown default:
                            Rectangle()
                                .fill(Color(.systemGray5))
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .clipped()
                    .overlay(
                        Rectangle()
                            .fill(Color.black.opacity(isCurrentlyPlaying ? 0.4 : 0))
                            .cornerRadius(8)
                    )
                    .overlay(
                        Group {
                            if isCurrentlyPlaying {
                                HStack(spacing: 3) {
                                    PlayingIndicatorBar(delay: 0.0)
                                    PlayingIndicatorBar(delay: 0.2)
                                    PlayingIndicatorBar(delay: 0.4)
                                }
                                .frame(width: 24, height: 24)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(4)
                            }
                        }
                    )
                }
                
                // Информация о треке
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 16, weight: isCurrentlyPlaying ? .medium : .regular))
                        .foregroundColor(.primary) // системный цвет текста
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary) // системный вторичный цвет
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Длительность
                Text(track.formattedDuration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Color(.systemBackground) // системный фон строки
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Анимированный индикатор
struct PlayingIndicatorBar: View {
    let delay: Double
    @State private var scale: CGFloat = 0.4
    
    var body: some View {
        Rectangle()
            .fill(Color.green) // зелёный оставляем как акцентный цвет
            .frame(width: 4, height: 12 * scale)
            .cornerRadius(2)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(delay)
                ) {
                    scale = 1.0
                }
            }
    }
}




//import SwiftUI
//
//struct PlaylistTrackRow: View {
//    let track: Track
//    let isCurrentlyPlaying: Bool
//    let onTap: () -> Void
//    
//    var body: some View {
//        Button(action: onTap) {
//            HStack(spacing: 12) {
//                // Обложка трека
//                ZStack {
//                    AsyncImage(url: URL(string: track.thumbnailURL)) { phase in
//                        switch phase {
//                        case .empty:
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                                .overlay(ProgressView())
//                        case .success(let image):
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                        case .failure:
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                                .overlay(
//                                    Image(systemName: "music.note")
//                                        .foregroundColor(.gray)
//                                )
//                        @unknown default:
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                        }
//                    }
//                    .frame(width: 50, height: 50)
//                    .cornerRadius(8)
//                    .clipped()
//                    .overlay(
//                        Rectangle()
//                            .fill(Color.black.opacity(isCurrentlyPlaying ? 0.4 : 0))
//                            .cornerRadius(8)
//                    )
//                    .overlay(
//                        Group {
//                            if isCurrentlyPlaying {
//                                HStack(spacing: 3) {
//                                    PlayingIndicatorBar(delay: 0.0)
//                                    PlayingIndicatorBar(delay: 0.2)
//                                    PlayingIndicatorBar(delay: 0.4)
//                                }
//                                .frame(width: 24, height: 24)
//                                .background(Color.black.opacity(0.6))
//                                .cornerRadius(4)
//                            }
//                        }
//                    )
//                }
//                
//                // Информация о треке
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(track.title)
//                        .font(.system(size: 16, weight: isCurrentlyPlaying ? .medium : .regular))
//                        .foregroundColor(.primary)
//                        .lineLimit(1)
//                    
//                    Text(track.artist)
//                        .font(.system(size: 14))
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//                
//                Spacer()
//                
//                // Длительность
//                Text(track.formattedDuration)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.secondary)
//                    .monospacedDigit()
//            }
//            .padding(.vertical, 8)
//            .padding(.horizontal, 16)
//            .background(
//                // Динамический фон при нажатии
//                Color(.systemGray6)
//                    .opacity(0)
//            )
//            .contentShape(Rectangle())
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// MARK: - Анимированный индикатор
//struct PlayingIndicatorBar: View {
//    let delay: Double
//    @State private var scale: CGFloat = 0.4
//    
//    var body: some View {
//        Rectangle()
//            .fill(Color.green)
//            .frame(width: 4, height: 12 * scale)
//            .cornerRadius(2)
//            .onAppear {
//                withAnimation(
//                    Animation.easeInOut(duration: 0.6)
//                        .repeatForever(autoreverses: true)
//                        .delay(delay)
//                ) {
//                    scale = 1.0
//                }
//            }
//    }
//}




//
//  PlaylistTrackRow.swift
//  Строка плейлиста с обложкой и индикатором воспроизведения
//

//import SwiftUI
//
//struct PlaylistTrackRow: View {
//    let track: Track
//    let isCurrentlyPlaying: Bool
//    let onTap: () -> Void
//    
//    var body: some View {
//        Button(action: onTap) {
//            HStack(spacing: 12) {
//                // Обложка трека с затемнением и индикатором
//                ZStack {
//                    AsyncImage(url: URL(string: track.thumbnailURL)) { phase in
//                        switch phase {
//                        case .empty:
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                                .overlay(ProgressView())
//                        case .success(let image):
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                        case .failure:
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                                .overlay(
//                                    Image(systemName: "music.note")
//                                        .foregroundColor(.gray)
//                                )
//                        @unknown default:
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                        }
//                    }
//                    .frame(width: 50, height: 50)
//                    .cornerRadius(8)
//                    .clipped()
//                    .overlay(
//                        // Затемнение для текущего трека
//                        Rectangle()
//                            .fill(Color.black.opacity(isCurrentlyPlaying ? 0.4 : 0))
//                            .cornerRadius(8)
//                    )
//                    .overlay(
//                        // Индикатор воспроизведения (три полоски)
//                        Group {
//                            if isCurrentlyPlaying {
//                                HStack(spacing: 3) {
//                                    PlayingIndicatorBar(delay: 0.0)
//                                    PlayingIndicatorBar(delay: 0.2)
//                                    PlayingIndicatorBar(delay: 0.4)
//                                }
//                                .frame(width: 24, height: 24)
//                                .background(Color.black.opacity(0.6))
//                                .cornerRadius(4)
//                            }
//                        }
//                    )
//                }
//                
//                // Информация о треке
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(track.title)
//                        .font(.system(size: 16, weight: isCurrentlyPlaying ? .medium : .regular))
//                        .foregroundColor(isCurrentlyPlaying ? .primary : .primary)
//                        .lineLimit(1)
//                    
//                    Text(track.artist)
//                        .font(.system(size: 14))
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//                
//                Spacer()
//                
//                // Длительность
//                Text(track.formattedDuration)
//                    .font(.system(size: 14, weight: .medium))
//                    .foregroundColor(.secondary)
//                    .monospacedDigit()
//            }
//            .padding(.vertical, 8)
//            .padding(.horizontal, 16)
//            .background(
//                // Лёгкий фон при нажатии (standard button feedback)
//                Color(.systemGray6)
//                    .opacity(0)
//            )
//            .contentShape(Rectangle())
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// MARK: - Анимированный индикатор воспроизведения (три полоски)
//struct PlayingIndicatorBar: View {
//    let delay: Double
//    @State private var scale: CGFloat = 0.4
//    
//    var body: some View {
//        Rectangle()
//            .fill(Color.green)
//            .frame(width: 4, height: 12 * scale)
//            .cornerRadius(2)
//            .onAppear {
//                withAnimation(
//                    Animation.easeInOut(duration: 0.6)
//                        .repeatForever(autoreverses: true)
//                        .delay(delay)
//                ) {
//                    scale = 1.0
//                }
//            }
//    }
//}









//import SwiftUI
//
//struct PlaylistTrackRow: View {
//    let track: Track
//    let isCurrentlyPlaying: Bool
//    let onTap: () -> Void
//    
//    var body: some View {
//        Button(action: onTap) {
//            HStack(spacing: 12) {
//                // Индикатор воспроизведения
//                ZStack {
//                    Circle()
//                        .fill(isCurrentlyPlaying ? Color.green : Color.gray.opacity(0.3))
//                        .frame(width: 8, height: 8)
//                    
//                    if isCurrentlyPlaying {
//                        Image(systemName: "speaker.wave.2.fill")
//                            .font(.system(size: 12))
//                            .foregroundColor(.green)
//                            .offset(x: 16)
//                    }
//                }
//                .frame(width: 24, alignment: .center)
//                
//                // Информация о треке
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(track.title)
//                        .font(.system(size: 16, weight: isCurrentlyPlaying ? .semibold : .regular))
//                        .foregroundColor(isCurrentlyPlaying ? .green : .primary)
//                        .lineLimit(1)
//                    
//                    Text(track.artist)
//                        .font(.system(size: 14))
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//                
//                Spacer()
//                
//                // Длительность
//                Text(track.formattedDuration)
//                    .font(.system(size: 14))
//                    .foregroundColor(.secondary)
//                    .monospacedDigit()
//            }
//            .padding(.vertical, 8)
//            .padding(.horizontal, 16)
//            .background(
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(isCurrentlyPlaying ? Color.green.opacity(0.1) : Color.clear)
//            )
//        }
//        .buttonStyle(.plain)
//    }
//}
