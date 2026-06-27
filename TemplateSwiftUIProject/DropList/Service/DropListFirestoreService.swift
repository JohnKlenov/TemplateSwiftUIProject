//
//  DropListFirestoreService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 15.05.26.
//



// MARK: - Безопасное декодирование Firestore
//
// 🔐 do-catch + compactMap + errorHandler.handle = 100% защита от крашей
//
// ЧТО ЛОВИТ catch (ошибка → логируем → пропускаем документ):
// • Поле имеет другой тип (String вместо Int)
// • Отсутствует обязательное поле (не Optional)
// • Обязательное поле = null
// • Все поля другие/повреждённые данные
//
// ЧТО НЕ ВЫЗЫВАЕТ ОШИБОК:
// • Лишние поля в Firestore → игнорируются
// • Отсутствует Optional поле → получает nil
// • Optional поле = null → получает nil
//
// ℹ️ Optional защищает только от ОТСУТСТВИЯ поля, но НЕ от неправильного типа!
//    String? при Int значении → catch, документ пропущен



// MARK: - Стратегия защиты от крашей при декодировании Firestore

/*
 
 🔐 ПОЛНАЯ ЗАЩИТА ОТ КРАШЕЙ ПРИ ДЕКОДИРОВАНИИ FIRESTORE ДАННЫХ
 
 Текущая схема: do-catch + compactMap + errorHandler.handle
 Гарантирует: 100% защиту от крашей при ЛЮБЫХ проблемах с данными
 
 ═══════════════════════════════════════════════════════════
 ЧТО ЗАЩИЩАЕТ do-catch (ВСЕГДА попадает в catch, краша нет):
 ═══════════════════════════════════════════════════════════
 
 ✅ Неправильный тип поля
    Пример: trackCount: String вместо Int
    → DecodingError.typeMismatch → catch → логируем → пропускаем документ
 
 ✅ Отсутствует обязательное (не опциональное) поле
    Пример: нет поля playlistId, которое объявлено как String (не String?)
    → DecodingError.keyNotFound → catch → логируем → пропускаем документ
 
 ✅ Поле имеет значение null, но объявлено как не опциональное
    Пример: title: nil в Firestore, а в модели let title: String
    → DecodingError.valueNotFound → catch → логируем → пропускаем документ
 
 ✅ Документ имеет совершенно другую структуру
    Пример: все поля называются по-другому, другой набор полей
    → DecodingError.keyNotFound (по первому обязательному полю) → catch → логируем → пропускаем
 
 ✅ Повреждённые/невалидные данные
    Пример: поле createdAt содержит строку "вчера" вместо Timestamp
    → DecodingError.dataCorrupted → catch → логируем → пропускаем документ
 
 ✅ Вложенные объекты с ошибками
    Пример: поле-словарь внутри документа имеет неправильный тип
    → DecodingError.typeMismatch → catch → логируем → пропускаем документ
 
 ✅ Массивы с неправильными типами элементов
    Пример: tags: [String] приходит как [Int]
    → DecodingError.typeMismatch → catch → логируем → пропускаем документ
 
 
 ═══════════════════════════════════════════════════════════
 ЧТО НЕ ВЫЗЫВАЕТ ОШИБОК (документ успешно декодируется):
 ═══════════════════════════════════════════════════════════
 
 ✅ Документ имеет ЛИШНИЕ поля (которых нет в DTO модели)
    Пример: в Firestore есть поле internalNotes: "test", а в DTO такого поля нет
    → Лишние поля молча ИГНОРИРУЮТСЯ
    → Документ считается валидным
 
 ✅ Отсутствует ОПЦИОНАЛЬНОЕ поле (объявлено как Type?)
    Пример: нет поля description, а в DTO оно let description: String?
    → Поле получает значение nil
    → Документ считается валидным
 
 ✅ Опциональное поле имеет значение null в Firestore
    Пример: description: nil, а в DTO оно let description: String?
    → Поле получает значение nil
    → Документ считается валидным
 
 
 ═══════════════════════════════════════════════════════════
 СМЫСЛ ОПЦИОНАЛЬНЫХ ПОЛЕЙ (Type?) В DTO МОДЕЛЯХ:
 ═══════════════════════════════════════════════════════════
 
 Назначение: указать, что поле МОЖЕТ ОТСУТСТВОВАТЬ в Firestore
           и это НОРМАЛЬНАЯ ситуация, а не ошибка
 
 ❗️ ВАЖНО: Optional защищает ТОЛЬКО от ОТСУТСТВИЯ поля
           Optional НЕ защищает от НЕПРАВИЛЬНОГО ТИПА поля
 
 Когда делать поле опциональным:
 
 1️⃣ Поле не критично для UI
    Пример: coverImageURL: String?
    → Если картинки нет, показываем плейсхолдер
    → Плейлист всё равно показываем пользователю
 
 2️⃣ Поле добавлено недавно, есть старые документы без него
    Пример: createdAt: Date?
    → Старые плейлисты создавались без этого поля
    → Новые имеют дату, старые показываем без неё
 
 3️⃣ Поле по бизнес-логике не обязательно
    Пример: description: String?
    → Админ может не заполнять описание плейлиста
    → Это нормально, показываем без описания
 
 4️⃣ Поле может быть удалено админом в будущем
    Пример: tags: [String]?
    → Если админ решит убрать теги из схемы
    → Старые документы с тегами и новые без — работают
 
 Когда делать поле ОБЯЗАТЕЛЬНЫМ (не опциональным):
 
 1️⃣ Поле критично для идентификации
    Пример: let playlistId: String
    → Без ID плейлист бесполезен, его нельзя открыть
    → Лучше не показывать такой плейлист вообще
 
 2️⃣ Поле критично для UI
    Пример: let title: String
    → Без названия нечего показывать пользователю
    → Лучше пропустить такой плейлист
 
 3️⃣ Поле гарантированно есть во всех документах
    Пример: let orderIndex: Int
    → Админ всегда заполняет это поле
    → Если его нет — это ошибка админа, документ битый
 
 
 ═══════════════════════════════════════════════════════════
 ПРИМЕРЫ ПОВЕДЕНИЯ:
 ═══════════════════════════════════════════════════════════
 
 Модель:
 struct PlaylistDoc: Codable {
     let playlistId: String       // обязательное
     let title: String            // обязательное
     let description: String?     // опциональное
     let trackCount: Int          // обязательное
     let createdAt: Date?         // опциональное
 }
 
 Документ в Firestore: {
   playlistId: "abc123",
   title: "My Playlist",
   description: null,        ← ок, опциональное = nil
   trackCount: "десять",     ← ОШИБКА! String вместо Int → catch
   extraField: "something"   ← ок, лишнее поле игнорируется
 }
 Результат: ❌ Документ попадает в catch, НЕ показывается
 Причина: trackCount имеет неправильный тип
 
 Документ в Firestore: {
   playlistId: "abc123",
   title: "My Playlist",
   trackCount: 10,
   extraField: "something"   ← ок, лишнее поле игнорируется
   // description отсутствует ← ок, опциональное = nil
   // createdAt отсутствует   ← ок, опциональное = nil
 }
 Результат: ✅ Документ успешно декодируется, показывается
 
 Документ в Firestore: {
   // playlistId отсутствует  ← ОШИБКА! Обязательное поле → catch
   title: "My Playlist",
   trackCount: 10
 }
 Результат: ❌ Документ попадает в catch, НЕ показывается
 Причина: отсутствует обязательное поле playlistId
 
 Документ в Firestore: {
   playlistId: "abc123",
   title: null,              ← ОШИБКА! Обязательное поле = null → catch
   trackCount: 10
 }
 Результат: ❌ Документ попадает в catch, НЕ показывается
 Причина: обязательное поле title имеет значение null
 
 
 ═══════════════════════════════════════════════════════════
 СТРАТЕГИЯ ПОЛНОЙ ЗАЩИТЫ:
 ═══════════════════════════════════════════════════════════
 
 1. Всегда используем do-catch + compactMap
    → Ни один документ не вызовет краш
    → Битые документы логируются и пропускаются
 
 2. Критичные поля делаем обязательными
    → Без них документ не имеет смысла
    → Пользователь не увидит "сломанный" контент
 
 3. Некритичные поля делаем опциональными
    → Документ показывается даже без них
    → UI использует fallback значения (плейсхолдеры)
 
 4. Все ошибки логируются через errorHandler
    → Администратор видит проблемные документы
    → Можно быстро найти и исправить битые данные
 
 5. При КАЖДОМ декодировании указываем контекст
    → Понятно в каком методе и какой документ сломан
    → Легко дебажить в продакшене
 
 
 ═══════════════════════════════════════════════════════════
 ИТОГО:
 ═══════════════════════════════════════════════════════════
 
 ✅ do-catch защищает от ВСЕХ возможных несоответствий типов и структуры
 ✅ Optional поля позволяют документу быть валидным без необязательных полей
 ✅ Лишние поля в Firestore игнорируются и не вызывают ошибок
 ✅ Ни при каких обстоятельствах не будет краша из-за данных из Firestore
 ✅ Пользователь видит только полностью валидный контент
 ✅ Администратор получает логи обо всех проблемных документах
 
 */




