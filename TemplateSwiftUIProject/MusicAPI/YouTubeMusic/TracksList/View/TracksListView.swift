//
//  TracksListView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
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
                    print("Plus tapped for \(track.videoId)")
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
            .sheet(item: $selectedTrack) { track in
//                SafariPlayerView(videoId: track.videoId)
//                PlayerView(videoId: track.videoId)
                YouTubePlayerView(videoId: track.videoId)
//                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

//
//
//struct TracksListView: View {
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
//                    selectedTrack = track
//                }
//            }
//            .navigationTitle("Мои треки")
//            .onAppear {
//                vm.loadTracks()
//            }
//            .sheet(item: $selectedTrack) { track in
//                PlayerView(videoId: track.videoId)
//            }
//        }
//    }
//}

