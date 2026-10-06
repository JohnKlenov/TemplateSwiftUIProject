//
//  DroplistViewInjected.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//


// DropTop
//
// DropTop уже имеет путь и метод фетч
// нужно добавить в объект tag или поле по которому мы будем фетч данные только для секции TopDrop на главном экране.
// будет список который будет иметь следующие категории (Top year + Top decada (четыре декады для каждого года) + Artist List#1 и тд + прочии категории типа ечеринка или Рождество и в таком духе)
// каждая категория будет иметь свой tag (All + TopYear + Decada + Artist и так далее)
// то есть мы как и на главном экране в секции TopDrop будем получать весь список и иметь возможность фильтровать по тегам(в новых версиях может сделаем экран фильтр с более сложной настройкой)
// как будет выглядеть ячейка image + Title + ears (Top 2026 or Lil Wayne - List#2 2026 or Top decade 1/2 2026 or Christmas 2020 ) размер как на droplist


// смотри сейчас мы через AdminView в частности через AdminViewModel в первой версии func savePlaylistToFirestore() добавляем треки в droplistRef.collection("tracks") и в db.collection("dropTracks") а во второй версии func savePlaylistToFirestore() добавляем треки в db
//            .collection("topSection")
// и именно тут на сколько я понимаю нам нужно добавить наши два новых поля artists [String] + tags ! поле tags наверно может быть просто String потому что в этом поле у нас не может быть два значения, разве что значение all ! не уверен может all это будет первый запрос по которому мы получаем все данные из коллекции а потом каждый новый запрос по tags будет отдельным запросом! тут я бы хотел что бы ты сделал это так как реализуют в проде в боевых прложениях!
// нужно будет посмотреть наверно нужно будет сделать изменения в методах фетч на топ сектион из за того что измениться модель!
// наверно нужно -
// //  TopSectionDoc — документ плейлиста (topSections/{playlistId})
//
//struct TopSectionDoc: Codable {
//    let playlistId: String      // Критично → обязательное
//    let title: String           // Критично → обязательное
//    let description: String?    // Не критично → опциональное
//    let coverImageURL: String?  // Не критично → опциональное
//    let trackCount: Int         // Критично → обязательное
//    let createdAt: Date?        // Может отсутствовать → опциональное
//    let orderIndex: Int         // Критично → обязательное
//}
//
//func fetchTopSection() async throws -> TopSectionModel {
//
//    try await withCheckedThrowingContinuation { continuation in
//
//        db.collection("topSection")
//            .order(
//                by: "orderIndex",
//                descending: false
//            )
//            .getDocuments { [weak self] snapshot, error in
//
//                guard let self else {
//                    return
//                }
//
//                if let error {
//
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: error,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//
//                    return
//                }
//
//                guard let snapshot else {
//
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: AppInternalError.nilSnapshot,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//
//                    return
//                }
//
//                if snapshot.documents.isEmpty {
//
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: AppInternalError.snapshotIsEmpty,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//
//                    return
//                }
//
//                // Безопасное декодирование Firestore
//                // ========================================================
//                // 🔐 do-catch + compactMap + errorHandler.handle = 100% защита от крашей
//                //
//                // ЧТО ЛОВИТ catch (ошибка → логируем → пропускаем документ):
//                // • Поле имеет другой тип (String вместо Int)
//                // • Отсутствует обязательное поле (не Optional)
//                // • Обязательное поле = null
//                // • Все поля другие/повреждённые данные
//                //
//                // ЧТО НЕ ВЫЗЫВАЕТ ОШИБОК:
//                // • Лишние поля в Firestore → игнорируются
//                // • Отсутствует Optional поле → получает nil
//                // • Optional поле = null → получает nil
//                //
//                // ℹ️ Optional защищает только от ОТСУТСТВИЯ поля, но НЕ от неправильного типа!
//                //    String? при Int значении → catch, документ пропущен
//                let docs: [
//                    (id: String, data: TopSectionDoc)
//                ] = snapshot.documents.compactMap { doc in
//
//                    do {
//
//                        let decoded =
//                            try doc.data(
//                                as: TopSectionDoc.self
//                            )
//
//                        return (
//                            doc.documentID,
//                            decoded
//                        )
//
//                    } catch {
//
//                        let _ = self.errorHandler.handle(
//                            error: error,
//                            context:
//                                "fetchTopSection | decode \(doc.documentID)"
//                        )
//
//                        return nil
//                    }
//                }
//
//                if docs.isEmpty {
//
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: AppInternalError.docsIsEmpty,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//
//                    return
//                }
//
//                let items: [TopItem] =
//                    docs.map { playlist in
//
//                        TopItem(
//                            id: playlist.id,
//                            title: playlist.data.title,
//                            imageURL:
//                                playlist.data.coverImageURL.flatMap {
//                                    URL(string: $0)
//                                }
//                        )
//                    }
//
//                let sectionModel = TopSectionModel(
//                    id: "top_section",
//                    title: "TopDrop",
//                    items: items
//                )
//
//                continuation.resume(
//                    returning: sectionModel
//                )
//            }
//    }
//}
//
//struct TopItem: Identifiable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//}
//
// в TopItem нужно добавить поле artists мы будем его заполнять из поля объекта TopSectionDoc!
//
//
// мы решили что у нас будет два пути: /topSection/ с документами как на скрин шоте + /dropTop/ - это две коллекции которые будут иметь однотимные документы как на скриншоте
// только  /dropTop/ будет содержать полный список топовых сборников треков (по фиксированным категориям Top year + Top decada + Artist) а /topSection/ будут содежать дублирующие данные из dropTop для карусели в верхней секции главного экрана Droplist - там будет наверно не более 5 карточек в этой карусели !
// я решил все таки разделить дата сорс для карусели в верхней секции и отдельного экрана dropTop по разным причинам (я смогу менять порядок отображения карточек в карусели через orderIndex + возможно у нас будет какая то рекламная интеграция которая потребует данных которые не будут дублироваться в  dropTop и т.д)
// 
// в каждый документ коллекции /topSection/PLQcuPcwlJLVB97DdyKtV2E-STKQydRPeR нужно добавить при записи из админки поле artists [String] мы просто будем руками прописывать его в коде аминке для каждого сохранения документа /topSection/PLQcuPcwlJLVB97DdyKtV2E-STKQydRPeR ! также нужно добавить поле tags (topYear, topDecada, artist - пока будет три! как на скрин шоте) по которому мы будем из экрана DropTop фильтровать список с DropTop то есть если выбрали из списка только topDecada то на экране отображаються только документы содержащие в поле tags: topDecada! если выбрали из списка all то получаем весь список документов из коллекции DropTop
//
// что такое категории topYear, topDecada, artist ! По мере того как мы будем в наши текущие плэйлисты на главном экране добавлять лучшие треки из последних альбомов разных исполнителей мы будем из всего этого списка за текущий год в конце каждого года создавать Top year 2026 затем Top year 2027 и так далее! кроме этого в течении года мы раз в три месяца будем создавать топ треков по итогу декады (первых трех месяцев года - за год будет 4 декады это и будет категория topDecada)! так же мы можем добавлять в список плэйлистов DropTop другие категории например artist - то есть мы к примеру захотмим в какой то момент собрать плэйлист с подборкой треков для Lil Wayne к примеру и выложить его в DropTop! возможно в будущем появиться новая категория для плэйлистов в DropTop и мы добавим ее к нашим тегам!
//
// смотри что я хочу иметь в итоге!
// нам нужно добавить в AdminViewModel в версии func savePlaylistToFirestore() (во второй версии где мы будем добавлять плейлисты в  db
// .collection("topSection")) новые поля для добавления нового плэйлиста (поле artists [String] + tag: String ) в artists я буду руками в AdminViewModel прописывать массив ортистов и поле tag я буду тоже прописывать руками к примеру topYear! вторую версию func savePlaylistToFirestore() мы будем использовать так же для добавления плейлистов с треками для корневого католога топовых плейлиство и будем менять только пути на .collection("dropTop")!
// то есть на главном экране Droplist в верхней карусели мы будем использовать данные из источника .collection("topSection")
// а для кнопки DropTop по которой мы будем переходить на экран DropTop вот тут наш дата сорс будет  .collection("dropTop") !
// Как будет выглядеть экран DropTop - это по сути обычный список с ячейками которые имеют вид ячейки image + Title  (image будет небольшая картинка 60 на 60 , Title будет строка к примеру Top 2026 или Top 1/2 decada 2026 или Lil Wayne - List#1 2026)
// при переходе на ячейку мы переходим непосредственно на плейлист с трками на наш TracklistView!
// на экране DropTop нам нужно иметь способ переключаться по нашим тегам(topYear, topDecada, artist) то есть при переходе на DropTop мы сразу фетчим данные из .collection("dropTop") допустим первые 30 или 20 так что бы список заполнил весь экран с запасом за экран! а затем если пользователь прокручивает ленту ниже то мы подтягиваем новую порцию плейлистов! Дак вот пользователь должен иметь возможность переключаться по тегам на экране то есть фильтровать весь список допустим только по тегу topDecada и на эране мы увидем спсико с первыми допустим 20 плейлистами только по topDecada ! если пользователь захочет вернуться на весь список он должен выбрать из списка на экране DropTop tag all!
// экран DropTop мы делаем по принципу экрана TracklistView то есть он будет иметь DropTopViewInjected + DropTopContentView + DropTopViewModel!
// смотри цепочка получения данных для DropTopViewInjected та же что и раньше ! мы в ViewBuilderService инициализируем DropTopViewInjected через func dropViewBuild(page: DroplistFlow) -> some View далее передаем туда dropListDataSource и получается из DropTopViewModel обращаемся к dropListDataSource как и раньше а базовый фетч лежит в DropListFirestoreService! 

