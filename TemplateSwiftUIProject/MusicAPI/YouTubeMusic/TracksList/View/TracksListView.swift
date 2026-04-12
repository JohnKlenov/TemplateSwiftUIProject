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



// TracksListView нужно переводить на Home View
// Структура композитного view. 
// Верхний блок небольшая карусель с бил бордами
// Средняя секция карусель как в VK на сообществах при прокрутки вниз этой ленты эта секция прилипает к верху экрана и далее идет лента с плэйлистами
//лента с плэйлистами - Droplist (первая вкладка в средней секции) - тут только плэйлисты с новинками
// Anyplaylist (вторая вкладка в средней секции) - тут разные тематические плэйлисты (не новинки, что то из прошлых лет не вошедшее в Droplist и прочее)
// All track for droplist (третяя вкладка в средней секции) - тут просто все треки по порядку одно лентой для Droplist было бы не похо что бы при прокрутки отображались года релизов!
// при нажатии на трек открывается плеер для одного трека.
// мы можем добавить каждый трек в мои треки и в плейлист.
// нвад всеми треками есть строка с Reserch.
// All track for Anyplaylist (третяя вкладка в средней секции) - тут просто все треки по порядку одно лентой для Anyplaylist!
// при нажатии на трек открывается плеер для одного трека.
// мы можем добавить каждый трек в мои треки и в плейлист.
// нвад всеми треками есть строка с Reserch.

// лента с плэйлистами - Droplist - выглядит как лента в сообществе VK (картинка состоящая из обложек альбомов для релизов котороые представлены в плэйлисте + поверх полупрозрачная дорожка с названиями альбомов по нажатию на которую мы переходим в навигационном стеке на PlayerEmbedView а под картинкой с обложками альбомов текстовое поле в котором указаны через || артисты которые представлены в плэйлисте)

// структура данных на CloudFirestore должна отталкиваться от структуры UI на Home View???


//Tabbar

// Home + Navigation + MyMusic + Profile
// Navigation - возможность гулять по массиву всех треков переходя в подмассивы разных категорий + рекомендации + top world charts (Rap / hiphop/ R&B ... GYM, Pathy ..)
// MyMusic - мои треки в списке + кастомные плэйлисты (возможность удалять и добавлять и редактировать) + возможность миграции всех треков в Youtube music 


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
        }
        .navigationBarBackButtonHidden(true)
    }
}







//            .sheet(item: $selectedTrack) { track in
//                print("📱 Открываем плеер: tracksForPlayer.count = \(vm.tracks)")
//                return PlayerEmbedView(
//                    tracks: vm.tracks,
//                    initialTrack: track
//                )
//            }



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