// реализация новой логики после после изменения в model
//  let hasMore = snapshot.documents.count == pageSize - как работает эта реализация
// заетм в DropListDataSource мы  guard currentPage.hasMore else - // Больше страниц нет ! а если они были добавлены админом и теперь там есть новые данные???


import Foundation
import FirebaseFirestore

struct FirestoreGetServiceError: Error {
    let underlying: Error
    let context: ErrorContext
}

// MARK: - Protocol

protocol DropListFirestoreServiceProtocol {
    func fetchTopSection() async throws -> TopSectionModel
    func fetchCarouselItems() async throws -> [CarouselItem]
    func fetchInitialLowerPage(
        for item: CarouselItem,
        pageSize: Int
    ) async throws -> LowerSectionPage
    func fetchNextLowerPage(
        for item: CarouselItem,
        after lastSnapshot: DocumentSnapshot,
        pageSize: Int
    ) async throws -> LowerSectionPage
}


final class DropListFirestoreService: DropListFirestoreServiceProtocol {

    private let db: Firestore
    private let errorHandler: ErrorDiagnosticsProtocol

    init(
        db: Firestore = Firestore.firestore(),
        errorHandler: ErrorDiagnosticsProtocol
    ) {
        self.db = db
        self.errorHandler = errorHandler
    }