// Tabs Category
//
// Верхняя секция список Alltracks + DropTop
// Нижняя секция список - все оттенки gym + pathy ...


// MyPlaylist


// для версии 2.0  нужно оставить так же стратегию использования AppleMusic - то есть интерфейс будет все тот же но дата сорс уже будет тругой


import SwiftUI

struct DroplistViewInjected: View {

    // ============================================================
    // MARK: - ViewModel
    // ============================================================

    @StateObject private var viewModel: DroplistViewModel

    // ============================================================
    // MARK: - Init
    // ============================================================

    init(
        sessionManager: AppSessionManager,
        dropListDataSource: DropListDataSource,
        playlistUser: PlaylistUser
    ) {
        _viewModel = StateObject(
            wrappedValue: DroplistViewModel(
                sessionManager: sessionManager,
                dropListDataSource: dropListDataSource,
                playlistUser: playlistUser
            )
        )
    }

    // ============================================================
    // MARK: - Body
    // ============================================================

    var body: some View {
        let _ = Self._printChanges()

        DroplistContentView(
            viewModel: viewModel
        )
    }
}

// MARK: - before PlaylistUser

//import SwiftUI
//
//struct DroplistViewInjected: View {
//    
//    @StateObject private var viewModel: DroplistViewModel
//    
//    init(sessionManager: AppSessionManager, dropListDataSource:DropListDataSource) {
//        
//        _viewModel = StateObject(
//            wrappedValue: DroplistViewModel(
//                sessionManager: sessionManager, dropListDataSource: dropListDataSource)
//        )
//    }
//    
//    var body: some View {
//        let _ = Self._printChanges()
//        DroplistContentView(viewModel: viewModel)
//    }
//}










