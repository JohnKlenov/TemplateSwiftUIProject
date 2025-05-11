//
//  ProductCell.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//


import SwiftUI
    

struct ProductCell: View {
    
    @EnvironmentObject var localization: LocalizationService
    
    let item: ProductItem
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
                WebImageView(
                    url: URL(string: item.urlImage),
                    placeholderColor: AppColors.secondarySystemBackground,
                    displayStyle: .aspectRatio(2/3, contentMode: .fit)
                )
            ///Да, если вы добавите .frame(height: 200) к WebImageView с модификатором .aspectRatio(2/3, contentMode: .fit), то ширина будет автоматически подбираться так, чтобы соблюдалось соотношение 2:3 (то есть около 133 pt для высоты 200 pt), при условии отсутствия других ограничений по ширине.
            ///Мы можем передавать значение height в качестве параметра в зависисмости от ширины и высоты доступного экрана!
                .frame(height: 200)
//                .background(GeometryReader { geometry in
//                    Color.clear
//                        .onAppear {
//                            print("Высота WebImageView: \(geometry.size.height)")
//                            print("Ширина WebImageView: \(geometry.size.width)")
//                        }
//                })
                .cornerRadius(12)
           
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.value())
                    .font(.headline)
                    .lineLimit(1)
                
                Text(item.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(item.description.value())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.top, .bottom], 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.secondarySystemBackground)
        )
//        .background(GeometryReader { geometry in
//            Color.clear
//                .onAppear {
//                    print("Высота ProductCell: \(geometry.size.height)")
//                    print("Ширина ProductCell: \(geometry.size.width)")
//                }
//        })
    }
}




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


