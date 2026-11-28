//
//  ArtistsView.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 23.11.2026.
//


// =================================================
// MARK: - Artists Implementation Checklist
// =================================================

/*
 Важные моменты для проверки реализации Artists:

 1. CarouselItemType:
    - Для .artists используется отдельный cacheKey = "artists".
    - Artists хранится во временном PagesCache.
    - .artists не смешивается с .artist(tag:), который загружает треки конкретного артиста.

 2. Firestore:
    - Артисты загружаются из коллекции "Artists".
    - Сортировка выполняется по orderIndex по возрастанию.
    - Пагинация использует start(afterDocument:).
    - Курсор берётся из последнего документа исходного snapshot,
      даже если его декодирование завершилось ошибкой.
    - hasMore определяется по количеству исходных документов.
    - Некорректные документы пропускаются с регистрацией ошибки.
    - Если все документы страницы не удалось декодировать,
      выбрасывается docsIsEmpty.
    - ArtistDocument.lowerItem передаёт orderIndex в LowerItem.

 3. PagesCache:
    - Первоначальная загрузка использует общий кэш.
    - Refresh загружает первую страницу заново.
    - Пагинация объединяет старые и новые элементы.
    - После Refresh используется новый Firestore cursor.
    - beginLoading/endLoading корректно блокируют повторные запросы.
    - Освобождение блокировки должно завершаться до выхода из метода.
    - Старый запрос пагинации не должен перезаписывать результат Refresh.
    - Очистка временного кэша должна удалять страницу Artists.

 4. ArtistsViewModel:
    - Первоначальная загрузка выполняется через fetchArtists().
    - Обновление выполняется через refresh().
    - Пагинация выполняется через loadNextPageIfNeeded(for:).
    - retry() корректно обрабатывает ошибки первоначальной загрузки
      и пагинации.
    - При ошибке пагинации уже загруженные артисты сохраняются.
    - isLoadingNextPage и paginationError корректно обновляются.
    - currentRequestID защищает от применения устаревших результатов.

 5. ArtistsView:
    - Первоначальная загрузка запускается через onFirstAppear.
    - Pull-to-refresh вызывает refresh().
    - Пагинация запускается при появлении последнего артиста.
    - Повторная попытка пагинации работает через retry().
    - Переход к артисту открывает правильный artistDetails.
    - Возврат на экран не должен вызывать лишнюю загрузку.
    - Пустая коллекция Firestore корректно отображается без ошибки.

 6. Ручное тестирование:
    - Первый вход и повторный вход в Artists.
    - Загрузка нескольких страниц без дублирования.
    - Refresh с последующей пагинацией.
    - Переход к артисту и возврат назад.
    - Ошибка первоначальной загрузки и повторная попытка.
    - Ошибка пагинации и повторная попытка.
    - Работа при отключённом интернете.
    - Очистка временного PagesCache.
 */


import SwiftUI

