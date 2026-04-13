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




// MARK: -  Структура композитного Droplist:

// структура композитного Droplist

// Верхний блок
// Верхний блок небольшая карусель с бил бордами (top year + top 100 ... )

// Средний блок
// Средний блок горизонтальная карусель c item (Droplist || All tracks for Droplist || GYM || Party || R&B ... )(как в VK на сообществах) При прокрутки общего скрола композитного View (Верхний блок + Средний блок +  Нижний блок) вниз, блок горизонтальной карусели прилипает к верху экрана и далее идет лента с плэйлистами.

// Нижний блок - вертикальная лента  (Droplist или All tracks for Droplist или GYM или Party или R&B .. )
// Droplist
//лента с плэйлистами - Droplist (первая вкладка в средней секции) - тут только плэйлисты с новинками

// All tracks for Droplist
// All track for droplist (вторая вкладка в средней секции) - тут просто все треки по порядку одно лентой для Droplist было бы не похо что бы при прокрутки отображались года релизов!
// при нажатии на трек открывается плеер для одного трека.
// мы можем добавить каждый трек в мои треки и в плейлист.
// над всеми треками есть строка с Reserch. (когда мы листаем вниз она пропадает а когда подымаемся навернх она снова появлятся и как только начинаем скоролить ленту вниз она исчезает)

// лента с плэйлистами - Droplist - выглядит как лента в сообществе VK (картинка состоящая из обложек альбомов для релизов котороые представлены в плэйлисте + поверх полупрозрачная дорожка с названиями альбомов (треки с альбомов: ...) по нажатию на которую мы переходим в навигационном стеке на PlayerEmbedView а под картинкой с обложками альбомов текстовое поле в котором указаны через || артисты которые представлены в плэйлисте)
// картинка состоящая из обложек альбомов должна состоять из картинок которые пришли с треками (мы их не должны хранить в нашей базе данных и по возможности не кэшировать что бы не нарушать авторских прав + свои картинки лучше не вставлять можно получить бан ??? )

//GYM || Party || R&B
// в вертикальной ленте выглядит как список треков (или  как лента с плэйлистами)


//Tabbar

// Home + Navigation(для MVP не нужен) + MyMusic + Profile
// Navigation - возможность гулять по массиву всех треков переходя в подмассивы разных категорий + рекомендации + top world charts (Rap / hiphop/ R&B ... GYM, Pathy ..)
// MyMusic - мои треки в списке + кастомные плэйлисты (возможность удалять и добавлять и редактировать) + возможность миграции всех треков в Youtube music 



// MARK: - fetch data (из CloudFirestore)

// при первом запуске HomeView мы делаем запросы в CloudFirestore для получения данных для:

// Верхний блок + Средний блок + Нижний блок (но первым делом мы должны выполнить запрос на получение данных о том какие треки уже добавлены в "карзину" MyTrack - это важно для того что бы правильно реализовывать логику в PlayerEmbedView при нажатии на кнопку ellipsis в PlaylistTrackRow презентуется action shet с вариантами: + добавить в мои треки + добавить в плейлист! Если трек уже добавлен в корзину то кнопка + добавить в мои треки будет отсутствовать в появившимся action shet)
// сдесь нужно очень хорошо продумать архитектуру

//Верхний блок
// получаем только данные для наполнения карусели items то есть url для картинки и title для поисания + ссылку на получения данных при переходе по этому item в карусели.

// Средний блок
// получаем данные для заполнения названия item то есть текст.

// Нижний блок -  при первом старте мы сразу делаем запрос на получение данных для Droplist (но не сразу всю пачку а по мере прокрутки ленты подгружаем новую порцию данных но так что бы немного с запасом за край ленты для лучшего UX)
// при переходе на вкладку All tracks for Droplist мы имеем тот же паттерн получения данных что и в случаи с Droplist


// MARK: - Структура данных

// сейчас у нас есть root collection Plylists(Droplists) -> documents (имя idPlylistForYoutubeMusic) -> collection (tracks) + fields
// collection (tracks) -> documents (имя idVideo (idVideo ащк YoutubeMusic))
// fields - playlistId + description + title + imageURL (его решили убрать так как будем собирать картинку для плэйлиста на клиенте из urlTracks)

// хотелось бы иметь возможность из одного источника root collection Plylists(Droplists)
// наполнять данными все вкладки для items горизонтальной карусели (если это возможно технически)
// наша структура root collection Plylists(Droplists) идеально подходит для наполнения данными ленту Droplist
// Но можно ли будет наполнить из источника root collection Plylists(Droplists) ленту All tracks for Droplist ??? (нужно будет пройтись по всем documents (имя idPlylistForYoutubeMusic) и забрать от туда все tracks для создании вертикальной ленты в Нижнем блоке)
// каждый tracks может иметь поле которое определяет к какой категории относится трек: GYM, R&B и тд. И тоглда может быть можно было бы заполнить данными вертикальную ленту нижнего блока для items среднего блока(GYM, R&B и тд. ) ???
// Если бы было возможно работать со структурой данных в CloudFirestore как мы описаль в root collection Plylists(Droplists) для всех моих сценариев описанных выше было бы просто здорово!
// Мне нужна по возможности идеальная структура данных для моего data source и моей структуры views. Она должна быть оптимизирована с учётом того что  запросы к CloudFirestore это расход выделенных квот которые нужно разумно использовать и экономить.
// Так же я хотел бы каждую ленту в нижнем блоке про пагинировать! то есть я хочу что бы мы получали сразу не все данные из источника root collection Plylists(Droplists) а отдельными порциями для ускорения загрузки и оптимизации ресурсов (если это разумнаый подход в таких сценариях)
// главная задача для меня в блоке Структура данных - профессионально организовать и потимизировать структуру данных в CloudFirestore для использования в моем приложении а сейчас конкретно на экране HomeView.



// как работать с чатом?
// сначало доработает общий функционал на PlayerEmbedView (что бы реализация + добавить в мои треки была в контексте )
// далее подумаем на тишине как лучше для нашей архитектуру в TemplateProject совместить экран Droplist (этап авторизации -> получение данных из корзины -> получение данных для Droplist)! + изоляция старого кода и добавления новых экранов.
// далее нужно попробывать взять за основу наш GalleryView! подумать как его можно адаптировать под наш случай (там уже есть много решенных вопросов)! - скормить всю кодовую базу GalleryView для контекста.
// далее нужно подобрать скрин шоты того как будут выглядеть наш Droplist + описать всю механику (скормить Структура композитного Droplist)
// скормить Структура данных + fetch data (из CloudFirestore) - поговорить о том как организовать струтуру данных и data source
// попросить чат собрать из нашего GalleryView новую реализацию в качестве Droplist (на основе описаний Структуры композитного Droplist + скрин шоты)

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

