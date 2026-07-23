//
//  DropListDataSource.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 15.05.26.
//



//  func loadInitialDropList(defaultSelectedIndex: Int = 0) async throws -> DropData - не возвращает ошибки
// при первичной загрузки если хотябы один из асинхронных запросов возвращает ошибку loadInitialDropList failad

// func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage  - если вернет ошибку в firestoreService.fetchInitialLowerPage то как реагировать на UI ?

// func loadNextPageIfNeeded(for item: CarouselItem) async throws -> LowerSectionPage? - если вернет ошибку в firestoreService.fetchNextLowerPage то как реагировать (сейчас он похоже вернет [] при ошибки и в сумме на экране все будет без изменений в нижней секции так как let mergedItems = currentPage.items + nextPage.items?)

//  func refreshCurrentItem() async throws -> LowerSectionPage - Мягкий refresh (pull‑to‑refresh) от хедера экрана подразумевает в моем случае обновление всего экрана и если где то в трех асинхронных запросах (firestoreService.fetchTopSections() +  firestoreService.fetchCarouselItems() + firestoreService.fetchInitialLowerPage) приходит ошибка мы оставляем наш DropView без изменения и не заменяем DropView плэйсхолдером с кнопкой retry как при первом старте (func loadInitialDropList(defaultSelectedIndex: Int = 0) async throws -> DropData )
// мы можем показать когда спинер прокрутится какой нибудь элемент на мгновения вместа спинера что операция не удалась



/// Явный контракт для результата пагинации
//enum NextPageResult {
//    case loaded(itemId: String, page: LowerSectionPage)
//    case noMore(itemId: String)
//    case alreadyLoading(itemId: String)
//    case invalidState(itemId: String?)
//}


// MARK: - DropListDataSource


import Foundation
import FirebaseFirestore



enum NextPageResult {
    case loaded(page: LowerSectionPage)
    case noMore
    case invalidState
}

struct DropListUserFacingError: Error {
    let message: String
}

final class DropListDataSource {

    // MARK: - Dependencies

    private let firestoreService: DropListFirestoreServiceProtocol
    private let errorHandler: ErrorDiagnosticsProtocol
    private let alertManager: AlertManager
    private let pageSize: Int

    // MARK: - Cached State (actor)
    private let pagesCache = PagesCache()
    private(set) var currentItem: CarouselItem?
    // Флаг, предотвращающий гонку при пагинации (локальная защита)
//    private var isLoadingNextPageForItem: Set<String> = []

    // MARK: - Init

    init(
        firestoreService: DropListFirestoreServiceProtocol,
        errorHandler: ErrorDiagnosticsProtocol,
        alertManager: AlertManager = .shared,
        pageSize: Int = 10
    ) {
        self.firestoreService = firestoreService
        self.errorHandler = errorHandler
        self.alertManager = alertManager
        self.pageSize = pageSize
    }

    // MARK: - help methods

    // Сбрасывает весь локальный кэш страниц и состояние пагинации.
    // Используется при полном сбросе состояния (retry), когда не требуется
    // ждать завершения операции — initial load всё равно загрузит данные заново.
    func resetCache() {
        // синхронный wrapper — для совместимости с существующим кодом
        Task {
            await pagesCache.reset()
        }
        currentItem = nil
    }

    // Полностью сбрасывает кэш страниц и состояние пагинации,
    // гарантируя последовательность выполнения (await).
    // Используется в refreshAll(), где важно, чтобы кэш был очищен
    // до записи новых данных — предотвращает гонки и некорректные состояния.
    func resetCacheAsync() async {
        await pagesCache.reset()
        currentItem = nil
    }

    func cachedPage(for item: CarouselItem) async -> LowerSectionPage? {
        return await pagesCache.get(item.id)
    }

    // MARK: - Public API