    // MARK: - Top Sections

    func fetchTopSection() async throws -> TopSectionModel {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("topSection")
                .order(by: "orderIndex", descending: false)
                .getDocuments { [weak self] snapshot, error in
                    guard let self else { return }

                    if let error {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: error,
                                context: .DropListFirestoreService_fetchTopSection
                            )
                        )
                        return
                    }

                    guard let snapshot else {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.nilSnapshot,
                                context: .DropListFirestoreService_fetchTopSection
                            )
                        )
                        return
                    }

                    if snapshot.documents.isEmpty {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.emptyResult,
                                context: .DropListFirestoreService_fetchTopSection
                            )
                        )
                        return
                    }

                    // MARK: - Безопасное декодирование Firestore
                    //
                    // 🔐 do-catch + compactMap + errorHandler.handle = 100% защита от крашей
                    //
                    // ЧТО ЛОВИТ catch (ошибка → логируем → пропускаем документ):
                    // • Поле имеет другой тип (String вместо Int)
                    // • Отсутствует обязательное поле (не Optional)
                    // • Обязательное поле = null
                    // • Все поля другие/повреждённые данные
                    //
                    // ЧТО НЕ ВЫЗЫВАЕТ ОШИБОК:
                    // • Лишние поля в Firestore → игнорируются
                    // • Отсутствует Optional поле → получает nil
                    // • Optional поле = null → получает nil
                    //
                    // ℹ️ Optional защищает только от ОТСУТСТВИЯ поля, но НЕ от неправильного типа!
                    //    String? при Int значении → catch, документ пропущен
                    let docs: [(id: String, data: TopSectionDoc)] = snapshot.documents.compactMap { doc in
                        do {
                            let decoded = try doc.data(as: TopSectionDoc.self)
                            return (doc.documentID, decoded)
                        } catch {
                            let _ = self.errorHandler.handle(
                                error: error,
                                context: "fetchTopSection | decode \(doc.documentID)"
                            )
                            return nil
                        }
                    }

                    if docs.isEmpty {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.emptyResult,
                                context: .DropListFirestoreService_fetchTopSection
                            )
                        )
                        return
                    }

                    let items: [TopItem] = docs.map { playlist in
                        TopItem(
                            id: playlist.id,
                            title: playlist.data.title,
                            imageURL: playlist.data.coverImageURL.flatMap { URL(string: $0) }
                        )
                    }

                    let sectionModel = TopSectionModel(
                        id: "top_section",
                        title: "Top Section",
                        items: items
                    )

                    continuation.resume(returning: sectionModel)
                }
        }
    }

    // MARK: - Carousel Items


    func fetchCarouselItems() async throws -> [CarouselItem] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("carouselItems")
                .order(by: "orderIndex", descending: false) // сортировка по возрастанию
                .getDocuments { [weak self] snapshot, error in
                    guard let self else { return }

                    if let error {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: error,
                                context: .DropListFirestoreService_fetchCarouselItems
                            )
                        )
                        return
                    }

                    guard let snapshot else {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.nilSnapshot,
                                context: .DropListFirestoreService_fetchCarouselItems
                            )
                        )
                        return
                    }

                    if snapshot.documents.isEmpty {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.emptyResult,
                                context: .DropListFirestoreService_fetchCarouselItems
                            )
                        )
                        return
                    }

                    let items: [CarouselItem] = snapshot.documents.compactMap { doc in
                        do {
                            let decoded = try doc.data(as: CarouselDoc.self)
                            return CarouselItem(
                                id: decoded.id,
                                title: decoded.title,
                                type: decoded.type
                            )
                        } catch {
                            let _ = self.errorHandler.handle(
                                error: error,
                                context: "\(ErrorContext.DropListFirestoreService_fetchCarouselItems.rawValue) | documentID: \(doc.documentID)"
                            )
                            return nil
                        }
                    }

                    if items.isEmpty {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.emptyResult,
                                context: .DropListFirestoreService_fetchCarouselItems
                            )
                        )
                        return
                    }

                    continuation.resume(returning: items)
                }
        }
    }


    // MARK: - Lower Section (Initial Page)

    func fetchInitialLowerPage(
        for item: CarouselItem,
        pageSize: Int
    ) async throws -> LowerSectionPage {
        switch item.type {
        case .droplist:
            return try await fetchPlaylistsPage(
                after: nil,
                pageSize: pageSize
            )

        case .allTracks:
            return try await fetchTracksPage(
                tag: nil,
                pageSize: pageSize,
                after: nil
            )

        case .gym, .party, .rnb:
            return try await fetchTracksPage(
                tag: item.type.rawValue,
                pageSize: pageSize,
                after: nil
            )
        }
    }

    // MARK: - Lower Section (Next Page)

    func fetchNextLowerPage(
        for item: CarouselItem,
        after lastSnapshot: DocumentSnapshot,
        pageSize: Int
    ) async throws -> LowerSectionPage {
        switch item.type {
        case .droplist:
            return try await fetchPlaylistsPage(
                after: lastSnapshot,
                pageSize: pageSize
            )

        case .allTracks:
            return try await fetchTracksPage(
                tag: nil,
                pageSize: pageSize,
                after: lastSnapshot
            )

        case .gym, .party, .rnb:
            return try await fetchTracksPage(
                tag: item.type.rawValue,
                pageSize: pageSize,
                after: lastSnapshot
            )
        }
    }

    // MARK: - Private: Playlists Page (droplist)

    private func fetchPlaylistsPage(
        after lastSnapshot: DocumentSnapshot?,
        pageSize: Int
    ) async throws -> LowerSectionPage {

        try await withCheckedThrowingContinuation { continuation in
            var query: Query = db.collection("droplist")
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)

            if let lastSnapshot {
                query = query.start(afterDocument: lastSnapshot)
            }

            query.getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: error,
                            context: .DropListFirestoreService_fetchPlaylistsPage
                        )
                    )
                    return
                }

                guard let snapshot else {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: AppInternalError.nilSnapshot,
                            context: .DropListFirestoreService_fetchPlaylistsPage
                        )
                    )
                    return
                }

                if snapshot.documents.isEmpty {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: AppInternalError.emptyResult,
                            context: .DropListFirestoreService_fetchPlaylistsPage
                        )
                    )
                    return
                }

                let docs: [PlaylistDoc] = snapshot.documents.compactMap { doc in
                    do {
                        let decoded = try doc.data(as: PlaylistDoc.self)

                        return PlaylistDoc(
                            playlistId: decoded.playlistId,
                            title: decoded.title,
                            description: decoded.description,
                            coverImageURL: decoded.coverImageURL,
                            trackCount: decoded.trackCount,
                            createdAt: decoded.createdAt
                        )

                    } catch {
                        let _ = self.errorHandler.handle(
                            error: error,
                            context: "\(ErrorContext.DropListFirestoreService_fetchPlaylistsPage.rawValue) | documentID: \(doc.documentID)"
                        )
                        return nil
                    }
                }

                if docs.isEmpty {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: AppInternalError.emptyResult,
                            context: .DropListFirestoreService_fetchPlaylistsPage
                        )
                    )
                    return
                }

                let items: [LowerItem] = docs.map { playlist in
                    let coverURL = playlist.coverImageURL.flatMap { URL(string: $0) }

                    return LowerItem(
                        id: playlist.playlistId,
                        title: playlist.title,
                        subtitle: playlist.description,
                        coverImageURL: coverURL,
                        thumbnailURL: nil,
                        durationISO8601: nil,
                        trackCount: playlist.trackCount,
                        isTrack: false
                    )
                }

                let last = snapshot.documents.last
                let hasMore = snapshot.documents.count == pageSize

                continuation.resume(
                    returning: LowerSectionPage(
                        items: items,
                        lastDocumentSnapshot: last,
                        hasMore: hasMore
                    )
                )
            }
        }
    }

    // MARK: - Private: Tracks Page (dropTracks)

    /// Firestore использует оффлайн‑кэш по умолчанию.
    /// Поэтому поведение getDocuments зависит от состояния сети:
    /// • Сеть есть → возвращаются актуальные online‑данные
    /// • Сети нет, но есть кэш → возвращаются cached‑данные без ошибки
    /// • Сети нет и кэша нет → генерируется ошибка
    ///
    /// Это нормальное поведение Firestore SDK: запросы не гарантируют онлайн‑результат,
    /// а автоматически подставляют локальный кэш, если сеть недоступна.

    private func fetchTracksPage(
        tag: String?,
        pageSize: Int,
        after lastSnapshot: DocumentSnapshot?
    ) async throws -> LowerSectionPage {

        try await withCheckedThrowingContinuation { continuation in
            var query: Query = db.collection("dropTracks")

            if let tag {
                query = query.whereField("tags", arrayContains: tag)
            }

            query = query
                .order(by: "createdAt", descending: true)
                .limit(to: pageSize)

            if let lastSnapshot {
                query = query.start(afterDocument: lastSnapshot)
            }

            query.getDocuments { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: error,
                            context: .DropListFirestoreService_fetchTracksPage
                        )
                    )
                    return
                }

                guard let snapshot else {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: AppInternalError.nilSnapshot,
                            context: .DropListFirestoreService_fetchTracksPage
                        )
                    )
                    return
                }

                if snapshot.documents.isEmpty {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: AppInternalError.emptyResult,
                            context: .DropListFirestoreService_fetchTracksPage
                        )
                    )
                    return
                }

                print("snapshot.documents.count = \(snapshot.documents.count)")

                let docs: [TrackDoc] = snapshot.documents.compactMap { doc in
                    do {
                        var track = try doc.data(as: TrackDoc.self)
                        track = TrackDoc(
                            id: doc.documentID,
                            videoId: track.videoId,
                            title: track.title,
                            artist: track.artist,
                            thumbnailURL: track.thumbnailURL,
                            durationISO8601: track.durationISO8601,
                            tags: track.tags,
                            playlists: track.playlists,
                            createdAt: track.createdAt,
                            searchKeywords: track.searchKeywords
                        )
                        return track
                    } catch {
                        let _ = self.errorHandler.handle(
                            error: error,
                            context: "\(ErrorContext.DropListFirestoreService_fetchTracksPage.rawValue) | tags: \(tag ?? "allTracks") | documentID: \(doc.documentID)"
                        )
                        return nil
                    }
                }

                if docs.isEmpty {
                    continuation.resume(
                        throwing: FirestoreGetServiceError(
                            underlying: AppInternalError.emptyResult,
                            context: .DropListFirestoreService_fetchTracksPage
                        )
                    )
                    print("private func fetchTracksPage - docs.isEmpty - error ")
                    return
                }

                let items: [LowerItem] = docs.map { track in
                    let thumbURL = track.thumbnailURL.flatMap { URL(string: $0) }

                    return LowerItem(
                        id: track.videoId,
                        title: track.title,
                        subtitle: track.artist,
                        coverImageURL: nil,
                        thumbnailURL: thumbURL,
                        durationISO8601: track.durationISO8601,
                        trackCount: nil,
                        isTrack: true
                    )
                }

                let last = snapshot.documents.last
                let hasMore = snapshot.documents.count == pageSize

                continuation.resume(
                    returning: LowerSectionPage(
                        items: items,
                        lastDocumentSnapshot: last,
                        hasMore: hasMore
                    )
                )
            }
        }
    }
    
    // MARK: - Fetch Tracks for Top Section Playlist

