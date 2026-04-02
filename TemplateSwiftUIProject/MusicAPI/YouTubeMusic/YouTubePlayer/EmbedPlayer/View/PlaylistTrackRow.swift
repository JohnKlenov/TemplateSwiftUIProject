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
                // Индикатор воспроизведения
                ZStack {
                    Circle()
                        .fill(isCurrentlyPlaying ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                    
                    if isCurrentlyPlaying {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                            .offset(x: 16)
                    }
                }
                .frame(width: 24, alignment: .center)
                
                // Информация о треке
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.title)
                        .font(.system(size: 16, weight: isCurrentlyPlaying ? .semibold : .regular))
                        .foregroundColor(isCurrentlyPlaying ? .green : .primary)
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Длительность
                Text(track.formattedDuration)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentlyPlaying ? Color.green.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
