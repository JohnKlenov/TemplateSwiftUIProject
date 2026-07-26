//
//  DroplistCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.05.26.
//



// MARK: - Внешняя локализация title (строк) (на стороне Firebase как в BookStores)

import SwiftUI

struct DroplistCompositView: View {
    
    let data: DropData
    let onRefresh: () -> Void
    let onSelectCarouselItem: (CarouselItem) -> Void
    let onLoadNextPage: (CarouselItem) -> Void
    let onSelectLowerItem: (LowerItem) -> Void
    
    @State private var selectedCarouselItem: CarouselItem?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                topSections
                carouselSection
                lowerSectionWithFooter()
            }
            .padding(.vertical, 12)
        }
        .refreshable {
            onRefresh()
        }
        .onAppear {
            selectedCarouselItem = data.selectedItem
        }
    }
}

// MARK: - Top Sections

private extension DroplistCompositView {
    var topSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            
            // 1. Главный заголовок
            Text(data.topSection.title)
                .font(.headline)
                .padding(.horizontal)
            
            // 2. Карусель с карточками (Чистый код благодаря TopSectionItemView)
            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(data.topSection.items) { item in
                            TopSectionItemView(item: item)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Carousel Section (ВАШ ОРИГИНАЛЬНЫЙ КОД - БЕЗ ИЗМЕНЕНИЙ)

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
    
    func carouselItem(_ item: CarouselItem) -> some View {
        let isSelected = selectedCarouselItem?.id == item.id
        
        return Text(item.title)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
            )
            .onTapGesture {
                guard selectedCarouselItem?.id != item.id else { return }
                selectedCarouselItem = item
                onSelectCarouselItem(item)
            }
    }
}

// MARK: - Lower Section + Footer Loader (ВАШ ОРИГИНАЛЬНЫЙ КОД - БЕЗ ИЗМЕНЕНИЙ)

private extension DroplistCompositView {
    
    @ViewBuilder
    func lowerSectionWithFooter() -> some View {
        if data.isLowerSectionLoading {
            VStack {
                ProgressView()
                Text("Загрузка...")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
        }
        else if data.initialLowerSection.items.isEmpty {
            lowerSectionErrorPlaceholder
        }
        else {
            LazyVStack(spacing: 16) {
                ForEach(data.initialLowerSection.items) { item in
                    lowerItemCell(item)
                }
                
                if data.initialLowerSection.hasMore {
                    footerView
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Footer
    
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
            .onAppear {
                print("footerView case .loading")
            }
            
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

// MARK: - Top Section Item View (ВЫНЕСЕНА ОТДЕЛЬНО)


struct TopSectionItemView: View {
    let item: TopItem
    
    // Тестовый массив с именами исполнителей
    let artists: [String] = [
        "French Montana",
        "Kodak Black",
        "Lil Wayne",
        "Drake",
        "Future",
        "Travis Scott",
        "21 Savage"
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // ЛЕВАЯ ЧАСТЬ: Изображение
            WebImageView(
                url: item.imageURL,
                placeholderColor: AppColors.secondarySystemBackground,
                displayStyle: .fixedFrame(width: 160, height: 160),
                context: "TopSectionCard_\(item.id)"
            )
            // Скрываем правый угол картинки
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .mask(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .padding(.trailing, -100)
            )
            
            // ПРАВАЯ ЧАСТЬ: Эффект стекла (Glassmorphism)
            ZStack(alignment: .topLeading) {
                // 1. Слой с размытием (адаптируется под тему)
                Rectangle()
                    .fill(.ultraThinMaterial) // Используем системный материал
                    // Добавляем очень легкую черную подложку, чтобы в светлой теме размытие было чуть глубже
                    .overlay(
                        Color.black.opacity(0.05)
                    )
                    // Тень для создания объема и границы
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 2, y: 2)
                
                // 2. Контент поверх стекла
                VStack(alignment: .leading, spacing: 8) {
                    // Заголовок TOP 10
                    Text("TOP 10")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.primary)
                        .padding(.top, 16)
                        .padding(.leading, 16)
                    
                    // Список исполнителей
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(artists, id: \.self) { artist in
                            Text(artist)
                                .font(.subheadline)
                                .foregroundColor(AppColors.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.leading, 16)
                    // Эффект "уходящего за горизонт"
                    .mask(
                        VStack(spacing: 0) {
                            Color.white
                            LinearGradient(
                                gradient: Gradient(colors: [Color.white, Color.clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 50)
                        }
                    )
                }
            }
            // Правый скругленный угол
            .clipShape(
                .rect(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12
                )
            )
        }
        .frame(width: 320, height: 160)
        // Создаем контур для всей карточки (чтобы границы между картинкой и стеклом были четкими)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
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
