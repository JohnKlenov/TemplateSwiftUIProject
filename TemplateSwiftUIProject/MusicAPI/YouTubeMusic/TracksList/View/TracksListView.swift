//
//  TracksListView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//




//
//  TracksListView.swift
//  Главный список треков с открытием плеера
//

import SwiftUI

struct TracksListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = TracksViewModel()
    @State private var selectedTrack: Track?
    
    var body: some View {
        NavigationView {
            List(vm.tracks) { track in
                TrackRow(track: track) {
                    print("Plus tapped for \(track.title)")
                }
                .onTapGesture {
                    print("Selected track: \(track.videoId)")
                    // Сохраняем все треки и выбранный трек
                    selectedTrack = track
                }
            }
            .navigationTitle("Мои треки")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                vm.loadTracks()
            }
            .fullScreenCover(item: $selectedTrack) { track in
                print("📱 Открываем плеер: tracksForPlayer.count = \(vm.tracks)")
                return PlayerEmbedView(
                    tracks: vm.tracks,
                    initialTrack: track
                )
            }
//            .sheet(item: $selectedTrack) { track in
//                print("📱 Открываем плеер: tracksForPlayer.count = \(vm.tracks)")
//                return PlayerEmbedView(
//                    tracks: vm.tracks,
//                    initialTrack: track
//                )
//            }
        }
        .navigationBarBackButtonHidden(true)
    }
}


//            .sheet(item: $selectedTrack) { track in
//                // track уже развёрнут, не нужно проверять selectedTrack
//                PlayerEmbedView(
//                    tracks: tracksForPlayer,
//                    initialTrack: track  // используем track, который пришёл в замыкание
//                )
//            }


//            .fullScreenCover(isPresented: $showPlayerSheet) {
//                if let track = selectedTrack {
//                    PlayerEmbedView(
//                        tracks: tracksForPlayer,
//                        initialTrack: track
//                    )
//                }
//            }

//            .sheet(isPresented: $showPlayerSheet) {
//                if let track = selectedTrack {
//                    PlayerEmbedView(
//                        tracks: tracksForPlayer,
//                        initialTrack: track
//                    )
//                }
//            }

// MARK: - not PlaylistTrackRow 

//import SwiftUI
//
//struct TracksListView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var vm = TracksViewModel()
//    @State private var selectedTrack: Track?
//
//    var body: some View {
//        NavigationView {
//            List(vm.tracks) { track in
//                TrackRow(track: track) {
//                    print("Plus tapped for \(track.title)")
//                }
//                .onTapGesture {
//                    print("Plus tapped for \(track.videoId)")
//                    selectedTrack = track
//                }
//            }
//            .navigationTitle("Мои треки")
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button(action: { dismiss() }) {
//                        Image(systemName: "xmark")
//                            .font(.title2)
//                    }
//                }
//            }
//            .onAppear {
//                vm.loadTracks()
//            }
//            .sheet(item: $selectedTrack) { track in
////                SafariPlayerView(videoId: track.videoId)
//                PlayerView(videoId: track.videoId)
////                YouTubePlayerView(videoId: track.videoId)
////                    .edgesIgnoringSafeArea(.all)
//            }
//        }
//        .navigationBarBackButtonHidden(true)
//    }
//}

