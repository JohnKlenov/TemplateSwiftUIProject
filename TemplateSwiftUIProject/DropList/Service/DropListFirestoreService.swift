//
//  DropListFirestoreService.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 15.05.26.
//



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
    func fetchTopSections() async throws -> [TopSectionModel]
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


    func fetchTopSections() async throws -> [TopSectionModel] {
        try await withCheckedThrowingContinuation { continuation in
            db.collection("topSections")
                .order(by: "createdAt", descending: true)
                .getDocuments { [weak self] snapshot, error in
                    guard let self else { return }

                    if let error {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: error,
                                context: .DropListFirestoreService_fetchTopSections
                            )
                        )
                        return
                    }

                    guard let snapshot else {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.nilSnapshot,
                                context: .DropListFirestoreService_fetchTopSections
                            )
                        )
                        return
                    }

                    if snapshot.documents.isEmpty {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.emptyResult,
                                context: .DropListFirestoreService_fetchTopSections
                            )
                        )
                        return
                    }

                    let docs: [PlaylistDoc] = snapshot.documents.compactMap { doc in
                        do {
                            var playlist = try doc.data(as: PlaylistDoc.self)
                            playlist = PlaylistDoc(
                                id: doc.documentID,
                                playlistId: playlist.playlistId,
                                title: playlist.title,
                                description: playlist.description,
                                coverImageURL: playlist.coverImageURL,
                                trackCount: playlist.trackCount,
                                createdAt: playlist.createdAt
                            )
                            return playlist
                        } catch {
                            let _ = self.errorHandler.handle(
                                error: error,
                                context: "\(ErrorContext.DropListFirestoreService_fetchTopSections.rawValue) | documentID: \(doc.documentID)"
                            )
                            return nil
                        }
                    }

                    if docs.isEmpty {
                        continuation.resume(
                            throwing: FirestoreGetServiceError(
                                underlying: AppInternalError.emptyResult,
                                context: .DropListFirestoreService_fetchTopSections
                            )
                        )
                        return
                    }

                    let sections: [TopSectionModel] = docs.map { playlist in
                        let coverURL = playlist.coverImageURL.flatMap { URL(string: $0) }
                        return TopSectionModel(
                            id: playlist.playlistId,
                            title: playlist.title,
                            items: [
                                TopItem(
                                    id: playlist.playlistId,
                                    title: playlist.title,
                                    imageURL: coverURL
                                )
                            ]
                        )
                    }

                    continuation.resume(returning: sections)
                }
        }
    }

    // MARK: - Carousel Items

    // MARK: - Fetch Carousel Items

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
                        var playlist = try doc.data(as: PlaylistDoc.self)
                        playlist = PlaylistDoc(
                            id: doc.documentID,
                            playlistId: playlist.playlistId,
                            title: playlist.title,
                            description: playlist.description,
                            coverImageURL: playlist.coverImageURL,
                            trackCount: playlist.trackCount,
                            createdAt: playlist.createdAt
                        )
                        return playlist
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
}



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
