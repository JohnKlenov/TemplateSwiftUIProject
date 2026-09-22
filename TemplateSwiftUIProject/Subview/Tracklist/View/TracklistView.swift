//
//  TracklistView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 28.08.2026.
//


import SwiftUI

struct TracklistView: View {
    let data: Tracklist
    let details: [String]
    let imageURL: URL?

    let onLoadNextTracks: () -> Void
    let onSelectTrack: (LowerItem) -> Void
    let onAddToPlaylist: (LowerItem) -> Void
    let onPlayInYouTubeMusic: (LowerItem) -> Void
    let isTrackInPlaylist: (LowerItem) -> Bool

    var body: some View {
        GeometryReader { geometry in
            //Сделай изображение шириной 45% экрана, но никогда не увеличивай его больше чем до 320 pt.(для iPad)
            let imageSize = min(
                geometry.size.width * 0.45,
                320
            )

            ScrollView {
                VStack(spacing: 12) {
                    if let imageURL {
                        WebImageView(
                            url: imageURL,
                            placeholderColor:
                                AppColors.secondarySystemBackground,
                            displayStyle:
                                .fixedFrame(
                                    width: imageSize,
                                    height: imageSize
                                ),
                            context:
                                "TracklistDetailsImage"
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12
                            )
                        )
                    }

                    if !details.isEmpty {
                        PlaylistDetailsView(
                            details: details
                        )
                    }

                    lowerSectionWithFooter()
                        .padding(.vertical, 12)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .top
                )
            }
        }
    }
}

