//
//  PopularProductsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//



import SwiftUI
import SDWebImage
import SDWebImageSwiftUI


// MARK: - WebImageView

//.resizable()
///Модификатор .resizable() в SwiftUI говорит системе, что изображение можно изменить по размеру, а не использовать его исходные (физические) размеры. То есть, когда вы применяете этот модификатор к изображению, вы разрешаете SwiftUI масштабировать его, адаптируя под размеры контейнера, куда вы его помещаете (например, через .frame, .aspectRatio, .scaledToFill() или .scaledToFit()).
///Без .resizable(), изображение будет отображаться в своих оригинальных размерах, независимо от того, какой размер имеет контейнер. Это может привести к тому, что изображение либо не заполнит отведённое пространство, либо выйдет за его пределы. С .resizable() изображение подстраивается под заданные размеры, что особенно полезно для создания гибкого и адаптивного интерфейса.

//.scaledToFill()
///.scaledToFill() в SwiftUI — это модификатор, который изменяет масштаб изображения так, чтобы оно заполнило всё доступное пространство контейнера (например, .frame) с сохранением исходных пропорций. Это значит, что изображение не будет искажаться (например, становиться слишком узким или растянутым), но если его соотношение сторон не совпадает с соотношением сторон контейнера, то части изображения могут обрезаться, чтобы полностью заполнить контейнер.
///Как работает .scaledToFill():
///Сохранение пропорций (aspect ratio): Изображение остаётся визуально правильным, масштабируясь одинаково в ширину и высоту. Например, если изображение имеет пропорции 3:2, оно не станет "сквадратным", даже если контейнер — квадрат.
///Заполнение контейнера: Изображение увеличивается или уменьшается так, чтобы занять весь контейнер. Если при этом размеры контейнера и изображения несовместимы по пропорциям, часть изображения будет "обрезана" за пределами контейнера.
//Image("example").resizable().scaledToFill().frame(width: 100, height: 100).clipped()
///Здесь изображение заполнит квадратный контейнер 100x100 пикселей, сохраняя свои пропорции, но часть изображения обрежется, если оно не квадратное.

//scaledToFit()
///Если вместо .scaledToFill() использовать .scaledToFit(), изображение целиком впишется внутрь контейнера, сохраняя пропорции, но при этом может остаться "пустое пространство" (например, появятся полосы сверху/снизу или по бокам).

//.aspectRatio(3/2, contentMode: .fit)
///.aspectRatio(3/2, contentMode: .fit) обеспечивает сохранение соотношения сторон 3:2 при вписывании изображения в доступное пространство. То есть, даже если контейнер меняется по размеру, изображение будет масштабироваться так, чтобы сохранить это соотношение.
///Параметр 3/2 указывает желаемое соотношение ширины к высоте. Это означает, что ширина элемента будет в 1.5 раза больше высоты (так как 3÷2=1.5). То есть, элемент примет пропорции горизонтального прямоугольника.
///соотношением сторон 3:2 — это скорее условное представление пропорций, чем точное пиксель-в-пиксель совпадение.
///3000×2000 пикселей, что математически соответствует пропорции 3:2.
///Когда в программировании (например, в SwiftUI) используется модификатор .aspectRatio(3/2, contentMode: .fit), это указывает на желаемое соотношение сторон для отображения, но SwiftUI не требует идеальной пиксельной точности от изображения. Вместо этого система масштабирует и обрезает его так, чтобы оно выглядело как 3:2 в пределах заданного контейнера.
///Если вы хотите, чтобы изображения выглядели максимально гармонично при использовании конфигурации .aspectRatio(3/2, contentMode: .fit) без лишнего масштабирования или обрезки, лучше подготовить изображения заранее с пропорцией 3:2, прежде чем загружать их на сервер.
///если исходные изображения(на сервере) имеют другие пропорции, система:
///либо уменьшает масштаб изображения, чтобы оно поместилось целиком в контейнер, оставляя "пустые области" по краям;
///либо увеличивает масштаб и обрезает части изображения, чтобы сохранить пропорции 3:2.
///размеры могут быть любыми, главное, чтобы ширина была в 1.5 раза больше высоты.
//.aspectRatio(2/3, contentMode: .fit)
///.aspectRatio(2/3, contentMode: .fit), то элемент или изображение будет масштабироваться так, чтобы его соотношение сторон стало 2:3 — то есть ширина будет в 2 раза меньше высоты. Это приведёт к вертикально ориентированному прямоугольнику, который выглядит более вытянутым по высоте.


