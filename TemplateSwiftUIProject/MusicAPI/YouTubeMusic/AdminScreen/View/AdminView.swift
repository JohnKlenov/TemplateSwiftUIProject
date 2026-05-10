//
//  AdminView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 9.05.26.
//






import SwiftUI

struct AdminView: View {

    @StateObject private var vm = AdminViewModel(
        apiKey: Secrets.youtubeAPIKey,
        playlistId: "PLQcuPcwlJLVBYcEV8-ecFBBorqca52gtP",
        playlistTitle: "Droplist#2: Kodak Black",
        playlistDescription: "Evil Genius || Painting Pictures || Project Baby 2 || Closure || Institution"
    )

    @State private var showSafari = false

    var body: some View {
        NavigationView {
            Form {

                // MARK: - Метаданные
                Section("Метаданные плейлиста") {
                    Text("Title: \(vm.playlistTitle)")
                    Text("Description: \(vm.playlistDescription)")
                    Text("Cover URL: \(vm.playlistImageURL.isEmpty ? "— не сгенерирован" : vm.playlistImageURL)")
                        .lineLimit(2)
                        .font(.footnote)
                }

                // MARK: - Добавить трек вручную
                Section("Добавить трек вручную") {
                    TextField("Artist", text: $vm.searchArtist)
                    TextField("Track Title", text: $vm.searchTitle)

                    Button("Искать трек") {
                        Task { await vm.searchTrack() }
                    }

                    if let _ = vm.foundTrackURL {
                        Button("Открыть найденный трек в Safari") {
                            showSafari = true
                        }
                    }

                    if vm.foundTrack != nil {

                        // Теги найденного трека
                        HStack {
                            Text("Теги:")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            ForEach(vm.availableTags, id: \.self) { tag in
                                Button {
                                    vm.toggleFoundTrackTag(tag)
                                } label: {
                                    Text(tag)
                                        .font(.caption2)
                                        .padding(6)
                                        .background(
                                            vm.foundTrackTags.contains(tag)
                                            ? Color.blue.opacity(0.25)
                                            : Color.gray.opacity(0.15)
                                        )
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Toggle(isOn: $vm.useFoundTrackThumbnailInCollage) {
                            Text("Использовать thumbnail в коллаже")
                                .font(.caption)
                        }

                        Button("Добавить трек в список") {
                            vm.addFoundTrack()
                        }
                        .foregroundColor(.green)
                    }
                }

                // MARK: - Thumbnail
                Section("Выбранные thumbnail для коллажа (\(vm.coverThumbnailURLs.count)/4)") {
                    if vm.coverThumbnailURLs.isEmpty {
                        Text("Пока нет выбранных thumbnail")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(Array(vm.coverThumbnailURLs.enumerated()), id: \.offset) { idx, url in
                            Text("\(idx + 1). \(url)")
                                .font(.caption2)
                                .lineLimit(1)
                        }
                    }
                    // Вместо текущей кнопки:
                    if vm.coverThumbnailURLs.count == 4 {
                        Button("Собрать coverImage 2×2 (Cloud Function)") {
                            Task {
                                await vm.generateCoverImage()
                            }
                        }
                        .disabled(vm.isGeneratingCover) // ← кнопка отключается во время генерации
                    }
                }

                // MARK: - Треки в плейлисте
                Section("Треки в плейлисте") {
                    if vm.tracks.isEmpty {
                        Text("Пока нет треков")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(vm.tracks.sorted(by: { $0.orderIndex < $1.orderIndex })) { track in

                                    VStack(alignment: .leading, spacing: 6) {

                                        HStack {
                                            Text("\(track.orderIndex + 1).")
                                                .foregroundColor(.secondary)

                                            VStack(alignment: .leading) {
                                                Text(track.title)
                                                    .font(.subheadline)
                                                    .lineLimit(1)

                                                Text(track.artist)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            if !track.tags.isEmpty {
                                                Text(track.tags.joined(separator: ", "))
                                                    .font(.caption2)
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                            }
                                        }

                                        // Теги — теперь работают идеально
                                        HStack {
                                            Text("Теги:")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)

                                            ForEach(vm.availableTags, id: \.self) { tag in
                                                Button {
                                                    vm.toggleTag(forVideoId: track.videoId, tag: tag)
                                                } label: {
                                                    Text(tag)
                                                        .font(.caption2)
                                                        .padding(6)
                                                        .background(
                                                            track.tags.contains(tag)
                                                            ? Color.blue.opacity(0.25)
                                                            : Color.gray.opacity(0.15)
                                                        )
                                                        .cornerRadius(6)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 4)
                                }
                            }
                        }
                        .frame(minHeight: 200)
                    }
                }

                // MARK: - Сохранение
                Section("Сохранение") {
                    Button("Сохранить плейлист в Firestore (droplist + dropTracks)") {
                        Task { await vm.savePlaylistToFirestore() }
                    }
                    .disabled(vm.playlistImageURL.isEmpty || vm.tracks.isEmpty)
                    .foregroundColor(.blue)
                }

                // MARK: - Статус
                Section("Статус") {
                    Text(vm.status)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showSafari) {
                if let url = vm.foundTrackURL {
                    SafariView(url: url)
                }
            }
            .navigationTitle("Admin • Manual Playlist Builder")
        }
    }
}