    func loadInitialDropList(
        defaultSelectedIndex: Int = 0
    ) async -> Result<DropData, DropListUserFacingError> {
        do {
            async let topTask: TopSectionModel = firestoreService.fetchTopSection()
            async let carouselTask: [CarouselItem] = firestoreService.fetchCarouselItems()

            let (topSection, carouselItems) = try await (topTask, carouselTask)

            // Определяем дефолтный item
            // Гарантируем, что индекс всегда в допустимых пределах массива (0 ... count-1),
            // чтобы избежать выхода за границы и всегда иметь валидный выбранный элемент.
            let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
            let selected = carouselItems[index]
            currentItem = selected

            let firstPage = try await firestoreService.fetchInitialLowerPage(
                for: selected,
                pageSize: pageSize
            )

            await pagesCache.set(selected.id, page: firstPage)

            let dropData = DropData(
                topSection: topSection,
                carouselItems: carouselItems,
                initialLowerSection: firstPage,
                selectedItem: selected,
                isLowerSectionLoading: false,
                footerState: .idle
            )

            return .success(dropData)

        } catch {
            let message = handleError(error)
            return .failure(DropListUserFacingError(message: message))
        }
    }

    // Смена item в карусели
    func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
        currentItem = item

        let firstPage = try await firestoreService.fetchInitialLowerPage(
            for: item,
            pageSize: pageSize
        )

        await pagesCache.set(item.id, page: firstPage)
        return firstPage
    }

    // Пагинация — возвращаем явный NextPageResult
    func loadNextPageIfNeeded(for item: CarouselItem) async throws -> NextPageResult {

        guard let currentPage = await pagesCache.get(item.id) else {
            return .invalidState
        }

        guard currentPage.hasMore,
              let lastSnapshot = currentPage.lastDocumentSnapshot else {
            return .noMore
        }

        // Firestore больше НЕ бросает emptyResult при пагинации
        let nextPage = try await firestoreService.fetchNextLowerPage(
            for: item,
            after: lastSnapshot,
            pageSize: pageSize
        )

        // Пустая страница = конец списка
        if nextPage.items.isEmpty {
            let mergedPage = LowerSectionPage(
                items: currentPage.items,
                lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
                hasMore: false
            )
            await pagesCache.set(item.id, page: mergedPage)
            return .noMore
        }

        // Нормальная страница
        let mergedItems = currentPage.items + nextPage.items
        let mergedPage = LowerSectionPage(
            items: mergedItems,
            lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
            hasMore: nextPage.hasMore
        )

        await pagesCache.set(item.id, page: mergedPage)
        return .loaded(page: mergedPage)
    }

    // MARK: - Soft Refresh
    
    func refreshAll() async -> DropData? {
        do {
            async let topTask: TopSectionModel = firestoreService.fetchTopSection()
            async let carouselTask: [CarouselItem] = firestoreService.fetchCarouselItems()

            let (topSection, carouselItems) = try await (topTask, carouselTask)

            let selectedItem: CarouselItem
            if let current = currentItem,
               let matched = carouselItems.first(where: { $0.id == current.id }) {
                selectedItem = matched
            } else {
                guard let first = carouselItems.first else {
                    return nil
                }
                selectedItem = first
            }

            let firstPage = try await firestoreService.fetchInitialLowerPage(
                for: selectedItem,
                pageSize: pageSize
            )

            await resetCacheAsync()
            currentItem = selectedItem
            await pagesCache.set(selectedItem.id, page: firstPage)

            return DropData(
                topSection: topSection,
                carouselItems: carouselItems,
                initialLowerSection: firstPage,
                selectedItem: selectedItem,
                isLowerSectionLoading: false,
                footerState: .idle
            )

        } catch {
            // Мягкий refresh — UI не ломаем
            let _ = errorHandler.handle(
                error: error,
                context: ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue
            )
            return nil
        }
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) -> String {
        if let serviceError = error as? FirestoreGetServiceError {
            let combinedContext =
            "\(serviceError.context.rawValue) | \(ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue)"
            return errorHandler.handle(
                error: serviceError.underlying,
                context: combinedContext
            )
        } else {
            return errorHandler.handle(
                error: error,
                context: ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue
            )
        }
    }
}
    


// MARK: - before deleted isLoadingNextPageForItem