struct WebImageViewAspectRatio: View {
    let url: URL?
    let placeholderColor: Color
    
    var body: some View {
        Color.clear
            .overlay(
                WebImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    placeholderColor
                }
                    .indicator(.progress)
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipped())
    }
}

//@Environment(\.dynamicTypeSize) private var dynamicType
///dynamicTypeSize — это встроенное значение в SwiftUI, которое хранит текущий размер текста, установленный пользователем через настройки устройства (в разделе "Размер текста" или "Доступность").
///Значение dynamicTypeSize будет обновляться автоматически, если пользователь изменит настройки(размер текста или увеличить его для лучшей читаемости).
//dynamicType.isAccessibilitySize
///isAccessibilitySize — это свойство переменной dynamicTypeSize. Оно возвращает:
///true, если текущий размер текста относится к категориям "доступности" (например, Extra Large, XXL и выше).
///false, если используется стандартный диапазон размеров текста.
///Таким образом, этот флаг позволяет вашему интерфейсу адаптироваться под большие размеры текста, не требуя ручных вычислений.
///dynamicType.isAccessibilitySize (если размер для доступности, разрешается больше строк).
///Инклюзивность — это принцип, подход или стратегия, направленные на создание среды, где каждый человек чувствует себя принятым, уважаемым и ценным, независимо от его индивидуальных особенностей, таких как происхождение, способности, возраст, пол, культурные или религиозные различия.

//.frame(maxWidth: .infinity, alignment: .leading)
///.frame(maxWidth: .infinity, alignment: .leading) гарантируется, что текст займет максимально доступную ширину, выравниваясь по левому краю.

// MARK: - ProductCell


struct ProductCell: View {
    let item: ProductItem
    @Environment(\.dynamicTypeSize) private var dynamicType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                WebImageViewAspectRatio(
                    url: URL(string: item.urlImage),
                    placeholderColor: Color(.secondarySystemBackground)
                )
                .layoutPriority(1)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title.value())
                    .font(.headline)
                    .lineLimit(dynamicType.isAccessibilitySize ? 3 : 2)
                
                Text(item.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text(item.description.value())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(dynamicType.isAccessibilitySize ? 5 : 3)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding([.bottom, .top], 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    print("Высота ячейки: \(geometry.size.height)")
                }
        })
    }
}



