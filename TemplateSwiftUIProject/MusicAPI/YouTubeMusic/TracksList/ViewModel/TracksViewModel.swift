//
//  TracksViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 30.03.26.
//

import Foundation
import FirebaseFirestore

@MainActor
class TracksViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    private let db = Firestore.firestore()

    func loadTracks() {
        db.collection("playlists")
            .document("FirstList")
            .collection("tracks")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Firestore error: \(error)")
                    return
                }

                guard let docs = snapshot?.documents else {
                    print("snapshot is empty")
                    return
                }

                self.tracks = docs.compactMap { doc in
                    let data = doc.data()
                    return Track(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "",
                        artist: data["artist"] as? String ?? "",
                        thumbnailURL: data["thumbnailURL"] as? String ?? "",
                        videoId: data["videoId"] as? String ?? "",
                        durationISO8601: data["durationISO8601"] as? String ?? ""
                    )
                }
            }
    }
}
