//
//  PopularProductsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//



import SwiftUI

//sizeClass

///Size Class — это концепция в UIKit и SwiftUI, которая позволяет адаптировать пользовательский интерфейс к различным размерам экрана и ориентациям устройства. Она представляет собой абстрактные категории размеров, а не точные пиксели или разрешение.
///Compact — маленькое пространство (например, iPhone в портретной ориентации).
///Regular — большое пространство (например, iPad в альбомной ориентации).
///Они применяются по двум направлениям: Horizontal Size Class — по горизонтали. + Vertical Size Class — по вертикали.
///В SwiftUI есть EnvironmentValue horizontalSizeClass и verticalSizeClass, которые позволяют динамически изменять UI в зависимости от размеров экрана.

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

//LazyVGrid + GridItem(.adaptive(minimum: minWidth)
///Модификатор .adaptive(minimum:) говорит LazyVGrid: Создавай столько колонок, сколько позволяет ширина контейнера.
///как работает .adaptive(minimum:) в GridItem. Даже если вы указали всего один элемент в массиве [GridItem], этот единственный элемент с .adaptive(minimum:) позволяет SwiftUI динамически добавлять столько колонок, сколько поместится в доступное пространство, с учётом заданной минимальной ширины minWidth.
///Даже с одним GridItem и .adaptive(minimum:), LazyVGrid может адаптироваться под ширину экрана и добавлять больше колонок. Это гибкость дизайна SwiftUI. Если вам нужно больше контроля над количеством колонок, вы можете использовать подход с GeometryReader или даже вручную задать нужное количество колонок с помощью .fixed.


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
            .padding(.horizontal, 8)
        }
    }
}


// MARK: - adaptive gridItems

/// сейчас у нас ячейка ProductCell в LazyVGrid всегда выглядит одинаково на всех устройствах и изменяется только в приделах ограничения minWidth: CGFloat = sizeClass == .compact ? 160 : 200 и .frame(minHeight: 280).

///Если вы хотите более точного контроля, например, чтобы адаптировать минимальную ширину колонки к конкретной ширине экрана, можно использовать GeometryReader для вычислений:

//private var gridItems: [GridItem] {
//    GeometryReader { geometry in
//        let availableWidth = geometry.size.width
//        let minWidth = availableWidth / 2.5 // Например, разделяем ширину на 2.5 для адаптации
//        return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
//    }
//}


// MARK: - adaptive VStack for Texts

/// на сколько я понял из своего анализа что когда мы хотим иметь вертикальную сетку с двумя колонками каждая ячейка которой  ProductView  (имеет Image и 3 Text в своей структуре и каждая из них может быть  в несколько строк а может быть и в одну строку все зависит от контента который пришол из сети.) Мы так же хотим что бы ProductView был всегда одного размера по высоте (что бы все ячейки в сетки смотрелись идеально) )в не зависимости от того сколько строк заполненно в каждом Text в VStack для текста.  Для такой задачи мы должны всегда расчитывать высоту VStack для текста с максимальным колличеством возможного заполненного пространства.



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

//dynamicTypeSize for image
///Чтобы изображение тоже масштабировалось, нужно явно сделать его контейнер адаптивным, используя информацию из окружения, в частности—среду dynamicTypeSize.
///var imageHeight: CGFloat { dynamicType.isAccessibilitySize ? 300 : 240 }
//.frame(maxWidth: .infinity, alignment: .leading)
///.frame(maxWidth: .infinity, alignment: .leading) гарантируется, что текст займет максимально доступную ширину, выравниваясь по левому краю.

//отключить использования Larger Accessibility Sizes
//некоторые разработчики намеренно отключают адаптацию текста к настройкам Dynamic Type, даже если системные настройки iOS позволяют увеличивать размер шрифта(kufar wildberies VK(внутренняя настройка)).
///Полностью отключить возможность использования Larger Accessibility Sizes — то есть игнорировать настройки пользователя по динамическому увеличению шрифтов — не рекомендуется и, по сути, нельзя сделать "системно корректно", так как это нарушает принципы инклюзивного дизайна, заложенные в iOS.
/// 1. Переопределение окружения целиком: .environment(\.sizeCategory, .medium) - WindowGroup { ContentView() .environment(\.sizeCategory, .medium) }
/// 2. Использование фиксированных размеров шрифта: .font(.system(size: ...))
/// 3. Локальное изменение для отдельных вью: SomeView() .environment(\.sizeCategory, .medium)