// case:
//но смотри что может произойти если я конечно не ввел себя в заблуждение! допустим мы вызвали на одном selectedCarouselItem loadNextPage не дождались ответа так как от сервера он еще не пришол и значит func loadNextPageIfNeeded(for item: CarouselItem) async throws -> NextPageResult еще не завершил свою работу и не вызвал defer { isLoadingNextPageForItem.remove(item.id) } и ушли на овый selectedCarouselItem затем вернулись быстро обратно на первый selectedCarouselItem и снова вызвали там loadNextPage ! и если в   первом вызове func loadNextPageIfNeeded(for item: CarouselItem) async throws -> NextPageResult еще не завершил свою работу то мы получим if isLoadingNextPageForItem.contains(item.id) {
//            return .alreadyLoading
//        } что приведет к тому что спинер будет крутится и он не остановится когда в первом вызове func loadNextPageIfNeeded(for item: CarouselItem) async throws -> NextPageResult придеть ответ от сервера потому что requestID уже другой! что скажегь моя мысль верная? или это на столько редкий кейс что можно не переживать ?или как это улучшить ?



//enum NextPageResult {
//    case loaded(page: LowerSectionPage)
//    case noMore
//    case alreadyLoading
//    case invalidState
//}

//func resetCache() {
//    // синхронный wrapper — для совместимости с существующим кодом
//    Task {
//        await pagesCache.reset()
//    }
//    currentItem = nil
//    // возможно isLoadingNextPageForItem будет не нужен
//    isLoadingNextPageForItem.removeAll()
//}

//func resetCacheAsync() async {
//    await pagesCache.reset()
//    currentItem = nil
//    isLoadingNextPageForItem.removeAll()
//}


//func loadNextPageIfNeeded(for item: CarouselItem) async throws -> NextPageResult {
//
//    // Защита от гонки
//    if isLoadingNextPageForItem.contains(item.id) {
//        return .alreadyLoading
//    }
//
//    guard let currentPage = await pagesCache.get(item.id) else {
//        return .invalidState
//    }
//
//    guard currentPage.hasMore,
//          let lastSnapshot = currentPage.lastDocumentSnapshot else {
//        return .noMore
//    }
//
//    isLoadingNextPageForItem.insert(item.id)
//    defer { isLoadingNextPageForItem.remove(item.id) }
//
//    // Firestore больше НЕ бросает emptyResult при пагинации
//    let nextPage = try await firestoreService.fetchNextLowerPage(
//        for: item,
//        after: lastSnapshot,
//        pageSize: pageSize
//    )
//
//    // Пустая страница = конец списка
//    if nextPage.items.isEmpty {
//        let mergedPage = LowerSectionPage(
//            items: currentPage.items,
//            lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
//            hasMore: false
//        )
//        await pagesCache.set(item.id, page: mergedPage)
//        return .noMore
//    }
//
//    // Нормальная страница
//    let mergedItems = currentPage.items + nextPage.items
//    let mergedPage = LowerSectionPage(
//        items: mergedItems,
//        lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//        hasMore: nextPage.hasMore
//    )
//
//    await pagesCache.set(item.id, page: mergedPage)
//    return .loaded(page: mergedPage)
//}


    
    // MARK: - before Query relevance mechanism (Task + currentRequestID + cancellation)
    
    
    
    