//    func fetchTopSectionTracks(for playlistId: String) async throws -> [TopSectionTrackDoc] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("topSections")
//                .document(playlistId)
//                .collection("tracks")
//                .order(by: "orderIndex", descending: false)
//                .getDocuments { [weak self] snapshot, error in
//                    guard let self else { return }
//
//                    if let error {
//                        continuation.resume(
//                            throwing: FirestoreGetServiceError(
//                                underlying: error,
//                                context: .DropListFirestoreService_fetchTopSectionTracks
//                            )
//                        )
//                        return
//                    }
//
//                    guard let snapshot else {
//                        continuation.resume(
//                            throwing: FirestoreGetServiceError(
//                                underlying: AppInternalError.nilSnapshot,
//                                context: .DropListFirestoreService_fetchTopSectionTracks
//                            )
//                        )
//                        return
//                    }
//
//                    if snapshot.documents.isEmpty {
//                        continuation.resume(returning: [])
//                        return
//                    }
//
//                    let tracks: [TopSectionTrackDoc] = snapshot.documents.compactMap { doc in
//                        do {
//                            var track = try doc.data(as: TopSectionTrackDoc.self)
//                            track = TopSectionTrackDoc(
//                                id: doc.documentID,
//                                videoId: track.videoId,
//                                title: track.title,
//                                artist: track.artist,
//                                thumbnailURL: track.thumbnailURL,
//                                durationISO8601: track.durationISO8601,
//                                orderIndex: track.orderIndex,
//                                createdAt: track.createdAt
//                            )
//                            return track
//                        } catch {
//                            let _ = self.errorHandler.handle(
//                                error: error,
//                                context: "fetchTopSectionTracks | decode \(doc.documentID)"
//                            )
//                            return nil
//                        }
//                    }
//
//                    continuation.resume(returning: tracks)
//                }
//        }
//    }

}