//// ============================================================
//// MARK: - DropTop
//// ============================================================
//
//enum DropTopTag: String, CaseIterable, Identifiable, Hashable {
//    case all
//    case topYear
//    case topDecada
//    case artist
//
//    var id: String {
//        rawValue
//    }
//
//    var title: String {
//        switch self {
//        case .all:
//            return "All"
//        case .topYear:
//            return "Top Year"
//        case .topDecada:
//            return "Top Decada"
//        case .artist:
//            return "Artist"
//        }
//    }
//
//    var firestoreTag: String? {
//        switch self {
//        case .all:
//            return nil
//        case .topYear:
//            return "topYear"
//        case .topDecada:
//            return "topDecada"
//        case .artist:
//            return "artist"
//        }
//    }
//
//    var cacheKey: String {
//        "dropTop.\(rawValue)"
//    }
//}
//
//struct DropTopDoc: Codable {
//    let playlistId: String
//    let title: String
//    let description: String?
//    let coverImageURL: String?
//    let trackCount: Int
//    let createdAt: Date?
//    let tag: String
//}
//
//struct DropTopItem: Identifiable, Hashable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//    let tag: String
//}
//
//struct DropTopPage {
//    let items: [DropTopItem]
//    let lastDocumentSnapshot: DocumentSnapshot?
//    let hasMore: Bool
//}
//
//enum NextDropTopPageResult {
//    case loaded(page: DropTopPage)
//    case noMore
//    case invalidState
//}
//



