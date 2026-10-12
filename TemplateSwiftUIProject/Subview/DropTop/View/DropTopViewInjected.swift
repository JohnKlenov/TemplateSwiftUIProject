//
//  DropTopViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//

//  в details массив с элементами (артист - альбом для отображения как на droplist) - но details мы не будем отображать как на droplist так как в Droptop этот список будт большой и перекроет весь экран на старте - этот список нужно будет отображать на отдельном экране по кнопке!
// для первых тестов не будем реализовывать только на этапе финиша!



// проблемы :

// нажатие на ячейку в списках работает только если это происходи в зону с текстом ???

// при обновлении данных на домашнем экране мы при переходе на дроптоп не переходдим на новый фетч а почему то используем кэш хотя должны как только данные обновились на главном экране делать новый фетч на всех экранах
// при обновлении на дроп топ списка у нас сразу пропадает список с рывком !
// проблема с тем что скрол повторяет высоту на новых вкладках дроптоп


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
