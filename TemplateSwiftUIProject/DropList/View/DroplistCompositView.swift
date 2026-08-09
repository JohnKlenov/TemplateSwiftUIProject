//
//  DroplistCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.05.26.
//



// MARK: -  Color Design

// для TopSectionItemView

// первый - рутовый фон Color(.systemBackground) + фон карточки TopSectionItemView Color(.secondarySystemBackground) как сейчас (при темной теме рут черный а поверх темно серый а при белой теме рут белый а верх светло серый )!
// второй - специальная логика при которой (при темной теме рут черный а поверх темно серый а при белой рут светло серый а верх белый - как на системных настройках в универсальном доступе)
// третий вариант (при темной теме рут черный а поверх темно серый при старте а затем меняется на блюр от картинки а при белой теме рут белый а верх светло серый при старте а затем меняется на блюр от картинки )!
// четвертая это кастомный вариант когда рут может быть блюром (темным/светлым и уже фон карточки любого цвета)


// tasks:
// разобраться с работай текущего кода!
// добавить при подьеме скрола прилипание средней секции к верхнему краю экрана!
// Droplist - все Colors системные и через единый AppColors + локализация Текстов в App + локализация текстов на стороне Firestore( Внешняя локализация title (строк) (на стороне Firebase как в BookStores)) ?
// ErrorHandler там где нужно + локализация и контекст
// добавить кнопку allTopdrop при переходе на который мы попадаем на список Topdrop а в ленте мы отображаем к примеру не больше трех или четырех + добавить индикатор прокрутки по Topdrop (такое новое решение с анимацией как квадратные точечки)
// доработать дизайн макета для lowerItemCell
// переходы из плейлиста в плеер со списком треков из плейлиста(или сначало переход на view со списком треков а потом по одному включаем через плеер или открывается плеер со списком) + переход на плеер из трека(allTracks) без списка треков
// для каждого item в TopSection добавить поле artists + title


//struct DroplistCompositView: View {
//
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//
//    @State private var selectedCarouselItem: CarouselItem?
//
//    var body: some View {
//        // Профессиональный подход для адаптивной ширины без поломок скролла
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            // КЛЮЧЕВОЙ МОМЕНТ: Запрещаем анимацию смены размеров при повороте экрана
//            .animation(.easeOut(duration: 0.0), value: screenWidth)
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        // Не даем GeometryReader растягивать контент на всю высоту экрана
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}







import SwiftUI

//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//            let screenHeight = geometry.size.height
//            
//            ScrollView {
//                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
//                    
//                    Section {
//                        topSections(screenWidth: screenWidth)
//                    }
//                    
//                    Section {
//                        // ⭐ ГЛАВНОЕ: Фиксируем высоту нижней секции.
//                        // Даже когда список меняется, рутовый ScrollView не дергается.
//                        VStack(spacing: 0) {
//                            lowerSectionWithFooter()
//                        }
//                        .frame(minHeight: max(screenHeight - 200, 400), alignment: .top)
//                        
//                    } header: {
//                        carouselSection
//                            .padding(.top, 8)
//                            .padding(.bottom, 16)
//                            .background(AppColors.background)
//                    }
//                }
//                .padding(.vertical, 12)
//            }
//            .animation(.easeOut(duration: 0.0), value: screenWidth)
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}


struct DroplistCompositView: View {
    
    let data: DropData
    let onRefresh: () -> Void
    let onSelectCarouselItem: (CarouselItem) -> Void
    let onLoadNextPage: (CarouselItem) -> Void
    let onSelectLowerItem: (LowerItem) -> Void
    
    @State private var selectedCarouselItem: CarouselItem?
    
    // Единственное, что нам нужно — помнить, какой был прошлый item.
    @State private var previousItemId: CarouselItem.ID? = nil
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        
                        Section {
                            topSections(screenWidth: screenWidth)
                        }
                        
