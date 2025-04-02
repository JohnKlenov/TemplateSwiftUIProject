//
//  ProductCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//

import SwiftUI


// MARK: - Version Frame Bilding 

//struct ProductCell: View {
//    let item: ProductItem
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // Изображение: его высота рассчитывается по соотношению 3:2 от переданной ширины
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholderColor: AppColors.secondaryBackground,
//                width: width,
//                height: width * 0.66
//            )
//            .clipped()
//            // Вычисляем высоту для текстовой части:
//            // imageHeight = width * 0.66, тогда текстовый блок должен занять:
//            let imageHeight = width * 0.66
//            let textBlockHeight = height - imageHeight
//            
//            // Текстовая информация обвернута во VStack с фиксированной высотой,
//            // чтобы все ячейки имели одинаковое расположение текста.
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//            }
//            .frame(height: textBlockHeight) // Фиксированная высота текстового блока
//            .padding(.horizontal, 8)
//            .padding(.bottom, 6)
//        }
//        // Фиксируем размеры всей ячейки
//        .frame(width: width, height: height)
//        .background(Color.red.opacity(0.2))
//        .cornerRadius(8)
//    }
//}


//struct ProductCell: View {
//    let item: ProductItem
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Изображение: его высота рассчитывается с соотношением 3:2 от переданной ширины
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholderColor: AppColors.secondaryBackground,
//                width: width,
//                height: width * 0.66
//            )
//            .clipped()
//            
//            // Текстовая информация
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        // Фиксируем размеры ячейки согласно вычисленным значениям
//        .frame(width: width, height: height)
//        .background(Color.red.opacity(0.2))
//        .cornerRadius(8)
//    }
//}

//struct ProductCell: View {
//    let item: ProductItem
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Изображение: высота рассчитывается по соотношению 3:2 от переданной ширины
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholderColor: AppColors.secondaryBackground,
//                width: width,
//                height: width * 0.66
//            )
//            .clipped()
//            
//            // Текстовая информация
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        // Задаём точные размеры ячейки
//        .frame(width: width, height: height)
//        .background(Color.red.opacity(0.2))
//        .cornerRadius(8)
//    }
//}


//struct ProductCell: View {
//    let item: ProductItem
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Изображение: его высота вычисляется по соотношению 3:2
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholderColor: AppColors.secondaryBackground,
//                width: width,
//                height: width * 0.66
//            )
//            .clipped()
//            
//            // Текстовая информация
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        // Явно задаём общую ширину и высоту ячейки
//        .frame(width: width, height: height)
//        .background(Color.red.opacity(0.2))
//        .cornerRadius(8)
//    }
//}

//struct ProductCell: View {
//    let item: ProductItem
//    let width: CGFloat
//    let height: CGFloat
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            // Передаём ширину, а высоту изображения вычисляем по соотношению 3:2
//            WebImageView(
//                url: URL(string: item.urlImage),
//                placeholderColor: AppColors.secondaryBackground,
//                width: width,
//                height: width * 0.66
//            )
//            .clipped()
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        // Явно задаём общую ширину и высоту ячейки
//        .frame(width: width, height: height)
//        .background(Color.red.opacity(0.2))
//        .cornerRadius(8)
//    }
//}

//struct ProductCell: View {
//    let item: ProductItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) { // Заменяем ZStack на VStack
//            // Изображение
//           
//                
//                // Текстовая информация
//                VStack(alignment: .leading, spacing: 4) {
//                    GeometryReader { geometry in
//                        WebImageView(
//                            url: URL(string: item.urlImage),
//                            placeholderColor: AppColors.secondaryBackground,
//                            width: geometry.size.width,
//                            height: geometry.size.width * 0.66 // 3:2 соотношение
//                        )
//                    }
//                    .aspectRatio(3/2, contentMode: .fit)
//                    Text(item.title.value())
//                        .font(.headline)
//                        .lineLimit(2)
//                    
//                    Text(item.author)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    Text(item.description.value())
//                        .font(.caption)
//                        .lineLimit(3)
//                }
//                .padding(.horizontal, 8)
//                .padding(.bottom, 8)
//        }
//        .background(Color.red.opacity(0.2))
//    }
//}