//struct ProductCell: View {
//    let item: ProductItem
//    @Environment(\.dynamicTypeSize) private var dynamicType
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            WebImageViewAspectRatio(
//                url: URL(string: item.urlImage),
//                placeholderColor: Color(.secondarySystemBackground)
//            )
//            .cornerRadius(12)
//            
//            VStack(alignment: .leading, spacing: 6) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(dynamicType.isAccessibilitySize ? 3 : 2)
//                
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                    .lineLimit(1)
//                
//                Text(item.description.value())
//                    .font(.caption)
//                    .foregroundStyle(.tertiary)
//                    .lineLimit(dynamicType.isAccessibilitySize ? 5 : 3)
//            }
//            .padding(.horizontal, 8)
//            ///все работает корректно и без .frame
//            .frame(maxWidth: .infinity, alignment: .leading)
//        }
//        .padding(.bottom, 8)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.secondarySystemBackground))
//        )
//    }
//}

// MARK: - PopularProductsSectionView

//@Environment(\.horizontalSizeClass) private var sizeClass

///@Environment — это механизм SwiftUI, который позволяет вашему представлению (View) получить доступ к информации из окружающей среды приложения, без необходимости передавать её явно.
//horizontalSizeClass
///horizontalSizeClass определяет класс размера экрана по горизонтали (ширине). Это позволяет адаптировать интерфейс в зависимости от доступного пространства.
///.compact — узкий экран (например, iPhone в портретной ориентации или Split View на iPad).
///.regular — широкий экран (например, iPad в ландшафтной ориентации или большие экраны).
///Если sizeClass равно .compact (узкий экран, например, iPhone в портретной ориентации), минимальная ширина ячейки будет 160 пунктов.
///Если sizeClass равно .regular (широкий экран, например, iPad в ландшафтной ориентации), минимальная ширина ячейки увеличится до 200 пунктов.
///Через @Environment получаем информацию о горизонтальном классе размера устройства (horizontalSizeClass), чтобы адаптировать отображение для компактных и обычных экранов.
///@Environment(\.horizontalSizeClass) помогает понять контекст устройства (широкий экран или узкий) и адаптировать дизайн для улучшения пользовательского опыта.

///let minWidth: CGFloat = sizeClass == .compact ? 160 : 200
///Здесь определяется минимальная ширина ячейки: если экран компактен, минимальная ширина — 160, иначе — 200.
///GridItem с типом .adaptive(minimum: minWidth). Это означает, что система сама рассчитает, сколько столбцов может уместиться в доступном пространстве, основываясь на минимальной ширине элемента, и расставит между столбцами отступы 16 пунктов.

//.frame(minHeight: 280)
///Внутри LazyVGrid происходит итерация по всем элементам items через ForEach, для каждого создаётся ProductCell, которому задаётся минимальная высота в 280 пунктов с помощью .frame(minHeight: 280).
///Отметим, что зафиксированная минимальная высота гарантирует, что ячейка никогда не станет ниже 280, но ширина остаётся адаптивной – именно за счёт механизма .adaptive система рассчитывает, сколько по ширине элементов может разместиться.
//как распределяется пространство внутри ProductCell (в нутри него два компонента - WebImageViewAspectRatio + VStack с текстами)
///SwiftUI распределяет доступное пространство внутри составного вью на основе его внутренней логики, которая учитывает «intrinsicContentSize» (естественный размер элемента) и модификатор .layoutPriority()
///Когда суммарная высота этих двух компонентов должна вписаться в 280 пунктов, SwiftUI распределяет пространство между ними. Если текстовый блок занимает больше места из-за того, что, например, описание занимает три строки, то оставшееся пространство для WebImageViewAspectRatio уменьшается – именно поэтому вы видите, что изображение как бы «сжалось». То есть приоритет в распределении пространства отдаётся тому элементу, который имеет больший «intrinsicContentSize» или более высокий приоритет в системе.
///При уменьшении минимальной высоты (.frame(minHeight: 50)), система будет стремиться сделать ячейку как можно меньше – и тогда все вью (и текстовые блоки, и изображение) будут сжаты до минимально допустимого отображения, что приводит к обрезанию текста и изменению scale у изображения.
//.layoutPriority(_:)
///.layoutPriority(_:) для того, чтобы явно указать, какой элемент должен получить больше пространства в конфликтной ситуации.
///.layoutPriority(1)
//Если хочется добиться, чтобы изображение всегда имело оптимальное соотношение и не «сжималось», можно попробовать:
/// Задать изображению фиксированный фрейм (например, .frame(height: ...)) или Настроить его приоритет через .layoutPriority(1) по сравнению с текстовыми элементами.
struct PopularProductsSectionView: View {
    let items: [ProductItem]
    let headerTitle: String
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    private var gridItems: [GridItem] {
        let minWidth: CGFloat = sizeClass == .compact ? 160 : 200
        return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(headerTitle)
                .font(.title2.bold())
                .padding(.horizontal)
            
            LazyVGrid(columns: gridItems, spacing: 16) {
                ForEach(items) { item in
                    ProductCell(item: item)
                        .frame(minHeight: 280)
                }
            }
            .padding(.horizontal)
        }
    }
}