// MARK: - Lower Section + Footer Loader

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

    func lowerItemCell(
        _ item: LowerItem
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                onSelectTrack(item)
            } label: {
                HStack(spacing: 12) {
                    thumbnail(for: item)

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            trackActionsMenu(for: item)
        }
    }

    @ViewBuilder
    func trackActionsMenu(
        for item: LowerItem
    ) -> some View {
        Menu {
            Button {
                onAddToPlaylist(item)
            } label: {
                Label(
                    "Add to Playlist",
                    systemImage: "text.badge.plus"
                )
            }
            .disabled(isTrackInPlaylist(item))

            Button {
                onPlayInYouTubeMusic(item)
            } label: {
                Label(
                    "Open in YouTube Music",
                    systemImage: "play.circle"
                )
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundColor(.primary)
                .frame(
                    width: 40,
                    height: 40
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func thumbnail(
        for item: LowerItem
    ) -> some View {
        
        let url = item.thumbnailURL

        WebImageView(
            url: url,
            placeholderColor:
                AppColors.secondarySystemBackground,
            displayStyle:
                .fixedFrame(
                    width: 50,
                    height: 50
                ),
            context:
                "LowerItemThumbnail_\(item.id)"
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 6)
        )
    }
}

// before add let imageURL for case .droplistDetails
//import SwiftUI
//
//struct TracklistView: View {
//    let data: Tracklist
//    let details: [String]
//
//    let onLoadNextTracks: () -> Void
//    let onSelectTrack: (LowerItem) -> Void
//    let onAddToPlaylist: (LowerItem) -> Void
//    let onPlayInYouTubeMusic: (LowerItem) -> Void
//
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 12) {
//
//                if !details.isEmpty {
//                    PlaylistDetailsView(
//                        details: details
//                    )
//                }
//
//                lowerSectionWithFooter()
//                    .padding(.vertical, 12)
//            }
//        }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader
//
//private extension TracklistView {
//
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        LazyVStack(spacing: 8) {
//
//            ForEach(data.tracks.items) { item in
//                lowerItemCell(item)
//            }
//
//            if data.tracks.hasMore {
//                footerView
//            }
//        }
//        .padding(.horizontal)
//    }
//
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//
//        case .idle:
//            HStack {
//                Spacer()
//
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        onLoadNextTracks()
//                    }
//
//                Spacer()
//            }
//            .padding(.vertical, 12)
//
//        case .loading:
//            HStack {
//                Spacer()
//
//                ProgressView()
//
//                Spacer()
//            }
//            .padding(.vertical, 12)
//
//        case .error(let message):
//            HStack {
//                Spacer()
//
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//
//                    Button("Повторить") {
//                        onLoadNextTracks()
//                    }
//                }
//
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//
//    func lowerItemCell(
//        _ item: LowerItem
//    ) -> some View {
//        HStack(spacing: 12) {
//
//            Button {
//                onSelectTrack(item)
//            } label: {
//                HStack(spacing: 12) {
//
//                    thumbnail(for: item)
//
//                    VStack(
//                        alignment: .leading,
//                        spacing: 4
//                    ) {
//                        Text(item.title)
//                            .font(.headline)
//                            .foregroundColor(.primary)
//                            .lineLimit(1)
//
//                        if let subtitle = item.subtitle {
//                            Text(subtitle)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .lineLimit(1)
//                                .multilineTextAlignment(.leading)
//                                .frame(
//                                    maxWidth: .infinity,
//                                    alignment: .leading
//                                )
//                        }
//                    }
//
//                    Spacer()
//                }
//            }
//            .buttonStyle(.plain)
//
//            trackActionsMenu(for: item)
//        }
//    }
//
//    @ViewBuilder
//    func trackActionsMenu(
//        for item: LowerItem
//    ) -> some View {
//        Menu {
//            Button {
//                onAddToPlaylist(item)
//            } label: {
//                Label(
//                    "Add to Playlist",
//                    systemImage: "text.badge.plus"
//                )
//            }
//
//            Button {
//                onPlayInYouTubeMusic(item)
//            } label: {
//                Label(
//                    "Open in YouTube Music",
//                    systemImage: "play.circle"
//                )
//            }
//        } label: {
//            Image(systemName: "ellipsis")
//                .font(
//                    .system(
//                        size: 17,
//                        weight: .bold
//                    )
//                )
//                .foregroundColor(.primary)
//                .frame(
//                    width: 40,
//                    height: 40
//                )
//                .contentShape(Rectangle())
//        }
//        .buttonStyle(.plain)
//    }
//
//    @ViewBuilder
//    func thumbnail(
//        for item: LowerItem
//    ) -> some View {
//        let url = item.isTrack
//            ? item.thumbnailURL
//            : item.coverImageURL
//
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(
//                width: 50,
//                height: 50
//            ),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(
//            RoundedRectangle(cornerRadius: 6)
//        )
//    }
//}



// MARK: - before add PlaylistDetailsView

//import SwiftUI
//
//struct TracklistView: View {
//
//    let data: Tracklist
//
//    let onLoadNextTracks: () -> Void
//    let onSelectTrack: (LowerItem) -> Void
//
//    let onAddToPlaylist: (LowerItem) -> Void
//    let onPlayInYouTubeMusic: (LowerItem) -> Void
//
//    var body: some View {
//
//        ScrollView {
//
//            lowerSectionWithFooter()
//                .padding(.vertical, 12)
//        }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader
//
//private extension TracklistView {
//
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//
//        LazyVStack(spacing: 8) {
//
//            ForEach(data.tracks.items) { item in
//                lowerItemCell(item)
//            }
//
//            if data.tracks.hasMore {
//                footerView
//            }
//        }
//        .padding(.horizontal)
//    }
//
//    @ViewBuilder
//    var footerView: some View {
//
//        switch data.footerState {
//
//        case .idle:
//
//            HStack {
//
//                Spacer()
//
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        onLoadNextTracks()
//                    }
//
//                Spacer()
//            }
//            .padding(.vertical, 12)
//
//        case .loading:
//
//            HStack {
//
//                Spacer()
//
//                ProgressView()
//
//                Spacer()
//            }
//            .padding(.vertical, 12)
//
//        case .error(let message):
//
//            HStack {
//
//                Spacer()
//
//                VStack(spacing: 6) {
//
//                    Text(message)
//                        .foregroundColor(.secondary)
//
//                    Button("Повторить") {
//                        onLoadNextTracks()
//                    }
//                }
//
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//
//    // Пока используем такой title:
//    // Droplist#143: Artist(Headliner)
//    //
//    // subtitle - на альбомы и артисты.
//
//    func lowerItemCell(
//        _ item: LowerItem
//    ) -> some View {
//
//        HStack(spacing: 12) {
//
//            Button {
//                onSelectTrack(item)
//            } label: {
//
//                HStack(spacing: 12) {
//
//                    thumbnail(for: item)
//
//                    VStack(
//                        alignment: .leading,
//                        spacing: 4
//                    ) {
//
//                        Text(item.title)
//                            .font(.headline)
//                            .foregroundColor(.primary)
//                            .lineLimit(1)
//
//                        if let subtitle = item.subtitle {
//
//                            Text(subtitle)
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                                .lineLimit(1)
//                                .multilineTextAlignment(.leading)
//                                .frame(
//                                    maxWidth: .infinity,
//                                    alignment: .leading
//                                )
//                        }
//                    }
//
//                    Spacer()
//                }
//            }
//            .buttonStyle(.plain)
//
//            trackActionsMenu(for: item)
//        }
//    }
//
//    @ViewBuilder
//    func trackActionsMenu(
//        for item: LowerItem
//    ) -> some View {
//
//        Menu {
//
//            Button {
//                onAddToPlaylist(item)
//            } label: {
//                Label(
//                    "Add to Playlist",
//                    systemImage: "text.badge.plus"
//                )
//            }
//
//            Button {
//                onPlayInYouTubeMusic(item)
//            } label: {
//                Label(
//                    "Open in YouTube Music",
//                    systemImage: "play.circle"
//                )
//            }
//
//        } label: {
//
//            Image(systemName: "ellipsis")
//                .font(
//                    .system(
//                        size: 17,
//                        weight: .bold
//                    )
//                )
//                .foregroundColor(.primary)
//                .frame(
//                    width: 40,
//                    height: 40
//                )
//                .contentShape(Rectangle())
//        }
//        .buttonStyle(.plain)
//    }
//
//    @ViewBuilder
//    func thumbnail(
//        for item: LowerItem
//    ) -> some View {
//
//        let url = item.isTrack
//            ? item.thumbnailURL
//            : item.coverImageURL
//
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(
//                width: 50,
//                height: 50
//            ),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(
//            RoundedRectangle(cornerRadius: 6)
//        )
//    }
//}

// MARK: - before add 2 action onAddToPlaylist + onPlayInYouTubeMusic

//import SwiftUI
//
//
//struct TracklistView: View {
//    
//    let data: Tracklist
//    let onLoadNextTracks: () -> Void
//    let onSelectTrack: (LowerItem) -> Void
//    
//    var body: some View {
//        ScrollView {
//            lowerSectionWithFooter()
//                .padding(.vertical, 12)
//        }
//    }
//}
//                    
//
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension TracklistView {
//   
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        LazyVStack(spacing: 8) {
//            ForEach(data.tracks.items) { item in
//                lowerItemCell(item)
//            }
//            
//            if data.tracks.hasMore {
//                footerView
//            }
//        }
//        .padding(.horizontal)
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        onLoadNextTracks()
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        onLoadNextTracks()
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    // пока используем такой title Droplist#143: Artist(Headliner)
//    // subtitle - на альбомы а артисты
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectTrack(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                        .lineLimit(1)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(1)
//                            .multilineTextAlignment(.leading)          // ← прижимаем строки
//                            .frame(maxWidth: .infinity, alignment: .leading) // ← фиксируем выравнивание
//                    }
//
//                }
//                Spacer()
//            }
//        }
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 50, height: 50),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 6))
//    }
//}
