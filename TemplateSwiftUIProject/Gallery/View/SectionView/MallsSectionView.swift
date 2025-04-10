//
//  MallsSectionView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 12.03.25.
//


// MARK: - padding

///Общее пространство, которое занимает MallCell: 110 пунктов (100 ширина(frame) + 5 слева + 5 справа).
///MallCell(item: item, width: cellWidth, height: cellHeight).padding(.horizontal, cellSpacing / 2)



// MARK: - TabView

/// TabView в SwiftUI — это универсальный контейнер, который позволяет представлять контент в виде вкладок или переключаемых страниц. Именно благодаря своей универсальности он может использоваться для таких разных задач, как создание нижнего TabBar (как в UITabBarController) или для реализации горизонтально прокручиваемых страниц, например коллекций карточек. Это достигается за счёт того, что TabView управляет набором дочерних представлений (вкладок) и позволяет настраивать их стиль поведения через модификатор .tabViewStyle.
/// Два основных сценария использования TabView: Создание TabBar + Горизонтальная прокрутка (PageView)

// MARK: - GeometryReader

///GeometryReader — это контейнер в SwiftUI, который предоставляет дочерним представлениям доступ к информации о геометрии (размерах и координатах) родительского контейнера. Это полезно для создания адаптивных и динамических интерфейсов, которые зависят от текущих размеров экрана или других представлений.
///Основной принцип: Когда GeometryReader используется внутри иерархии, он занимает всё доступное ему пространство, предоставляемое родителем. Затем он позволяет узнать:
///Размеры пространства, которое он занимает (через geometry.size). + Координаты относительно разных систем координат (например, .local или .global через geometry.frame).
///Что он возвращает:
///geometry.size.width и geometry.size.height: Размеры пространства, выделенного для GeometryReader.
///geometry.frame(in: .local) и geometry.frame(in: .global): Положение контейнера относительно локальной или глобальной системы координат.

///Для чего его используют на проектах:
///Адаптивные интерфейсы + Динамические размеры и позиции + Работа с анимациями + Реализация кастомных компонентов + Учет Safe Area(GeometryReader позволяет учитывать safe area insets, чтобы интерфейс корректно отображался на устройствах с вырезами или закруглёнными углами.)

///Потенциальные подводные камни
///Избыточное использование: Если GeometryReader вызывается внутри большого количества повторяющихся представлений (например, в ячейках списка), это может привести к избыточным вычислениям. В вашем случае использование GeometryReader внутри MallCell действительно избыточно, так как размеры уже вычислены в MallsSectionView. Лучше передавать их через параметры.
///Поглощение всего пространства: По умолчанию GeometryReader занимает всё доступное пространство родителя. Это иногда может вызывать неожиданные проблемы, особенно если родительский контейнер имеет динамические ограничения.
///Непредсказуемость размеров: Если родительское представление не имеет фиксированных размеров, geometry.size может меняться в зависимости от контекста, что иногда ведёт к непредсказуемому поведению (например, коллапс в ячейках или изменения высоты).



// MARK: - контейнеров, которые автоматически адаптируют свои размеры при изменении ориентации устройства.

///GeometryReader + VStack, HStack, ZStack + List + ScrollView + LazyVStack и LazyHStack + NavigationStack/NavigationView + Grid + Spacer




// MARK: - Preference

///PreferenceKey — это протокол, который позволяет дочерним представлениям передавать некоторое значение (например, высоту, ширину, позицию, цвет и т.д.) вверх по иерархии view. Родительское представление может затем "подписаться" на эти значения и использовать их для изменения своего расположения или других параметров. Механизм удобен, когда нужно, чтобы дочерние view «сообщали» какую-то информацию своим родителям, без прямой связи через свойства.

///Дочернее представление
///Color.clear.preference(key: CellHeightKey.self, value: cellHeight)
///.preference(key:value:) – модификатор, который привязывает значение cellHeight к указанному PreferenceKey (CellHeightKey).
///cellHeight - Это значение затем поднимается вверх по иерархии view.