//// MARK: - WebImageView (Новая версия)
//struct WebImageView2: View {
//    let url: URL?
//    let placeholderColor: Color
//    var debugMode: Bool = true
//    var contentMode: ContentMode = .fill
//    var cornerRadius: CGFloat = 0
//    
//    @State private var lastError: String?
//    
//    var body: some View {
//        ZStack {
//            WebImage(url: url) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: contentMode)
//            } placeholder: {
//                placeholderColor
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//            }
//            .onFailure { error in
//                lastError = error.localizedDescription
//            }
//            .indicator(.progress)
//            .transition(.fade(duration: 0.5))
//            .clipped()
//            .cornerRadius(cornerRadius)
//            
//            errorOverlay
//        }
//        .aspectRatio(contentMode == .fill ? 3/2 : nil, contentMode: .fit)
//    }
//    
//    @ViewBuilder
//    private var errorOverlay: some View {
//        if debugMode, let error = lastError {
//            Text(error)
//                .font(.system(size: 8))
//                .foregroundColor(.red)
//                .padding(4)
//                .background(Color.black.opacity(0.8))
//                .cornerRadius(4)
//                .padding(4)
//                .frame(maxWidth: .infinity, alignment: .bottom)
//        }
//    }
//}
//
//// MARK: - ProductCell (Обновленная)
//struct ProductCell: View {
//    let item: ProductItem
//    @Environment(\.dynamicTypeSize) private var dynamicType
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            WebImageView2(
//                url: URL(string: item.urlImage),
//                placeholderColor: Color(.secondarySystemBackground),
//                contentMode: .fill,
//                cornerRadius: 12
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(Color(.systemGray5), lineWidth: 0.5)
//            )
//            
//            VStack(alignment: .leading, spacing: 6) {
//                Text(item.title.value())
//                    .font(.headline)
//                    .lineLimit(dynamicType.isAccessibilitySize ? 3 : 2)
//                
//                Text(item.author)
//                    .font(.subheadline)
//                    .foregroundStyle(.secondary)
//                    .lineLimit(1)
//                
//                Text(item.description.value())
//                    .font(.caption)
//                    .foregroundStyle(.tertiary)
//                    .lineLimit(dynamicType.isAccessibilitySize ? 5 : 3)
//            }
//            .padding(.horizontal, 8)
//            .padding(.bottom, 8)
//        }
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.secondarySystemBackground))
//        )
//        .contentShape(RoundedRectangle(cornerRadius: 16))
//    }
//}
//
//// MARK: - PopularProductsSectionView (Финал)
//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    @State private var containerWidth: CGFloat = 0
//    @Environment(\.horizontalSizeClass) private var sizeClass
//    
//    private var gridItems: [GridItem] {
//        let minWidth: CGFloat = sizeClass == .compact ? 160 : 240
//        return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text(headerTitle)
//                .font(.title2.bold())
//                .padding(.horizontal)
//            
//            LazyVGrid(columns: gridItems, spacing: 16) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .aspectRatio(0.75, contentMode: .fit)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .readSize { containerWidth = $0.width }
//    }
//}
//// MARK: - Helper Extensions
//extension View {
//    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
//        background(
//            GeometryReader { geometry in
//                Color.clear
//                    .preference(key: SizePreferenceKey.self, value: geometry.size)
//            }
//        )
//        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
//    }
//}
//
//private struct SizePreferenceKey: PreferenceKey {
//    static var defaultValue: CGSize = .zero
//    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
//}
//
//struct SectionHeader: View {
//    let title: String
//    
//    var body: some View {
//        Text(title)
//            .font(.system(.title2, design: .rounded, weight: .semibold))
//            .padding(.horizontal, 4)
//            .frame(maxWidth: .infinity, alignment: .leading)
//    }
//}

// MARK: - Version Frame Bilding