                        Section {
                            VStack(spacing: 0) {
                                lowerSectionWithFooter()
                            }
                            .frame(minHeight: max(screenHeight - 200, 400), alignment: .top)
                            
                        } header: {
                            carouselSection
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                                .background(AppColors.background)
                        }
                    }
                    .padding(.vertical, 12)
                }
                .animation(.easeOut(duration: 0.0), value: screenWidth)
                .refreshable {
                    onRefresh()
                }
                .onAppear {
                    selectedCarouselItem = data.selectedItem
                }
                
                // 🛡️ Защита от черного экрана и потери позиции
                .onChange(of: data.initialLowerSection.items) { _, newItems in
                    guard let currentItem = selectedCarouselItem else { return }
                    guard !newItems.isEmpty else { return }
                    
                    // Если мы перешли на НОВУЮ вкладку (сброс не нужен) — выходим
                    if previousItemId != currentItem.id {
                        previousItemId = currentItem.id
                        return
                    }
                    
                    // Если это возврат на СТАРУЮ вкладку — мы должны восстановить скролл
                    // Проверяем: не находится ли скролл в пустоте.
                    // Самый простой способ — проверить первый элемент.
                    if let firstId = newItems.first?.id {
                        DispatchQueue.main.async {
                            withAnimation(.easeOut(duration: 0.0)) {
                                proxy.scrollTo(firstId, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Top Sections (Идеальные пропорции)
private extension DroplistCompositView {
    func topSections(screenWidth: CGFloat) -> some View {
        // Чистая математика. Никаких защитных констант.
        let cardWidth = screenWidth * 0.80
        let cardHeight = cardWidth * 0.50
        let imageSize = cardHeight - 12
        
        return VStack(alignment: .leading, spacing: 20) {
            Text(data.topSection.title)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(data.topSection.items) { item in
                            TopSectionItemView(
                                item: item,
                                cardWidth: cardWidth,
                                cardHeight: cardHeight,
                                imageSize: imageSize
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

                    
// MARK: - Carousel Section (Без изменений)
private extension DroplistCompositView {
    var carouselSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(data.carouselItems) { item in
                    carouselItem(item)
                }
            }
            .padding(.horizontal)
        }
    }
    //AppColors.activeColor
    func carouselItem(_ item: CarouselItem) -> some View {
        let isSelected = selectedCarouselItem?.id == item.id
        
        return Text(item.title)
            .font(.subheadline.weight(.medium))
            // Активный элемент меняет цвет текста на пурпурный
            .foregroundColor(isSelected ? AppColors.activeColor : AppColors.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            // У неактивных элементов фона НЕТ вообще
            // У активного элемента - легкая пурпурная плашка
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.secondarySystemBackground.opacity(0.8))
                : nil
            )
            .onTapGesture {
                guard selectedCarouselItem?.id != item.id else { return }
                // Сохраняем, какой item был предыдущим
                previousItemId = selectedCarouselItem?.id
                selectedCarouselItem = item
                onSelectCarouselItem(item)
            }
    }
}

// MARK: - Lower Section + Footer Loader (Без изменений)
private extension DroplistCompositView {
   
    @ViewBuilder
       func lowerSectionWithFooter() -> some View {
           // Всегда рисуем LazyVStack, если есть хоть какие-то данные
           // Если данных нет вообще (например, при первом запуске) – показываем заглушку
           if data.initialLowerSection.items.isEmpty && !data.isLowerSectionLoading {
               lowerSectionErrorPlaceholder
           } else {
               LazyVStack(spacing: 16) {
                   ForEach(data.initialLowerSection.items) { item in
                       lowerItemCell(item)
                   }
                   
                   if data.initialLowerSection.hasMore {
                       footerView
                   }
               }
               .padding(.horizontal)
               // ✅ Лоадер поверх списка, не заменяя его
               .overlay {
                   if data.isLowerSectionLoading {
                       ZStack {
                           AppColors.background.opacity(0.7)
                           ProgressView()
                       }
                       .allowsHitTesting(false)
                   }
               }
           }
       }
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
    
    @ViewBuilder
    var footerView: some View {
        switch data.footerState {
        case .idle:
            HStack {
                Spacer()
                Color.clear
                    .frame(height: 44)
                    .onAppear {
                        print("footerView case .idle")
                        if let selected = selectedCarouselItem {
                            onLoadNextPage(selected)
                        }
                    }
                Spacer()
            }
            .padding(.vertical, 12)
            
        case .loading:
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, 12)
            
        case .error(let message):
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Text(message)
                        .foregroundColor(.secondary)
                    Button("Повторить") {
                        if let selected = selectedCarouselItem {
                            onLoadNextPage(selected)
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
    
    
    func lowerItemCell(_ item: LowerItem) -> some View {
        Button {
            onSelectLowerItem(item)
        } label: {
            HStack(spacing: 12) {
                thumbnail(for: item)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
        }
    }
    
    var lowerSectionErrorPlaceholder: some View {
        VStack(spacing: 12) {
            Text("Не удалось загрузить данные")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button("Повторить") {
                if let selected = selectedCarouselItem {
                    onSelectCarouselItem(selected)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
        }
        .padding(.top, 40)
    }

    @ViewBuilder
    func thumbnail(for item: LowerItem) -> some View {
        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
        
        WebImageView(
            url: url,
            placeholderColor: AppColors.secondarySystemBackground,
            displayStyle: .fixedFrame(width: 60, height: 60),
            context: "LowerItemThumbnail_\(item.id)"
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Top Section Item View (Идеальный макет)


struct TopSectionItemView: View {
    let item: TopItem
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let imageSize: CGFloat

    let artists: [String] = [
        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
        "Future", "21 Savage", "Travis Scott"
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImageView(
                url: item.imageURL,
                placeholderColor: AppColors.secondarySystemBackground,
                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
                context: "TopSectionCard_\(item.id)"
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text("TOP 50")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primary)

                // Список артистов с жесткой высотой
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption2)
                            .foregroundColor(AppColors.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                // Фиксируем высоту
                .frame(height: imageSize, alignment: .top)
                .clipped()
                
                // ОВЕРЛЕЙ: Затемнение начинается С САМОГО СТАРТА (плавно нарастает)
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppColors.secondarySystemBackground.opacity(0.0), // Самый верх: прозрачный (видно полностью)
                            AppColors.secondarySystemBackground.opacity(0.6), // Чуть ниже: легкое затемнение (было 0.3)
                            AppColors.secondarySystemBackground               // Внизу: сливается с фоном
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: imageSize)
                }
            }
            .padding(.trailing, 6)
        }
        .padding(6)
        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
        .background(AppColors.secondarySystemBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}









// MARK: - before work imlemintation






//struct DroplistCompositView: View {
//
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//
//    @State private var selectedCarouselItem: CarouselItem?
//
//    var body: some View {
//        // Профессиональный подход для адаптивной ширины без поломок скролла
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            // КЛЮЧЕВОЙ МОМЕНТ: Запрещаем анимацию смены размеров при повороте экрана
//            .animation(.easeOut(duration: 0.0), value: screenWidth)
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        // Не даем GeometryReader растягивать контент на всю высоту экрана
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}


//
//
//
//
//
//import SwiftUI
//
//struct DroplistCompositView: View {
//
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//
//    @State private var selectedCarouselItem: CarouselItem?
//
//    var body: some View {
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//            let screenHeight = geometry.size.height
//
//            ScrollView {
//                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
//
//                    Section {
//                        topSections(screenWidth: screenWidth)
//                    }
//
//                    Section {
//                        // ⭐ ГЛАВНОЕ: Фиксируем высоту нижней секции.
//                        // Даже когда список меняется, рутовый ScrollView не дергается.
//                        VStack(spacing: 0) {
//                            lowerSectionWithFooter()
//                        }
//                        .frame(minHeight: max(screenHeight - 200, 400), alignment: .top)
//
//                    } header: {
//                        carouselSection
//                            .padding(.top, 8)
//                            .padding(.bottom, 16)
//                            .background(AppColors.background)
//                    }
//                }
//                .padding(.vertical, 12)
//            }
//            .animation(.easeOut(duration: 0.0), value: screenWidth)
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}
//
//
//
//// MARK: - Top Sections (Идеальные пропорции)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // Чистая математика. Никаких защитных констант.
//        let cardWidth = screenWidth * 0.80
//        let cardHeight = cardWidth * 0.50
//        let imageSize = cardHeight - 12
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//                    
//// MARK: - Carousel Section (Без изменений)
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    //AppColors.activeColor
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            // Активный элемент меняет цвет текста на пурпурный
//            .foregroundColor(isSelected ? AppColors.activeColor : AppColors.secondary)
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            // У неактивных элементов фона НЕТ вообще
//            // У активного элемента - легкая пурпурная плашка
//            .background(
//                isSelected ?
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(AppColors.secondarySystemBackground.opacity(0.8))
//                : nil
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension DroplistCompositView {
//   
//
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (Идеальный макет)
//
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "Future", "21 Savage", "Travis Scott"
//    ]
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TOP 50")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                // Список артистов с жесткой высотой
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
//                        Text(line)
//                            .font(.caption2)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//                // Фиксируем высоту
//                .frame(height: imageSize, alignment: .top)
//                .clipped()
//                
//                // ОВЕРЛЕЙ: Затемнение начинается С САМОГО СТАРТА (плавно нарастает)
//                .overlay(alignment: .bottom) {
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            AppColors.secondarySystemBackground.opacity(0.0), // Самый верх: прозрачный (видно полностью)
//                            AppColors.secondarySystemBackground.opacity(0.6), // Чуть ниже: легкое затемнение (было 0.3)
//                            AppColors.secondarySystemBackground               // Внизу: сливается с фоном
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: imageSize)
//                }
//            }
//            .padding(.trailing, 6)
//        }
//        .padding(6)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}













//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        // 1. Если нет данных вообще (например, критическая ошибка при загрузке)
//        if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        // 2. Если есть данные - всегда рисуем LazyVStack
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//
//            // 3. НАКЛАДЫВАЕМ лоадер ПОВЕРХ списка, когда идет загрузка
//            .overlay {
//                if data.isLowerSectionLoading {
//                    ZStack {
//                        AppColors.background.opacity(0.7) // Полупрозрачный фон, чтобы скрыть старый список
//                        VStack(spacing: 8) {
//                            ProgressView()
//                            Text("Загрузка...")
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                    // Игнорируем тапы, чтобы лоадер не мешал скроллу
//                    .allowsHitTesting(false)
//                }
//            }
//        }
//    }
    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        LazyVStack(spacing: 16) {
//            // 1. Если идет загрузка и нет данных, показываем лоадер как полноэкранную ячейку
//            if data.isLowerSectionLoading && data.initialLowerSection.items.isEmpty {
//                VStack(spacing: 8) {
//                    ProgressView()
//                    Text("Загрузка...")
//                        .foregroundColor(.secondary)
//                }
//                .frame(maxWidth: .infinity, minHeight: 200)
//            }
//            // 2. Если ошибка и нет данных, показываем ошибку как полноэкранную ячейку
//            else if data.initialLowerSection.items.isEmpty {
//                lowerSectionErrorPlaceholder
//                    .frame(maxWidth: .infinity)
//            }
//            // 3. Если есть данные — показываем их
//            else {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//        }
//        .padding(.horizontal)
//    }





// MARK: - Sticky Header Copilot

//struct DroplistCompositView: View {
//
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//
//    @State private var selectedCarouselItem: CarouselItem?
//
//    var body: some View {
//        // Профессиональный подход для адаптивной ширины без поломок скролла
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            // КЛЮЧЕВОЙ МОМЕНТ: Запрещаем анимацию смены размеров при повороте экрана
//            .animation(.easeOut(duration: 0.0), value: screenWidth)
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        // Не даем GeometryReader растягивать контент на всю высоту экрана
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}



//import SwiftUI
//
//private struct StickyHeaderKey: PreferenceKey {
//    static var defaultValue: CGFloat = 0
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = nextValue()
//    }
//}
//
//
//// MARK: - Sticky Position Reader
//private extension View {
//    func stickyPosition(_ onChange: @escaping (CGFloat) -> Void) -> some View {
//        self.background(
//            GeometryReader { proxy in
//                Color.clear
//                    .preference(key: StickyHeaderKey.self,
//                                value: proxy.frame(in: .global).minY)
//            }
//        )
//        .onPreferenceChange(StickyHeaderKey.self, perform: onChange)
//    }
//}
//
//
//// MARK: - Sticky Header Container
//struct StickyHeaderContainer<Content: View>: View {
//    let content: () -> Content
//
//    @State private var minY: CGFloat = 0
//    @State private var initialY: CGFloat? = nil
//    @State private var height: CGFloat = 0
//    @State private var isSticky: Bool = false
//
//    var body: some View {
//        ZStack(alignment: .top) {
//
//            // Оригинал внутри ScrollView
//            content()
//                .background(
//                    GeometryReader { proxy in
//                        Color.clear.onAppear {
//                            height = proxy.size.height
//                        }
//                    }
//                )
//                .stickyPosition { y in
//                    if initialY == nil { initialY = y }
//                    minY = y
//                    updateSticky()
//                }
//
//            // Дубликат вне ScrollView
//            if isSticky {
//                content()
//                    .frame(height: height)
//                    .zIndex(999)
//            }
//        }
//    }
//
//    private func updateSticky() {
//        guard let start = initialY else { return }
//        isSticky = minY <= start
//    }
//}
//
//struct StickyCarousel: View {
//    let items: [CarouselItem]
//    let selected: CarouselItem?
//    let onSelect: (CarouselItem) -> Void
//
//    var body: some View {
//        ScrollViewReader { proxy in
//            HStack(spacing: 12) {
//                ForEach(items) { item in
//                    Text(item.title)
//                        .font(.subheadline.weight(.medium))
//                        .foregroundColor(selected?.id == item.id ? AppColors.activeColor : AppColors.secondary)
//                        .padding(.horizontal, 14)
//                        .padding(.vertical, 8)
//                        .background(
//                            selected?.id == item.id ?
//                            RoundedRectangle(cornerRadius: 10)
//                                .fill(AppColors.secondarySystemBackground.opacity(0.8))
//                            : nil
//                        )
//                        .id(item.id)
//                        .onTapGesture {
//                            onSelect(item)
//                            withAnimation {
//                                proxy.scrollTo(item.id, anchor: .center)
//                            }
//                        }
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//}
//
//
//// MARK: - DroplistCompositView
//struct DroplistCompositView: View {
//
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//
//    @State private var selectedCarouselItem: CarouselItem?
//
//    var body: some View {
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//
//            ZStack(alignment: .top) {
//
//                ScrollView {
//                    VStack(spacing: 16) {
//
//                        // Верхняя секция
//                        topSections(screenWidth: screenWidth)
//
//                        // Sticky-карусель
//                        StickyHeaderContainer {
//                            StickyCarousel(
//                                items: data.carouselItems,
//                                selected: selectedCarouselItem,
//                                onSelect: { item in
//                                    selectedCarouselItem = item
//                                    onSelectCarouselItem(item)
//                                }
//                            )
//                        }
//
//                        // Нижняя секция
//                        lowerSectionWithFooter()
//                    }
//                    .padding(.vertical, 12)
//                }
//                .refreshable { onRefresh() }
//                .onAppear { selectedCarouselItem = data.selectedItem }
//            }
//        }
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}
//
//
//
//// MARK: - Top Sections (Идеальные пропорции)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // Чистая математика. Никаких защитных констант.
//        let cardWidth = screenWidth * 0.80
//        let cardHeight = cardWidth * 0.50
//        let imageSize = cardHeight - 12
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//                    
//// MARK: - Carousel Section (Без изменений)
//
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    //AppColors.activeColor
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            // Активный элемент меняет цвет текста на пурпурный
//            .foregroundColor(isSelected ? AppColors.activeColor : AppColors.secondary)
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            // У неактивных элементов фона НЕТ вообще
//            // У активного элемента - легкая пурпурная плашка
//            .background(
//                isSelected ?
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(AppColors.secondarySystemBackground.opacity(0.8))
//                : nil
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (Идеальный макет)
//
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "Future", "21 Savage", "Travis Scott"
//    ]
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TOP 50")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                // Список артистов с жесткой высотой
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
//                        Text(line)
//                            .font(.caption2)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//                // Фиксируем высоту
//                .frame(height: imageSize, alignment: .top)
//                .clipped()
//                
//                // ОВЕРЛЕЙ: Затемнение начинается С САМОГО СТАРТА (плавно нарастает)
//                .overlay(alignment: .bottom) {
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            AppColors.secondarySystemBackground.opacity(0.0), // Самый верх: прозрачный (видно полностью)
//                            AppColors.secondarySystemBackground.opacity(0.6), // Чуть ниже: легкое затемнение (было 0.3)
//                            AppColors.secondarySystemBackground               // Внизу: сливается с фоном
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: imageSize)
//                }
//            }
//            .padding(.trailing, 6)
//        }
//        .padding(6)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}
//


// MARK: - defore implemintation Sticky Header

//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        // Профессиональный подход для адаптивной ширины без поломок скролла
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//            
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            // КЛЮЧЕВОЙ МОМЕНТ: Запрещаем анимацию смены размеров при повороте экрана
//            .animation(.easeOut(duration: 0.0), value: screenWidth)
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        // Не даем GeometryReader растягивать контент на всю высоту экрана
//        .frame(maxHeight: .infinity, alignment: .top)
//    }
//}
//
//// MARK: - Top Sections (Идеальные пропорции)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // Чистая математика. Никаких защитных констант.
//        let cardWidth = screenWidth * 0.80
//        let cardHeight = cardWidth * 0.50
//        let imageSize = cardHeight - 12
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//                    
//// MARK: - Carousel Section (Без изменений)
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    //AppColors.activeColor
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            // Активный элемент меняет цвет текста на пурпурный
//            .foregroundColor(isSelected ? AppColors.activeColor : AppColors.secondary)
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            // У неактивных элементов фона НЕТ вообще
//            // У активного элемента - легкая пурпурная плашка
//            .background(
//                isSelected ?
//                RoundedRectangle(cornerRadius: 10)
//                    .fill(AppColors.secondarySystemBackground.opacity(0.8))
//                : nil
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (Идеальный макет)
//
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "Future", "21 Savage", "Travis Scott"
//    ]
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TOP 50")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                // Список артистов с жесткой высотой
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
//                        Text(line)
//                            .font(.caption2)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//                // Фиксируем высоту
//                .frame(height: imageSize, alignment: .top)
//                .clipped()
//                
//                // ОВЕРЛЕЙ: Затемнение начинается С САМОГО СТАРТА (плавно нарастает)
//                .overlay(alignment: .bottom) {
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            AppColors.secondarySystemBackground.opacity(0.0), // Самый верх: прозрачный (видно полностью)
//                            AppColors.secondarySystemBackground.opacity(0.6), // Чуть ниже: легкое затемнение (было 0.3)
//                            AppColors.secondarySystemBackground               // Внизу: сливается с фоном
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: imageSize)
//                }
//            }
//            .padding(.trailing, 6)
//        }
//        .padding(6)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}
//
//
//
//
//
//
//
//
//



// MARK: - versions TopSectionItemView


//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "Future", "21 Savage", "Travis Scott"
//    ]
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 16) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            VStack(alignment: .leading, spacing: 0) { // spacing: 0, чтобы мы сами управляли отступами
//                
//                // 1. ЗАГОЛОВОК "TOP 50"
//                Text("TOP 50")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                    // Отступ НИЖЕ заголовка
//                    .padding(.bottom, 2) // spacing между TOP 50 и 15 tracks = 4
//                
//                // 2. ПОДЗАГОЛОВОК С КОЛИЧЕСТВОМ ТРЕКОВ
//                Text("\(artists.count) tracks")
//                    .font(.footnote)
//                    .fontWeight(.regular)
//                    .foregroundColor(AppColors.secondary)
//                    // Отступ НИЖЕ количества треков
//                    .padding(.bottom, 6) // spacing между 15 tracks и списком = 6
//
//                // 3. СПИСОК АРТИСТОВ
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
//                        Text(line)
//                            .font(.caption2)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//                .frame(height: imageSize, alignment: .top)
//                .clipped()
//                
//                // ОВЕРЛЕЙ с градиентом
//                .overlay(alignment: .bottom) {
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            AppColors.secondarySystemBackground.opacity(0.0),
//                            AppColors.secondarySystemBackground.opacity(0.8),
//                            AppColors.secondarySystemBackground
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: imageSize)
//                }
//            }
//            .padding(.trailing, 16)
//        }
//        .padding(12)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "Future", "21 Savage", "Travis Scott"
//    ]
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 16) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            VStack(alignment: .leading, spacing: 6) { // spacing немного уменьшили для компактности
//                
//                // 1. ЗАГОЛОВОК "TOP 50" (Чуть крупнее, но не огромный)
//                Text("TOP 50")
//                    .font(.headline) // Системный заголовок. Отлично масштабируется.
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                
//                // 2. ПОДЗАГОЛОВОК С КОЛИЧЕСТВОМ ТРЕКОВ (Меньше, обычный вес)
//                Text("\(artists.count) tracks")
//                    .font(.footnote) // Самый маленький системный читаемый шрифт.
//                    .fontWeight(.regular)
//                    .foregroundColor(AppColors.primary)
//                    .padding(.bottom, 4) // Небольшой отступ до списка
//
//                // 3. СПИСОК АРТИСТОВ (Самый мелкий, но читаемый)
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
//                        Text(line)
//                            // Используем .caption2, это самый мелкий системный шрифт iOS.
//                            // На Pro Max он будет ~13pt, на iPhone 8 ~10pt. Идеально читается!
//                            .font(.caption2)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//                // Фиксируем высоту
//                .frame(height: imageSize, alignment: .top)
//                .clipped()
//                
//                // ОВЕРЛЕЙ с градиентом
//                .overlay(alignment: .bottom) {
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            AppColors.secondarySystemBackground.opacity(0.0),
//                            AppColors.secondarySystemBackground.opacity(0.8),
//                            AppColors.secondarySystemBackground
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: imageSize)
//                }
//            }
//            .padding(.trailing, 16)
//        }
//        .padding(12)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "Future", "21 Savage", "Travis Scott"
//    ]
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 16) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TOP 50")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                // Список артистов с жесткой высотой
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(Array(artists.enumerated()), id: \.offset) { _, line in
//                        Text(line)
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                    }
//                }
//                // Фиксируем высоту
//                .frame(height: imageSize, alignment: .top)
//                .clipped()
//                
//                // ОВЕРЛЕЙ: Затемнение начинается С САМОГО СТАРТА (плавно нарастает)
//                .overlay(alignment: .bottom) {
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            AppColors.secondarySystemBackground.opacity(0.0), // Самый верх: прозрачный (видно полностью)
//                            AppColors.secondarySystemBackground.opacity(0.8), // Чуть ниже: легкое затемнение (было 0.3)
//                            AppColors.secondarySystemBackground               // Внизу: сливается с фоном
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: imageSize)
//                }
//            }
//            .padding(.trailing, 16)
//        }
//        .padding(12)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}

// implement deepseek #work cod

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake", "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
////    let artists: [String] = [
////        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
////        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake"
////    ]
//
//    var body: some View {
//        // 1. Жестко фиксируем выравнивание влево через leading!
//        HStack(alignment: .top, spacing: 16) {
//            
//            // ЛЕВАЯ ЧАСТЬ: Картинка
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            // 2. УБРАЛИ .padding(.leading, 10) полностью!
//            // Теперь картинка занимает ровно свой размер, не создавая лишнего отступа.
//
//            // ПРАВАЯ ЧАСТЬ: Текст
//            VStack(alignment: .leading, spacing: 10) {
//                Text("TOP 50")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                
//                FadingBottomLines(
//                    lines: artists,
//                    font: .subheadline,
//                    foreground: AppColors.secondary,
//                    fadeHeight: cardHeight / 2
//                )
//                .frame(maxHeight: imageSize - 50, alignment: .top)
//                
//                // Spacer() убран. Контент сам прижмется к верху за счет alignment .top в HStack
//            }
//            .padding(.top, 0) // Убираем лишний отступ сверху для текста
//            .padding(.trailing, 16)
//            
//            // Не добавляем Spacer в конце. Это жестко прижмет HStack к левому краю!
//        }
//        // 3. ГЛАВНЫЙ ФИКС: Задаем ВНЕШНИЕ отступы для всей карточки РАЗОМ!
//        // Это создаст идеально ровный отступ 12пт со всех сторон.
//        .padding(12)
//        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}
//
//
//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let fadeHeight: CGFloat // Теперь эта переменная реально используется!
//    
//    var body: some View {
//        // 1. Используем GeometryReader, чтобы узнать реальную высоту списка
//        GeometryReader { geometry in
//            VStack(alignment: .leading, spacing: 2) {
//                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
//                    Text(line)
//                        .font(font)
//                        .foregroundColor(foreground)
//                        .lineLimit(1)
//                        .truncationMode(.tail)
//                }
//            }
//            // 2. Накладываем маску. Высота градиента берется из переданной fadeHeight
//            .mask(
//                VStack(spacing: 0) {
//                    // Верхняя часть до начала исчезновения (полностью видна)
//                    Color.white
//                        .frame(height: geometry.size.height - fadeHeight)
//                    
//                    // Нижняя часть - плавный градиент от белого к прозрачному
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color.white,
//                            Color.white.opacity(0.0)
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                    .frame(height: fadeHeight)
//                }
//            )
//        }
//        // 3. Важно: Фиксируем высоту контейнера, чтобы GeometryReader не растягивал лэйаут
//        .frame(height: fadeHeight * 2) // Или передавайте maxHeight извне
//    }
//}





//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let fadeHeight: CGFloat
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
//                Text(line)
//                    .font(font)
//                    .foregroundColor(foreground)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//            }
//        }
//        .mask(
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.white,
//                    Color.white,
//                    Color.white.opacity(0.0)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//    }
//}



//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let fadeHeight: CGFloat
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            // ИЗМЕНЕНИЕ: .prefix(4) гарантирует, что мы никогда не выйдем за рамки
//            ForEach(Array(lines.prefix(4).enumerated()), id: \.offset) { _, line in
//                Text(line)
//                    .font(font)
//                    .foregroundColor(foreground)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//            }
//        }
//        .mask(
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.white,
//                    Color.white,
//                    Color.white.opacity(0.0)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//    }
//}

// implement deepseek #2

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
////    let artists: [String] = [
////        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
////        // Убрали лишние элементы, чтобы не растягивать макет
////    ]
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    var body: some View {
//        HStack(alignment: .top, spacing: 14) {
//
//            // 1. Картинка с padding 10 сверху, снизу и слева
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            .padding(.leading, 10)
//            .padding(.vertical, 10)
//
//            // 2. Текстовый блок с spacing 10
//            VStack(alignment: .leading, spacing: 10) { // spacing 10 как вы и хотели
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                FadingBottomLines(
//                    lines: artists,
//                    font: .subheadline,
//                    foreground: AppColors.secondary,
//                    fadeHeight: cardHeight / 2
//                )
//                // ВАЖНО: Ограничиваем высоту текста, чтобы он не вылезал за cardHeight
//                .frame(maxHeight: imageSize, alignment: .top)
//
//                Spacer() // Прижимает текстовый блок к верху VStack
//            }
//            .padding(.top, 10) // Выравниваем "TOP 10" по верхнему краю картинки
//            .padding(.trailing, 16)
//        }
//        .frame(width: cardWidth, height: cardHeight)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16) // Сделал 16, чтобы совпадало с общим скруглением
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}




// implement new #1

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//
//    var body: some View {
//        HStack(spacing: 14) {
//            VStack(alignment: .leading) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                    context: "TopSectionCard_\(item.id)"
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//            }
//          
//            VStack(alignment: .leading, spacing: 0) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                FadingBottomLines(
//                    lines: artists,
//                    font: .subheadline,
//                    foreground: AppColors.secondary,
//                    fadeHeight: cardHeight / 2
//                )
//            }
//        }
//        .frame(width: cardWidth, height: cardHeight)
////        .frame(width: cardWidth)
////        .padding(10)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(10)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}


//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let fadeHeight: CGFloat
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
//                Text(line)
//                    .font(font)
//                    .foregroundColor(foreground)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//            }
//        }
//        .mask(
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.white,
//                    Color.white,
//                    Color.white.opacity(0.0)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//    }
//}



//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let fadeHeight: CGFloat
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
//                Text(line)
//                    .font(font)
//                    .foregroundColor(foreground)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//            }
//        }
//        .mask(
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.white,
//                    Color.white,
//                    Color.white.opacity(0.0)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//    }
//}


// implement new #2

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake",
//        "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//
//    var body: some View {
//        HStack(spacing: 14) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//
//            VStack(alignment: .leading, spacing: 6) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                FadingBottomLines(
//                    lines: artists,
//                    font: .subheadline,
//                    foreground: AppColors.secondary,
//                    fadeHeight: cardHeight / 2
//                )
//            }
//        }
//        .frame(width: cardWidth)
//        .padding(10)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}

//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let fadeHeight: CGFloat
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            // ИЗМЕНЕНИЕ: .prefix(4) гарантирует, что мы никогда не выйдем за рамки
//            ForEach(Array(lines.prefix(4).enumerated()), id: \.offset) { _, line in
//                Text(line)
//                    .font(font)
//                    .foregroundColor(foreground)
//                    .lineLimit(1)
//                    .truncationMode(.tail)
//            }
//        }
//        .mask(
//            LinearGradient(
//                gradient: Gradient(colors: [
//                    Color.white,
//                    Color.white,
//                    Color.white.opacity(0.0)
//                ]),
//                startPoint: .top,
//                endPoint: .bottom
//            )
//        )
//    }
//}



// implement new #3

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake", "French Montana + French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    let trackCount: Int = 50
//    
//    var body: some View {
//        HStack(spacing: 14) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            
//            VStack(alignment: .leading, spacing: 4) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                FadingBottomLines(
//                                    lines: artists,
//                                    font: .subheadline,
//                                    foreground: AppColors.secondary,
//                                    background: AppColors.secondarySystemBackground,
//                                    fadeHeight: imageSize/2
//                                )
//                // ВАЖНО: ограничиваем высоту по картинке, ширину не трогаем
//                                .frame(height: imageSize, alignment: .topLeading)
//                FadingBottomText(
//                    text: artists.joined(separator: "\n"),
//                    font: .subheadline,
//                    foreground: AppColors.secondary,
//                    background: AppColors.secondarySystemBackground,
//                    lineLimit: 1,          // сколько строк показывать максимум
//                    fadeHeight: cardHeight/2         // высота зоны исчезновения
//                )
//            }
//        }
//        .frame(width: cardWidth, height: cardHeight)
//        .padding(10)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}
//
//
//
//struct FadingBottomLines: View {
//    let lines: [String]
//    let font: Font
//    let foreground: Color
//    let background: Color
//    let fadeHeight: CGFloat
//
//    var body: some View {
//        ZStack(alignment: .topLeading) {
//            VStack(alignment: .leading, spacing: 2) {
//                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
//                    Text(line)
//                        .font(font)
//                        .foregroundColor(foreground)
//                        .lineLimit(1)
//                        .truncationMode(.tail)
//                }
//            }
//            .padding(.bottom, fadeHeight)
//
//            VStack {
//                Spacer()
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color.clear,
//                        background.opacity(0.7),
//                        background
//                    ]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .frame(height: fadeHeight)
//            }
//        }
//        .clipped()              // критично: обрезаем содержимое по высоте родителя
//        .background(background)
//    }
//}







//struct FadingBottomText: View {
//    let text: String
//    let font: Font
//    let foreground: Color
//    let background: Color
//    let lineLimit: Int
//    let fadeHeight: CGFloat   // высота зоны градиента снизу
//
//    var body: some View {
//        ZStack(alignment: .topLeading) {
//            Text(text)
//                .font(font)
//                .foregroundColor(foreground)
//
//            // Градиент снизу, который делает текст прозрачным
//            VStack {
//                Spacer()
//                LinearGradient(
//                    gradient: Gradient(colors: [
//                        Color.clear,
//                        background.opacity(0.9),
//                        background
//                    ]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .frame(height: fadeHeight)
//                .allowsHitTesting(false)
//            }
//        }
//        .background(background)
//        .compositingGroup()
//    }
//}

//                .lineLimit(lineLimit)
//                .multilineTextAlignment(.leading)
//                .fixedSize(horizontal: false, vertical: true)



//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    let trackCount: Int = 50
//
//    var body: some View {
//        HStack(spacing: 14) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(artists.prefix(4), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                }
//
//                Spacer(minLength: 0)
//
//                HStack(alignment: .bottom) {
//                    Text("....")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(AppColors.secondary)
//
//                    Spacer()
//
//                    Text("\(trackCount) tracks")
//                        .font(.footnote)
//                        .foregroundColor(AppColors.secondary)
//                }
//                .padding(.bottom, 2)
//            }
//            .padding(.top, 8)
//            .padding(.bottom, 4)
//            .padding(.trailing, 4)
//
//            Spacer()
//        }
//        .padding(10)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}

//+------------------------------------------------------+
//| [IMAGE]   TOP 50                                     |
//|          50 tracks                                   |
//|                                                      |
//| French Montana, Kodak Black, Lil Wayne, Drake        |
//+------------------------------------------------------+



//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // Чистая математика. Никаких защитных констант.
//        let cardWidth = screenWidth * 0.80
//        let cardHeight = cardWidth * 0.50
//        let imageSize = cardHeight - 16
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight
//                            )
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}


//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    var body: some View {
//        
//        let artistsLine = artists.joined(separator: ", ")
//        
//        VStack(alignment: .leading, spacing: 12) {
//            
//            // MARK: - Верхняя строка: картинка + заголовок справа
//            HStack(alignment: .top, spacing: 12) {
//                
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(width: cardHeight * 0.55, height: cardHeight * 0.55),
//                    context: "TopSectionCard_\(item.id)"
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("TOP 50")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(.primary)
//                    
//                    Text("\(50) tracks")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//            }
//            
//            // MARK: - Artists в одну строку под картинкой
//            Text(artistsLine)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .lineLimit(1)
//                .padding(.horizontal, 4)
//            
//        }
//        .padding(12)
//        .frame(width: cardWidth)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}











//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        // АБСОЛЮТНО НАДЕЖНОЕ МЕСТО ДЛЯ РАСЧЕТА ШИРИНЫ
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//            
//            ScrollView {
//                VStack(spacing: 16) {
//                    // Передаём ширину прямо в функцию. Без @State, без задержек.
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        // Запрещаем GeometryReader растягиваться до бесконечности
//        .frame(maxHeight: .infinity)
//    }
//}
//
//// MARK: - Top Sections (АДАПТИВНЫЙ РАСЧЕТ)
//// MARK: - Top Sections (Идеальные пропорции всегда, защита только от краша)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // 1. Сначала рассчитываем идеальные значения строго по формулам
//        let calculatedWidth = screenWidth * 0.80
//        let calculatedHeight = calculatedWidth * 0.50
//        let calculatedImageSize = calculatedHeight - 24
//        
//        // 2. Применяем защиту ТОЛЬКО от нулевых значений.
//        // Минимальные значения (50, 20) НАМНОГО МЕНЬШЕ любых реальных пропорций.
//        // Теперь на iPhone 17 Pro сработает ТОЛЬКО calculation!
//        let cardWidth = max(calculatedWidth, 50)
//        let cardHeight = max(calculatedHeight, 20)
//        let imageSize = max(calculatedImageSize, 20)
//        
//        // ВЫВОД ДЛЯ ПРОВЕРКИ (Теперь вы увидите реальные пропорции!)
//        print("✅ Реальная ширина экрана: \(screenWidth)")
//        print("✅ Итоговая cardWidth: \(cardWidth)")     // Будет ~ 314.4
//        print("✅ Итоговая cardHeight: \(cardHeight)")   // Будет ~ 157.2
//        print("✅ Итоговая imageSize: \(imageSize)")     // Будет ~ 133.2
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                            .frame(width: cardWidth, height: cardHeight)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
////private extension DroplistCompositView {
////    func topSections(screenWidth: CGFloat) -> some View {
////        // Тот самый расчет, который выводил правильные цифры в консоль
////        let cardWidth = max(screenWidth * 0.80, 280)
////        print("cardWidth - \(cardWidth)")
////        let cardHeight = max(cardWidth * 0.50, 170)
////        print("cardHeight - \(cardHeight)")
////        let imageSize = max(cardHeight - 24, 120)
////        
////        return VStack(alignment: .leading, spacing: 20) {
////            Text(data.topSection.title)
////                .font(.headline)
////                .padding(.horizontal)
////            
////            VStack(alignment: .leading, spacing: 8) {
////                ScrollView(.horizontal, showsIndicators: false) {
////                    HStack(spacing: 16) {
////                        ForEach(data.topSection.items) { item in
////                            TopSectionItemView(
////                                item: item,
////                                cardWidth: cardWidth,
////                                cardHeight: cardHeight,
////                                imageSize: imageSize
////                            )
////                            .frame(width: cardWidth, height: cardHeight)
////                        }
////                    }
////                    .padding(.horizontal)
////                }
////            }
////        }
////    }
////}
//
//// MARK: - Carousel Section (Без изменений)
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View
//
//// MARK: - Top Section Item View (Сбалансированные отступы)
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    let trackCount: Int = 50
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            
//            VStack(alignment: .leading, spacing: 4) { // spacing уменьшен с 6 до 4
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                
//                VStack(alignment: .leading, spacing: 2) { // spacing 2 между артистами
//                    ForEach(artists.prefix(4), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                }
//                
//                Spacer(minLength: 4) // Минимальный отступ, чтобы прижать треки к низу
//                
//                HStack(alignment: .bottom) {
//                    Text("....")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(AppColors.secondary)
//                    
//                    Spacer()
//                    
//                    Text("\(trackCount) tracks")
//                        .font(.footnote)
//                        .foregroundColor(AppColors.secondary)
//                }
//            }
//            .padding(.top, 8)
//            .padding(.trailing, 4)
//            
//            Spacer()
//        }
//        .padding(10)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    let trackCount: Int = 50
//    
//    var body: some View {
//        HStack(spacing: 14) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            
//            VStack(alignment: .leading, spacing: 6) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                    .padding(.top, 2)
//                
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(artists.prefix(4), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                }
//                
//                Spacer()
//                
//                HStack(alignment: .bottom) {
//                    Text("....")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .foregroundColor(AppColors.secondary)
//                    
//                    Spacer()
//                    
//                    Text("\(trackCount) tracks")
//                        .font(.footnote)
//                        .foregroundColor(AppColors.secondary)
//                }
//                .padding(.bottom, 2)
//            }
//            .padding(.top, 6)
//            .padding(.trailing, 2)
//            
//            Spacer()
//        }
//        .padding(12)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}


//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        // 1. GeometryReader в корне. Это надежно и без дерганий.
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//            
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//        // 2. Защита от растягивания GeometryReader в бесконечность
//        .frame(maxHeight: .infinity)
//    }
//}
//
//// MARK: - Top Sections (ИСПРАВЛЕННЫЕ ПРОПОРЦИИ)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // 3. ВАЖНО: Минимальная высота 170. Текст теперь влезает идеально!
//        let cardWidth = max(screenWidth * 0.80, 280)
//        print("cardWidth - \(cardWidth)")
//        let cardHeight = max(cardWidth * 0.50, 170)
//        print("cardHeight - \(cardHeight)")
//        let imageSize = max(cardHeight - 24, 120)
////        let cardWidth = max(screenWidth * 0.80, 100) // 280
////        print("cardWidth - \(cardWidth)")
////        let cardHeight = max(cardWidth * 0.50, 50) // 170
////        print("cardHeight - \(cardHeight)")
//////        let imageSize = max(cardHeight - 24, 120)
////        let imageSize = max(cardHeight - 16, 30)
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                            .frame(width: cardWidth, height: cardHeight)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section (Без изменений)
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (Идеальный макет под 2-й скрин)
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    let trackCount: Int = 50
//    
//    @ViewBuilder
//    var body: some View {
//        if imageSize > 0 && cardHeight > 0 {
//            HStack(spacing: 14) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                    context: "TopSectionCard_\(item.id)"
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("TOP 10")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(AppColors.primary)
//                        .padding(.top, 4)
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                        ForEach(artists.prefix(4), id: \.self) { artist in
//                            Text(artist)
//                                .font(.subheadline)
//                                .foregroundColor(AppColors.secondary)
//                                .lineLimit(1)
//                        }
//                    }
//                    
//                    Spacer()
//                    
//                    // Нижняя строка с многоточием и треками
//                    HStack(alignment: .bottom) {
//                        Text("....")
//                            .font(.subheadline)
//                            .fontWeight(.medium)
//                            .foregroundColor(AppColors.secondary)
//                        
//                        Spacer()
//                        
//                        Text("\(trackCount) tracks")
//                            .font(.footnote)
//                            .foregroundColor(AppColors.secondary)
//                    }
//                    .padding(.bottom, 4)
//                }
//                .padding(.top, 8)
//                .padding(.trailing, 4)
//                
//                Spacer()
//            }
//            .padding(12)
//            .background(AppColors.secondarySystemBackground)
//            .cornerRadius(16)
//            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//        } else {
//            Color.clear.frame(height: cardHeight)
//        }
//    }
//}

//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    @State private var screenWidth: CGFloat = UIScreen.main.bounds.width
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 16) {
//                topSections(screenWidth: screenWidth)
//                carouselSection
//                lowerSectionWithFooter()
//            }
//            .padding(.vertical, 12)
//            .background(
//                GeometryReader { geometry in
//                    Color.clear
//                        .preference(key: ScreenWidthPreferenceKey.self, value: geometry.size.width)
//                }
//            )
//        }
//        .onPreferenceChange(ScreenWidthPreferenceKey.self) { newWidth in
//            if screenWidth != newWidth {
//                screenWidth = newWidth
//            }
//        }
//        .refreshable {
//            onRefresh()
//        }
//        .onAppear {
//            selectedCarouselItem = data.selectedItem
//        }
//    }
//}
//
//// MARK: - Top Sections (С обновленной защитой от схлопывания)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // ЗАЩИТА: Если ширина пришла 0, даем карточке заведомо большой размер (280x160),
//        // чтобы текстовый блок НЕ СХЛОПНУЛСЯ.
//        let cardWidth = max(screenWidth * 0.80, 100) // 280
//        let cardHeight = max(cardWidth * 0.50, 60) // 160
//        let imageSize = max(cardHeight - 16, 50) // 100
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                            .frame(width: cardWidth, height: cardHeight)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section (Без изменений)
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (Без изменений)
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (БЕЗ AnyView, переписана на @ViewBuilder)
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    let artists: [String] = [
//        "French Montana", "Kodak Black", "Lil Wayne", "Drake"
//    ]
//    let trackCount: Int = 50
//    
//    @ViewBuilder
//    var body: some View {
//        if imageSize > 0 && cardHeight > 0 {
//            HStack(spacing: 12) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                    context: "TopSectionCard_\(item.id)"
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 10))
//                
//                VStack(alignment: .leading, spacing: 0) {
//                    Text("TOP 10")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(AppColors.primary)
//                        .padding(.bottom, 10)
//                    
//                    VStack(alignment: .leading, spacing: 6) {
//                        ForEach(artists.prefix(4), id: \.self) { artist in
//                            Text(artist)
//                                .font(.subheadline)
//                                .foregroundColor(AppColors.secondary)
//                                .lineLimit(1)
//                        }
//                        
//                        HStack(alignment: .bottom) {
//                            Text("....")
//                                .font(.subheadline)
//                                .fontWeight(.medium)
//                                .foregroundColor(AppColors.secondary)
//                            
//                            Spacer()
//                            
//                            Text("\(trackCount) tracks")
//                                .font(.footnote)
//                                .foregroundColor(AppColors.secondary)
//                        }
//                    }
//                    Spacer()
//                }
//                .padding(.top, 8)
//                .padding(.trailing, 4)
//                
//                Spacer()
//            }
//            .padding(8)
//            .background(AppColors.secondarySystemBackground)
//            .cornerRadius(16)
//            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//        } else {
//            Color.clear.frame(height: cardHeight)
//        }
//    }
//}
//
//// Preference Key
//struct ScreenWidthPreferenceKey: PreferenceKey {
//    static let defaultValue: CGFloat = 0
//    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
//        value = nextValue()
//    }
//}




// before ScreenWidthPreferenceKey

//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//
//    @State private var selectedCarouselItem: CarouselItem?
//
//    var body: some View {
//        // 1. GeometryReader считывает ширину ЭКРАНА с учетом Safe Area и ориентации
//        GeometryReader { geometry in
//            let screenWidth = geometry.size.width
//
//            ScrollView {
//                VStack(spacing: 16) {
//                    // 2. Передаем вычисленную ширину в секции
//                    topSections(screenWidth: screenWidth)
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//    }
//}
//
//// MARK: - Top Sections (АДАПТИВНЫЙ РАСЧЕТ РАЗМЕРОВ)
//private extension DroplistCompositView {
//    func topSections(screenWidth: CGFloat) -> some View {
//        // Адаптивные размеры, рассчитываемые от ширины экрана:
//        let cardWidth = screenWidth * 0.80 // Ширина 80% экрана. Вторая карточка выступает на оставшиеся 20%.
//        let cardHeight = cardWidth * 0.50 // Высота 60% от ширины, чтобы сделать карточку "повыше".
//        let imageSize = cardHeight - 16   // Размер картинки = высота карточки минус отступы по 8pt сверху и снизу.
//        
//        return VStack(alignment: .leading, spacing: 20) {
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            // Передаем вычисленные размеры внутрь карточки
//                            TopSectionItemView(
//                                item: item,
//                                cardWidth: cardWidth,
//                                cardHeight: cardHeight,
//                                imageSize: imageSize
//                            )
//                            .frame(width: cardWidth, height: cardHeight)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section (ОСТАЕТСЯ ФИКСИРОВАННЫМ, ТАК КАК ЭТО ТЕГИ)
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (ОСТАЕТСЯ СТАНДАРТНЫМ)
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    // MARK: - Footer
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            .onAppear {
//                print("footerView case .loading")
//            }
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}



// MARK: - Top Section Item View (АДАПТИВНАЯ, БЕЗ ЖЕСТКИХ РАЗМЕРОВ)

//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    // Тестовые данные (В будущем придут из модели)
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott"
//    ]
//    let trackCount: Int = 50
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // ЛЕВАЯ ЧАСТЬ: Адаптивная квадратная картинка
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            
//            // ПРАВАЯ ЧАСТЬ: Текстовый блок
//            VStack(alignment: .leading, spacing: 0) {
//                
//                // 1. TOP 10 (Жирный заголовок)
//                Text("TOP 10")
//                    .font(.headline) // Используем системный Headline
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                    .padding(.bottom, 10) // Отступ до списка артистов
//                
//                // 2. Список артистов с многоточием
//                VStack(alignment: .leading, spacing: 6) {
//                    // Берем ТОЛЬКО ПЕРВЫХ 4 артистов
//                    ForEach(artists.prefix(4), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline) // Системный Subheadline (гайдлайн Apple)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                    
//                    // 3. Строка с многоточием и количеством треков (прижаты к краям)
//                    HStack(alignment: .bottom) {
//                        // Многоточие (...)
//                        Text("....")
//                            .font(.subheadline) // Такой же шрифт, как у артистов
//                            .fontWeight(.medium)
//                            .foregroundColor(AppColors.secondary)
//                        
//                        Spacer() // Раздвигает текст по краям
//                        
//                        // Количество треков (50 tracks)
//                        Text("\(trackCount) tracks")
//                            .font(.footnote) // Самый мелкий читаемый шрифт по гайдлайну
//                            .foregroundColor(AppColors.secondary)
//                    }
//                }
//                
//                Spacer() // Прижимает весь блок вверх, если карточка слишком высокая
//            }
//            .padding(.top, 8)
//            .padding(.trailing, 4) // Небольшой отступ справа, чтобы текст не прилипал к краю
//            
//            Spacer() // Прижимает HStack влево
//        }
//        .padding(8)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}
//struct TopSectionItemView: View {
//    let item: TopItem
//    let cardWidth: CGFloat
//    let cardHeight: CGFloat
//    let imageSize: CGFloat
//    
//    // Тестовый массив с именами исполнителей (Не более 4, чтобы точно влезть в макет)
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        // "Future" // Убрал до 4, чтобы текст не вылезал за границы
//    ]
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // ЛЕВАЯ ЧАСТЬ: Адаптивная квадратная картинка
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: imageSize, height: imageSize), // Размер зависит от экрана
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            
//            // ПРАВАЯ ЧАСТЬ: Текстовая информация
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                    // Если очень маленький экран, уменьшаем шрифт:
//                    .minimumScaleFactor(0.8)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    ForEach(artists.prefix(4), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                }
//                Spacer() // Прижимает весь контент к верху, компенсируя высоту
//            }
//            .frame(maxHeight: cardHeight - 24, alignment: .top) // Ограничиваем высоту текста, не даем вылезти
//            .padding(.top, 8)
//            
//            Spacer()
//        }
//        .padding(8) // Отступы всей карточки от границ
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}


//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 16) {
//                topSections
//                carouselSection
//                lowerSectionWithFooter()
//            }
//            .padding(.vertical, 12)
//        }
//        .refreshable {
//            onRefresh()
//        }
//        .onAppear {
//            selectedCarouselItem = data.selectedItem
//        }
//    }
//}
//
//// MARK: - Top Sections (ВЫРОВНЕНЫ ОТСТУПЫ)
//
//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal) // Оставляем паддинг для заголовка
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                                // УМЕНЬШИЛИ ШИРИНУ: 0.68 вместо 0.82. Вторая карточка будет сильнее выступать.
//                                .frame(width: UIScreen.main.bounds.width * 0.68)
//                        }
//                    }
//                    // Чтобы первая карточка начиналась ровно от края экрана, как и остальные секции
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section (ВАШ ОРИГИНАЛЬНЫЙ КОД)
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal) // Отступ слева выровнен с topSections
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (ВАШ ОРИГИНАЛЬНЫЙ КОД)
//
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal) // Отступ слева выровнен с topSections
//        }
//    }
//    
//    // MARK: - Footer
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            .onAppear {
//                print("footerView case .loading")
//            }
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (ОБНОВЛЕНЫ ОТСТУПЫ КАРТИНКИ)
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    // Тестовый массив с именами исполнителей
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott",
//        "21 Savage"
//    ]
//    
//    var body: some View {
//        HStack(spacing: 12) { // spacing между картинкой и текстом тоже уменьшили
//            // ЛЕВАЯ ЧАСТЬ: Квадратная картинка
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 100, height: 100),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            // УБРАЛИ padding у картинки, добавили отступы через .padding(8) у всего HStack внизу.
//            
//            // ПРАВАЯ ЧАСТЬ: Текстовая информация
//            VStack(alignment: .leading, spacing: 8) {
//                Text("TOP 10")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    ForEach(artists.prefix(5), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline)
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                }
//            }
//            Spacer()
//        }
//        // Фон карточки и размеры
//        .padding(8) // МАЛЕНЬКИЙ ОТСТУП (8 пунктов) для всей карточки.
//        // Картинка теперь касается этих границ, так как у нее нет своего дополнительного паддинга.
//        .frame(height: 116) // Высота = 100 (картинка) + 8 (верх) + 8 (низ)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16)
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}

