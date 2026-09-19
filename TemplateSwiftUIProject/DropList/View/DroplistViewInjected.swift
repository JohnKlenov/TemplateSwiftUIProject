//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//


// TracklistView

//TracklistContentView
//
// Details View
// только для Droplist (карточка в том же дизайне и что карточка TopDrop на главном экране)
// на Details View будет информация Artist - Name Album (year relis)
// как мы будем понимать что нужно отображать этот Details View (у нас будет поле в объекте которое будет содержать эти строки и возможно если это поле не nil мы будем отображать Details View?)

//TracklistViewModel
//
// реализовать viewModel.addToPlaylist(item)
// мы решили что быдем просто сохранять общим списком без деректорий для начала!


// DropTop
//
// DropTop уже имеет путь и метод фетч
// нужно добавить в объект tag или поле по которому мы будем фетч данные только для секции TopDrop на главном экране.
// будет список который будет иметь следующие категории (Top year + Top decada (четыре декады для каждого года) + Artist List#1 и тд + прочии категории типа ечеринка или Рождество и в таком духе)
// каждая категория будет иметь свой tag (All + TopYear + Decada + Artist и так далее)
// то есть мы как и на главном экране в секции TopDrop будем получать весь список и иметь возможность фильтровать по тегам(в новых версиях может сделаем экран фильтр с более сложной настройкой)
// как будет выглядеть ячейка image + Title + ears (Top 2026 or Lil Wayne - List#2 2026 or Top decade 1/2 2026 or Christmas 2020 ) размер как на droplist



// Tabs Category
//
// Верхняя секция список Alltracks + DropTop
// Нижняя секция список - все оттенки gym + pathy ...


// MyPlaylist


// для версии 2.0  нужно оставить так же стратегию использования AppleMusic - то есть интерфейс будет все тот же но дата сорс уже будет тругой


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