//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Состояние для хранения вычисленной высоты ячейки
//    @State private var computedCellHeight: CGFloat = 0
//    
//    let columns = [
//        GridItem(.flexible()),
//        GridItem(.flexible())
//    ]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок секции
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//                .padding(.top, 10)
//            
//            // GeometryReader для вычисления размеров ячеек — один раз для всей секции
//            GeometryReader { geometry in
//                let totalHorizontalPadding: CGFloat = 16 * 2   // отступы слева и справа
//                let totalSpacing: CGFloat = 15                 // spacing между колонками
//                // Вычисляем ширину одной ячейки
//                let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
//                // Высота изображения соотношением 3:2
//                let imageHeight = cellWidth * 0.66
//                
//                // Расчёт высоты текстовой части с учётом Dynamic Type:
//                // Заголовок: стиль .headline — максимум 2 строки
//                let titleLineHeight = UIFont.lineHeight(for: .headline)
//                let titleHeight = titleLineHeight * 2
//                
//                // Автор: стиль .subheadline — 1 строка
//                let authorLineHeight = UIFont.lineHeight(for: .subheadline)
//                let authorHeight = authorLineHeight * 1
//                
//                // Описание: стиль .caption1 — максимум 3 строки
//                let descriptionLineHeight = UIFont.lineHeight(for: .caption1)
//                let descriptionHeight = descriptionLineHeight * 3
//                
//                // Внутренний spacing между текстовыми элементами — два промежутка по 4 пункта
//                let textInnerSpacing: CGFloat = 4 * 2
//                // Внешние отступы: 8 пунктов между изображением и текстом плюс 8 снизу
//                let outerTextSpacing: CGFloat = 6 + 6
//                
//                // Итоговая высота текстовой части
//                let textAndPadding = titleHeight + authorHeight + descriptionHeight + textInnerSpacing + outerTextSpacing
//                
//                // Итоговая ожидаемая высота ячейки
//                let cellHeightEstimate = imageHeight + textAndPadding
//                
//                // Передаём вычисленное значение через PreferenceKey
//                Color.clear
//                    .preference(key: CellHeightKey.self, value: cellHeightEstimate)
//                
//                // Выводим LazyVGrid с 2 колонками, каждая ячейка получает вычисленные размеры
//                LazyVGrid(columns: columns, spacing: 15) {
//                    ForEach(items) { item in
//                        ProductCell(
//                            item: item,
//                            width: cellWidth,
//                            height: computedCellHeight > 0 ? computedCellHeight : cellHeightEstimate
//                        )
//                    }
//                }
//                .padding(.horizontal, 16)
//            }
//            // Обрабатываем изменение значения PreferenceKey
//            .onPreferenceChange(CellHeightKey.self) { newHeight in
//                computedCellHeight = newHeight
//            }
//            // Определяем общую высоту контейнера для ячеек.
//            ///Функция ceil(_:) из стандартной библиотеки принимает значение типа Double и возвращает наименьшее целое число (в виде Double), которое не меньше исходного.
//            ///Например, если у вас 5 элементов, тогда 5 / 2.0 = 2.5, а ceil(2.5) даст 3.
//            ///(CGFloat(numRows - 1) * 15) – добавляем отступ между строками (если строк больше одной, то между ними именно (numRows - 1) промежуток, а spacing между строками задаётся равным 15).
//            .frame(height: {
//                let numRows = ceil(Double(items.count) / 2.0)
//                return computedCellHeight > 0
//                    ? computedCellHeight * CGFloat(numRows) + (CGFloat(numRows - 1) * 15)
//                    : 0
//            }())
//        }
//    }
//}