struct ArtistsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: ArtistsViewModel

    @EnvironmentObject private var libraryCoordinator: LibraryCoordinator

    // MARK: - Body

    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loading:
                loadingView

            case .content(let artists):
                contentView(artists)

            case .error:
                errorView
            }
        }
        .background(AppColors.background)
        .navigationTitle("Artists")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            Task {
                await viewModel.fetchArtists()
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        ProgressView()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
    }

    // MARK: - Content

    private func contentView(_ artists: [Artist]) -> some View {
        List {
            ForEach(artists) { artist in
                Button {
                    openArtist(artist)
                } label: {
                    artistRow(artist)
                }
                .buttonStyle(.plain)
                .onAppear {
                    Task {
                        await viewModel.loadNextPageIfNeeded(for: artist)
                    }
                }
            }

            paginationFooter
                .listRowSeparator(.hidden)
                .listRowBackground(AppColors.background)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
//        .refreshable {
//            await viewModel.refresh()
//        }
    }

    // MARK: - Artist Row

    private func artistRow(_ artist: Artist) -> some View {
        HStack(spacing: 14) {
            artistImage(artist)

            Text(artist.name)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    // MARK: - Artist Image

    @ViewBuilder
    private func artistImage(_ artist: Artist) -> some View {
        if let imageURL = artist.imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .empty, .failure:
                    imagePlaceholder

                @unknown default:
                    imagePlaceholder
                }
            }
            .frame(width: 54, height: 54)
            .clipShape(Circle())
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        Image(systemName: "music.mic")
            .font(.title3)
            .foregroundStyle(.secondary)
            .frame(width: 54, height: 54)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
    }

    // MARK: - Pagination Footer

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.isLoadingNextPage {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()

        } else if viewModel.paginationError {
            VStack(spacing: 8) {
                Text("Не удалось загрузить артистов")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Повторить") {
                    Task {
                        await viewModel.retry()
                    }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    }

    // MARK: - Navigation

    private func openArtist(_ artist: Artist) {
        libraryCoordinator.navigateTo(
            page: .artistDetails(
                tag: artist.tag,
                title: artist.name,
                imageURL: artist.imageURL
            )
        )
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("Не удалось загрузить артистов")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Повторить") {
                Task {
                    await viewModel.retry()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


// MARK: - before new implementetion artist

//import SwiftUI
//
//struct ArtistsView: View {
//
//    @ObservedObject var viewModel: ArtistsViewModel
//
//    @EnvironmentObject private var libraryCoordinator: LibraryCoordinator
//
//    var body: some View {
//        Group {
//            switch viewModel.viewState {
//            case .loading:
//                loadingView
//
//            case .content(let artists):
//                contentView(artists)
//
//            case .error(let message):
//                errorView(message)
//            }
//        }
//        .navigationTitle("Artists")
//        .navigationBarTitleDisplayMode(.inline)
//        .task {
//            if case .loading = viewModel.viewState {
//                await viewModel.fetchArtists()
//            }
//        }
//    }
//
//    // MARK: - Loading
//
//    private var loadingView: some View {
//        ProgressView()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//
//    // MARK: - Content
//
//    private func contentView(_ artists: [Artist]) -> some View {
//        List {
//            ForEach(artists) { artist in
//                Button {
//                    openArtist(artist)
//                } label: {
//                    artistRow(artist)
//                }
//                .buttonStyle(.plain)
//                .onAppear {
//                    if artist.id == artists.last?.id {
//                        Task {
//                            await viewModel.loadNextPage()
//                        }
//                    }
//                }
//            }
//
//            paginationFooter
//                .listRowSeparator(.hidden)
//        }
//        .listStyle(.plain)
//    }
//
//    // MARK: - Artist Row
//
//    private func artistRow(_ artist: Artist) -> some View {
//        HStack(spacing: 14) {
//            artistImage(artist)
//
//            Text(artist.name)
//                .font(.body.weight(.medium))
//                .foregroundStyle(.primary)
//
//            Spacer()
//
//            Image(systemName: "chevron.right")
//                .font(.caption.weight(.semibold))
//                .foregroundStyle(.secondary)
//        }
//        .padding(.vertical, 6)
//        .contentShape(Rectangle())
//    }
//
//    // MARK: - Artist Image
//
//    @ViewBuilder
//    private func artistImage(_ artist: Artist) -> some View {
//        if let imageURL = artist.imageURL {
//            AsyncImage(url: imageURL) { phase in
//                switch phase {
//                case .success(let image):
//                    image
//                        .resizable()
//                        .scaledToFill()
//
//                case .empty, .failure:
//                    imagePlaceholder
//
//                @unknown default:
//                    imagePlaceholder
//                }
//            }
//            .frame(width: 54, height: 54)
//            .clipShape(Circle())
//
//        } else {
//            imagePlaceholder
//        }
//    }
//
//    private var imagePlaceholder: some View {
//        Image(systemName: "music.mic")
//            .font(.title3)
//            .foregroundStyle(.secondary)
//            .frame(width: 54, height: 54)
//            .background(.ultraThinMaterial)
//            .clipShape(Circle())
//    }
//
//    // MARK: - Pagination Footer
//
//    @ViewBuilder
//    private var paginationFooter: some View {
//        if viewModel.isLoadingNextPage {
//            ProgressView()
//                .frame(maxWidth: .infinity)
//                .padding()
//
//        } else if let error = viewModel.paginationError {
//            VStack(spacing: 8) {
//                Text(error)
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                    .multilineTextAlignment(.center)
//
//                Button("Повторить") {
//                    Task {
//                        await viewModel.retryNextPage()
//                    }
//                }
//                .buttonStyle(.bordered)
//            }
//            .frame(maxWidth: .infinity)
//            .padding()
//        }
//    }
//
//    // MARK: - Navigation
//
//    private func openArtist(_ artist: Artist) {
//        libraryCoordinator.navigateTo(
//            page: .artistDetails(
//                tag: artist.tag,
//                title: artist.name,
//                imageURL: artist.imageURL
//            )
//        )
//    }
//
//    // MARK: - Error
//
//    private func errorView(_ message: String) -> some View {
//        VStack(spacing: 16) {
//            Image(systemName: "exclamationmark.circle")
//                .font(.largeTitle)
//                .foregroundStyle(.secondary)
//
//            Text(message)
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.secondary)
//
//            Button("Повторить") {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//            .buttonStyle(.borderedProminent)
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}



//import SwiftUI
//
//struct ArtistsView: View {
//
//    // MARK: - ViewModel
//
//    @ObservedObject var viewModel: ArtistsViewModel
//
//    // MARK: - Environment
//
//    @EnvironmentObject private var libraryCoordinator: LibraryCoordinator
//
//    // MARK: - Body
//
//    var body: some View {
//
//        Group {
//
//            switch viewModel.viewState {
//
//            case .loading:
//                loadingView
//
//            case .content(let artists):
//                contentView(artists)
//
//            case .error(let message):
//                errorView(message)
//            }
//        }
//        .navigationTitle("Artists")
//        .navigationBarTitleDisplayMode(.inline)
//        .task {
//            if case .loading = viewModel.viewState {
//                await viewModel.fetchArtists()
//            }
//        }
//    }
//
//    // =================================================
//    // MARK: - Loading
//    // =================================================
//
//    private var loadingView: some View {
//
//        ProgressView()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//
//    // =================================================
//    // MARK: - Content
//    // =================================================
//
//    private func contentView(
//        _ artists: [Artist]
//    ) -> some View {
//
//        List(artists) { artist in
//
//            Button {
//                openArtist(artist)
//            } label: {
//
//                artistRow(artist)
//            }
//            .buttonStyle(.plain)
//        }
//        .listStyle(.plain)
//    }
//
//    // =================================================
//    // MARK: - Artist Row
//    // =================================================
//
//    private func artistRow(
//        _ artist: Artist
//    ) -> some View {
//
//        HStack(spacing: 14) {
//
//            artistImage(artist)
//
//            Text(artist.name)
//                .font(.body.weight(.medium))
//                .foregroundStyle(.primary)
//
//            Spacer()
//
//            Image(systemName: "chevron.right")
//                .font(.caption.weight(.semibold))
//                .foregroundStyle(.secondary)
//        }
//        .padding(.vertical, 6)
//        .contentShape(Rectangle())
//    }
//
//    // =================================================
//    // MARK: - Artist Image
//    // =================================================
//
//    @ViewBuilder
//    private func artistImage(
//        _ artist: Artist
//    ) -> some View {
//
//        if let imageURL = artist.imageURL {
//
//            AsyncImage(url: imageURL) { phase in
//
//                switch phase {
//
//                case .success(let image):
//                    image
//                        .resizable()
//                        .scaledToFill()
//
//                case .empty, .failure:
//                    imagePlaceholder
//
//                @unknown default:
//                    imagePlaceholder
//                }
//            }
//            .frame(width: 54, height: 54)
//            .clipShape(Circle())
//
//        } else {
//
//            imagePlaceholder
//        }
//    }
//
//    private var imagePlaceholder: some View {
//
//        Image(systemName: "music.mic")
//            .font(.title3)
//            .foregroundStyle(.secondary)
//            .frame(width: 54, height: 54)
//            .background(.ultraThinMaterial)
//            .clipShape(Circle())
//    }
//
//    // =================================================
//    // MARK: - Navigation
//    // =================================================
//
//    private func openArtist(
//        _ artist: Artist
//    ) {
//
//        libraryCoordinator.navigateTo(
//            page: .artistDetails(
//                tag: artist.tag,
//                title: artist.name,
//                imageURL: artist.imageURL
//            )
//        )
//    }
//
//    // =================================================
//    // MARK: - Error
//    // =================================================
//
//    private func errorView(
//        _ message: String
//    ) -> some View {
//
//        VStack(spacing: 16) {
//
//            Image(systemName: "exclamationmark.circle")
//                .font(.largeTitle)
//                .foregroundStyle(.secondary)
//
//            Text(message)
//                .multilineTextAlignment(.center)
//                .foregroundStyle(.secondary)
//
//            Button("Повторить") {
//                Task {
//                    await viewModel.retry()
//                }
//            }
//            .buttonStyle(.borderedProminent)
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
