//
//  TrackRow.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//




//  Строка трека в главном списке


import SwiftUI

struct TrackRow<T: TrackProtocol>: View {
    let track: T
    let onPlusTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Обложка
            AsyncImage(url: URL(string: track.thumbnailURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.gray)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
            .frame(width: 55, height: 55)
            .cornerRadius(8)
            .clipped()
            
            // Информация
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                Text(track.artist)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Кнопка добавления
            Button(action: onPlusTap) {
                Image(systemName: "plus.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}


// MARK: - not button add

//import SwiftUI
//
//struct TrackRow<T: TrackProtocol>: View {
//    let track: T
//    let onPlusTap: () -> Void
//
//    var body: some View {
//        HStack {
//            AsyncImage(url: URL(string: track.thumbnailURL)) { img in
//                img.resizable()
//            } placeholder: {
//                Color.gray.opacity(0.3)
//            }
//            .frame(width: 60, height: 60)
//            .cornerRadius(8)
//
//            VStack(alignment: .leading) {
//                Text(track.title)
//                    .font(.headline)
//                    .lineLimit(1)
//
//                Text(track.artist)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//            }
//
//            Spacer()
//
//            Button(action: onPlusTap) {
//                Image(systemName: "plus.circle")
//                    .font(.title2)
//            }
//        }
//        .padding(.vertical, 6)
//    }
//}
//