//    func fetchTopSections() async throws -> [TopSectionModel] {
//        try await withCheckedThrowingContinuation { continuation in
//            db.collection("topSections")
//                .order(by: "createdAt", descending: true)
//                .getDocuments { [weak self] snapshot, error in
//                    guard let self else { return }
//
//                    if let error {
//                        continuation.resume(
//                            throwing: FirestoreGetServiceError(
//                                underlying: error,
//                                context: .DropListFirestoreService_fetchTopSections
//                            )
//                        )
//                        return
//                    }
//
//                    guard let snapshot else {
//                        continuation.resume(
//                            throwing: FirestoreGetServiceError(
//                                underlying: AppInternalError.nilSnapshot,
//                                context: .DropListFirestoreService_fetchTopSections
//                            )
//                        )
//                        return
//                    }
//
//                    if snapshot.documents.isEmpty {
//                        continuation.resume(
//                            throwing: FirestoreGetServiceError(
//                                underlying: AppInternalError.emptyResult,
//                                context: .DropListFirestoreService_fetchTopSections
//                            )
//                        )
//                        return
//                    }
//
//                    let docs: [PlaylistDoc] = snapshot.documents.compactMap { doc in
//                        do {
//                            var playlist = try doc.data(as: PlaylistDoc.self)
//                            playlist = PlaylistDoc(
//                                id: doc.documentID,
//                                playlistId: playlist.playlistId,
//                                title: playlist.title,
//                                description: playlist.description,
//                                coverImageURL: playlist.coverImageURL,
//                                trackCount: playlist.trackCount,
//                                createdAt: playlist.createdAt
//                            )
//                            return playlist
//                        } catch {
//                            let _ = self.errorHandler.handle(
//                                error: error,
//                                context: "\(ErrorContext.DropListFirestoreService_fetchTopSections.rawValue) | documentID: \(doc.documentID)"
//                            )
//                            return nil
//                        }
//                    }
//
//                    if docs.isEmpty {
//                        continuation.resume(
//                            throwing: FirestoreGetServiceError(
//                                underlying: AppInternalError.emptyResult,
//                                context: .DropListFirestoreService_fetchTopSections
//                            )
//                        )
//                        return
//                    }
//
//                    let sections: [TopSectionModel] = docs.map { playlist in
//                        let coverURL = playlist.coverImageURL.flatMap { URL(string: $0) }
//                        return TopSectionModel(
//                            id: playlist.playlistId,
//                            title: playlist.title,
//                            items: [
//                                TopItem(
//                                    id: playlist.playlistId,
//                                    title: playlist.title,
//                                    imageURL: coverURL
//                                )
//                            ]
//                        )
//                    }
//
//                    continuation.resume(returning: sections)
//                }
//        }
//    }


