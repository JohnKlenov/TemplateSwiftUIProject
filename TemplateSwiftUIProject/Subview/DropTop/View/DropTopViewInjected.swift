//
//  DropTopViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//

//  в details массив с элементами (артист - альбом для отображения как на droplist) - но details мы не будем отображать как на droplist так как в Droptop этот список будт большой и перекроет весь экран на старте - этот список нужно будет отображать на отдельном экране по кнопке!
// для первых тестов не будем реализовывать только на этапе финиша!



// проблемы :

// при обновлении на дроп топ списка у нас сразу пропадает список с рывком !
// .refreshable мы пока блокируем и возможно его не будет в проде
// а если ты обновил тэг артистов потом перешол на алл а там еще нет новых данных так как есть кэш?


// сейчас мы при загрузки видим список который начинается с самых ранних лет 2026 а потом листаем вниз до 2036, должно быть на оборот!
// так потому что мы создали объекты в неправильном порядке а сортировка по createdAt


// делаем переход на TrackView
// одинаковый ли у нас errorView для paginationFooter (главнфй экран дроплист и дроптоп)???




// DropTopView - это выжимка лучших треков из наших списков Droplist
// по Top Year (за год) + Top Quarter(в году 4 квартала по 3 месяца в каждом и возможно не все треки из 4 квартолов попудут в Top Year) + Artist (список всех артистов попавших в Top Drop и каждый раз при выходе нового Top Year или Top Quarter мы будем пополнять их треками   -   тут нужно будет продумать как мы будем сортировать список потому что по дате будет не корректно нужны будут индексы)


import SwiftUI

struct DropTopViewInjected: View {

    @StateObject private var viewModel: DropTopViewModel

    init(
        dropListDataSource: DropListDataSource
    ) {
        _viewModel = StateObject(
            wrappedValue: DropTopViewModel(
                dropListDataSource: dropListDataSource
            )
        )
    }

    var body: some View {
        DropTopContentView(
            viewModel: viewModel
        )
    }
}
