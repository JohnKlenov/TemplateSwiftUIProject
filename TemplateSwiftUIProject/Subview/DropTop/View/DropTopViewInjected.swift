//
//  DropTopViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//

// изменение для title в Droptop:
// у нас будут две строки в func dropTopRow DropTopContentView - первая title а вторая 100 Tracks ("\(trackCount) Tracks") с секондери стилем
// то есть в dropTopRow для разных плейлистов будет так (Top years - Top Tracks 2025 + 100 Tracks, Top Quarter - Top Tracks 2036 | First Quarter + 100 Tracks, Artist - This Is Drake | Vol. 1 2036 + 100 Tracks)
// меняем title в savePlaylistToDropTop() для тэгов + меняем Top Decada на Top Quarter
// для Top years - Top Tracks 2025
// для Top Quarter - Top Tracks 2036 | First Quarter (First Quarter + Second Quarter + Third Quarter + Fourth Quarter)
// для Artist - This Is Drake | Vol. 1 2036

// в description будет храниться список артистов на плейлисте а в details массив с элементами (артист - альбом для отображения как на droplist) - но details мы не будем отображать как на droplist так как в Droptop этот список будт большой и перекроет весь экран на старте - этот список нужно будет отображать на отдельном экране по кнопке!
// для первых тестов не будем реализовывать только на этапе финиша!

// нам нужно в func savePlaylistToDropTop() изменить логику создание и сохранение тестовых плэйлистов!
// изменить текст для title (для плейлистов Top years + Top Quarter (Top Decada убераем и изменяем тег на Top Quarter  во всех сущностях а именно в enum DropTopTag нужно сделать эту замену) + Artist)
// теперь давай поговорим об изменении логики создания и сохранения:
// сейчас мы сохраняем по порядку сначало Top years с 2026 по 2036 потом все Top Decada по порядку декад и по году (незабудь мы меняем это на Top Quarter) затем Artist по порядку и по годам!
// то есть при загрузки all мы получаем список сначало все Top years потом все Top Quarter потом все Artist!
// а мне хочется что бы это в списке выглядело естественно как будто мы из года в год заполняли список
// то есть сначало Top years 2026 потом все его четыре Top Quarter а затем артисты Drake 2026 LilWayne 2026! и вот так это будет естественно выглядеть для тестов!
// дай мне пожалуйста такую реализацию savePlaylistToDropTop()


// проблемы :

//VStack(alignment: .leading, spacing: 4) {
//Text(item.title)
//    .font(.headline)
//    .foregroundColor(.primary)
//    .lineLimit(2)
//
//Text("\(item.trackCount) Tracks")
//    .font(.subheadline)
//    .foregroundColor(.secondary)
//}

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