// MARK: - before return FirestoreGetServiceError



//import Foundation
//import FirebaseFirestore
//
//// MARK: - Protocol
//
//protocol DropListFirestoreServiceProtocol {
//    func fetchTopSections() async throws -> [TopSectionModel]
//    func fetchCarouselItems() async throws -> [CarouselItem]
//    func fetchInitialLowerPage(
//        for item: CarouselItem,
//        pageSize: Int
//    ) async throws -> LowerSectionPage
//    func fetchNextLowerPage(
//        for item: CarouselItem,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> LowerSectionPage
//}
//
//// MARK: - Service
//
//final class DropListFirestoreService: DropListFirestoreServiceProtocol {
//
//    private let db: Firestore
//
//    init(db: Firestore = Firestore.firestore()) {
//        self.db = db
//    }
//
//    // MARK: - Top Sections
//
//    func fetchTopSections() async throws -> [TopSectionModel] {
//        // Пока заглушка — можно позже привязать к коллекции, например "top_sections"
//        return []
//    }
//
//    // MARK: - Carousel Items
//
//    func fetchCarouselItems() async throws -> [CarouselItem] {
//        // Статическая карусель (можно вынести в Firestore при желании)
//        return [
//            CarouselItem(id: "droplist",   title: "Droplist",                type: .droplist),
//            CarouselItem(id: "all_tracks", title: "All tracks for Droplist", type: .allTracks),
//            CarouselItem(id: "gym",        title: "GYM",                     type: .gym),
//            CarouselItem(id: "party",      title: "Party",                   type: .party),
//            CarouselItem(id: "rnb",        title: "R&B",                     type: .rnb)
//        ]
//    }
//
//    // MARK: - Lower Section (Initial Page)
//
//    func fetchInitialLowerPage(
//        for item: CarouselItem,
//        pageSize: Int
//    ) async throws -> LowerSectionPage {
//        switch item.type {
//        case .droplist:
//            return try await fetchPlaylistsPage(
//                after: nil,
//                pageSize: pageSize
//            )
//
//        case .allTracks:
//            return try await fetchTracksPage(
//                tag: nil,
//                pageSize: pageSize,
//                after: nil
//            )
//
//        case .gym, .party, .rnb:
//            return try await fetchTracksPage(
//                tag: item.type.rawValue,   // "gym", "party", "rnb"
//                pageSize: pageSize,
//                after: nil
//            )
//        }
//    }
//
//    // MARK: - Lower Section (Next Page)
//
//    func fetchNextLowerPage(
//        for item: CarouselItem,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> LowerSectionPage {
//        switch item.type {
//        case .droplist:
//            return try await fetchPlaylistsPage(
//                after: lastSnapshot,
//                pageSize: pageSize
//            )
//
//        case .allTracks:
//            return try await fetchTracksPage(
//                tag: nil,
//                pageSize: pageSize,
//                after: lastSnapshot
//            )
//
//        case .gym, .party, .rnb:
//            return try await fetchTracksPage(
//                tag: item.type.rawValue,
//                pageSize: pageSize,
//                after: lastSnapshot
//            )
//        }
//    }
//
//    // MARK: - Private: Playlists Page (droplist)
//
//    private func fetchPlaylistsPage(
//        after lastSnapshot: DocumentSnapshot?,
//        pageSize: Int
//    ) async throws -> LowerSectionPage {
//
//        var query: Query = db.collection("droplist")
//            .order(by: "createdAt", descending: true)
//            .limit(to: pageSize)
//
//        if let lastSnapshot {
//            query = query.start(afterDocument: lastSnapshot)
//        }
//
//        let snapshot = try await query.getDocuments()
//
//        let docs: [PlaylistDoc] = snapshot.documents.compactMap { doc in
//            do {
//                var playlist = try doc.data(as: PlaylistDoc.self)
//                // Пробрасываем Firestore ID
//                playlist = PlaylistDoc(
//                    id: doc.documentID,
//                    playlistId: playlist.playlistId,
//                    title: playlist.title,
//                    description: playlist.description,
//                    coverImageURL: playlist.coverImageURL,
//                    trackCount: playlist.trackCount,
//                    createdAt: playlist.createdAt
//                )
//                return playlist
//            } catch {
//                print("Playlist decode error: \(error)")
//                return nil
//            }
//        }
//
//        let items: [LowerItem] = docs.map { playlist in
//            let coverURL = playlist.coverImageURL.flatMap { URL(string: $0) }
//
//            return LowerItem(
//                id: playlist.playlistId,          // бизнес-ID (YouTube)
//                title: playlist.title,
//                subtitle: playlist.description,
//                coverImageURL: coverURL,
//                thumbnailURL: nil,
//                durationISO8601: nil,
//                trackCount: playlist.trackCount,
//                isTrack: false
//            )
//        }
//
//        let last = snapshot.documents.last
//        let hasMore = snapshot.documents.count == pageSize
//
//        return LowerSectionPage(
//            items: items,
//            lastDocumentSnapshot: last,
//            hasMore: hasMore
//        )
//    }
//
//    // MARK: - Private: Tracks Page (dropTracks)
//
//    private func fetchTracksPage(
//        tag: String?,
//        pageSize: Int,
//        after lastSnapshot: DocumentSnapshot?
//    ) async throws -> LowerSectionPage {
//
//        var query: Query = db.collection("dropTracks")
//
//        if let tag {
//            query = query.whereField("tags", arrayContains: tag)
//        }
//
//        query = query
//            .order(by: "createdAt", descending: true)
//            .limit(to: pageSize)
//
//        if let lastSnapshot {
//            query = query.start(afterDocument: lastSnapshot)
//        }
//
//        let snapshot = try await query.getDocuments()
//
//        let docs: [TrackDoc] = snapshot.documents.compactMap { doc in
//            do {
//                var track = try doc.data(as: TrackDoc.self)
//                track = TrackDoc(
//                    id: doc.documentID,
//                    videoId: track.videoId,
//                    title: track.title,
//                    artist: track.artist,
//                    thumbnailURL: track.thumbnailURL,
//                    durationISO8601: track.durationISO8601,
//                    tags: track.tags,
//                    playlists: track.playlists,
//                    createdAt: track.createdAt,
//                    searchKeywords: track.searchKeywords
//                )
//                return track
//            } catch {
//                print("Track decode error: \(error)")
//                return nil
//            }
//        }
//
//        let items: [LowerItem] = docs.map { track in
//            let thumbURL = track.thumbnailURL.flatMap { URL(string: $0) }
//
//            return LowerItem(
//                id: track.videoId,
//                title: track.title,
//                subtitle: track.artist,
//                coverImageURL: nil,
//                thumbnailURL: thumbURL,
//                durationISO8601: track.durationISO8601,
//                trackCount: nil,
//                isTrack: true
//            )
//        }
//
//        let last = snapshot.documents.last
//        let hasMore = snapshot.documents.count == pageSize
//
//        return LowerSectionPage(
//            items: items,
//            lastDocumentSnapshot: last,
//            hasMore: hasMore
//        )
//    }
//}