//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Состояние для хранения вычисленной высоты ячейки
//    @State private var computedCellHeight: CGFloat = 0
//    
//    // Определяем 2 колонки с гибкой шириной
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок секции
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//                .padding(.top, 10)
//            
//            // GeometryReader вычисляет ширину для обеспечения адаптивного расчёта размеров
//            GeometryReader { geometry in
//                let totalHorizontalPadding: CGFloat = 16 * 2   // отступы слева и справа
//                let totalSpacing: CGFloat = 15                 // spacing между колонками
//                // Вычисляем ширину одной ячейки
//                let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
////                let cellWidth = floor((geometry.size.width - totalHorizontalPadding - totalSpacing) / 2)
//
//                // Высота изображения задаётся соотношением 3:2
//                let imageHeight = cellWidth * 0.66
//                
//                // Расчёт высоты текстовой части с учётом Dynamic Type
//                // Заголовок: используем стиль .headline, максимум 2 строки
//                let titleLineHeight = UIFont.lineHeight(for: .headline)
//                let titleHeight = titleLineHeight * 2
//                
//                // Автор: стиль .subheadline — 1 строка
//                let authorLineHeight = UIFont.lineHeight(for: .subheadline)
//                let authorHeight = authorLineHeight * 1
//                
//                // Описание: используем стиль .caption1 для 3-х строк
//                let descriptionLineHeight = UIFont.lineHeight(for: .caption1)
//                let descriptionHeight = descriptionLineHeight * 3
//                
//                // Внутренний spacing между текстовыми элементами — предположим два промежутка по 4 пункта
//                let textInnerSpacing: CGFloat = 4 * 2
//                // Внешние отступы: например, 8 пунктов между изображением и текстом, плюс 8 снизу
//                let outerTextSpacing: CGFloat = 8 + 8
//                
//                // Итоговая высота текстовой части
//                let textAndPadding = titleHeight + authorHeight + descriptionHeight + textInnerSpacing + outerTextSpacing
//                
//                // Итоговая ожидаемая высота ячейки
//                let cellHeightEstimate = imageHeight + textAndPadding
////                let cellHeightEstimate = (imageHeight + textAndPadding).rounded(.toNearestOrEven)
//
//                
//                // Передаём вычисленное значение через PreferenceKey
//                Color.clear
//                    .preference(key: CellHeightKey.self, value: cellHeightEstimate)
//                
//                // LazyVGrid с 2 колонками, где каждая ячейка получает вычисленные width и height
//                LazyVGrid(columns: columns, spacing: 15) {
//                    ForEach(items) { item in
//                        ProductCell(
//                            item: item,
//                            width: cellWidth,
//                            height: computedCellHeight > 0 ? computedCellHeight : cellHeightEstimate
//                        )
//                    }
//                }
//                .padding(.horizontal, 16)
//            }
//            // Обработчик изменений PreferenceKey – сохраняем вычисленную высоту
//            .onPreferenceChange(CellHeightKey.self) { newHeight in
//                computedCellHeight = newHeight
//            }
//            // Задаём общую высоту контейнера для ячеек, рассчитывая число строк с учётом spacing’а
//            /Функция ceil(_:) из стандартной библиотеки принимает значение типа Double и возвращает наименьшее целое число (в виде Double), которое не меньше исходного.
//            /Например, если у вас 5 элементов, тогда 5 / 2.0 = 2.5, а ceil(2.5) даст 3.
//            /(CGFloat(numRows - 1) * 15) – добавляем отступ между строками (если строк больше одной, то между ними именно (numRows - 1) промежуток, а spacing между строками задаётся равным 15).
//            .frame(height: {
//                let numRows = ceil(Double(items.count) / 2.0)
//                return computedCellHeight > 0
//                    ? computedCellHeight * CGFloat(numRows) + (CGFloat(numRows - 1) * 15)
//                    : 0
//            }())
//        }
//    }
//}

