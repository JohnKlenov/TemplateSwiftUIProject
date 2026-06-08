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




// MARK: - DropListDataSource



import Foundation
import FirebaseFirestore

struct DropListUserFacingError: Error {
    let message: String
}

final class DropListDataSource {

    // MARK: - Dependencies

    private let firestoreService: DropListFirestoreServiceProtocol
    private let errorHandler: ErrorDiagnosticsProtocol
    private let alertManager: AlertManager
    private let pageSize: Int

    // MARK: - Cached State

    private var lowerPagesCache: [String: LowerSectionPage] = [:]
    private(set) var currentItem: CarouselItem?
    // Флаг, предотвращающий гонку при пагинации
    private var isLoadingNextPageForItem: Set<String> = []

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
    
    func resetCache() {
        lowerPagesCache.removeAll()
        currentItem = nil
        isLoadingNextPageForItem.removeAll()
    }

    // MARK: - Public API

    /// Первичная загрузка Droplist:
    /// - topSections
    /// - carouselItems
    /// - первая страница нижней секции
    func loadInitialDropList(
        defaultSelectedIndex: Int = 0
    ) async -> Result<DropData, DropListUserFacingError> {
        do {
            async let topTask: TopSectionModel = firestoreService.fetchTopSection()
            async let carouselTask: [CarouselItem] = firestoreService.fetchCarouselItems()

            // Загружаем верхнюю секцию и карусель параллельно
            let (topSection, carouselItems) = try await (topTask, carouselTask)

            // Определяем дефолтный item
            // Гарантируем, что индекс всегда в допустимых пределах массива (0 ... count-1),
            // чтобы избежать выхода за границы и всегда иметь валидный выбранный элемент.
            let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
            let selected = carouselItems[index]
            currentItem = selected

            // Загружаем первую страницу нижней секции
            let firstPage = try await firestoreService.fetchInitialLowerPage(
                for: selected,
                pageSize: pageSize
            )

            lowerPagesCache[selected.id] = firstPage

            let dropData = DropData(
                topSection: topSection,
                carouselItems: carouselItems,
                initialLowerSection: firstPage,
                selectedItem: selected
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

        /// Если есть кэш — возвращаем мгновенно
        if let cached = lowerPagesCache[item.id] {
            print("func selectCarouselItem: return cached for - \(item.id)")
            return cached
        }

        /// Иначе загружаем первую страницу
        let firstPage = try await firestoreService.fetchInitialLowerPage(
            for: item,
            pageSize: pageSize
        )

        lowerPagesCache[item.id] = firstPage
        return firstPage
    }

    // Пагинация — загрузка следующей страницы
    func loadNextPageIfNeeded(for item: CarouselItem) async throws -> LowerSectionPage? {
        
        // Защита от гонки: если уже грузим для этого item — выходим
        if isLoadingNextPageForItem.contains(item.id) {
            return nil
        }
        
        guard let currentPage = lowerPagesCache[item.id] else {
            return nil
        }
        
        guard currentPage.hasMore,
              let lastSnapshot = currentPage.lastDocumentSnapshot else {
            return nil
        }
        
        isLoadingNextPageForItem.insert(item.id)
        defer {
            isLoadingNextPageForItem.remove(item.id)
        }
        
        let nextPage = try await firestoreService.fetchNextLowerPage(
            for: item,
            after: lastSnapshot,
            pageSize: pageSize
        )
        
        let mergedItems = currentPage.items + nextPage.items
        
        let mergedPage = LowerSectionPage(
            items: mergedItems,
            lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
            hasMore: nextPage.hasMore
        )
        
        lowerPagesCache[item.id] = mergedPage
        
        return mergedPage
    }


    
    // MARK: - Soft Refresh (обновляет три секции, но не ломает UI при ошибке)

    func refreshAll() async -> DropData? {
        do {
            // Параллельные запросы (как в Gallery)
            async let topTask: TopSectionModel = firestoreService.fetchTopSection()
            async let carouselTask: [CarouselItem] = firestoreService.fetchCarouselItems()

            let (topSection, carouselItems) = try await (topTask, carouselTask)

            // Определяем текущий выбранный item
            let selectedItem: CarouselItem
            if let current = currentItem,
               let matched = carouselItems.first(where: { $0.id == current.id }) {
                selectedItem = matched
            } else {
                // fallback — первый элемент
                guard let first = carouselItems.first else {
                    return nil
                }
                selectedItem = first
            }

            // Загружаем первую страницу нижней секции
            let firstPage = try await firestoreService.fetchInitialLowerPage(
                for: selectedItem,
                pageSize: pageSize
            )

            resetCache()
            currentItem = selectedItem
            lowerPagesCache[selectedItem.id] = firstPage


            // Собираем DropData
            return DropData(
                topSection: topSection,
                carouselItems: carouselItems,
                initialLowerSection: firstPage, 
                selectedItem: selectedItem
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