// MARK: - before adaption models



//// MARK: -  DropListFirestoreServiceProtocol
//
//
//import Foundation
//import FirebaseFirestore
//
//protocol DropListFirestoreServiceProtocol {
//   
//   /// Верхняя секция (баннеры, промо и т.п.)
//   func fetchTopSections() async throws -> [TopSectionModel]
//   
//   /// Элементы горизонтальной карусели (Droplist, All tracks, GYM, Party...)
//   func fetchCarouselItems() async throws -> [CarouselItem]
//   
//   /// Первая страница нижней секции для выбранного item
//   func fetchInitialLowerPage(
//       for item: CarouselItem,
//       pageSize: Int
//   ) async throws -> LowerSectionPage
//   
//   /// Следующая страница нижней секции для выбранного item
//   func fetchNextLowerPage(
//       for item: CarouselItem,
//       after lastSnapshot: DocumentSnapshot,
//       pageSize: Int
//   ) async throws -> LowerSectionPage
//}
//
//
//
//
//final class DropListFirestoreService: DropListFirestoreServiceProtocol {
//   
//   private let db: Firestore
//   
//   init(db: Firestore = Firestore.firestore()) {
//       self.db = db
//   }
//   
//   // MARK: - Top Sections
//   
//   func fetchTopSections() async throws -> [TopSectionModel] {
//       // Здесь можно сделать реальный запрос к коллекции, например "top_sections"
//       // Пока оставим как заглушку / пример.
//       return []
//   }
//   
//   // MARK: - Carousel Items
//   
//   func fetchCarouselItems() async throws -> [CarouselItem] {
//       // В простейшем варианте карусель статична и не хранится в Firestore.
//       // Если захочешь — можно вынести в коллекцию "drop_carousel".
//       return [
//           CarouselItem(id: "droplist",   title: "Droplist",              type: .droplist),
//           CarouselItem(id: "all_tracks", title: "All tracks for Droplist", type: .allTracks),
//           CarouselItem(id: "gym",        title: "GYM",                   type: .gym),
//           CarouselItem(id: "party",      title: "Party",                 type: .party)
//       ]
//   }
//   
//   // MARK: - Lower Section (Initial Page)
//   
//   func fetchInitialLowerPage(
//       for item: CarouselItem,
//       pageSize: Int
//   ) async throws -> LowerSectionPage {
//       switch item.type {
//       case .droplist:
//           return try await fetchPlaylistsPage(
//               after: nil,
//               pageSize: pageSize
//           )
//           
//       case .allTracks:
//           return try await fetchTracksPage(
//               tag: nil,
//               pageSize: pageSize,
//               after: nil
//           )
//           
//       case .gym, .party, .rnb:
//           return try await fetchTracksPage(
//               tag: item.type.rawValue,   // "gym", "party", "rnb"
//               pageSize: pageSize,
//               after: nil
//           )
//       }
//   }
//   
//   // MARK: - Lower Section (Next Page)
//   
//   func fetchNextLowerPage(
//       for item: CarouselItem,
//       after lastSnapshot: DocumentSnapshot,
//       pageSize: Int
//   ) async throws -> LowerSectionPage {
//       switch item.type {
//       case .droplist:
//           return try await fetchPlaylistsPage(
//               after: lastSnapshot,
//               pageSize: pageSize
//           )
//           
//       case .allTracks:
//           return try await fetchTracksPage(
//               tag: nil,
//               pageSize: pageSize,
//               after: lastSnapshot
//           )
//           
//       case .gym, .party, .rnb:
//           return try await fetchTracksPage(
//               tag: item.type.rawValue,
//               pageSize: pageSize,
//               after: lastSnapshot
//           )
//       }
//   }
//   
//   // MARK: - Private: Playlists Page
//   
//   private func fetchPlaylistsPage(
//       after lastSnapshot: DocumentSnapshot?,
//       pageSize: Int
//   ) async throws -> LowerSectionPage {
//       
//       var query: Query = db.collection("droplist")
//           .order(by: "createdAt", descending: true)
//           .limit(to: pageSize)
//       
//       if let lastSnapshot {
//           query = query.start(afterDocument: lastSnapshot)
//       }
//       
//       let snapshot = try await query.getDocuments()
//       
//       let docs: [PlaylistDoc] = snapshot.documents.compactMap { doc in
//           do {
//               var playlist = try doc.data(as: PlaylistDoc.self)
//               // Пробрасываем Firestore ID в модель
//               playlist = PlaylistDoc(
//                   id: doc.documentID,
//                   playlistId: playlist.playlistId,
//                   title: playlist.title,
//                   description: playlist.description,
//                   curatedTags: playlist.curatedTags,
//                   coverImageURL: playlist.coverImageURL,
//                   sampleThumbnails: playlist.sampleThumbnails,
//                   trackCount: playlist.trackCount,
//                   createdAt: playlist.createdAt
//               )
//               return playlist
//           } catch {
//               print("Playlist decode error: \(error)")
//               return nil
//           }
//       }
//       
//       let items: [LowerItem] = docs.map { playlist in
//           let coverURL = playlist.coverImageURL.flatMap { URL(string: $0) }
//           let thumbs: [URL] = (playlist.sampleThumbnails ?? [])
//               .compactMap { URL(string: $0) }
//           
//           return LowerItem(
//               id: playlist.playlistId,          // бизнес-ID (YouTube)
//               title: playlist.title,
//               subtitle: playlist.description,
//               coverImageURL: coverURL,
//               sampleThumbnails: thumbs,
//               trackCount: playlist.trackCount,
//               isTrack: false
//           )
//       }
//       
//       let last = snapshot.documents.last
//       let hasMore = snapshot.documents.count == pageSize
//       
//       return LowerSectionPage(
//           items: items,
//           lastDocumentSnapshot: last,
//           hasMore: hasMore
//       )
//   }
//   
//   // MARK: - Private: Tracks Page (All / by Tag)
//   
//   private func fetchTracksPage(
//       tag: String?,
//       pageSize: Int,
//       after lastSnapshot: DocumentSnapshot?
//   ) async throws -> LowerSectionPage {
//       
//       var query: Query = db.collection("dropTracks")
//
//       if let tag {
//           query = query.whereField("tags", arrayContains: tag)
//       }
//       
//       query = query
//           .order(by: "createdAt", descending: true)
//           .limit(to: pageSize)
//       
//       if let lastSnapshot {
//           query = query.start(afterDocument: lastSnapshot)
//       }
//       
//       let snapshot = try await query.getDocuments()
//       
//       let docs: [TrackDoc] = snapshot.documents.compactMap { doc in
//           do {
//               var track = try doc.data(as: TrackDoc.self)
//               track = TrackDoc(
//                   id: doc.documentID,
//                   videoId: track.videoId,
//                   title: track.title,
//                   artist: track.artist,
//                   thumbnailURL: track.thumbnailURL,
//                   durationISO8601: track.durationISO8601,
//                   tags: track.tags,
//                   playlists: track.playlists,
//                   createdAt: track.createdAt,
//                   searchKeywords: track.searchKeywords
//               )
//               return track
//           } catch {
//               print("Track decode error: \(error)")
//               return nil
//           }
//       }
//       
//       let items: [LowerItem] = docs.map { track in
//           let thumbURL = track.thumbnailURL.flatMap { URL(string: $0) }
//           
//           return LowerItem(
//               id: track.videoId,
//               title: track.title,
//               subtitle: track.artist,
//               coverImageURL: nil,
//               sampleThumbnails: thumbURL.map { [$0] } ?? [],
//               trackCount: nil,
//               isTrack: true
//           )
//       }
//       
//       let last = snapshot.documents.last
//       let hasMore = snapshot.documents.count == pageSize
//       
//       return LowerSectionPage(
//           items: items,
//           lastDocumentSnapshot: last,
//           hasMore: hasMore
//       )
//   }
//}
//
//
