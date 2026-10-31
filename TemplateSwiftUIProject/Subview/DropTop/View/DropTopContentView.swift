//
//  DropTopContentView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//

//Внесём изменения так, чтобы DropTopContentView сохранял собственную позицию прокрутки для каждого DropTopTag на iOS 17+.


// =================================================
// MARK: - Scroll Position
// =================================================

// Текущий ID элемента, используемый SwiftUI для отслеживания
// позиции прокрутки через .scrollPosition(id:anchor:).
// Значение обновляется автоматически при прокрутке списка.

//@State private var currentScrollID: String?

// Последняя сохранённая позиция для каждого тега.
// При переключении сохраняем ID предыдущего списка,
// чтобы при возвращении восстановить прежнюю позицию.

//@State private var savedScrollPositions: [
//    DropTopTag: String
//] = [:]

// =================================================
// MARK: - Scroll Position Tracking
// =================================================

// При смене выбранного тега сохраняем позицию предыдущего
// списка и сбрасываем текущую привязку перед показом нового.
// Сам currentScrollID обновляется автоматически через SwiftUI.

//.onChange(of: viewModel.selectedTag) { oldTag, _ in
//    saveScrollPosition(for: oldTag)
//    currentScrollID = nil
//}

// Ждём, пока ViewModel сообщит, какой тег фактически загружен.
// Если он совпадает с выбранным, восстанавливаем его позицию.
// Это не позволяет применять позицию другой вкладки.

//.onChange(of: viewModel.displayedTag) { _, newTag in
//    guard let tag = newTag else {
//        return
//    }
//
//    guard tag == viewModel.selectedTag else {
//        return
//    }
//
//    restoreScrollPosition(for: tag)
//}

// =================================================
// MARK: - Scroll Position Binding
// =================================================

// SwiftUI автоматически обновляет currentScrollID при прокрутке.
// При восстановлении сохранённого ID SwiftUI позиционирует список
// относительно соответствующего элемента.
// .scrollTargetLayout() позволяет использовать элементы LazyVStack
// в качестве целей прокрутки.

//.scrollPosition(
//    id: $currentScrollID,
//    anchor: .top
//)


// =================================================
// MARK: - Ошибка загрузки отдельного тега
// =================================================

/*
 ЛОГИКА .tagError И retrySelectedTag()

 1. Когда пользователь выбирает другой тег, ViewModel
    сначала пытается получить его страницу из кэша.

 2. Если кэша нет, выполняется запрос к Firestore.
    На время загрузки состояние становится .loading.

 3. Если запрос завершается ошибкой, ViewModel
    устанавливает состояние .tagError(tag:message:).

    В отличие от .error, это состояние не означает
    критическую ошибку всего экрана. Оно используется
    при неудачной загрузке конкретного тега.

 4. DropTopContentView обрабатывает .tagError отдельно:
    - селектор тегов остаётся доступным;
    - вместо списка отображается сообщение об ошибке;
    - пользователь может повторить загрузку кнопкой Retry.

 5. Кнопка Retry вызывает retrySelectedTag().
    Метод:
    - инвалидирует предыдущий запрос через новый UUID,
      чтобы устаревший результат не изменил состояние;
    - отменяет текущую задачу пагинации и сбрасывает
      её ссылку;
    - очищает ошибку пагинации;
    - повторно загружает выбранный тег с useCache: false.

 6. useCache: false означает, что для повторной попытки
    не используется кэшированная страница: выполняется
    новый запрос к Firestore.

 7. Если запрос успешен, ViewModel устанавливает
    .contentList с полученной страницей и обновляет
    displayedTag. Представление снова показывает список.

 8. Если запрос снова завершается ошибкой, ViewModel
    повторно устанавливает .tagError с сообщением
    об ошибке. Пользователь может попробовать ещё раз.

 ВАЖНО:
 Повторная попытка не сбрасывает кэш всех тегов.
 Загрузка и обновление страницы выполняются для
 выбранного тега через DropListDataSource.

 Поэтому ошибка одного тега не должна приводить
 к очистке данных других тегов или к переходу
 всего экрана в полноэкранное состояние ошибки.
*/




import SwiftUI

struct DropTopContentView: View {

    @ObservedObject var viewModel: DropTopViewModel

    @EnvironmentObject var droplistCoordinator: DroplistCoordinator