// before выравнивания

//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//    }
//}
//
//// MARK: - Top Sections
//
//// MARK: - Top Sections
//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(alignment: .leading, spacing: 20) {
//            
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                                // ВАЖНО: Задаем ширину здесь. 0.85 от ширины экрана = крупная карточка
//                                .frame(width: UIScreen.main.bounds.width * 0.82)
//                        }
//                    }
//                    .padding(.horizontal)
//                    // Чтобы первая карточка выглядывала слева, как на макете:
//                    .padding(.leading, 16)
//                }
//            }
//        }
//    }
//}
//
//
//// MARK: - Carousel Section (ВАШ ОРИГИНАЛЬНЫЙ КОД - БЕЗ ИЗМЕНЕНИЙ)
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader (ВАШ ОРИГИНАЛЬНЫЙ КОД - БЕЗ ИЗМЕНЕНИЙ)
//
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    // MARK: - Footer
//    
//    @ViewBuilder
//    var footerView: some View {
//        switch data.footerState {
//        case .idle:
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            .onAppear {
//                print("footerView case .loading")
//            }
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View (ВЫНЕСЕНА ОТДЕЛЬНО)
//
//
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    // Тестовый массив с именами исполнителей
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott",
//        "21 Savage"
//    ]
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            // ЛЕВАЯ ЧАСТЬ: Квадратная картинка (увеличили до 100x100)
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 100, height: 100),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 10))
//            
//            // ПРАВАЯ ЧАСТЬ: Текстовая информация
//            VStack(alignment: .leading, spacing: 8) {
//                // 1. Заголовок TOP 10
//                Text("TOP 10")
//                    .font(.headline) // Чуть крупнее
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary)
//                
//                // 2. Список исполнителей
//                VStack(alignment: .leading, spacing: 4) {
//                    // Добавили .prefix(5), чтобы немного удлинить список
//                    ForEach(artists.prefix(5), id: \.self) { artist in
//                        Text(artist)
//                            .font(.subheadline) // Сделали шрифт чуть крупнее
//                            .foregroundColor(AppColors.secondary)
//                            .lineLimit(1)
//                    }
//                }
//            }
//            Spacer() // Прижимаем контент влево
//        }
//        // Фон карточки и размеры
//        .padding(16) // Увеличили внутренние отступы
//        .frame(height: 132) // Фиксируем высоту (100px картинка + 2 отступа по 16px = 132)
//        .background(AppColors.secondarySystemBackground)
//        .cornerRadius(16) // Увеличили радиус скругления углов
//        // Тень стала чуть заметнее для "парящего" эффекта
//        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
//    }
//}