//    import Foundation
//    import FirebaseFirestore
//
//    struct DropListUserFacingError: Error {
//        let message: String
//    }
//
//    final class DropListDataSource {
//
//        // MARK: - Dependencies
//
//        private let firestoreService: DropListFirestoreServiceProtocol
//        private let errorHandler: ErrorDiagnosticsProtocol
//        private let alertManager: AlertManager
//        private let pageSize: Int
//        
//        
//        // MARK: - Cached State
//
//        private var lowerPagesCache: [String: LowerSectionPage] = [:]
//        private(set) var currentItem: CarouselItem?
//        // Флаг, предотвращающий гонку при пагинации
//        private var isLoadingNextPageForItem: Set<String> = []
//
//        // MARK: - Init
//
//        init(
//            firestoreService: DropListFirestoreServiceProtocol,
//            errorHandler: ErrorDiagnosticsProtocol,
//            alertManager: AlertManager = .shared,
//            pageSize: Int = 10
//        ) {
//            self.firestoreService = firestoreService
//            self.errorHandler = errorHandler
//            self.alertManager = alertManager
//            self.pageSize = pageSize
//        }
//        
//        
//        
//        // MARK: - help methods
//        
//        func resetCache() {
//            lowerPagesCache.removeAll()
//            currentItem = nil
//            isLoadingNextPageForItem.removeAll()
//        }
//        
//        func cachedPage(for item: CarouselItem) -> LowerSectionPage? {
//            return lowerPagesCache[item.id]
//        }
//
//
//        // MARK: - Public API
//
//        /// Первичная загрузка Droplist:
//        /// - topSections
//        /// - carouselItems
//        /// - первая страница нижней секции
//        func loadInitialDropList(
//            defaultSelectedIndex: Int = 0
//        ) async -> Result<DropData, DropListUserFacingError> {
//            do {
//                async let topTask: TopSectionModel = firestoreService.fetchTopSection()
//                async let carouselTask: [CarouselItem] = firestoreService.fetchCarouselItems()
//
//                // Загружаем верхнюю секцию и карусель параллельно
//                let (topSection, carouselItems) = try await (topTask, carouselTask)
//
//                 Определяем дефолтный item
//                 Гарантируем, что индекс всегда в допустимых пределах массива (0 ... count-1),
//                 чтобы избежать выхода за границы и всегда иметь валидный выбранный элемент.
//                let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
//                let selected = carouselItems[index]
//                currentItem = selected
//
//                // Загружаем первую страницу нижней секции
//                let firstPage = try await firestoreService.fetchInitialLowerPage(
//                    for: selected,
//                    pageSize: pageSize
//                )
//
//                lowerPagesCache[selected.id] = firstPage
//
//                let dropData = DropData(
//                    topSection: topSection,
//                    carouselItems: carouselItems,
//                    initialLowerSection: firstPage,
//                    selectedItem: selected,
//                    isLowerSectionLoading: false,
//                    footerState: .idle
//                )
//
//                return .success(dropData)
//
//            } catch {
//                let message = handleError(error)
//                return .failure(DropListUserFacingError(message: message))
//            }
//        }
//        // Смена item в карусели
//        func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
//            currentItem = item
//
//            /// Иначе загружаем первую страницу
//            let firstPage = try await firestoreService.fetchInitialLowerPage(
//                for: item,
//                pageSize: pageSize
//            )
//
//            /// если в lowerPagesCache произойдет конфликтующая запись по одному [item.id?
//            /// к примеру мы вызвали  selectCarouselItem для одного итема дважды)
//            lowerPagesCache[item.id] = firstPage
//            return firstPage
//        }
//        
//
//        
//        // Пагинация — загрузка следующей страницы
//        func loadNextPageIfNeeded(for item: CarouselItem) async throws -> LowerSectionPage? {
//            
//            // Защита от гонки: если уже грузим для этого item — выходим
//            if isLoadingNextPageForItem.contains(item.id) {
//                return nil
//            }
//            
//            guard let currentPage = lowerPagesCache[item.id] else {
//                return nil
//            }
//            
//            guard currentPage.hasMore,
//                  let lastSnapshot = currentPage.lastDocumentSnapshot else {
//                return nil
//            }
//            
//            isLoadingNextPageForItem.insert(item.id)
//            defer {
//                isLoadingNextPageForItem.remove(item.id)
//            }
//            
//            let nextPage = try await firestoreService.fetchNextLowerPage(
//                for: item,
//                after: lastSnapshot,
//                pageSize: pageSize
//            )
//            
//            let mergedItems = currentPage.items + nextPage.items
//            
//            let mergedPage = LowerSectionPage(
//                items: mergedItems,
//                lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//                hasMore: nextPage.hasMore
//            )
//            
//            lowerPagesCache[item.id] = mergedPage
//            
//            return mergedPage
//        }
//
//
//        
//        // MARK: - Soft Refresh (обновляет три секции, но не ломает UI при ошибке)
//
//        func refreshAll() async -> DropData? {
//            do {
//                // Параллельные запросы (как в Gallery)
//                async let topTask: TopSectionModel = firestoreService.fetchTopSection()
//                async let carouselTask: [CarouselItem] = firestoreService.fetchCarouselItems()
//
//                let (topSection, carouselItems) = try await (topTask, carouselTask)
//
//                // Определяем текущий выбранный item
//                let selectedItem: CarouselItem
//                if let current = currentItem,
//                   let matched = carouselItems.first(where: { $0.id == current.id }) {
//                    selectedItem = matched
//                } else {
//                    // fallback — первый элемент
//                    guard let first = carouselItems.first else {
//                        return nil
//                    }
//                    selectedItem = first
//                }
//
//                // Загружаем первую страницу нижней секции
//                let firstPage = try await firestoreService.fetchInitialLowerPage(
//                    for: selectedItem,
//                    pageSize: pageSize
//                )
//
//                resetCache()
//                currentItem = selectedItem
//                lowerPagesCache[selectedItem.id] = firstPage
//
//
//                // Собираем DropData
//                return DropData(
//                    topSection: topSection,
//                    carouselItems: carouselItems,
//                    initialLowerSection: firstPage,
//                    selectedItem: selectedItem,
//                    isLowerSectionLoading: false,
//                    footerState: .idle
//                )
//
//            } catch {
//                // Мягкий refresh — UI не ломаем
//                let _ = errorHandler.handle(
//                    error: error,
//                    context: ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue
//                )
//                return nil
//            }
//        }
//
//        // MARK: - Error Handling
//
//        func handleError(_ error: Error) -> String {
//            if let serviceError = error as? FirestoreGetServiceError {
//                let combinedContext =
//                "\(serviceError.context.rawValue) | \(ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue)"
//                return errorHandler.handle(
//                    error: serviceError.underlying,
//                    context: combinedContext
//                )
//            } else {
//                return errorHandler.handle(
//                    error: error,
//                    context: ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue
//                )
//            }
//        }
//
    
    
    
    
    
    
    

    //    func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
    //        currentItem = item
    //
    //        // ИСКУССТВЕННАЯ ЗАДЕРЖКА ДЛЯ ТЕСТА ГОНКИ
    //        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 секунд
    //
    //        // Возвращаем пустую страницу
    //        let page = LowerSectionPage(
    //            items: [],
    //            lastDocumentSnapshot: nil,
    //            hasMore: false
    //        )
    //
    ////        lowerPagesCache[item.id] = page
    //        return page
    //    }

    //    func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
    //        currentItem = item
    //
    //        // Считаем количество вызовов для конкретного item.id
    //        count += 1
    //
    //        // Первая загрузка — 10 секунд, вторая — 3 секунды
    //        if count == 1 {
    //            try await Task.sleep(nanoseconds: 15_000_000_000)
    //        } else {
    //            try await Task.sleep(nanoseconds: 3_000_000_000)
    //        }
    //
    //        // Возвращаем пустую страницу
    //        let page = LowerSectionPage(
    //            items: [],
    //            lastDocumentSnapshot: nil,
    //            hasMore: false
    //        )
    //
    ////        lowerPagesCache[item.id] = page
    //        return page
    //    }
    
    
    // MARK: - Trash
    
    
    //    func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
    //        currentItem = item
    //
    //        /// Если есть кэш — возвращаем мгновенно
    //        if let cached = lowerPagesCache[item.id] {
    //            print("func selectCarouselItem: return cached for - \(item.id)")
    //            return cached
    //        }
    //
    //        /// Иначе загружаем первую страницу
    //        let firstPage = try await firestoreService.fetchInitialLowerPage(
    //            for: item,
    //            pageSize: pageSize
    //        )
    //
    //        lowerPagesCache[item.id] = firstPage
    //        return firstPage
    //    }
    
    
    
    //        let err = AppInternalError.emptyResult
    //        if let serviceError = err as? AppInternalError {
    //            print("func handleError if let serviceError = error as? AppInternalError ")
    //            return errorHandler.handle(
    //                error: serviceError,
    //                context: "combinedContext"
    //            )
    //        } else {
    //            print("func handleError else")
    //            return errorHandler.handle(
    //                error: err,
    //                context: ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue
    //            )
    //        }
    //                let err = PhotoPickerError.iCloudRequired
            //        if let serviceError = err as? PhotoPickerError {
            //            print("func handleError if let serviceError = error as? PhotoPickerError ")
            //            return errorHandler.handle(
            //                error: serviceError,
            //                context: "combinedContext"
            //            )
            //        } else {
            //            print("func handleError else")
            //            return errorHandler.handle(
            //                error: error,
            //                context: ErrorContext.DropListDataSource_loadInitialDropList_DropListFirestoreService.rawValue
            //            )
            //        }
            
    