    // =================================================
    // MARK: - Scroll Position
    // =================================================

    // SwiftUI автоматически обновляет ID при прокрутке.
    @State private var currentScrollID: String?

    // Сохраняем отдельную позицию для каждого тега.
    @State private var savedScrollPositions: [DropTopTag: String] = [:]

    // =================================================
    // MARK: - Body
    // =================================================

    var body: some View {
        VStack(spacing: 0) {
            tagSelector

            Divider()

            content
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
        }
        .background(AppColors.background)
        .navigationTitle("DropTop")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            Task {
                await viewModel.setupViewModel()
            }
        }
        .onChange(of: viewModel.selectedTag) { oldTag, _ in
            saveScrollPosition(for: oldTag)
            currentScrollID = nil
        }
        .onChange(of: viewModel.displayedTag) { _, newTag in
            guard let tag = newTag else {
                return
            }

            guard tag == viewModel.selectedTag else {
                return
            }

            restoreScrollPosition(for: tag)
        }
    }
}

// =================================================
// MARK: - TAG SELECTOR
// =================================================

private extension DropTopContentView {

    var tagSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DropTopTag.allCases) { tag in
                    Button {
                        Task {
                            await viewModel.selectTag(tag)
                        }
                    } label: {
                        Text(tag.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(
                                viewModel.selectedTag == tag
                                    ? .white
                                    : .primary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                Capsule()
                                    .fill(
                                        viewModel.selectedTag == tag
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.12)
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}

// =================================================
// MARK: - CONTENT
// =================================================

private extension DropTopContentView {

    @ViewBuilder
    var content: some View {
        switch viewModel.viewState {

        case .loading:
            ProgressView()

        case .error(let error):
            ContentErrorView(error: error) {
                Task {
                    await viewModel.retry()
                }
            }

        case .contentList(let page):
            dropTopList(page)
        }
    }
}

// =================================================
// MARK: - LIST
// =================================================

private extension DropTopContentView {

    func dropTopList(
        _ page: DropTopPage
    ) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(page.items) { item in
                    dropTopRow(item)
                        .onAppear {
                            guard item.id == page.items.last?.id else {
                                return
                            }

                            viewModel.loadNextPage()
                        }
                }

                if page.hasMore {
                    paginationFooter
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(
            id: $currentScrollID,
            anchor: .top
        )
        .refreshable {
            await viewModel.retry()
        }
    }

    // -------------------------------------------------
    // Footer пагинации.
    // При ошибке показываем Retry вместо индикатора,
    // чтобы не провоцировать бесконечные запросы.
    // -------------------------------------------------

    @ViewBuilder
    var paginationFooter: some View {
        if viewModel.paginationError != nil {
            VStack(spacing: 8) {
                Text("Что-то пошло не так!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.loadNextPage()
                } label: {
                    Label(
                        "Загрузить ещё",
                        systemImage: "arrow.clockwise"
                    )
                    .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

        } else {
            ProgressView()
                .padding(.vertical, 20)
        }
    }
}

// =================================================
// MARK: - SCROLL POSITION
// =================================================

private extension DropTopContentView {

    func saveScrollPosition(
        for tag: DropTopTag
    ) {
        guard let currentScrollID else {
            return
        }

        savedScrollPositions[tag] = currentScrollID
    }

    func restoreScrollPosition(
        for tag: DropTopTag
    ) {
        guard case .contentList(let page) = viewModel.viewState else {
            return
        }

        guard
            let savedID = savedScrollPositions[tag],
            page.items.contains(where: { $0.id == savedID })
        else {
            // Нет сохранённой позиции или элемента в текущей странице.
            currentScrollID = nil
            return
        }

        // Ждём обновления списка перед восстановлением позиции.
        Task { @MainActor in
            await Task.yield()
            currentScrollID = savedID
        }
    }
}

// =================================================
// MARK: - ROW
// =================================================

private extension DropTopContentView {

    func dropTopRow(
        _ item: DropTopItem
    ) -> some View {
        Button {
            openPlaylist(item)
        } label: {
            HStack(spacing: 12) {
                WebImageView(
                    url: item.imageURL,
                    placeholderColor: AppColors.secondarySystemBackground,
                    displayStyle: .fixedFrame(
                        width: 60,
                        height: 60
                    ),
                    context: "DropTop_\(item.id)"
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(item.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// =================================================
// MARK: - NAVIGATION
// =================================================

private extension DropTopContentView {

    func openPlaylist(
        _ item: DropTopItem
    ) {
        // droplistCoordinator.navigate(
        //     to: .topDropDetails(
        //         playlistId: item.id,
        //         title: item.title,
        //         imageURL: item.imageURL
        //     )
        // )
    }
}















// no case tagError

//import SwiftUI
//
//struct DropTopContentView: View {
//    
//    @ObservedObject var viewModel: DropTopViewModel
//    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//
//    // =================================================
//    // MARK: - Scroll Position
//    // =================================================
//
//    // SwiftUI автоматически обновляет ID при прокрутке.
//    @State private var currentScrollID: String?
//
//    // Сохраняем отдельную позицию для каждого тега.
//    @State private var savedScrollPositions: [DropTopTag: String] = [:]
//
//    var body: some View {
//        VStack(spacing: 0) {
//            tagSelector
//
//            Divider()
//
//            content
//                .frame(
//                    maxWidth: .infinity,
//                    maxHeight: .infinity
//                )
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//        .onChange(of: viewModel.selectedTag) { oldTag, _ in
//            saveScrollPosition(for: oldTag)
//            currentScrollID = nil
//        }
//        .onChange(of: viewModel.displayedTag) { _, newTag in
//            guard let tag = newTag else {
//                return
//            }
//
//            guard tag == viewModel.selectedTag else {
//                return
//            }
//
//            restoreScrollPosition(for: tag)
//        }
//    }
//}
//
//// =================================================
//// MARK: - TAG SELECTOR
//// =================================================
//
//private extension DropTopContentView {
//
//    var tagSelector: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//                ForEach(DropTopTag.allCases) { tag in
//                    Button {
//                        Task {
//                            await viewModel.selectTag(tag)
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(.subheadline.weight(.medium))
//                            .foregroundColor(
//                                viewModel.selectedTag == tag
//                                    ? .white
//                                    : .primary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background {
//                                Capsule()
//                                    .fill(
//                                        viewModel.selectedTag == tag
//                                            ? Color.accentColor
//                                            : Color.secondary.opacity(0.12)
//                                    )
//                            }
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//        }
//    }
//}
//
//// =================================================
//// MARK: - CONTENT
//// =================================================
//
//private extension DropTopContentView {
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.viewState {
//
//        case .loading:
//            ProgressView()
//
//        case .error(let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//
//        case .tagError( _ , let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retrySelectedTag()
//                }
//            }
//        case .contentList(let page):
//            dropTopList(page)
//        }
//    }
//}
//
//// =================================================
//// MARK: - LIST
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopList(
//        _ page: DropTopPage
//    ) -> some View {
//        ScrollView {
//            LazyVStack(spacing: 0) {
//                ForEach(page.items) { item in
//                    dropTopRow(item)
//                        .onAppear {
//                            guard item.id == page.items.last?.id else {
//                                return
//                            }
//
//                            viewModel.loadNextPage()
//                        }
//                }
//
//                if page.hasMore {
//                    paginationFooter
//                }
//            }
//            .scrollTargetLayout()
//        }
//        .scrollPosition(
//            id: $currentScrollID,
//            anchor: .top
//        )
//        .refreshable {
//            await viewModel.retrySelectedTag()
//        }
//    }
//
//    // -------------------------------------------------
//    // Footer пагинации.
//    // При ошибке показываем Retry вместо индикатора,
//    // чтобы не провоцировать бесконечные запросы.
//    // -------------------------------------------------
//
//    @ViewBuilder
//    var paginationFooter: some View {
//        if let _ = viewModel.paginationError {
//            VStack(spacing: 8) {
//                Text("Что-то пошло не так!")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//
//                Button {
//                    viewModel.loadNextPage()
//                } label: {
//                    Label(
//                        "Загрузить ещё",
//                        systemImage: "arrow.clockwise"
//                    )
//                    .font(.subheadline.weight(.medium))
//                }
//                .buttonStyle(.plain)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 20)
//
//        } else {
//            ProgressView()
//                .padding(.vertical, 20)
//        }
//    }
//}
//
//// =================================================
//// MARK: - SCROLL POSITION
//// =================================================
//
//private extension DropTopContentView {
//
//    func saveScrollPosition(
//        for tag: DropTopTag
//    ) {
//        guard let currentScrollID else {
//            return
//        }
//
//        savedScrollPositions[tag] = currentScrollID
//    }
//
//    func restoreScrollPosition(
//        for tag: DropTopTag
//    ) {
//        guard case .contentList(let page) = viewModel.viewState else {
//            return
//        }
//
//        guard
//            let savedID = savedScrollPositions[tag],
//            page.items.contains(where: { $0.id == savedID })
//        else {
//            // Нет сохранённой позиции или элемента в текущей странице.
//            currentScrollID = nil
//            return
//        }
//
//        // Ждём обновления списка перед восстановлением позиции.
//        Task { @MainActor in
//            await Task.yield()
//            currentScrollID = savedID
//        }
//    }
//}
//
//// =================================================
//// MARK: - ROW
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//        Button {
//            openPlaylist(item)
//        } label: {
//            HStack(spacing: 12) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor: AppColors.secondarySystemBackground,
//                    displayStyle: .fixedFrame(
//                        width: 60,
//                        height: 60
//                    ),
//                    context: "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(cornerRadius: 8)
//                )
//
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                        .lineLimit(2)
//
//                    Text(item.description)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//            .contentShape(Rectangle())
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// =================================================
//// MARK: - NAVIGATION
//// =================================================
//
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
//        // droplistCoordinator.navigate(
//        //     to: .topDropDetails(
//        //         playlistId: item.id,
//        //         title: item.title,
//        //         imageURL: item.imageURL
//        //     )
//        // )
//    }
//}



// MARK: - before .tagError

//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//
//    // =================================================
//    // MARK: - Scroll Position
//    // =================================================
//
//    // ID элемента, к которому привязана текущая позиция скролла.
//    @State private var currentScrollID: String?
//
//    // Последняя позиция прокрутки для каждого тега.
//    @State private var savedScrollPositions: [
//        DropTopTag: String
//    ] = [:]
//
//    var body: some View {
//        VStack(spacing: 0) {
//            tagSelector
//
//            Divider()
//
//            content
//                .frame(
//                    maxWidth: .infinity,
//                    maxHeight: .infinity
//                )
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//        .onChange(of: viewModel.selectedTag) { oldTag, _ in
//            saveScrollPosition(for: oldTag)
//            currentScrollID = nil
//        }
//        .onChange(of: viewModel.displayedTag) { _, newTag in
//            guard let tag = newTag else {
//                return
//            }
//
//            guard tag == viewModel.selectedTag else {
//                return
//            }
//
//            restoreScrollPosition(for: tag)
//        }
//    }
//}
//
//// =================================================
//// MARK: - TAG SELECTOR
//// =================================================
//
//private extension DropTopContentView {
//
//    var tagSelector: some View {
//        ScrollView(
//            .horizontal,
//            showsIndicators: false
//        ) {
//            HStack(spacing: 8) {
//                ForEach(DropTopTag.allCases) { tag in
//                    Button {
//                        Task {
//                            await viewModel.selectTag(tag)
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(
//                                .subheadline.weight(.medium)
//                            )
//                            .foregroundColor(
//                                viewModel.selectedTag == tag
//                                    ? .white
//                                    : .primary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background {
//                                Capsule()
//                                    .fill(
//                                        viewModel.selectedTag == tag
//                                            ? Color.accentColor
//                                            : Color.secondary.opacity(0.12)
//                                    )
//                            }
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//        }
//    }
//}
//
//// =================================================
//// MARK: - CONTENT
//// =================================================
//
//private extension DropTopContentView {
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.viewState {
//
//        case .loading:
//            ProgressView()
//
//        case .error(let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//
//        case .contentList(let page):
//            dropTopList(page)
//        }
//    }
//}
//
//// =================================================
//// MARK: - LIST
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopList(
//        _ page: DropTopPage
//    ) -> some View {
//        ScrollView {
//            LazyVStack(spacing: 0) {
//                ForEach(page.items) { item in
//                    dropTopRow(item)
//                        .onAppear {
//                            guard item.id == page.items.last?.id else {
//                                return
//                            }
//
//                            viewModel.loadNextPage()
//                        }
//                }
//
//                if page.hasMore {
//                    ProgressView()
//                        .padding(.vertical, 20)
//                }
//            }
//            // Разрешаем SwiftUI использовать элементы
//            // списка как цели для восстановления позиции.
//            .scrollTargetLayout()
//        }
//        .scrollPosition(
//            id: $currentScrollID,
//            anchor: .top
//        )
//        .refreshable {
//            await viewModel.retry()
//        }
//    }
//}
//
//// =================================================
//// MARK: - SCROLL POSITION
//// =================================================
//
//private extension DropTopContentView {
//
//    func saveScrollPosition(
//        for tag: DropTopTag
//    ) {
//        guard let currentScrollID else {
//            return
//        }
//
//        savedScrollPositions[tag] = currentScrollID
//    }
//
//    func restoreScrollPosition(
//        for tag: DropTopTag
//    ) {
//        guard
//            case .contentList(let page) = viewModel.viewState
//        else {
//            return
//        }
//
//        guard
//            let savedID = savedScrollPositions[tag],
//            page.items.contains(where: { $0.id == savedID })
//        else {
//            // Если позиция ещё не сохранена или элемент
//            // отсутствует в загруженных данных — начинаем сверху.
//            currentScrollID = nil
//            return
//        }
//
//        // Дожидаемся обновления иерархии после смены списка,
//        // затем восстанавливаем позицию нужного тега.
//        Task { @MainActor in
//            await Task.yield()
//            currentScrollID = savedID
//        }
//    }
//}
//
//// =================================================
//// MARK: - ROW
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//        Button {
//            openPlaylist(item)
//        } label: {
//            HStack(spacing: 12) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor:
//                        AppColors.secondarySystemBackground,
//                    displayStyle:
//                        .fixedFrame(
//                            width: 60,
//                            height: 60
//                        ),
//                    context: "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                VStack(
//                    alignment: .leading,
//                    spacing: 4
//                ) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                        .lineLimit(2)
//
//                    Text(item.description)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// =================================================
//// MARK: - NAVIGATION
//// =================================================
//
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
//        // droplistCoordinator.navigate(
//        //     to: .topDropDetails(
//        //         playlistId: item.id,
//        //         title: item.title,
//        //         imageURL: item.imageURL
//        //     )
//        // )
//    }
//}
//








// MARK: - before savedScrollPositions

//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//
//    var body: some View {
//        VStack(spacing: 0) {
//            tagSelector
//
//            Divider()
//
//            content
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//    }
//}
//
//// =================================================
//// MARK: - TAG SELECTOR
//// =================================================
//
//private extension DropTopContentView {
//
//    var tagSelector: some View {
//        ScrollView(
//            .horizontal,
//            showsIndicators: false
//        ) {
//            HStack(spacing: 8) {
//                ForEach(DropTopTag.allCases) { tag in
//                    Button {
//                        print("tag - \(tag)")
//
//                        Task {
//                            await viewModel.selectTag(tag)
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(
//                                .subheadline.weight(
//                                    .medium
//                                )
//                            )
//                            .foregroundColor(
//                                viewModel.selectedTag == tag
//                                    ? .white
//                                    : .primary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background {
//                                Capsule()
//                                    .fill(
//                                        viewModel.selectedTag == tag
//                                            ? Color.accentColor
//                                            : Color.secondary.opacity(0.12)
//                                    )
//                            }
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//        }
//    }
//}
//
//// =================================================
//// MARK: - CONTENT
//// =================================================
//
//private extension DropTopContentView {
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.viewState {
//
//        case .loading:
//            ProgressView()
//
//        case .error(let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//
//        case .contentList(let page):
//            dropTopList(page)
//        }
//    }
//}
//
//// =================================================
//// MARK: - LIST
//// =================================================
//
//private extension DropTopContentView {
//
//    func dropTopList(
//        _ page: DropTopPage
//    ) -> some View {
//        ScrollView {
//            LazyVStack(
//                spacing: 0
//            ) {
//                ForEach(page.items) { item in
//                    dropTopRow(item)
//                        .onAppear {
//                            guard item.id == page.items.last?.id else {
//                                return
//                            }
//
//                            print(
//                                "onAppear - viewModel.loadNextPage()"
//                            )
//
//                            viewModel.loadNextPage()
//                        }
//                }
//
//                if page.hasMore {
//                    ProgressView()
//                        .padding(.vertical, 20)
//                }
//            }
//        }
//        .refreshable {
//            await viewModel.retry()
//        }
//    }
//}
//
//// =================================================
//// MARK: - ROW
//// =================================================
//
//
//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//        Button {
//            openPlaylist(item)
//        } label: {
//            HStack(spacing: 12) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor:
//                        AppColors.secondarySystemBackground,
//                    displayStyle:
//                        .fixedFrame(
//                            width: 60,
//                            height: 60
//                        ),
//                    context:
//                        "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                VStack(
//                    alignment: .leading,
//                    spacing: 4
//                ) {
//                    Text(item.title)
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                        .lineLimit(2)
//
//                    Text(item.description)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .lineLimit(1)
//                }
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//// =================================================
//// MARK: - NAVIGATION
//// =================================================
//
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
//        // droplistCoordinator.navigate(
//        //     to: .topDropDetails(
//        //         playlistId: item.id,
//        //         title: item.title,
//        //         imageURL: item.imageURL
//        //     )
//        // )
//    }
//}





















//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//        Button {
//            openPlaylist(item)
//        } label: {
//            HStack(spacing: 12) {
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor:
//                        AppColors.secondarySystemBackground,
//                    displayStyle:
//                        .fixedFrame(
//                            width: 60,
//                            height: 60
//                        ),
//                    context:
//                        "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                Text(item.title)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .lineLimit(2)
//                    .multilineTextAlignment(.leading)
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//}




//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    @EnvironmentObject var droplistCoordinator: DroplistCoordinator
//
//    var body: some View {
//        VStack(spacing: 0) {
//
//            tagSelector
//
//            Divider()
//
//            content
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//    }
//}
//
//private extension DropTopContentView {
//
//    var tagSelector: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 8) {
//
//                ForEach(DropTopTag.allCases) { tag in
//
//                    Button {
//                        print("tag - \(tag)")
//                        Task {
//                            await viewModel.selectTag(tag)
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(
//                                .subheadline.weight(
//                                    .medium
//                                )
//                            )
//                            .foregroundColor(
//                                viewModel.selectedTag == tag
//                                    ? .white
//                                    : .primary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background {
//                                Capsule()
//                                    .fill(
//                                        viewModel.selectedTag == tag
//                                            ? Color.accentColor
//                                            : Color.secondary.opacity(0.12)
//                                    )
//                            }
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 10)
//        }
//    }
//}
//
//
//private extension DropTopContentView {
//
//    @ViewBuilder
//    var content: some View {
//        switch viewModel.viewState {
//
//        case .loading:
//            ProgressView()
//
//        case .error(let error):
//            ContentErrorView(error: error) {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//
//        case .contentList(let page):
//            dropTopList(page)
//        }
//    }
//}
//
//private extension DropTopContentView {
//
//    func dropTopList(
//        _ page: DropTopPage
//    ) -> some View {
//
//        ScrollView {
//            LazyVStack(
//                spacing: 0
//            ) {
//                ForEach(page.items) { item in
//
//                    dropTopRow(item)
//
//                        .onAppear {
//                            guard item.id == page.items.last?.id else {
//                                return
//                            }
//                            print("onAppear - viewModel.loadNextPage()")
//                            viewModel.loadNextPage()
//                        }
//                }
//
//                // всегда крутится?
//                if page.hasMore {
//                    ProgressView()
//                        .padding(.vertical, 20)
//                        .onAppear {
//                            print("onAppear - if page.hasMore {")
//                        }
//                        .onDisappear {
//                            print("onDisappear - if page.hasMore {")
//                        }
//                }
//            }
//        }
//        .refreshable {
//            await viewModel.retry()
//        }
//    }
//}
//
//private extension DropTopContentView {
//
//    func dropTopRow(
//        _ item: DropTopItem
//    ) -> some View {
//
//        Button {
//            openPlaylist(item)
//        } label: {
//
//            HStack(spacing: 12) {
//
//                WebImageView(
//                    url: item.imageURL,
//                    placeholderColor:
//                        AppColors.secondarySystemBackground,
//                    displayStyle:
//                        .fixedFrame(
//                            width: 60,
//                            height: 60
//                        ),
//                    context:
//                        "DropTop_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                Text(item.title)
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                    .lineLimit(2)
//                    .multilineTextAlignment(.leading)
//
//                Spacer()
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//}
//
//
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
////        droplistCoordinator.navigate(
////            to: .topDropDetails(
////                playlistId: item.id,
////                title: item.title,
////                imageURL: item.imageURL
////            )
////        )
//    }
//}
