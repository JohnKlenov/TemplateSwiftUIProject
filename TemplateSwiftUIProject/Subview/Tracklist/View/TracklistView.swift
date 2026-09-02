//
//  TracklistView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.08.2026.
//


import SwiftUI


struct TracklistView: View {
    
    let data: Tracklist
    let onLoadNextTracks: () -> Void
    let onSelectTrack: (LowerItem) -> Void
    
    var body: some View {
        ScrollView {
            lowerSectionWithFooter()
                .padding(.vertical, 12)
        }
    }
}
                    


// MARK: - Lower Section + Footer Loader (Без изменений)
private extension TracklistView {
   
    @ViewBuilder
    func lowerSectionWithFooter() -> some View {
        LazyVStack(spacing: 8) {
            ForEach(data.tracks.items) { item in
                lowerItemCell(item)
            }
            
            if data.tracks.hasMore {
                footerView
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var footerView: some View {
        switch data.footerState {
        case .idle:
            HStack {
                Spacer()
                Color.clear
                    .frame(height: 44)
                    .onAppear {
                        print("footerView case .idle")
                        onLoadNextTracks()
                    }
                Spacer()
            }
            .padding(.vertical, 12)
            
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 12)
            
        case .error(let message):
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Text(message)
                        .foregroundColor(.secondary)
                    Button("Повторить") {
                        onLoadNextTracks()
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
    
    // пока используем такой title Droplist#143: Artist(Headliner)
    // subtitle - на альбомы а артисты
    func lowerItemCell(_ item: LowerItem) -> some View {
        Button {
            onSelectTrack(item)
        } label: {
            HStack(spacing: 12) {
                thumbnail(for: item)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .multilineTextAlignment(.leading)          // ← прижимаем строки
                            .frame(maxWidth: .infinity, alignment: .leading) // ← фиксируем выравнивание
                    }

                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    func thumbnail(for item: LowerItem) -> some View {
        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
        
        WebImageView(
            url: url,
            placeholderColor: AppColors.secondarySystemBackground,
            displayStyle: .fixedFrame(width: 60, height: 60),
            context: "LowerItemThumbnail_\(item.id)"
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