//    func handleError(_ error: Error) -> String {
//
//        // 1. FirestoreGetServiceError
//        if let serviceError = error as? FirestoreGetServiceError {
//
//            let underlying = serviceError.underlying
//
//            // 1.1 Swift enum AppInternalError
//            if let appError = underlying as? AppInternalError {
//                let safeError = NSError(
//                    domain: AppInternalError.errorDomain,
//                    code: appError.rawValue,
//                    userInfo: [
//                        NSLocalizedDescriptionKey: appError.errorDescription ?? "AppInternalError"
//
//                    ]
//                )
//
//                let result = errorHandler.handle(
//                    error: safeError,
//                    context: serviceError.context.rawValue
//                )
//                return result
//            }
//
//            // 1.2 underlying is already NSError
//            if let ns = underlying as? NSError {
//
//                let result = errorHandler.handle(
//                    error: ns,
//                    context: serviceError.context.rawValue
//                )
//                return result
//            }
//
//            // 1.3 underlying is some other Error
//            let result = errorHandler.handle(
//                error: underlying,
//                context: serviceError.context.rawValue
//            )
//            return result
//        }
//
//        // 2. Not FirestoreGetServiceError
//        let result = errorHandler.handle(
//            error: error,
//            context: "DropListDataSource"
//        )
//        return result
//    }