//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(alignment: .leading, spacing: 24) {
//
//            // 1. Главный заголовок
//            Text(data.topSection.title)
//                .font(.headline)
//                .padding(.horizontal)
//
//            // 2. Карусель с карточками (Чистый код благодаря TopSectionItemView)
//            VStack(alignment: .leading, spacing: 8) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}

//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    // Тестовый массив с именами исполнителей
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott",
//        "21 Savage"
//    ]
//    
//    var body: some View {
//        HStack(spacing: 16) {
//            
//            // ЛЕВАЯ ЧАСТЬ: Квадратная картинка
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 80, height: 80), // Квадрат 80x80 для простого макета
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 8)) // Аккуратные скругления
//            
//            // ПРАВАЯ ЧАСТЬ: Текстовая информация
//            VStack(alignment: .leading, spacing: 6) {
//                
//                // 1. Заголовок TOP 10
//                Text("TOP 10")
//                    .font(.subheadline)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppColors.primary) // Основной цвет (Черный/Белый)
//                
//                // 2. Список исполнителей
//                VStack(alignment: .leading, spacing: 2) {
//                    ForEach(artists.prefix(4), id: \.self) { artist in // Показываем только первых 4
//                        Text(artist)
//                            .font(.footnote)
//                            .foregroundColor(AppColors.secondary) // Второстепенный (Серый)
//                            .lineLimit(1)
//                    }
//                }
//            }
//            
//            Spacer() // Прижимаем контент влево
//        }
//        // Фон карточки
//        .padding(12)
//        .background(AppColors.secondarySystemBackground)
//        // Создаем красивый объем с помощью тени (чтобы отделить от основного фона)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
//    }
//}




