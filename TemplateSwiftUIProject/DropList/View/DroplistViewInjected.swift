//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//


// Tabs DropTop

// info:

// DropTopView - это выжимка лучших треков из наших списков Droplist
// по Top Year (за год) + Top Quarter(в году 4 квартала по 3 месяца в каждом и возможно не все треки из 4 квартолов попудут в Top Year) + Artist (список всех артистов попавших в Top Drop и каждый раз при выходе нового Top Year или Top Quarter мы будем пополнять их треками   -   тут нужно будет продумать как мы будем сортировать список потому что по дате будет не корректно нужны будут индексы)





// Tabs Category

// Это список который имеет четкую структуру

// Верхняя секция
// Alltracks + DropTop

// Средняя секция
// фильтры для Alltracks (gym + chill + party + triller) - делаем запрос с фильтром по тегу для Alltracks.
// фильтры для Alltracks (young money(>30) + old money((<30))) то есть молодые исполнители и уже уходящие в закат
// фильтры для Alltracks Artists - список артистов при переходе по которым мы можем увидеть все треки из Alltracks с их участием (ставим тег artistTag: и как нибудь коротко .wayne если трек с двумя артистами то [.wayne, .drake]) то есть при переходе на артиста мы делаем запрос с фильтром по тегу для Alltracks.
// фильтры для Alltracks musical genre (RNB HipHop Rock ...) ???

// (нужно предоставить модель для того что бы спросить как добавлять нужые теги для young money + artistTag ??? )

// Нижняя секция
// Unpublished(то что пропустили с 2015 и не попало в Droplist) + Все что за гранью начала мониторинга Droplist (то есть если старт 2015 то треки из 2014 уже тут)
// все это списком треков
// как вариант можно такие треки из Unpublished добавлять в Droplist которые подходят по дате уже ранее опубликованные но тогда придется так же добовлять эти треки и в DropTop
// или иметь список Unpublished + но из него по годам добавлять треки в DropTop даже после публикации (Top Year (за год) + Top Quarter) ???



// когда мы на Tabs Category на Alltracks
// затем перешли на Tabs DropTop обновили контент и перешли назад на Tabs Category / Alltracks
// нам поидее нужно на onAppier проверять обновился ли на DropTop если да то делать фетч из сети и удалять кэш???

// фича с зеленым кружочкам над ячейкой трека это зачит мы его включали один раз уже (то есть мы должны иметь отдельный MyPlaylistListened то есть если включали и люьой треклист который мы открывапем должен сверяться с этим массивом и там где нужно простовлять маленький кружочек или точку )







// Tabs MyPlaylist


// для версии 2.0  нужно оставить так же стратегию использования AppleMusic - то есть интерфейс будет все тот же но дата сорс уже будет тругой



// что делаем:
// изучаем как работает DropTopContentView с взаимодействием с DropTopPagesCache
// у нас вместо LowerSectionPage для DropTop struct DropTopPage и отдельный DropTopPagesCache
// может можно интегрировать его в PagesCache









