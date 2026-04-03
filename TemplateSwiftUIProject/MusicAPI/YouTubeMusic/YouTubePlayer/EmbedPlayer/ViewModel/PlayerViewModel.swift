//
//  EmbedPlayerViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 2.04.26.
//


//  Управляет текущим треком и состоянием плеера



import SwiftUI
import Combine

@MainActor
class PlayerViewModel: ObservableObject {
    @Published var currentTrack: Track
    @Published var tracks: [Track] = []
    @Published var isPlaying = false
    
    init(tracks: [Track], initialTrack: Track) {
        self.tracks = tracks
        self.currentTrack = initialTrack
        self.isPlaying = true
    }
    
    func selectTrack(_ track: Track) {
        currentTrack = track
        isPlaying = true
    }
    
    deinit {
        print("deinit PlayerViewModel")
    }
}




//import SwiftUI
//import Combine
//
//@MainActor
//class PlayerViewModel: ObservableObject {
//    @Published var currentTrack: Track?
//    @Published var tracks: [Track] = []
////    @Published var isPlaying = false
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    // Новый инициализатор
//    init(tracks: [Track] = [], initialTrack: Track? = nil) {
//        self.tracks = tracks
//        self.currentTrack = initialTrack ?? tracks.first
////        self.isPlaying = currentTrack != nil
//    }
//    
//    // Выбор трека для воспроизведения
//    func selectTrack(_ track: Track) {
//        currentTrack = track
////        isPlaying = true
//    }
//    
//    // Загрузка списка треков (оставляем для совместимости, но можно удалить)
//    func loadTracks(_ tracks: [Track]) {
//        self.tracks = tracks
//        if currentTrack == nil && !tracks.isEmpty {
//            currentTrack = tracks.first
//        }
//    }
//}


//import SwiftUI
//import Combine
//
//@MainActor
//class PlayerViewModel: ObservableObject {
//    @Published var currentTrack: Track?
//    @Published var tracks: [Track] = []
//    @Published var isPlaying = false
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    // Выбор трека для воспроизведения
//    func selectTrack(_ track: Track) {
//        currentTrack = track
//        isPlaying = true
//    }
//    
//    // Загрузка списка треков
//    func loadTracks(_ tracks: [Track]) {
//        self.tracks = tracks
//        // Если есть треки и нет текущего - выбираем первый
//        if currentTrack == nil && !tracks.isEmpty {
//            currentTrack = tracks.first
//        }
//    }
//}