// image прижат к краям карточки и примерно на половину карточки

//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    // Тестовый массив с именами исполнителей
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott",
//        "21 Savage"
//    ]
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            // ЛЕВАЯ ЧАСТЬ: Изображение
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 160, height: 160),
//                context: "TopSectionCard_\(item.id)"
//            )
//            // Скрываем правый угол картинки
//            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//            .mask(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .padding(.trailing, -100)
//            )
//            
//            // ПРАВАЯ ЧАСТЬ: Эффект стекла (Glassmorphism)
//            ZStack(alignment: .topLeading) {
//                // 1. Слой с размытием (адаптируется под тему)
//                Rectangle()
//                    .fill(.ultraThinMaterial) // Используем системный материал
//                    // Добавляем очень легкую черную подложку, чтобы в светлой теме размытие было чуть глубже
//                    .overlay(
//                        Color.black.opacity(0.05)
//                    )
//                    // Тень для создания объема и границы
//                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 2, y: 2)
//                
//                // 2. Контент поверх стекла
//                VStack(alignment: .leading, spacing: 8) {
//                    // Заголовок TOP 10
//                    Text("TOP 10")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(AppColors.primary)
//                        .padding(.top, 16)
//                        .padding(.leading, 16)
//                    
//                    // Список исполнителей
//                    VStack(alignment: .leading, spacing: 6) {
//                        ForEach(artists, id: \.self) { artist in
//                            Text(artist)
//                                .font(.subheadline)
//                                .foregroundColor(AppColors.secondary)
//                                .lineLimit(1)
//                        }
//                    }
//                    .padding(.leading, 16)
//                    // Эффект "уходящего за горизонт"
//                    .mask(
//                        VStack(spacing: 0) {
//                            Color.white
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.white, Color.clear]),
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                            .frame(height: 50)
//                        }
//                    )
//                }
//            }
//            // Правый скругленный угол
//            .clipShape(
//                .rect(
//                    topLeadingRadius: 0,
//                    bottomLeadingRadius: 0,
//                    bottomTrailingRadius: 12,
//                    topTrailingRadius: 12
//                )
//            )
//        }
//        .frame(width: 320, height: 160)
//        // Создаем контур для всей карточки (чтобы границы между картинкой и стеклом были четкими)
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}











