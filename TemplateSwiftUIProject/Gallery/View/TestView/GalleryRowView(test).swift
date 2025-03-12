//
//  GalleryRowView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 10.03.25.
//

//import SwiftUI
//// адаптивная ячейка по высоте
//struct GalleryRowView: View {
//    let book: GalleryBook
//    @EnvironmentObject var localization: LocalizationService
////    @EnvironmentObject var homeCoordinator: HomeCoordinator
//    
//    var body: some View {
//        HStack(spacing: 10) {
//            WebImageView(url: URL(string: book.urlImage), placeholder: Image(systemName: "photo"), width: 50, height: 50)
//            VStack(alignment: .leading) {
//                Text(book.title.value())
//                    .font(.headline)
//                    .lineLimit(1)
//                Text(book.description.value())
//                    .font(.subheadline)
//                    .lineLimit(2)
//                Text(book.author)
//                    .font(.caption)
//                    .lineLimit(1)
//            }
//            .fixedSize(horizontal: false, vertical: true) // Адаптивная высота
//            Spacer() // Добавление Spacer для заполнения оставшегося пространства
//        }
//        .frame(minHeight: 60) // Минимальная высота
//        .background(Color.clear) // Прозрачный фон для расширения области нажатия
//        .contentShape(Rectangle()) // Задает форму области для захвата событий жестов
//    }
//}