//Larger Accessibility Sizes
///Причина, по которой dynamicType.isAccessibilitySize срабатывает только тогда, когда вы вытягиваете слайдер размеров шрифта почти до самого края в настройках Larger Accessibility Sizes, заключается в том, как Apple определяет "размеры доступности" (Accessibility Sizes) в Dynamic Type.
///Что такое Larger Accessibility Sizes? Dynamic Type включает два диапазона размеров:
///Стандартный диапазон размеров: размеры текста, которые используются большинством пользователей.
///Доступный диапазон размеров (Larger Accessibility Sizes): более крупные размеры текста, предназначенные для людей с нарушениями зрения. Это доступно только при включении опции Larger Accessibility Sizes в настройках устройства.
///Свойство isAccessibilitySize становится true, если текущий размер текста превышает стандартный диапазон Dynamic Type и входит в расширенный диапазон Larger Accessibility Sizes. Это значение зависит от того, насколько далеко вы двигаете ползунок.
///Если вы увеличиваете размер до предела, который превышает стандартный диапазон (то есть ползунок продвигается в "область доступности"), isAccessibilitySize переключается на true.
///Поскольку в вашем случае lineLimit зависит от dynamicType.isAccessibilitySize, переключение с 3 на 5 строк происходит только тогда, когда шрифт попадает в категорию доступности (слайдер почти на максимуме).
//lineLimit(dynamicType > .large ? 5 : 3)
///Если вы хотите, чтобы изменения происходили уже на более низких уровнях (например, до того, как слайдер достигает почти максимального значения), вы можете ориентироваться не только на dynamicType.isAccessibilitySize, но и на конкретное значение текущего размера текста.
///Здесь вы проверяете, превышает ли размер текста (например, .large), а не только категорию доступности. Это даст вам больше гибкости в управлении строками.
///dynamicType.isAccessibilitySize срабатывает только при значениях из категории Larger Accessibility Sizes, потому что это логика, заложенная в систему. Если вы хотите более раннюю адаптацию интерфейса, можно использовать сравнение текущего размера текста с определённым значением (например, .large, .extraLarge), чтобы настройки изменялись более плавно и раньше.
/// let descriptionLines = dynamicType > .large ? 5 : 3 let titleLines = dynamicType > .large ? 3 : 2 - .lineLimit(dynamicType > .large ? 3 : 2)
//Стандартный диапазон размеров:
///.extraSmall + .small + .medium (по умолчанию) + .large + .extraLarge + .extraExtraLarge + .extraExtraExtraLarge


//struct PopularProductsSectionView: View {
//    let items: [ProductItem]
//    let headerTitle: String
//    
//    @Environment(\.horizontalSizeClass) private var sizeClass
//    @Environment(\.dynamicTypeSize) private var dynamicType
//    
//    private var minTextStackHeight: CGFloat {
//            let titleLines = dynamicType.isAccessibilitySize ? 3 : 2
//            let descriptionLines = dynamicType.isAccessibilitySize ? 5 : 3
//            print("titleLines - \(titleLines)")
//        print("descriptionLines - \(descriptionLines)")
//            // Рассчитываем высоту для каждого текстового элемента
//            let titleFont = UIFont.preferredFont(forTextStyle: .headline)
//            let authorFont = UIFont.preferredFont(forTextStyle: .subheadline)
//        let descriptionFont = UIFont.preferredFont(forTextStyle: .caption1)
//            
//            let titleHeight = titleFont.lineHeight * CGFloat(titleLines)
//            let authorHeight = authorFont.lineHeight
//            let descriptionHeight = descriptionFont.lineHeight * CGFloat(descriptionLines)
//            
//            // Учитываем spacing между элементами (6 * 2)
//            return titleHeight + authorHeight + descriptionHeight + 12
//        }
//    
//    private var gridItems: [GridItem] {
//        let minWidth: CGFloat = sizeClass == .compact ? 160 : 200
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
//                    ProductCell(item: item, minTextHeight: minTextStackHeight)
//                        .frame(minHeight: 280)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//}

//struct ProductCell: View {
//    let item: ProductItem
//    let minTextHeight: CGFloat  //Получаем извне
//    @Environment(\.dynamicTypeSize) private var dynamicType
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//                WebImageViewAspectRatio(
//                    url: URL(string: item.urlImage),
//                    placeholderColor: Color(.secondarySystemBackground)
//                )
//                .layoutPriority(1)
//                .cornerRadius(12)
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
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .frame(minHeight: minTextHeight)
//        }
//        .padding([.top], 8)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.secondarySystemBackground))
//        )
//        .background(GeometryReader { geometry in
//            Color.clear
//                .onAppear {
//                    print("Высота ячейки: \(geometry.size.height)")
//                }
//        })
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