//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    // Тестовый массив с именами исполнителей
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott",
//        "21 Savage"
//    ]
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            // ЛЕВАЯ ЧАСТЬ: Изображение
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 160, height: 160),
//                context: "TopSectionCard_\(item.id)"
//            )
//            // Скрываем правый угол картинки
//            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//            .mask(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .padding(.trailing, -100)
//            )
//            
//            // ПРАВАЯ ЧАСТЬ: Контрастный фон + Текст
//            ZStack(alignment: .topLeading) {
//                // ИСПОЛЬЗУЕМ AppColors.secondarySystemBackground.
//                // Это даст светло-серый фон в светлой теме и темно-серый в темной.
//                // Карточка всегда будет выделяться на фоне AppColors.background!
//                AppColors.secondarySystemBackground
//                    // Добавляем легкую тень, чтобы выделить границу справа и снизу
//                    .shadow(color: Color.black.opacity(0.06), radius: 6, x: 2, y: 2)
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    // 1. Заголовок TOP 10
//                    Text("TOP 10")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(AppColors.primary)
//                        .padding(.top, 16)
//                        .padding(.leading, 16)
//                    
//                    // 2. Список исполнителей
//                    VStack(alignment: .leading, spacing: 6) {
//                        ForEach(artists, id: \.self) { artist in
//                            Text(artist)
//                                .font(.subheadline)
//                                .foregroundColor(AppColors.secondary)
//                                .lineLimit(1)
//                        }
//                    }
//                    .padding(.leading, 16)
//                    // Эффект "уходящего за горизонт"
//                    .mask(
//                        VStack(spacing: 0) {
//                            Color.white // Верхняя часть полностью видима
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.white, Color.clear]),
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                            .frame(height: 50) // Увеличил высоту градиента для более плавного исчезновения
//                        }
//                    )
//                }
//            }
//            // Правый скругленный угол
//            .clipShape(
//                .rect(
//                    topLeadingRadius: 0,
//                    bottomLeadingRadius: 0,
//                    bottomTrailingRadius: 12,
//                    topTrailingRadius: 12
//                )
//            )
//        }
//        // Общая ширина карточки
//        .frame(width: 320, height: 160)
//        // Добавляем небольшую общую тень вокруг всей карточки, чтобы она "парила"
//        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
//        // Общее скругление всей карточки
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}


