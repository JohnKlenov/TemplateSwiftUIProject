//
//  DroplistCompositView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 14.05.26.
//

import SwiftUI

struct DroplistCompositView: View {
    
    let data: DropData
    let onRefresh: () -> Void
    let onSelectCarouselItem: (CarouselItem) -> Void
    let onLoadNextPage: (CarouselItem) -> Void
    let onSelectLowerItem: (LowerItem) -> Void
    
    @State private var selectedCarouselItem: CarouselItem?
    
    var body: some View {
        ScrollViewReader { proxy in
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
}

// MARK: - Top Sections

private extension DroplistCompositView {
    var topSections: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(data.topSection.title)
                    .font(.headline)
                    .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
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

// MARK: - Carousel Section

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

// MARK: - Lower Section + Footer Loader

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
                    footerLoader
                }
            }
            .padding(.horizontal)
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
    
    var footerLoader: some View {
        HStack {
            Spacer()
            ProgressView()
                .onAppear {
                    print("onAppear footerLoader")
                    if let selected = selectedCarouselItem {
                        onLoadNextPage(selected)
                    }
                }
                .onDisappear {
                    print("onDisappear footerLoader")
                }
            Spacer()
        }
        .padding(.vertical, 12)
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
                    }
                }
                
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    func thumbnail(for item: LowerItem) -> some View {
        if item.isTrack {
            AsyncImage(url: item.thumbnailURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            AsyncImage(url: item.coverImageURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Top Section Item View

struct TopSectionItemView: View {
    let item: TopItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: item.imageURL) { img in
                img.resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 140, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Text(item.title)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(width: 140, alignment: .leading)
    }
}




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