//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Храним вычисленную высоту ячейки
//    @State private var computedCellHeight: CGFloat = 0
//    
//    // Определяем 2 колонки с гибким распределением
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//    
//    var body: some View {
//            VStack(alignment: .leading, spacing: 10) {
//                // Заголовок секции
//                Text(headerTitle)
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal, 16)
//                    .padding(.top, 10)
//                
//                // GeometryReader для вычисления размеров ячеек — один раз для всей секции
//                GeometryReader { geometry in
//
//                    let totalHorizontalPadding: CGFloat = 16 * 2   // отступы слева и справа
//                    let totalSpacing: CGFloat = 15                 // spacing между колонками
//                    // Вычисляем ширину одной ячейки
//                    let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
//                    // Высота изображения по соотношению 3:2 (2/3 ≈ 0.66)
//                    let imageHeight = cellWidth * 0.66
//                    
//                    // Точный расчёт высоты текстовой части:
//                    // Предположим следующие оценки (в пунктах):
//                    // • Заголовок (.headline, максимум 2 строки): ~22 пункт * 2 = 44
//                    // • Автор (.subheadline, 1 строка): ~20 пункт
//                    // • Описание (.caption, максимум 3 строки): ~15 пункт * 3 = 45
//                    // Внутри VStack для текста spacing = 4 (между элементами), всего 2 промежутка → 8
//                    // Внешние отступы: .padding(.bottom, 8) и дополнительное расстояние между изображением и текстом = 8
//                    let titleHeight: CGFloat = 44
//                    let authorHeight: CGFloat = 20
//                    let descriptionHeight: CGFloat = 45
//                    let textInnerSpacing: CGFloat = 8    // между текстовыми элементами
//                    let outerTextSpacing: CGFloat = 8 + 8  // 8 между изображением и текстом, и 8 снизу
//                    let textAndPadding: CGFloat = titleHeight + authorHeight + descriptionHeight + textInnerSpacing + outerTextSpacing  // 44 + 20 + 45 + 8 + 16 = 133
//                    
//                    // Итоговая ожидаемая высота ячейки
//                    let cellHeightEstimate = imageHeight + textAndPadding
//                    
//                    // Передаём вычисленное значение через PreferenceKey
//                    Color.clear
//                        .preference(key: CellHeightKey.self, value: cellHeightEstimate)
//                    
//                    // Выводим LazyVGrid с передачей вычисленных width и heights в ProductCell
//                    LazyVGrid(columns: columns, spacing: 15) {
//                        ForEach(items) { item in
//                            ProductCell(
//                                item: item,
//                                width: cellWidth,
//                                height: computedCellHeight > 0 ? computedCellHeight : cellHeightEstimate
//                            )
//                        }
//                    }
//                    .padding(.horizontal, 16)
//                }
//                // Читаем вычисленное значение ячейки из PreferenceKey
//                .onPreferenceChange(CellHeightKey.self) { newHeight in
//                    computedCellHeight = newHeight
//                }
//                // Определяем общую высоту для зоны с ячейками.
//                // Расчитываем число строк: ceil(количество ячеек / 2)
//                .frame(height: {
//                    let numRows = ceil(Double(items.count) / 2.0)
//                    // Междустрочный spacing равен 15 для каждой промежутка между строками (numRows - 1 штук)
//                    return computedCellHeight > 0
//                        ? computedCellHeight * CGFloat(numRows) + (CGFloat(numRows - 1) * 15)
//                        : 0
//                }())
//            }
//        }
//    }