//}





//    // Пагинация — загрузка следующей страницы
//    func loadNextPageIfNeeded(for item: CarouselItem) async throws -> LowerSectionPage? {
//
//        guard let currentPage = lowerPagesCache[item.id] else {
//            /// Нет первой страницы — значит UI вызвал пагинацию слишком рано
//            return nil
//        }
//
//        guard currentPage.hasMore,
//              let lastSnapshot = currentPage.lastDocumentSnapshot else {
//            /// Больше страниц нет
//            /// Нет курсора — странно, но защищаемся
//            return nil
//        }
//
//        let nextPage = try await firestoreService.fetchNextLowerPage(
//            for: item,
//            after: lastSnapshot,
//            pageSize: pageSize
//        )
//
//        let mergedItems = currentPage.items + nextPage.items
//
//        let mergedPage = LowerSectionPage(
//            items: mergedItems,
//            lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//            hasMore: nextPage.hasMore
//        )
//
//        lowerPagesCache[item.id] = mergedPage
//
//        return mergedPage
//    }


// MARK: - before return DropListUserFacingError


//// MARK: - DropListDataSource
//
//
//import Foundation
//import FirebaseFirestore
//
///// DataSource отвечает за бизнес‑логику загрузки данных для DroplistCompositView:
///// - первичная загрузка (top + carousel + первая страница нижней секции)
///// - пагинация нижней секции
///// - смена item в карусели
///// - кэширование страниц для каждого item
//final class DropListDataSource {
//   
//   // MARK: - Dependencies
//   
//   private let firestoreService: DropListFirestoreServiceProtocol
//   private let pageSize: Int
//   
//   // MARK: - Cached State
//   
//   /// Кэш страниц нижней секции для каждого carouselItem.id
//   private var lowerPagesCache: [String: LowerSectionPage] = [:]
//   
//   /// Текущий выбранный item карусели
//   private(set) var currentItem: CarouselItem?
//   
//   // MARK: - Init
//   
//   init(
//       firestoreService: DropListFirestoreServiceProtocol,
//       pageSize: Int = 20
//   ) {
//       self.firestoreService = firestoreService
//       self.pageSize = pageSize
//   }
//   
//   // MARK: - Public API
//   
//   /// Первичная загрузка:
//   /// - topSections
//   /// - carouselItems
//   /// - первая страница нижней секции для defaultSelectedIndex
//
//    // нужно возвращать result - .success(let dropData) + .failure(let error)
//    // если вернулась .failure(let error) нужно при повторном loadInitialDropList обнулить кэши (lowerPagesCache[selected.id] .. )
//    // на сколько я понимаю firestoreService.fetchTopSections() + firestoreService.fetchCarouselItems() + firestoreService.fetchInitialLowerPage - должны иметь возможность возвращать ошибку !
//    // тогда если хотя бы один из них заканчивает свою работу с ошибкой мы из loadInitialDropList возвращаем .failure(let error) иначе .success(let dropData)
//   func loadInitialDropList(defaultSelectedIndex: Int = 0) async throws -> DropData {
//       
//       // Загружаем верхнюю секцию и карусель параллельно
//       async let topTask = firestoreService.fetchTopSections()
//       async let carouselTask = firestoreService.fetchCarouselItems()
//       
//       let (topSections, carouselItems) = try await (topTask, carouselTask)
//       
//       guard !carouselItems.isEmpty else {
//           // Если нет элементов карусели — возвращаем пустую структуру
//           let emptyPage = LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false)
//           return DropData(
//               topSections: topSections,
//               carouselItems: carouselItems,
//               initialLowerSection: emptyPage
//           )
//       }
//       
//       // Определяем дефолтный item
//       let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
//       let selected = carouselItems[index]
//       currentItem = selected
//       
//       // Загружаем первую страницу нижней секции
//       let firstPage = try await firestoreService.fetchInitialLowerPage(
//           for: selected,
//           pageSize: pageSize
//       )
//       
//       // Кэшируем
//       lowerPagesCache[selected.id] = firstPage
//       
//       return DropData(
//           topSections: topSections,
//           carouselItems: carouselItems,
//           initialLowerSection: firstPage
//       )
//   }
//   
//   /// Смена item в карусели
//   func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
//       currentItem = item
//       
//       // Если есть кэш — возвращаем мгновенно
//       if let cached = lowerPagesCache[item.id] {
//           return cached
//       }
//       
//       // Иначе загружаем первую страницу
//       let firstPage = try await firestoreService.fetchInitialLowerPage(
//           for: item,
//           pageSize: pageSize
//       )
//       
//       lowerPagesCache[item.id] = firstPage
//       return firstPage
//   }
//   
//   /// Пагинация — загрузка следующей страницы
//   func loadNextPageIfNeeded(for item: CarouselItem) async throws -> LowerSectionPage? {
//       
//       guard let currentPage = lowerPagesCache[item.id] else {
//           // Нет первой страницы — значит UI вызвал пагинацию слишком рано
//           return nil
//       }
//       
//       guard currentPage.hasMore else {
//           // Больше страниц нет
//           return nil
//       }
//       
//       guard let lastSnapshot = currentPage.lastDocumentSnapshot else {
//           // Нет курсора — странно, но защищаемся
//           return nil
//       }
//       
//       // Загружаем следующую страницу
//       let nextPage = try await firestoreService.fetchNextLowerPage(
//           for: item,
//           after: lastSnapshot,
//           pageSize: pageSize
//       )
//       
//       // Объединяем
//       let mergedItems = currentPage.items + nextPage.items
//       
//       let mergedPage = LowerSectionPage(
//           items: mergedItems,
//           lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//           hasMore: nextPage.hasMore
//       )
//       
//       // Обновляем кэш
//       lowerPagesCache[item.id] = mergedPage
//       
//       return mergedPage
//   }
//   
//   /// Мягкий refresh (pull‑to‑refresh)
//   /// Обновляет только текущий item
//   func refreshCurrentItem() async throws -> LowerSectionPage {
//       guard let item = currentItem else {
//           throw NSError(domain: "DropListDataSource", code: -1, userInfo: [
//               NSLocalizedDescriptionKey: "No current carousel item selected"
//           ])
//       }
//       
//       let firstPage = try await firestoreService.fetchInitialLowerPage(
//           for: item,
//           pageSize: pageSize
//       )
//       
//       lowerPagesCache[item.id] = firstPage
//       return firstPage
//   }
//}
