//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//


// Tabs DropTop

// нужно локализовать все текста + картинки
// // одинаковый ли у нас errorView для paginationFooter (главнфй экран дроплист и дроптоп)???

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