//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Храним вычисленную высоту всех ячеек
//    @State private var computedCellHeight: CGFloat = 0
//    
//
//    // Определяем две колонки с гибким распределением
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 10) {
//                // Заголовок секции
//                Text(headerTitle)
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal, 16)
//                    .padding(.top, 10)
//                
//                // Один GeometryReader для вычисления доступной ширины и ожидаемой высоты ячейки
//                GeometryReader { geometry in
//                    // Предположим, горизонтальные отступы по 16 слева и справа
//                    let totalHorizontalPadding: CGFloat = 16 * 2
//                    // Промежуток между двумя колонками (задаем фиксированное значение, например, 15)
//                    let totalSpacing: CGFloat = 15
//                    // Вычисляем ширину каждой ячейки
//                    let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
//                    // Высота изображения по соотношению 3:2 (2/3 ≈ 0.66)
//                    let imageHeight = cellWidth * 0.66
//                    // Дополнительная высота для текстовой части и отступов
//                    let textAndPadding: CGFloat = 100
//                    // Итоговая ожидаемая высота ячейки
//                    let cellHeightEstimate = imageHeight + textAndPadding
//                    
//                    // Передаём вычисленную высоту через preference
//                    Color.clear
//                        .preference(key: CellHeightKey.self, value: cellHeightEstimate)
//                    
//                    // LazyVGrid для размещения ячеек
//                    LazyVGrid(columns: columns, spacing: 15) {
//                        ForEach(items) { item in
//                            ProductCell(
//                                item: item,
//                                width: cellWidth,
//                                height: computedCellHeight == 0 ? cellHeightEstimate : computedCellHeight
//                            )
//                        }
//                    }
//                    .padding(.horizontal, 16)
//                }
//                // Получаем вычисленное значение высоты из preference
//                .onPreferenceChange(CellHeightKey.self) { newHeight in
//                    computedCellHeight = newHeight
//                }
//            }
//            .frame(height: computedCellHeight > 0 ? computedCellHeight * CGFloat(items.count/2 ) : nil)
//
//        }
//    }
//}


//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Используем две колонки с гибкой шириной
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//    
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 10) {
//                Text(headerTitle)
//                    .font(.title2)
//                    .bold()
//                    .padding(.horizontal, 16)
//                    .padding(.top, 10)
//                
//                // Оборачиваем нашу сетку в GeometryReader, чтобы вычислить размеры
//                GeometryReader { geometry in
//                    let totalHorizontalPadding: CGFloat = 16 * 2  // 16 прямая и 16 правая
//                    let totalSpacing: CGFloat = 15                // пространство между колонками
//                    // Вычисляем ширину одной ячейки
//                    let cellWidth = (geometry.size.width - totalHorizontalPadding - totalSpacing) / 2
//                    // Высота для изображения по соотношению 3:2 (0.66 = 2/3)
//                    let imageHeight = cellWidth * 0.66
//                    // Предположим, что высота текстовой секции плюс отступы составляет примерно 100 пунктов
//                    let textAndPadding: CGFloat = 100
//                    let cellHeight = imageHeight + textAndPadding
//                    
//                    LazyVGrid(columns: columns, spacing: 15) {
//                        ForEach(items) { item in
//                            ProductCell(item: item, width: cellWidth, height: cellHeight)
//                        }
//                    }
//                    .padding(.horizontal, 16)
//                }
//                // GeometryReader внутри ScrollView требует заданной высоты, чтобы правильно отобразиться.
//                // Здесь можно задать примерное значение или вычислить его по содержимому.
//                .frame(height: 600)
//            }
//        }
//    }
//}


//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    var columns: [GridItem] {
//        Array(repeating: GridItem(.flexible(minimum: 150)), count: 2)
//    }
//
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 15) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .background(Color.green.opacity(0.4))
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal, 16)
//        }
//    }
//}
                  
//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//    
//    var body: some View {
//    
//        VStack(alignment: .leading, spacing: 10) {
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal, 16)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 10) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal, 16)
//        }
//        .background(Color.yellow)
//        .padding(.bottom, 10)
//    }
//}



/// Секция Популярных товаров (PopularProducts)
//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    // Определяем 2 колонки для grid layout
//    let columns = [
//        GridItem(.flexible(), spacing: 10),
//        GridItem(.flexible(), spacing: 10)
//    ]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            // Заголовок. Для "прилипания" заголовка можно рассмотреть Section в List или
//            // новые возможности pinnedViews (iOS 16+)
//            Text(headerTitle)
//                .font(.title2)
//                .bold()
//                .padding(.horizontal)
//                .padding(.top, 10)
//            
//            LazyVGrid(columns: columns, spacing: 10) {
//                ForEach(items) { item in
//                    ProductCell(item: item)
//                        .cornerRadius(8)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .padding(.bottom, 10)
//    }
//}