//// ============================================================
//// MARK: - DropTop Pages Cache
//// ============================================================
//
//actor DropTopPagesCache {
//    private var cache: [String: DropTopPage] = [:]
//    private var loadingKeys: Set<String> = []
//
//    func get(_ key: String) -> DropTopPage? {
//        cache[key]
//    }
//
//    func set(
//        _ key: String,
//        page: DropTopPage
//    ) {
//        cache[key] = page
//    }
//
//    func remove(_ key: String) {
//        cache.removeValue(forKey: key)
//        loadingKeys.remove(key)
//    }
//
//    func reset() {
//        cache.removeAll()
//        loadingKeys.removeAll()
//    }
//
//    func beginLoading(_ key: String) -> Bool {
//        guard !loadingKeys.contains(key) else {
//            return false
//        }
//
//        loadingKeys.insert(key)
//        return true
//    }
//
//    func endLoading(_ key: String) {
//        loadingKeys.remove(key)
//    }
//}

//protocol DropListFirestoreServiceProtocol {
//    func fetchTopSection() async throws -> TopSectionModel
//
//    func fetchInitialLowerPage(
//        for item: CarouselItemType,
//        pageSize: Int
//    ) async throws -> LowerSectionPage
//
//    func fetchNextLowerPage(
//        for item: CarouselItemType,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> LowerSectionPage
//
//    func fetchInitialDropTopPage(
//        for tag: DropTopTag,
//        pageSize: Int
//    ) async throws -> DropTopPage
//
//    func fetchNextDropTopPage(
//        for tag: DropTopTag,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> DropTopPage
//
//    func addTrackToPlaylist(
//        userId: String,
//        track: MyTrackCloud
//    ) async throws
//}
//// ============================================================
//// MARK: - DropTop
//// ============================================================
//
//func fetchInitialDropTopPage(
//    for tag: DropTopTag,
//    pageSize: Int
//) async throws -> DropTopPage {
//
//    try await fetchDropTopPage(
//        tag: tag,
//        after: nil,
//        pageSize: pageSize
//    )
//}
//
//func fetchNextDropTopPage(
//    for tag: DropTopTag,
//    after lastSnapshot: DocumentSnapshot,
//    pageSize: Int
//) async throws -> DropTopPage {
//
//    try await fetchDropTopPage(
//        tag: tag,
//        after: lastSnapshot,
//        pageSize: pageSize
//    )
//}
//
//private func fetchDropTopPage(
//    tag: DropTopTag,
//    after lastSnapshot: DocumentSnapshot?,
//    pageSize: Int
//) async throws -> DropTopPage {
//
//    try await withCheckedThrowingContinuation { continuation in
//
//        var query: Query = db
//            .collection("dropTop")
//
//        // ========================================================
//        // Для All фильтр не используется.
//        // Для остальных вкладок фильтруем по tag.
//        // ========================================================
//
//        if let firestoreTag = tag.firestoreTag {
//            query = query.whereField(
//                "tag",
//                isEqualTo: firestoreTag
//            )
//        }
//
//        query = query
//            .order(
//                by: "createdAt",
//                descending: true
//            )
//            .limit(to: pageSize)
//
//        if let lastSnapshot {
//            query = query.start(
//                afterDocument: lastSnapshot
//            )
//        }
//
//        query.getDocuments { [weak self] snapshot, error in
//            guard let self else {
//                return
//            }
//
//            if let error {
//                continuation.resume(
//                    throwing: FirestoreGetServiceError(
//                        underlying: error,
//                        context: .DropListFirestoreService_fetchTopSection
//                    )
//                )
//
//                return
//            }
//
//            guard let snapshot else {
//                continuation.resume(
//                    throwing: FirestoreGetServiceError(
//                        underlying: AppInternalError.nilSnapshot,
//                        context: .DropListFirestoreService_fetchTopSection
//                    )
//                )
//
//                return
//            }
//
//            // ====================================================
//            // Pagination может вернуть пустую страницу.
//            // Для initial это ошибка.
//            // Для next page это означает конец списка.
//            // ====================================================
//
//            if snapshot.documents.isEmpty {
//                if lastSnapshot != nil {
//                    continuation.resume(
//                        returning: DropTopPage(
//                            items: [],
//                            lastDocumentSnapshot: nil,
//                            hasMore: false
//                        )
//                    )
//                } else {
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: AppInternalError.snapshotIsEmpty,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//                }
//
//                return
//            }
//
//            // ====================================================
//            // Безопасное декодирование документов.
//            // Повреждённый документ просто пропускаем.
//            // ====================================================
//
//            let docs: [DropTopDoc] =
//                snapshot.documents.compactMap { doc in
//
//                    do {
//                        let decoded = try doc.data(
//                            as: DropTopDoc.self
//                        )
//
//                        return DropTopDoc(
//                            playlistId: decoded.playlistId,
//                            title: decoded.title,
//                            description: decoded.description,
//                            coverImageURL: decoded.coverImageURL,
//                            trackCount: decoded.trackCount,
//                            createdAt: decoded.createdAt,
//                            tag: decoded.tag
//                        )
//
//                    } catch {
//                        let _ = self.errorHandler.handle(
//                            error: error,
//                            context:
//                                "fetchDropTopPage | tag: \(tag.rawValue) | documentID: \(doc.documentID)"
//                        )
//
//                        return nil
//                    }
//                }
//
//            if docs.isEmpty {
//                continuation.resume(
//                    throwing: FirestoreGetServiceError(
//                        underlying: AppInternalError.docsIsEmpty,
//                        context: .DropListFirestoreService_fetchTopSection
//                    )
//                )
//
//                return
//            }
//
//            let items: [DropTopItem] =
//                docs.map { playlist in
//
//                    DropTopItem(
//                        id: playlist.playlistId,
//                        title: playlist.title,
//                        imageURL: playlist.coverImageURL.flatMap {
//                            URL(string: $0)
//                        },
//                        tag: playlist.tag
//                    )
//                }
//
//            let last = snapshot.documents.last
//
//            let hasMore =
//                snapshot.documents.count == pageSize
//
//            continuation.resume(
//                returning: DropTopPage(
//                    items: items,
//                    lastDocumentSnapshot: last,
//                    hasMore: hasMore
//                )
//            )
//        }
//    }
//}