// смортри давай сделаем экран  Library LibraryView на основе нашего экрана Gallery
// это будет один из tabItem в нашем tabBar
// он будет сделан по принципу наших прошлых экранов TracklistView и DropTopView
// экран будет иметь вид вертикольной ленты которая может скроллится которая будет состоять из ячеек с текстовым полем (названием ячейки)
// значит что это за ячейки и в каком порядке они будут расположены на LibraryView:
//
// я бы может даже разбил их на три такие секции в одном списке:
//
// Alltracks
// DropTop
// Artists
//
// Gym
// Party
// RnB
//
// Unpublished
//
//
// что это за ячейки куда по ним должны перейти
//
// Alltracks (список всех треков) мы уже реализовывали и переход на него тоже может ты помниш это через прошлые наши чаты!
// вот такой будет переход:
//onAllTracks: {
//droplistCoordinator.navigateTo(
//    page: .allTracks
//)
//}
//
// DropTop (список топ треков по годам кварталам и артистам) мы уже реализовывали и переход на него тоже может ты помниш это через прошлые наши чаты!
// вот такой будет переход:
//droplistCoordinator.navigateTo(
//    page: .topDrops
//)
// сразу скажу мы не будем использовать отдельный galleryCoordinator а будет общий координатор для двух табов Home и Library - droplistCoordinator ! так как у нас есть общие переходы что в одном что во втором случае.
//
//
//
// Секция Gym + Party + RnB
// по сути у нас в каждом документе (треке) есть поле tags это array и в нем может быть несколько значений одновременно но может быть и один
// то есть вот в этом пути /dropTracks/ лежат документы (это и есть треки) в котором есть поле tags
// и вот тут может быть либо значение "gym" или "party" или "rnb" или несколько из них одновременно
//        case .gym:
//            return "gym"
//
//        case .party:
//            return "party"
//
//        case .rnb:
//            return "rnb"
//        }
//
// то есть нам нужно делать запрос к Alltracks (/dropTracks/) с фильтром (Gym, Party или RnB) в зависимости на какую ячейку нажмем
// отображение полученных треков будет на экране TracklistViewInjected
// то есть нужно будет добавить новые case для DroplistFlow - Gym, Party или RnB - они уже есть
// и для trackType новые кейсы передавать (Gym, Party или RnB) но они уже есть в CarouselItemType
// через:
//@ViewBuilder
//func dropViewBuild(page: DroplistFlow) -> some View {
//
//    switch page {
//
//    case .droplist:
//        DroplistViewInjected(
//            sessionManager: appSessionManager,
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser
//        )
//
//    case .someDroplistView:
//        SomeView()
//
//    case .allTracks:
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .allTracks,
//            navigationTitle: "All Tracks"
//        )
//
//    case .topDrops:
//        DropTopViewInjected(
//            dropListDataSource: dropListDataSource
//        )
//
//    case .droplistDetails(
//        let playlistId,
//        let details,
//        let title,
//        let imageURL
//    ):
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .droplistDetails(
//                playlistId: playlistId
//            ),
//            navigationTitle: title,
//            details: details,
//            imageURL: imageURL
//        )
//
//    case .topDropDetails(
//        let playlistId,
//        let title,
//        let imageURL
//    ):
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .topDropDetails(
//                playlistId: playlistId
//            ),
//            navigationTitle: title,
//            imageURL: imageURL
//        )
//
//    case .dropTopDetails(
//        let playlistId,
//        let title,
//        let imageURL
//    ):
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .dropTopDetails(
//                playlistId: playlistId
//            ),
//            navigationTitle: title,
//            imageURL: imageURL
//        )
//    }
//}
// весь контекст я сброшу отдельным сообщением что бы было понятно
//
// ячейка Artists из верхней секции
// я хочу что бы при нажатии на нее мы переходили на экран ArtistsView это экран будет иметь вид вертикольной ленты которая может скроллится которая будет состоять из ячеек с текстовым полем (названием ячейки) и в будущем наверно с картинкой !
// это будет список артистов или названия групп всех исполнителей которые попали в наш Alltracks (/dropTracks/)
// я думаю что я могу создать коллекцию Artists и руками в ней создавать документы для каждого атиста в нем будут поля с названием артиста время создания может быть индекс что бы по нему сортировать список при получении из сети возможно в будщем урл для картинки и tag?
// то есть как тольок повляется новый трек с новым артистом я создаю документ для него в Artists
// и при переходе на каждую из этих ячеек мы будем открывать список всех треков того или иного артиста или группы из наших Alltracks (/dropTracks/)
// переход из ячейки конкретного артиста я бы так же хотел делать по полю tags так же как мы это будем делать для Gym + RnB ...
// то есть для каждого артиста мы создадим короткий tag например case .lilWayne  ,будет записан в массив tags "LilWayne"
// если трек исполняют несколько артистов или коллективов то в поле tags для каждого трека в Alltracks (/dropTracks/) будет записано несколько "LilWayne" + "SnoopDog"
// отображение полученных треков будет на экране TracklistViewInjected
//
//
// Unpublished (просто список треков как Alltracks (/dropTracks/) но только по пути (/unpublished/) которые не вошли в Alltracks) тут при переходе по этой ячейки мы сразу переходим на TracklistViewInjected
//
//
//
//
// вопрос по CarouselItemType
// тут нужно создать какой то кейс для Artists что бы можно было использовать ключи для сохранения в кэш? какой то на подобии case .Artists(let ArtistId) ?
// в actor PagesCache {
//
//private var temporaryCache: [String: LowerSectionPage] = [:]
//private var permanentCache: [String: LowerSectionPage] = [:]
// есть два типа кэша temporaryCache + permanentCache
// и наши Artists + Gym + Party + RnB + Unpublished дожны попасть в temporaryCache
// то есть var isPermanentCache для этих  Artists + Gym + Party + RnB + Unpublished  будет false
//
//
// при загрузки Library в память нам не нужен спинер так как при первом его появлении мы не делаем запроса в сеть
//

// пока не подготавливай ответ по тому что я дам тебе в следующем сообщении контекст в виде кодовой базы!


import SwiftUI

struct DroplistViewInjected: View {

    // ============================================================
    // MARK: - ViewModel
    // ============================================================

    @StateObject private var viewModel: DroplistViewModel

    // ============================================================
    // MARK: - Init
    // ============================================================

    init(
        sessionManager: AppSessionManager,
        dropListDataSource: DropListDataSource,
        playlistUser: PlaylistUser
    ) {
        _viewModel = StateObject(
            wrappedValue: DroplistViewModel(
                sessionManager: sessionManager,
                dropListDataSource: dropListDataSource,
                playlistUser: playlistUser
            )
        )
    }

    // ============================================================
    // MARK: - Body
    // ============================================================

    var body: some View {
        let _ = Self._printChanges()

        DroplistContentView(
            viewModel: viewModel
        )
    }
}

// MARK: - before PlaylistUser

//import SwiftUI
//
//struct DroplistViewInjected: View {
//    
//    @StateObject private var viewModel: DroplistViewModel
//    
//    init(sessionManager: AppSessionManager, dropListDataSource:DropListDataSource) {
//        
//        _viewModel = StateObject(
//            wrappedValue: DroplistViewModel(
//                sessionManager: sessionManager, dropListDataSource: dropListDataSource)
//        )
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        DroplistContentView(viewModel: viewModel)
//    }
//}