//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    // Тестовый массив с именами исполнителей (в будущем придет из модели)
//    let artists: [String] = [
//        "French Montana",
//        "Kodak Black",
//        "Lil Wayne",
//        "Drake",
//        "Future",
//        "Travis Scott",
//        "21 Savage"
//    ]
//    
//    var body: some View {
//        HStack(spacing: 0) {
//            // ЛЕВАЯ ЧАСТЬ: Изображение
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 160, height: 160),
//                context: "TopSectionCard_\(item.id)"
//            )
//            // Скрываем правый угол картинки
//            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
//            .mask(
//                RoundedRectangle(cornerRadius: 12, style: .continuous)
//                    .padding(.trailing, -100)
//            )
//            
//            // ПРАВАЯ ЧАСТЬ: Адаптивный фон + Текст
//            ZStack(alignment: .topLeading) {
//                // Используем AppColors.background. В светлой теме - белый, в темной - черный.
//                // Добавляем легкую тень, чтобы выделить карточку в светлой теме.
//                AppColors.background
//                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
//                
//                VStack(alignment: .leading, spacing: 8) {
//                    // 1. Заголовок TOP 10 (Системный цвет текста - адаптируется сам)
//                    Text("TOP 10")
//                        .font(.headline)
//                        .fontWeight(.bold)
//                        .foregroundColor(AppColors.primary) // Адаптивный черный/белый
//                        .padding(.top, 16)
//                        .padding(.leading, 16)
//                    
//                    // 2. Список исполнителей (Второстепенный цвет)
//                    VStack(alignment: .leading, spacing: 6) {
//                        ForEach(artists, id: \.self) { artist in
//                            Text(artist)
//                                .font(.subheadline)
//                                .foregroundColor(AppColors.secondary) // Мягкий серый в светлой, мягкий белый в темной
//                                .lineLimit(1)
//                        }
//                    }
//                    .padding(.leading, 16)
//                    // Эффект "уходящего за горизонт"
//                    .mask(
//                        VStack(spacing: 0) {
//                            Color.white // Полная видимость вверху
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.white, Color.clear]),
//                                startPoint: .top,
//                                endPoint: .bottom
//                            )
//                            .frame(height: 40) // Плавное исчезновение внизу
//                        }
//                    )
//                }
//            }
//            // Правый скругленный угол
//            .clipShape(
//                .rect(
//                    topLeadingRadius: 0,
//                    bottomLeadingRadius: 0,
//                    bottomTrailingRadius: 12,
//                    topTrailingRadius: 12
//                )
//            )
//        }
//        // Общая ширина карточки 320
//        .frame(width: 320, height: 160)
//        // Общее скругление всей карточки
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}


//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        ZStack(alignment: .bottomLeading) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 320, height: 160),
//                context: "TopSectionCard_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            Text(item.title)
//                .font(.subheadline)
//                .fontWeight(.bold)
//                .foregroundColor(.white)
//                .padding(.horizontal, 12)
//                .padding(.vertical, 6)
//                .background(Color.black.opacity(0.4))
//                .cornerRadius(4)
//                .padding([.leading, .bottom], 12)
//        }
//    }
//}


// MARK: - before Deepseek -







//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//    }
//}
//
//// MARK: - Top Sections
//
//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(spacing: 12) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(data.topSection.title)
//                    .font(.headline)
//                    .padding(.horizontal)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 20) {   // ← spacing как в TL23
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                                .frame(width: UIScreen.main.bounds.width * 0.85) // ← ключевой момент
//                        }
//                    }
//                    .padding(.leading, 16)   // ← первая карточка начинается ровно от края
//                    .padding(.trailing, 8)   // ← вторая карточка выглядывает краем
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader
//
//private extension DroplistCompositView {
//    
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                
//                // footer показываем только если есть что догружать
//                if data.initialLowerSection.hasMore {
//                    footerView
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    // MARK: - Footer
//    
//    @ViewBuilder
//    var footerView: some View {
//        
//        switch data.footerState {
//            
//        case .idle:
//            
//            // idle: footer виден, но не показывает загрузку.
//            // onAppear → триггер первой подгрузки.
//            HStack {
//                Spacer()
//                Color.clear
//                    .frame(height: 44)
//                    .onAppear {
//                        print("footerView case .idle")
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            
//        case .loading:
//            HStack {
//                Spacer()
//                ProgressView()
//                Spacer()
//            }
//            .padding(.vertical, 12)
//            .onAppear {
//                print("footerView case .loading")
//            }
//            
//        case .error(let message):
//            HStack {
//                Spacer()
//                VStack(spacing: 6) {
//                    Text(message)
//                        .foregroundColor(.secondary)
//                    Button("Повторить") {
//                        if let selected = selectedCarouselItem {
//                            onLoadNextPage(selected)
//                        }
//                    }
//                }
//                Spacer()
//            }
//            .padding(.vertical, 12)
//        }
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .lineLimit(2)
//                    }
//                }
//                
//                Spacer()
//            }
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        let url = item.isTrack ? item.thumbnailURL : item.coverImageURL
//        
//        WebImageView(
//            url: url,
//            placeholderColor: AppColors.secondarySystemBackground,
//            displayStyle: .fixedFrame(width: 60, height: 60),
//            context: "LowerItemThumbnail_\(item.id)"
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//    }
//}
//
//// MARK: - Top Section Item View
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        GeometryReader { geo in
//            let cardWidth = geo.size.width * 0.85        // ← ключевой момент
//            let cardHeight = cardWidth * 0.72            // ← пропорция TL23
//            
//            VStack(alignment: .leading, spacing: 10) {
//                
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(width: cardWidth, height: cardHeight),
//                    context: "TopSectionItemView_\(item.id)"
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 18)) // как TL23
//                
//                Text(item.title)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .lineLimit(1)
//                    .padding(.horizontal, 4)
//            }
//            .frame(width: cardWidth, alignment: .leading)
//        }
//        .frame(height: 260) // высота контейнера
//    }
//}




//    var topSections: some View {
//        VStack(spacing: 12) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(data.topSection.title)
//                    .font(.headline)
//                    .padding(.horizontal)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }


//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 160, height: 120),
//                context: "TopSectionItemView_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 14))
//            
//            Text(item.title)
//                .font(.subheadline.weight(.medium))
//                .foregroundColor(.primary)
//                .lineLimit(1)
//                .padding(.horizontal, 2)
//        }
//        .frame(width: 160, alignment: .leading)
//    }
//}

//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            WebImageView(
//                url: item.imageURL,
//                placeholderColor: AppColors.secondarySystemBackground,
//                displayStyle: .fixedFrame(width: 140, height: 90),
//                context: "TopSectionItemView_\(item.id)"
//            )
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//                .lineLimit(1)
//        }
//        .frame(width: 140, alignment: .leading)
//    }
//}






// MARK: - before WebImageView



//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        if item.isTrack {
//            AsyncImage(url: item.thumbnailURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//        } else {
//            AsyncImage(url: item.coverImageURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//        }
//    }