// MARK: - Cached State

//private let pagesCache = PagesCache()
//
//private let dropTopPagesCache = DropTopPagesCache()
//private let dropTopPageSize = 20

//// ============================================================
//// MARK: - DropTop
//// ============================================================
//
//func cachedDropTopPage(
//    for tag: DropTopTag
//) async -> DropTopPage? {
//
//    await dropTopPagesCache.get(
//        tag.cacheKey
//    )
//}
//
//func fetchDropTopPage(
//    for tag: DropTopTag
//) async throws -> DropTopPage {
//
//    let page = try await firestoreService.fetchInitialDropTopPage(
//        for: tag,
//        pageSize: dropTopPageSize
//    )
//
//    await dropTopPagesCache.set(
//        tag.cacheKey,
//        page: page
//    )
//
//    return page
//}
//
//func loadNextDropTopPageIfNeeded(
//    for tag: DropTopTag
//) async throws -> NextDropTopPageResult {
//
//    let cacheKey = tag.cacheKey
//
//    guard let currentPage =
//        await dropTopPagesCache.get(cacheKey)
//    else {
//        return .invalidState
//    }
//
//    guard currentPage.hasMore else {
//        return .noMore
//    }
//
//    let canStart =
//        await dropTopPagesCache.beginLoading(cacheKey)
//
//    guard canStart else {
//        return .invalidState
//    }
//
//    guard let lastSnapshot =
//        currentPage.lastDocumentSnapshot
//    else {
//        await dropTopPagesCache.endLoading(cacheKey)
//        return .invalidState
//    }
//
//    do {
//        let nextPage =
//            try await firestoreService.fetchNextDropTopPage(
//                for: tag,
//                after: lastSnapshot,
//                pageSize: dropTopPageSize
//            )
//
//        if nextPage.items.isEmpty {
//            let finishedPage = DropTopPage(
//                items: currentPage.items,
//                lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
//                hasMore: false
//            )
//
//            await dropTopPagesCache.set(
//                cacheKey,
//                page: finishedPage
//            )
//
//            await dropTopPagesCache.endLoading(cacheKey)
//
//            return .noMore
//        }
//
//        let mergedPage = DropTopPage(
//            items: currentPage.items + nextPage.items,
//            lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//            hasMore: nextPage.hasMore
//        )
//
//        await dropTopPagesCache.set(
//            cacheKey,
//            page: mergedPage
//        )
//
//        await dropTopPagesCache.endLoading(cacheKey)
//
//        return .loaded(
//            page: mergedPage
//        )
//
//    } catch {
//        await dropTopPagesCache.endLoading(cacheKey)
//        throw error
//    }
//}
//
//func resetDropTopCache() async {
//    await dropTopPagesCache.reset()
//}