//struct ProductCell: View {
//    let item: ProductItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) { // Заменяем ZStack на VStack
//            // Изображение
//            GeometryReader { geometry in
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholderColor: AppColors.secondaryBackground,
//                    width: geometry.size.width,
//                    height: geometry.size.width * 0.66 // 3:2 соотношение
//                )
//            }
//            .aspectRatio(3/2, contentMode: .fit)
//            
//            // Текстовая информация
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        .background(Color.red.opacity(0.2))
////        .background(
////            RoundedRectangle(cornerRadius: 8)
////                .fill(AppColors.background)
////                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
////        )
//    }
//}


//struct ProductCell: View {
//    let item: ProductItem
////    @State private var imageHeight: CGFloat = 0
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            GeometryReader { geometry in
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholderColor: AppColors.secondaryBackground,
//                    width: geometry.size.width,
//                    height: geometry.size.width * 1.3 // 4:3 aspect ratio
//                )
//                .cornerRadius(8)
//                .clipped()
////                .onAppear {
////                    imageHeight = geometry.size.width * 1.3
////                }
//            }
//            .aspectRatio(1.3, contentMode: .fit) // Сохраняем пропорции
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                    .fixedSize(horizontal: false, vertical: true)
//                
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .lineLimit(1)
//                
//                Text(item.description.value())
//                    .font(.caption)
//                    .lineLimit(3)
//                    .fixedSize(horizontal: false, vertical: true)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(AppColors.background)
//                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
//        )
//        .padding(4)
//    }
//}



//struct ProductCell: View {
//    let item: ProductItem
//
//    var body: some View {
//        GeometryReader { geo in
//            VStack(alignment: .leading, spacing: 8) {
//                // Рассчитываем размеры изображения равными ширине ячейки и пропорциональной высотой
//                let horizontalPadding: CGFloat = 4
//                let cellWidth = geo.size.width - 2 * horizontalPadding
////                (9 / 16)
//                let imageHeight = cellWidth * 0.7
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholderColor: AppColors.secondaryBackground,
//                    width: cellWidth,
//                    height: imageHeight
//                )
//                .cornerRadius(8)
//                .clipped()
//                
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Text(item.description.value())
//                    .font(.body)
//                    .lineLimit(3)
//            }
//            .padding(4)
//            .background(AppColors.background)
//        }
//        .frame(height: 300) // Определяем высоту ячейки; можно экспериментировать с этим значением
//        .background(Color.red.opacity(0.2))
//    }
//}
//


//struct ProductCell: View {
//    let item: ProductItem
//    
//    var body: some View {
//        Group {
//            // Вычисляем ширину изображения с учётом горизонтальных отступов (например, 16 с обеих сторон)
//            let imageWidth: CGFloat = UIScreen.main.bounds.width - 32
//            // Задаём соотношение сторон, например, 16:9 (высота = ширина * (9/16))
//            let imageHeight: CGFloat = imageWidth * (9 / 16)
//            
//            VStack(alignment: .leading, spacing: 10) {
//                // Изображение с динамической высотой
//                WebImageView(
//                    url: URL(string: item.urlImage),
//                    placeholder: Image(systemName: "photo"),
//                    width: imageWidth,
//                    height: imageHeight
//                )
//                .cornerRadius(8)
//                .clipped()
//                
//                // Заголовок (title)
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(2)
//                
//                // Автор (author)
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                // Описание (description)
//                Text(item.description.value())
//                    .font(.body)
//                    .lineLimit(3)
//            }
//            .padding()
//        }
//    }
//}

//struct ProductCell: View {
//    let item: ProductItem
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.green)
//            Text(item.title.value())
//                .font(.subheadline)
//                .foregroundColor(.white)
//        }
//        .frame(height: 100)
//    }
//}