///Далее SwiftUI проходит всю иерархию view (допустим MallsSectionView - может быть мы где то в дочерних view у MallsSectionView тоже установили preference(key:value:) по ключу CellHeightKey.self)сверху вниз и собирает все значения этого preference, объединяя их при помощи метода reduce.
///В пределах родительского контейнера, где применяются preference, и собирает значения только из этой ветки иерархии.
///Если в параллельной ветке ShopsSectionView вы также используете тот же ключ CellHeightKey, но с другими значениями, то: В пределах ShopsSectionView будет выполнен аналогичный процесс сбора и объединения (reduce) только для дочерних view этой ветки + Значения из MallsSectionView и ShopsSectionView не пересекаются, потому что эти ветки не связаны между собой (если только они не встречаются в одном общем родителе, где вызывается .onPreferenceChange(CellHeightKey.self)).

///Родительское представление
///Родительское представление подписывается с помощью .onPreferenceChange(CellHeightKey.self)  на изменения preference для ключа CellHeightKey и получает итоговое значение.
///Когда дочерние view (в вашем случае, Color.clear) устанавливают значение для этого ключа(к примеру мы изменили ориентацию устройства и отработал GeometryReader передав новое значение в Color.clear.preference), SwiftUI собирает все эти значения (если их несколько – использует функцию reduce из PreferenceKey) и обновляет значение, которое затем передаётся в замыкание.

///GeometryReader заново отрабатывает
///Меняется размер или положение родительского контейнера.
///Обновляется состояние в связанной иерархии view.
///Происходит событие, влияющее на доступное пространство (смена ориентации, анимация, мультиоконность).
///Этот динамический пересчёт — одна из главных причин, почему GeometryReader удобен для создания адаптивных интерфейсов.

/// Как работает struct CellHeightKey: PreferenceKey
/// defaultValue — это начальное значение, которое используется, если ни одно дочернее представление не установило preference или для отправной точки при первом полученном установленном значении в иерархии.
/// Метод reduce(value:inout CGFloat, nextValue: () -> CGFloat) вызывается для объединения всех значений, переданных дочерними view для данного PreferenceKey.
/// Допустим мы передали одно значение через Color.clear.preference(key: CellHeightKey.self, value: 30)
///reduce вызывается с value = 0, nextValue() = 30, и затем новая value становится max(0, 30) = 30.
///Если мы вызвали их два и второе Color.clear.preference(key: CellHeightKey.self, value: 40)
///Потом вызывается reduce для следующего значения: value уже = 30, nextValue() = 40, и тогда value = max(30, 40) = 40.
///Таким образом, итоговое значение, которое поднимется на верхний уровень через .onPreferenceChange(CellHeightKey.self), будет равно 40.

import SwiftUI


struct CellHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // Можно выбрать, например, максимальное значение
        value = max(value, nextValue())
    }
}

struct MallsSectionView: View {
    let items: [MallItem]
    let headerTitle: String
    
    @State private var computedCellHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Заголовок секции
            Text(headerTitle)
                .font(.title2)
                .bold()
                .padding(.horizontal, 16)
            ///Здесь GeometryReader используется для получения ширины доступного пространства
            GeometryReader { geometry in
                let horizontalPadding: CGFloat = 16
                let cellSpacing: CGFloat = 10
                let availableWidth = geometry.size.width - 2 * horizontalPadding
                let cellWidth = availableWidth - cellSpacing
                let cellHeight = cellWidth * 0.55  // Вычисляем пропорциональную высоту
                // Помещаем прозрачный элемент, чтобы установить preference
                Color.clear
                    .preference(key: CellHeightKey.self, value: cellHeight)
                TabView {
                    ForEach(items) { item in
                        MallCell(item: item, width: cellWidth, height: cellHeight)
                            .cornerRadius(10)
                            .padding(.horizontal, cellSpacing / 2)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .frame(height: cellHeight)
                .padding(.horizontal, horizontalPadding)
            }
            .onPreferenceChange(CellHeightKey.self) { value in
                computedCellHeight = value
            }
        }
        // Общая высота секции: вычисленная cellHeight + отступы (например, 60)
        .frame(height: computedCellHeight + 40)
//        .background(Color.blue.opacity(0.1))
    }
}


