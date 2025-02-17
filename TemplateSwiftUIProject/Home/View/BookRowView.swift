//
//  BookRowView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 17.02.25.
//


///Модификатор scaledFontForTextStyle: Этот модификатор указывает, что текст должен адаптироваться к изменениям размера текста, внесенным пользователем в настройках устройства.
// .font(.system(.headline, design: .default).scaledFontForTextStyle(.headline))


import SwiftUI
// адаптивная ячейка по высоте
struct BookRowView: View {
    let book: BookCloud
    @EnvironmentObject var homeCoordinator: HomeCoordinator
    
    var body: some View {
        HStack(spacing: 10) {
            WebImageView(url: URL(string: book.urlImage), placeholder: Image(systemName: "photo"), width: 50, height: 50)
            VStack(alignment: .leading) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(book.description)
                    .font(.subheadline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.caption)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: false, vertical: true) // Адаптивная высота
            Spacer() // Добавление Spacer для заполнения оставшегося пространства
        }
        .frame(minHeight: 60) // Минимальная высота
        .background(Color.clear) // Прозрачный фон для расширения области нажатия
        .contentShape(Rectangle()) // Задает форму области для захвата событий жестов
        .onTapGesture {
            if let id = book.id {
                homeCoordinator.navigateTo(page: .bookDetails(id))
            }
        }
    }
}