//import SwiftUI
//
//@MainActor
//final class DropTopViewModel: ObservableObject {
//
//    // =========================================================
//    // MARK: Published
//    // =========================================================
//
//    @Published private(set) var viewState: DropTopContentState = .loading
//    @Published private(set) var selectedTag: DropTopTag = .all
//
//    // =========================================================
//    // MARK: Dependencies
//    // =========================================================
//
//    private let dropListDataSource: DropListDataSource
//
//    // =========================================================
//    // MARK: Request control
//    // =========================================================
//
//    private var currentRequestID = UUID()
//    private var currentPaginationTask: Task<Void, Never>?
//
//    // =========================================================
//    // MARK: Init
//    // =========================================================
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // =========================================================
//    // MARK: Setup
//    // =========================================================
//
//    func setupViewModel() async {
//        await load(tag: .all)
//    }
//
//    // =========================================================
//    // MARK: Tag selection
//    // =========================================================
//
//    func selectTag(_ tag: DropTopTag) async {
//        guard selectedTag != tag else {
//            return
//        }
//
//        currentRequestID = UUID()
//        currentPaginationTask?.cancel()
//
//        selectedTag = tag
//
//        await load(tag: tag)
//    }
//
//    // =========================================================
//    // MARK: Initial / cached page
//    // =========================================================
//
//    private func load(tag: DropTopTag) async {
//        viewState = .loading
//
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        // -----------------------------------------------------
//        // Сначала пытаемся получить данные из cache.
//        // -----------------------------------------------------
//
//        if let cachedPage = await dropListDataSource.cachedDropTopPage(
//            for: tag
//        ) {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(cachedPage)
//            return
//        }
//
//        // -----------------------------------------------------
//        // Cache отсутствует → идём в Firestore.
//        // -----------------------------------------------------
//
//        do {
//            let page = try await dropListDataSource.fetchDropTopPage(
//                for: tag
//            )
//
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            viewState = .contentList(page)
//
//        } catch {
//            guard requestID == currentRequestID else {
//                return
//            }
//
//            let userError = dropListDataSource.handleError(error)
//
//            viewState = .error(userError.message)
//        }
//    }
//
//    // =========================================================
//    // MARK: Pagination
//    // =========================================================
//
//    func loadNextPage() {
//        guard case .contentList(let currentPage) = viewState else {
//            return
//        }
//
//        guard currentPage.hasMore else {
//            return
//        }
//
//        currentPaginationTask?.cancel()
//
//        let requestID = UUID()
//        currentRequestID = requestID
//
//        viewState = .contentList(
//            DropTopPage(
//                items: currentPage.items,
//                lastDocumentSnapshot: currentPage.lastDocumentSnapshot,
//                hasMore: true
//            )
//        )
//
//        currentPaginationTask = Task { @MainActor in
//
//            do {
//                let result =
//                    try await dropListDataSource
//                        .loadNextDropTopPageIfNeeded(
//                            for: selectedTag
//                        )
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                switch result {
//
//                case .loaded(let page):
//                    viewState = .contentList(page)
//
//                case .noMore:
//                    let cached =
//                        await dropListDataSource
//                            .cachedDropTopPage(
//                                for: selectedTag
//                            )
//                        ?? latestPage
//
//                    viewState = .contentList(cached)
//
//                case .invalidState:
//                    viewState = .contentList(latestPage)
//                }
//
//            } catch {
//
//                guard requestID == currentRequestID else {
//                    return
//                }
//
//                guard case .contentList(let latestPage) = viewState else {
//                    return
//                }
//
//                let userError = dropListDataSource.handleError(error)
//
//                viewState = .contentList(
//                    DropTopPage(
//                        items: latestPage.items,
//                        lastDocumentSnapshot: latestPage.lastDocumentSnapshot,
//                        hasMore: latestPage.hasMore
//                    )
//                )
//
//                print(
//                    "❌ DropTop pagination error: \(userError.message)"
//                )
//            }
//        }
//    }
//
//    // =========================================================
//    // MARK: Retry
//    // =========================================================
//
//    func retry() async {
//        currentRequestID = UUID()
//        currentPaginationTask?.cancel()
//
//        viewState = .loading
//
//        await dropListDataSource.resetDropTopCache()
//
//        await load(tag: selectedTag)
//    }
//
//    // =========================================================
//    // MARK: Select playlist
//    // =========================================================
//
//    func didSelectPlaylist(_ item: DropTopItem) {
//        // Навигация выполняется в DropTopContentView.
//        // ViewModel только хранит данные экрана.
//    }
//
//    deinit {
//        currentPaginationTask?.cancel()
//        print("deinit DropTopViewModel")
//    }
//}
//
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
//private extension DropTopContentView {
//
//    func openPlaylist(
//        _ item: DropTopItem
//    ) {
//        droplistCoordinator.navigate(
//            to: .topDropDetails(
//                playlistId: item.id,
//                title: item.title,
//                imageURL: item.imageURL
//            )
//        )
//    }
//}
//import SwiftUI
//
//struct DropTopViewInjected: View {
//
//    @StateObject private var viewModel: DropTopViewModel
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        _viewModel = StateObject(
//            wrappedValue: DropTopViewModel(
//                dropListDataSource: dropListDataSource
//            )
//        )
//    }
//
//    var body: some View {
//        DropTopContentView(
//            viewModel: viewModel
//        )
//    }
//}
//
//@ViewBuilder
//func dropViewBuild(
//    page: DroplistFlow
//) -> some View {
//
//    switch page {
//
//    case .droplist:
//        DroplistViewInjected(
//            sessionManager: appSessionManager,
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser
//        )
//
//    case .someDroplistView:
//        SomeView()
//
//    case .allTracks:
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .allTracks,
//            navigationTitle: "All Tracks"
//        )
//
//    case .topDrops:
//        DropTopViewInjected(
//            dropListDataSource: dropListDataSource
//        )
//
//    case .droplistDetails(
//        let playlistId,
//        let details,
//        let title,
//        let imageURL
//    ):
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .droplistDetails(
//                playlistId: playlistId
//            ),
//            navigationTitle: title,
//            details: details,
//            imageURL: imageURL
//        )
//
//    case .topDropDetails(
//        let playlistId,
//        let title,
//        let imageURL
//    ):
//        TracklistViewInjected(
//            dropListDataSource: dropListDataSource,
//            playlistUser: playlistUser,
//            trackType: .topDropDetails(
//                playlistId: playlistId
//            ),
//            navigationTitle: title,
//            imageURL: imageURL
//        )
//    }
//}