//struct TopSectionItemView: View {
//    let item: TopItem
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            AsyncImage(url: item.imageURL) { img in
//                img.resizable()
//                    .scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 140, height: 90)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//                .lineLimit(1)
//        }
//        .frame(width: 140, alignment: .leading)
//    }
//}







// MARK: - implemintation before FooterState

//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(spacing: 16) {
//                    topSections
//                    carouselSection
//                    lowerSectionWithFooter()
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//    }
//}
//
//// MARK: - Top Sections
//

//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(spacing: 12) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(data.topSection.title)
//                    .font(.headline)
//                    .padding(.horizontal)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section + Footer Loader
//
//private extension DroplistCompositView {
//    
//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.isLowerSectionLoading {
//            VStack {
//                ProgressView()
//                Text("Загрузка...")
//                    .foregroundColor(.secondary)
//            }
//            .frame(maxWidth: .infinity, minHeight: 200)
//        }
//        else if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        }
//        else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                // так как это LazyVStack мы footerLoader запускае когда к ниму приближаемся?
//                if data.initialLowerSection.hasMore {
//                    footerLoader
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//    
//    var footerLoader: some View {
//        HStack {
//            Spacer()
//            ProgressView()
//                .onAppear {
//                    print("onAppear footerLoader")
//                    if let selected = selectedCarouselItem {
//                        onLoadNextPage(selected)
//                    }
//                }
//                .onDisappear {
//                    print("onDisappear footerLoader")
//                }
//            Spacer()
//        }
//        .padding(.vertical, 12)
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//                Spacer()
//            }
//        }
//    }
//    
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        if item.isTrack {
//            AsyncImage(url: item.thumbnailURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//        } else {
//            AsyncImage(url: item.coverImageURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//        }
//    }
//}
//
//// MARK: - Top Section Item View
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            AsyncImage(url: item.imageURL) { img in
//                img.resizable()
//                    .scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 140, height: 90)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//                .lineLimit(1)
//        }
//        .frame(width: 140, alignment: .leading)
//    }
//}




//    @ViewBuilder
//    func lowerSectionWithFooter() -> some View {
//        if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        } else {
//            LazyVStack(spacing: 16) {
//                ForEach(data.initialLowerSection.items) { item in
//                    lowerItemCell(item)
//                }
//                if data.initialLowerSection.hasMore  {
//                    footerLoader
//                }
//            }
//            .padding(.horizontal)
//        }
//    }


// MARK: - before footer‑loader


//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(spacing: 16) {
//                    
//                    topSections
//                    carouselSection
//                    lowerSectionOrError()   // ВАЖНО: теперь это функция, а не var
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                selectedCarouselItem = data.selectedItem
//            }
//        }
//    }
//}
//
//// MARK: - Top Sections
//
//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(spacing: 12) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(data.topSection.title)
//                    .font(.headline)
//                    .padding(.horizontal)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Carousel Section
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section (Error or List)
//
//private extension DroplistCompositView {
//    
//    /// ВАЖНО: используем @ViewBuilder, чтобы избежать ошибки some View mismatch
//    @ViewBuilder
//    func lowerSectionOrError() -> some View {
//        if data.initialLowerSection.items.isEmpty {
//            lowerSectionErrorPlaceholder
//        } else {
//            lowerSection
//        }
//    }
//    
//    var lowerSectionErrorPlaceholder: some View {
//        VStack(spacing: 12) {
//            Text("Не удалось загрузить данные")
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Button("Повторить") {
//                if let selected = selectedCarouselItem {
//                    onSelectCarouselItem(selected)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .background(Color.blue.opacity(0.2))
//            .cornerRadius(8)
//        }
//        .padding(.top, 40)
//    }
//}
//
//// MARK: - Lower Section (List)
//
//private extension DroplistCompositView {
//    
//    var lowerSection: some View {
//        LazyVStack(spacing: 16) {
//            ForEach(data.initialLowerSection.items) { item in
//                lowerItemCell(item)
//                    .onAppear {
//                        triggerPaginationIfNeeded(item)
//                    }
//            }
//        }
//        .padding(.horizontal)
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                
//                thumbnail(for: item)
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//                Spacer()
//            }
//        }
//    }
//    
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        if item.isTrack {
//            AsyncImage(url: item.thumbnailURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//            
//        } else {
//            AsyncImage(url: item.coverImageURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//        }
//    }
//    
//    /// Проверяет, нужно ли загрузить следующую страницу.
//    /// Метод вызывается при появлении каждой ячейки.
//    /// Если пользователь долистал до последних 5 элементов текущей страницы,
//    /// триггерит пагинацию через onLoadNextPage(selectedCarouselItem).
//    func triggerPaginationIfNeeded(_ item: LowerItem) {
//        guard let selected = selectedCarouselItem else { return }
//        
//        let thresholdIndex = data.initialLowerSection.items.count - 5
//        
//        if let index = data.initialLowerSection.items.firstIndex(where: { $0.id == item.id }),
//           index >= thresholdIndex {
//            print(" func triggerPaginationIfNeeded index: \(index) + thresholdIndex: \(thresholdIndex)")
//            onLoadNextPage(selected)
//        }
//    }
//}
//
//// MARK: - Top Section Item View
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            
//            AsyncImage(url: item.imageURL) { img in
//                img.resizable()
//                    .scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 140, height: 90)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//                .lineLimit(1)
//        }
//        .frame(width: 140, alignment: .leading)
//    }
//}






// MARK: - before lowerSectionErrorPlaceholder



//import SwiftUI
//
//struct DroplistCompositView: View {
//    
//    let data: DropData
//    let onRefresh: () -> Void
//    let onSelectCarouselItem: (CarouselItem) -> Void
//    let onLoadNextPage: (CarouselItem) -> Void
//    let onSelectLowerItem: (LowerItem) -> Void
//    
//    @State private var selectedCarouselItem: CarouselItem?
//    
//    var body: some View {
//        ScrollViewReader { proxy in
//            ScrollView {
//                VStack(spacing: 16) {
//                    
//                    // MARK: - Top Sections
//                    topSections
//                    
//                    // MARK: - Carousel
//                    carouselSection
//                    
//                    // MARK: - Lower Section (Vertical List)
//                    lowerSection
//                }
//                .padding(.vertical, 12)
//            }
//            .refreshable {
//                onRefresh()
//            }
//            .onAppear {
//                if selectedCarouselItem == nil {
//                    selectedCarouselItem = data.carouselItems.first
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Top Sections
//
//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(spacing: 12) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text(data.topSection.title)
//                    .font(.headline)
//                    .padding(.horizontal)
//
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(data.topSection.items) { item in
//                            TopSectionItemView(item: item)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//            }
//        }
//    }
//}
//
//
//// MARK: - Carousel Section
//
//private extension DroplistCompositView {
//    var carouselSection: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 12) {
//                ForEach(data.carouselItems) { item in
//                    carouselItem(item)
//                }
//            }
//            .padding(.horizontal)
//        }
//    }
//    
//    func carouselItem(_ item: CarouselItem) -> some View {
//        let isSelected = selectedCarouselItem?.id == item.id
//        
//        return Text(item.title)
//            .font(.subheadline.weight(.medium))
//            .padding(.horizontal, 14)
//            .padding(.vertical, 8)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
//            )
//            .onTapGesture {
//                guard selectedCarouselItem?.id != item.id else { return }
//                selectedCarouselItem = item
//                onSelectCarouselItem(item)
//            }
//    }
//}
//
//// MARK: - Lower Section (Vertical List)
//
//private extension DroplistCompositView {
//    var lowerSection: some View {
//        LazyVStack(spacing: 16) {
//            ForEach(data.initialLowerSection.items) { item in
//                lowerItemCell(item)
//                    .onAppear {
//                        triggerPaginationIfNeeded(item)
//                    }
//            }
//        }
//        .padding(.horizontal)
//    }
//    
//    func lowerItemCell(_ item: LowerItem) -> some View {
//        Button {
//            onSelectLowerItem(item)
//        } label: {
//            HStack(spacing: 12) {
//                
//                // MARK: - Thumbnail / Cover
//                thumbnail(for: item)
//                
//                // MARK: - Texts
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    
//                    if let subtitle = item.subtitle {
//                        Text(subtitle)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                    }
//                }
//                
//                Spacer()
//            }
//        }
//    }
//    
//    @ViewBuilder
//    func thumbnail(for item: LowerItem) -> some View {
//        if item.isTrack {
//            // Single thumbnail
//            AsyncImage(url: item.thumbnailURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//            
//        } else {
//            // Playlist cover
//            AsyncImage(url: item.coverImageURL) { img in
//                img.resizable().scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 60, height: 60)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//        }
//    }
//    
//    /// Проверяет, нужно ли загрузить следующую страницу.
//    /// Метод вызывается при появлении каждой ячейки.
//    /// Если пользователь долистал до последних 5 элементов текущей страницы,
//    /// триггерит пагинацию через onLoadNextPage(selectedCarouselItem).
//    func triggerPaginationIfNeeded(_ item: LowerItem) {
//        guard let selected = selectedCarouselItem else { return }
//        
//        let thresholdIndex = data.initialLowerSection.items.count - 5
//        
//        if let index = data.initialLowerSection.items.firstIndex(where: { $0.id == item.id }),
//           index >= thresholdIndex {
//            onLoadNextPage(selected)
//        }
//    }
//}
//
//
//
//
//import SwiftUI
//
//struct TopSectionItemView: View {
//    let item: TopItem
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            
//            // MARK: - Image
//            AsyncImage(url: item.imageURL) { img in
//                img.resizable()
//                    .scaledToFill()
//            } placeholder: {
//                Color.gray.opacity(0.2)
//            }
//            .frame(width: 140, height: 90)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            // MARK: - Title
//            Text(item.title)
//                .font(.subheadline)
//                .foregroundColor(.primary)
//                .lineLimit(1)
//        }
//        .frame(width: 140, alignment: .leading)
//    }
//}




//private extension DroplistCompositView {
//    var topSections: some View {
//        VStack(spacing: 12) {
//            ForEach(data.topSections) { section in
//                VStack(alignment: .leading, spacing: 8) {
//                    Text(section.title)
//                        .font(.headline)
//                        .padding(.horizontal)
//
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 12) {
//                            ForEach(section.items) { item in
//                                TopSectionItemView(item: item)
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                }
//            }
//        }
//    }
//}
