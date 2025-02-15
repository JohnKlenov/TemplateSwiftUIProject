//
//  WebImageView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.02.25.
//

import SwiftUI
import SDWebImageSwiftUI

struct WebImageView: View {
    let url: URL?
    let placeholder: Image
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        WebImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill) //Заполняет контейнер изображением, сохраняя пропорции.
                .frame(width: width, height: height)
                .clipped() //Обрезает изображение, чтобы оно не выходило за пределы контейнера.
        } placeholder: {
            //                        Color.black
            //ProfileView() Ваш кастомный плейсхолдер
            placeholder
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: width, height: height)
        }
        .onFailure { error in
            print("Ошибка загрузки изображения: \(error.localizedDescription)")
        }
        .indicator(.progress(style: .automatic))
        .transition(.fade(duration: 0.5)) // Плавное появление
        .scaledToFill() // Заполнение контейнера
        .frame(width: width, height: height)
        .clipped()
    }
}



// MARK: Типы ошибок, которые могут возникнуть: .onFailure

//Ошибка сети (Network Error):
//Пример: Error Domain=NSURLErrorDomain Code=-1009 "The Internet connection appears to be offline."
//Ошибка URL (URL Error):
//Пример: Error Domain=NSURLErrorDomain Code=-1002 "unsupported URL"
//Ошибка сервера (Server Error):
//Пример: Error Domain=NSURLErrorDomain Code=404 "Not Found"
//Ошибка декодирования (Decoding Error):
//Пример: Error Domain=SDWebImageErrorDomain Code=4 "Image data is corrupted"
//Ошибка кеширования (Caching Error):
//Пример: Error Domain=SDWebImageErrorDomain Code=5 "Cannot write image to cache"

//Ошибка сети: Возникает при проблемах с подключением к интернету.
//Ошибка URL: Возникает при недействительном или неподдерживаемом URL.
//Ошибка сервера: Возникает при получении ошибки от сервера (например, 404 Not Found).
//Ошибка декодирования: Возникает при невозможности декодировать изображение.
//Ошибка кеширования: Возникает при проблемах с сохранением или чтением изображений из кеша.


//import SDWebImageSwiftUI
//
//struct SDWebImageLoader: ImageLoader {
//    func loadImage(from url: URL, placeholder: Image, width: CGFloat, height: CGFloat) -> AnyView {
//        return AnyView(
//            WebImage(url: url) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: width, height: height)
//                    .clipped()
//            } placeholder: {
//                placeholder
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: width, height: height)
//            }
//            .onFailure { error in
//                print("Ошибка загрузки изображения: \(error.localizedDescription)")
//            }
//            .indicator(.progress(style: .automatic))
//            .transition(.fade(duration: 0.5))
//            .scaledToFill()
//            .frame(width: width, height: height)
//            .clipped()
//        )
//    }
//}


//struct HomeContentView: View {
//    let imageLoader: ImageLoader
//    // ... остальной код
//
//    private func bookRowView(_ book: BookCloud) -> some View {
//        VStack {
//            HStack(spacing: 10) {
//                if let url = URL(string: book.pathImage) {
//                    imageLoader.loadImage(from: url, placeholder: Image(systemName: "photo"), width: 50, height: 50)
//                } else {
//                    Image(systemName: "photo")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 50, height: 50)
//                }
//
//                VStack(alignment: .leading) {
//                    Text(book.title)
//                        .font(.headline)
//                    Text(book.description)
//                        .font(.subheadline)
//                    Text(book.author)
//                        .font(.subheadline)
//                }
//                Spacer()
//            }
//            .onTapGesture {
//                if let id = book.id {
//                    homeCoordinator.navigateTo(page: .bookDetails(id))
//                }
//            }
//        }
//    }
//}
