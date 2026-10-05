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













//
//// first DropView
//
//import Foundation
//
//// =================================================
//// TOP SECTION DOCUMENT
//// =================================================
//
//struct TopSectionDoc: Codable {
//    let playlistId: String
//    let title: String
//    let description: String?
//    let coverImageURL: String?
//    let trackCount: Int
//    let createdAt: Date?
//    let orderIndex: Int
//    let artists: [String]?
//}
//
//// =================================================
//// TOP SECTION ITEM
//// =================================================
//
//struct TopItem: Identifiable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//    let artists: [String]
//}
//
//import Foundation
//import FirebaseFirestore
//
//// =================================================
//// DROP TOP TAG
//// =================================================
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
//    // `all` не хранится в Firestore.
//    // Это отдельный режим запроса всей коллекции.
//    var firestoreTag: String? {
//        switch self {
//        case .all:
//            return nil
//        case .topYear, .topDecada, .artist:
//            return rawValue
//        }
//    }
//
//    // Отдельный cache key для каждого фильтра.
//    var cacheKey: String {
//        "dropTop.\(rawValue)"
//    }
//}
//
//// =================================================
//// DROP TOP DOCUMENT
//// =================================================
//
//struct DropTopDoc: Codable {
//    let playlistId: String
//    let title: String
//    let description: String?
//    let coverImageURL: String?
//    let trackCount: Int
//    let createdAt: Date?
//    let orderIndex: Int?
//    let tag: String
//}
//
//// =================================================
//// DROP TOP ITEM
//// =================================================
//
//struct DropTopItem: Identifiable, Hashable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//}
//
//// =================================================
//// DROP TOP PAGE
//// =================================================
//
//struct DropTopPage {
//    let items: [DropTopItem]
//    let hasMore: Bool
//    let lastDocumentSnapshot: DocumentSnapshot?
//}
//
//// =================================================
//// DROP TOP PAGINATION RESULT
//// =================================================
//
//enum NextDropTopPageResult {
//    case loaded(page: DropTopPage)
//    case noMore
//    case invalidState
//}
//
//import Foundation
//
//// =================================================
//// DROP TOP CACHE
//// =================================================
//
//actor DropTopPagesCache {
//    private var cache: [DropTopTag: DropTopPage] = [:]
//
//    func get(_ tag: DropTopTag) -> DropTopPage? {
//        cache[tag]
//    }
//
//    func set(
//        _ tag: DropTopTag,
//        page: DropTopPage
//    ) {
//        cache[tag] = page
//    }
//
//    func remove(_ tag: DropTopTag) {
//        cache.removeValue(forKey: tag)
//    }
//
//    func reset() {
//        cache.removeAll()
//    }
//
//    func contains(_ tag: DropTopTag) -> Bool {
//        cache[tag] != nil
//    }
//}
//
//protocol DropListFirestoreServiceProtocol {
//
//    // =================================================
//    // TOP SECTION
//    // =================================================
//
//    func fetchTopSection() async throws -> TopSectionModel
//
//    // =================================================
//    // LOWER SECTION
//    // =================================================
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
//    // =================================================
//    // PLAYLIST
//    // =================================================
//
//    func addTrackToPlaylist(
//        userId: String,
//        track: MyTrackCloud
//    ) async throws
//
//    // =================================================
//    // DROP TOP
//    // =================================================
//
//    func fetchInitialDropTopPage(
//        tag: DropTopTag,
//        pageSize: Int
//    ) async throws -> DropTopPage
//
//    func fetchNextDropTopPage(
//        tag: DropTopTag,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> DropTopPage
//}
//
//// =================================================
//// DROP TOP
//// =================================================
//
//extension DropListFirestoreService {
//
//    func fetchInitialDropTopPage(
//        tag: DropTopTag,
//        pageSize: Int
//    ) async throws -> DropTopPage {
//        try await fetchDropTopPage(
//            tag: tag,
//            pageSize: pageSize,
//            after: nil
//        )
//    }
//
//    func fetchNextDropTopPage(
//        tag: DropTopTag,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> DropTopPage {
//        try await fetchDropTopPage(
//            tag: tag,
//            pageSize: pageSize,
//            after: lastSnapshot
//        )
//    }
//
//    private func fetchDropTopPage(
//        tag: DropTopTag,
//        pageSize: Int,
//        after lastSnapshot: DocumentSnapshot?
//    ) async throws -> DropTopPage {
//
//        try await withCheckedThrowingContinuation { continuation in
//
//            var query: Query = db
//                .collection("dropTop")
//
//            // `all` = не добавляем whereField.
//            if let firestoreTag = tag.firestoreTag {
//                query = query.whereField(
//                    "tag",
//                    isEqualTo: firestoreTag
//                )
//            }
//
//            query = query
//                .order(
//                    by: "orderIndex",
//                    descending: false
//                )
//                .limit(to: pageSize)
//
//            if let lastSnapshot {
//                query = query.start(
//                    afterDocument: lastSnapshot
//                )
//            }
//
//            query.getDocuments { [weak self] snapshot, error in
//
//                guard let self else {
//                    return
//                }
//
//                if let error {
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: error,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//                    return
//                }
//
//                guard let snapshot else {
//                    continuation.resume(
//                        throwing: FirestoreGetServiceError(
//                            underlying: AppInternalError.nilSnapshot,
//                            context: .DropListFirestoreService_fetchTopSection
//                        )
//                    )
//                    return
//                }
//
//                let docs: [
//                    (
//                        id: String,
//                        data: DropTopDoc
//                    )
//                ] = snapshot.documents.compactMap { document in
//
//                    do {
//                        let decoded = try document.data(
//                            as: DropTopDoc.self
//                        )
//
//                        return (
//                            id: document.documentID,
//                            data: decoded
//                        )
//
//                    } catch {
//
//                        let _ = self.errorHandler.handle(
//                            error: error,
//                            context: "fetchDropTopPage | decode \(document.documentID)"
//                        )
//
//                        return nil
//                    }
//                }
//
//                let items = docs.map { document in
//                    DropTopItem(
//                        id: document.id,
//                        title: document.data.title,
//                        imageURL: document.data.coverImageURL.flatMap {
//                            URL(string: $0)
//                        }
//                    )
//                }
//
//                let page = DropTopPage(
//                    items: items,
//                    hasMore: snapshot.documents.count == pageSize,
//                    lastDocumentSnapshot: snapshot.documents.last
//                )
//
//                continuation.resume(
//                    returning: page
//                )
//            }
//        }
//    }
//}
//
//
//// =================================================
//// DROP TOP
//// =================================================
//
//extension DropListDataSource {
//
//    func cachedDropTopPage(
//        for tag: DropTopTag
//    ) async -> DropTopPage? {
//        await dropTopPagesCache.get(tag)
//    }
//
//    func fetchDropTopPage(
//        for tag: DropTopTag
//    ) async throws -> DropTopPage {
//
//        let page = try await firestoreService.fetchInitialDropTopPage(
//            tag: tag,
//            pageSize: dropTopPageSize
//        )
//
//        await dropTopPagesCache.set(
//            tag,
//            page: page
//        )
//
//        return page
//    }
//
//    func loadNextDropTopPageIfNeeded(
//        for tag: DropTopTag
//    ) async -> NextDropTopPageResult {
//
//        guard let cachedPage = await dropTopPagesCache.get(tag) else {
//            print("⚠️ DropTop pagination — cache is empty: \(tag.rawValue)")
//            return .invalidState
//        }
//
//        guard cachedPage.hasMore else {
//            return .noMore
//        }
//
//        guard let lastSnapshot = cachedPage.lastDocumentSnapshot else {
//            print("⚠️ DropTop pagination — hasMore=true but lastSnapshot=nil")
//            await dropTopPagesCache.set(
//                tag,
//                page: DropTopPage(
//                    items: cachedPage.items,
//                    hasMore: false,
//                    lastDocumentSnapshot: cachedPage.lastDocumentSnapshot
//                )
//            )
//            return .invalidState
//        }
//
//        do {
//            let nextPage = try await firestoreService.fetchNextDropTopPage(
//                tag: tag,
//                after: lastSnapshot,
//                pageSize: dropTopPageSize
//            )
//
//            guard !nextPage.items.isEmpty else {
//                print("⚠️ DropTop pagination — empty page, stopping pagination")
//
//                await dropTopPagesCache.set(
//                    tag,
//                    page: DropTopPage(
//                        items: cachedPage.items,
//                        hasMore: false,
//                        lastDocumentSnapshot: cachedPage.lastDocumentSnapshot
//                    )
//                )
//
//                return .noMore
//            }
//
//            let mergedPage = DropTopPage(
//                items: cachedPage.items + nextPage.items,
//                hasMore: nextPage.hasMore,
//                lastDocumentSnapshot: nextPage.lastDocumentSnapshot
//            )
//
//            await dropTopPagesCache.set(
//                tag,
//                page: mergedPage
//            )
//
//            return .loaded(
//                page: mergedPage
//            )
//
//        } catch {
//            print(
//                "❌ DropTop pagination error: \(error.localizedDescription)"
//            )
//
//            return .invalidState
//        }
//    }
//
//    func resetDropTopCache() async {
//        await dropTopPagesCache.reset()
//    }
//
//    func resetDropTopCache(
//        for tag: DropTopTag
//    ) async {
//        await dropTopPagesCache.remove(tag)
//    }
//}
//
//
//private let dropTopPageSize = 30
//private let dropTopPagesCache = DropTopPagesCache()
//
//import SwiftUI
//
//// =================================================
//// DROP TOP STATE
//// =================================================
//
//enum DropTopState {
//    case loading
//    case content([DropTopItem])
//    case error(String)
//}
//
//// =================================================
//// DROP TOP VIEW MODEL
//// =================================================
//
//@MainActor
//final class DropTopViewModel: ObservableObject {
//
//    @Published private(set) var viewState: DropTopState = .loading
//    @Published private(set) var selectedTag: DropTopTag = .all
//    @Published private(set) var isLoadingNextPage = false
//
//    private let dropListDataSource: DropListDataSource
//
//    private var loadedTags: Set<DropTopTag> = []
//
//    init(
//        dropListDataSource: DropListDataSource
//    ) {
//        self.dropListDataSource = dropListDataSource
//    }
//
//    // =================================================
//    // INITIAL SETUP
//    // =================================================
//
//    func setupViewModel() async {
//        await load(tag: .all)
//    }
//
//    // =================================================
//    // TAG
//    // =================================================
//
//    func selectTag(
//        _ tag: DropTopTag
//    ) async {
//        guard tag != selectedTag else {
//            return
//        }
//
//        selectedTag = tag
//
//        await load(
//            tag: tag
//        )
//    }
//
//    // =================================================
//    // LOAD
//    // =================================================
//
//    private func load(
//        tag: DropTopTag
//    ) async {
//
//        if let cachedPage = await dropListDataSource.cachedDropTopPage(
//            for: tag
//        ) {
//            viewState = .content(
//                cachedPage.items
//            )
//
//            loadedTags.insert(tag)
//            return
//        }
//
//        viewState = .loading
//
//        do {
//            let page = try await dropListDataSource.fetchDropTopPage(
//                for: tag
//            )
//
//            viewState = .content(
//                page.items
//            )
//
//            loadedTags.insert(tag)
//
//        } catch {
//            viewState = .error(
//                error.localizedDescription
//            )
//        }
//    }
//
//    // =================================================
//    // PAGINATION
//    // =================================================
//
//    func loadNextPage() async {
//
//        guard !isLoadingNextPage else {
//            return
//        }
//
//        guard case .content = viewState else {
//            return
//        }
//
//        isLoadingNextPage = true
//
//        defer {
//            isLoadingNextPage = false
//        }
//
//        let result = await dropListDataSource.loadNextDropTopPageIfNeeded(
//            for: selectedTag
//        )
//
//        switch result {
//
//        case .loaded(let page):
//            viewState = .content(
//                page.items
//            )
//
//        case .noMore:
//            break
//
//        case .invalidState:
//            break
//        }
//    }
//
//    // =================================================
//    // RETRY
//    // =================================================
//
//    func retry() async {
//        await dropListDataSource.resetDropTopCache(
//            for: selectedTag
//        )
//
//        await load(
//            tag: selectedTag
//        )
//    }
//}
//
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
//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    @EnvironmentObject var localization: LocalizationService
//
//    @State private var selectedPlaylist: DropTopItem?
//
//    var body: some View {
//        ZStack {
//
//            switch viewModel.viewState {
//
//            case .loading:
//                ProgressView(
//                    Localized.Home.loading.localized()
//                )
//
//            case .content(let items):
//                contentList(
//                    items: items
//                )
//
//            case .error(let message):
//                ContentErrorView(
//                    error: message
//                ) {
//                    Task {
//                        await viewModel.retry()
//                    }
//                }
//            }
//        }
//        .background(AppColors.background)
//        .navigationTitle("DropTop")
//        .navigationBarTitleDisplayMode(.inline)
//        .onFirstAppear {
//            Task {
//                await viewModel.setupViewModel()
//            }
//        }
//        .sheet(item: $selectedPlaylist) { item in
//            // Этот вариант НЕ используется для основной навигации.
//            // Основная навигация выполняется через NavigationLink ниже.
//            EmptyView()
//        }
//    }
//}
//
//// =================================================
//// CONTENT
//// =================================================
//
//private extension DropTopContentView {
//
//    func contentList(
//        items: [DropTopItem]
//    ) -> some View {
//
//        ScrollView {
//            LazyVStack(
//                spacing: 0
//            ) {
//
//                tagSelector
//
//                ForEach(items) { item in
//                    row(item)
//                        .onAppear {
//                            loadNextPageIfNeeded(
//                                item: item,
//                                items: items
//                            )
//                        }
//                }
//
//                if viewModel.isLoadingNextPage {
//                    ProgressView()
//                        .padding(.vertical, 20)
//                }
//            }
//        }
//        .scrollIndicators(.hidden)
//    }
//
//    // =================================================
//    // TAG SELECTOR
//    // =================================================
//
//    var tagSelector: some View {
//
//        ScrollView(
//            .horizontal,
//            showsIndicators: false
//        ) {
//
//            HStack(spacing: 8) {
//
//                ForEach(
//                    DropTopTag.allCases
//                ) { tag in
//
//                    Button {
//                        Task {
//                            await viewModel.selectTag(
//                                tag
//                            )
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(
//                                .subheadline.weight(
//                                    .medium
//                                )
//                            )
//                            .foregroundStyle(
//                                tag == viewModel.selectedTag
//                                    ? .primary
//                                    : .secondary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background(
//                                Capsule()
//                                    .fill(
//                                        tag == viewModel.selectedTag
//                                            ? AppColors.activeColor.opacity(0.18)
//                                            : Color.secondary.opacity(0.10)
//                                    )
//                            )
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 12)
//        }
//    }
//
//    // =================================================
//    // ROW
//    // =================================================
//
//    func row(
//        _ item: DropTopItem
//    ) -> some View {
//
//        NavigationLink {
//            TracklistViewInjected(
//                dropListDataSource: dropListDataSource,
//                playlistUser: playlistUser,
//                trackType: .topDropDetails(
//                    playlistId: item.id
//                ),
//                navigationTitle: item.title,
//                imageURL: item.imageURL
//            )
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
//                        "DropTopItemThumbnail_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                Text(item.title)
//                    .font(.headline)
//                    .foregroundStyle(.primary)
//                    .lineLimit(2)
//                    .multilineTextAlignment(.leading)
//
//                Spacer()
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//
//    // =================================================
//    // PAGINATION TRIGGER
//    // =================================================
//
//    func loadNextPageIfNeeded(
//        item: DropTopItem,
//        items: [DropTopItem]
//    ) {
//
//        guard let index = items.firstIndex(
//            where: {
//                $0.id == item.id
//            }
//        ) else {
//            return
//        }
//
//        // Загружаем следующую страницу,
//        // когда пользователь подходит к последним 5 элементам.
//        guard index >= items.count - 5 else {
//            return
//        }
//
//        Task {
//            await viewModel.loadNextPage()
//        }
//    }
//}
//
//import SwiftUI
//
//struct DropTopContentView: View {
//
//    @ObservedObject var viewModel: DropTopViewModel
//
//    let onOpenPlaylist: (DropTopItem) -> Void
//
//    @EnvironmentObject var localization: LocalizationService
//
//    var body: some View {
//        ZStack {
//
//            switch viewModel.viewState {
//
//            case .loading:
//                ProgressView(
//                    Localized.Home.loading.localized()
//                )
//
//            case .content(let items):
//                contentList(
//                    items: items
//                )
//
//            case .error(let message):
//                ContentErrorView(
//                    error: message
//                ) {
//                    Task {
//                        await viewModel.retry()
//                    }
//                }
//            }
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
//// CONTENT
//// =================================================
//
//private extension DropTopContentView {
//
//    func contentList(
//        items: [DropTopItem]
//    ) -> some View {
//
//        ScrollView {
//            LazyVStack(
//                spacing: 0
//            ) {
//
//                tagSelector
//
//                ForEach(items) { item in
//
//                    row(item)
//                        .onAppear {
//                            loadNextPageIfNeeded(
//                                item: item,
//                                items: items
//                            )
//                        }
//                }
//
//                if viewModel.isLoadingNextPage {
//                    ProgressView()
//                        .padding(.vertical, 20)
//                }
//            }
//        }
//        .scrollIndicators(.hidden)
//    }
//
//    // =================================================
//    // TAG SELECTOR
//    // =================================================
//
//    var tagSelector: some View {
//
//        ScrollView(
//            .horizontal,
//            showsIndicators: false
//        ) {
//
//            HStack(spacing: 8) {
//
//                ForEach(
//                    DropTopTag.allCases
//                ) { tag in
//
//                    Button {
//                        Task {
//                            await viewModel.selectTag(
//                                tag
//                            )
//                        }
//                    } label: {
//                        Text(tag.title)
//                            .font(
//                                .subheadline.weight(
//                                    .medium
//                                )
//                            )
//                            .foregroundStyle(
//                                tag == viewModel.selectedTag
//                                    ? .primary
//                                    : .secondary
//                            )
//                            .padding(.horizontal, 14)
//                            .padding(.vertical, 8)
//                            .background(
//                                Capsule()
//                                    .fill(
//                                        tag == viewModel.selectedTag
//                                            ? AppColors.activeColor.opacity(0.18)
//                                            : Color.secondary.opacity(0.10)
//                                    )
//                            )
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 12)
//        }
//    }
//
//    // =================================================
//    // ROW
//    // =================================================
//
//    func row(
//        _ item: DropTopItem
//    ) -> some View {
//
//        Button {
//            onOpenPlaylist(item)
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
//                        "DropTopItemThumbnail_\(item.id)"
//                )
//                .clipShape(
//                    RoundedRectangle(
//                        cornerRadius: 8
//                    )
//                )
//
//                Text(item.title)
//                    .font(.headline)
//                    .foregroundStyle(.primary)
//                    .lineLimit(2)
//                    .multilineTextAlignment(.leading)
//
//                Spacer()
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//        }
//        .buttonStyle(.plain)
//    }
//
//    // =================================================
//    // PAGINATION
//    // =================================================
//
//    func loadNextPageIfNeeded(
//        item: DropTopItem,
//        items: [DropTopItem]
//    ) {
//
//        guard let index = items.firstIndex(
//            where: {
//                $0.id == item.id
//            }
//        ) else {
//            return
//        }
//
//        guard index >= items.count - 5 else {
//            return
//        }
//
//        Task {
//            await viewModel.loadNextPage()
//        }
//    }
//}
//
//import SwiftUI
//
//struct DropTopViewInjected: View {
//
//    @StateObject private var viewModel: DropTopViewModel
//
//    let onOpenPlaylist: (DropTopItem) -> Void
//
//    init(
//        dropListDataSource: DropListDataSource,
//        onOpenPlaylist: @escaping (DropTopItem) -> Void
//    ) {
//        self.onOpenPlaylist = onOpenPlaylist
//
//        _viewModel = StateObject(
//            wrappedValue: DropTopViewModel(
//                dropListDataSource: dropListDataSource
//            )
//        )
//    }
//
//    var body: some View {
//        DropTopContentView(
//            viewModel: viewModel,
//            onOpenPlaylist: onOpenPlaylist
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
//
//        DropTopViewInjected(
//            dropListDataSource: dropListDataSource
//        ) { [weak self] item in
//
//            self?.topDropItemSelected(
//                item
//            )
//        }
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
//
//private extension ViewBuilderService {
//
//    func topDropItemSelected(
//        _ item: DropTopItem
//    ) {
//        // Этот callback должен передавать navigation
//        // через твой существующий DroplistCoordinator.
//    }
//}


