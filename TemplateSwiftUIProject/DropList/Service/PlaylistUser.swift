//
//  PlaylistUser.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 11.09.2026.
//


//Если у пользователя потенциально сотни/тысячи треков, лучше внутри PlaylistUser иметь Set<String>:
//private var videoIDs = Set<String>()

//func contains(videoId: String) -> Bool {
//    videoIDs.contains(videoId)
//}

// А [MyTrackCloud] оставить для отображения/данных.

//ViewBuilderService
//        │
//        │ owns
//        ▼
//   PlaylistUser
//        │
//        │ shared instance
//        ├───────────────┐
//        ▼               ▼
//DroplistViewModel  TracklistViewModel
//        │               │
//        └───────┬───────┘
//                ▼
//       playlistUser.contains(videoId)




import SwiftUI


final class PlaylistUser: ObservableObject {

    @Published private(set) var tracks: [MyTrackCloud] = []

    func contains(videoId: String) -> Bool {
        tracks.contains { $0.videoId == videoId }
    }

    func setTracks(_ tracks: [MyTrackCloud]) {
        self.tracks = tracks
    }

    func add(_ track: MyTrackCloud) {
        guard !contains(videoId: track.videoId) else {
            return
        }

        tracks.append(track)
    }

    func remove(videoId: String) {
        tracks.removeAll { $0.videoId == videoId }
    }

    func reset() {
        tracks.removeAll()
    }
}
