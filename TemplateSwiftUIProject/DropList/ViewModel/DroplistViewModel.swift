//
//  DroplistViewModel.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 20.04.26.
//

//import Combine
//import SwiftUI
//
//struct DropData {}
//struct TrackCloud {}
//
//enum DropeState {
//    case loading
//    case error(String)
//    case myTracks([TrackCloud])
//    case errorList(String)
//    case contentList(DropData)
//}
//
//extension DropeState {
//    var isError: Bool {
//        switch self {
//        case .error, .errorList:
//            return true
//        default:
//            return false
//        }
//    }
//}
//
//
//
//final class DroplistViewModel: ObservableObject {
//    
//    @Published var viewState: DropeState = .loading
//    
//    private let homeManager: HomeManager
//    let managerCRUDS: CRUDSManager
//    private var cancellables = Set<AnyCancellable>()
//    
//    private(set) var myTracks: [TrackCloud] = []
//    private var isDropListLoaded = false
//    
//    init(homeManager: HomeManager,
//         managerCRUDS: CRUDSManager) {
//        self.homeManager = homeManager
//        self.managerCRUDS = managerCRUDS
//        print("init HomeContentView + HomeContentViewModel")
//        
//        homeManager.statePublisher
//            .compactMap { $0 }
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.handleHomeManagerState(state)
//            }
//            .store(in: &cancellables)
//    }
//    
//    deinit {
//        print("deinit HomeContentView + HomeContentViewModel")
//    }
//    
//    func setupViewModel() {
//        viewState = .loading
//        homeManager.start()
//        homeManager.observe()
//    }
//    
//    func setRetryHandler(_ handler: GlobalRetryHandler) {
//        homeManager.setRetryHandler(handler)
//    }
//    
//    func retry() {
//        myTracks = []
//        isDropListLoaded = false
//        viewState = .loading
//        homeManager.retry()
//    }
//    
//    // MARK: - DropList
//

//func fetchDataDroplist() {
//    guard !isDropListLoaded else { return }
//    isDropListLoaded = true
//    
//    loadDropList(isInitial: true) { [weak self] result in
//        switch result {
//        case .success(let dropData):
//            self?.viewState = .contentList(dropData)
//        case .failure(let error):
//            self?.viewState = .errorList(error.localizedDescription)
//        }
//    }
//}

//    
//    func retryFetchDataDroplist() {
//        isDropListLoaded = false
//        fetchDataDroplist()
//    }
//    
//func refreshDropList() {
//    loadDropList(isInitial: false) { [weak self] result in
//        switch result {
//        case .success(let dropData):
//            self?.viewState = .contentList(dropData)
//        case .failure(let error):
//            print("DropList refresh failed: \(error.localizedDescription)")
//        }
//    }
//}

//    
//    // MARK: - Handle HomeManager state
//    
//    private func handleHomeManagerState(_ state: DropeState) {
//        switch state {
//            
//        case .loading:
//            viewState = .loading
//            
//        case .error(let message):
//            viewState = .error(message)
//            
//        case .myTracks(let tracks):
//            // Сохраняем треки, но НЕ меняем viewState
//            myTracks = tracks
//            fetchDataDroplist()
//            
//        case .contentList, .errorList:
//            break
//        }
//    }
//    
//    // MARK: - Abstract DropList API
//    
//private func loadDropList(
//    isInitial: Bool,
//    completion: @escaping (Result<DropData, Error>) -> Void
//) {
//    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//        completion(.success(DropData()))
//    }
//}
//}






// по этому блоку вопрсы

// 1. Смогу ли я получать из tracks выборку по запросу через APi Firebase - то есть к примеру обратится к коллекции tracks и поолучить сразу все треки которые имеют поле со значением GYM к примеру (то есть тут еще важно понимать что я бы хотел экономить на квотах при таком запросе - то есть получить при таком запросе от сети не все треки и на клиенте их отфильтровать по полям а именнно получить уже отфильрованные данные с сервера ?)
// У меня тариф Blaze - достуно ли такое APi Firebase для фильтрации данных из коллекции, сколько стоит такой запрос? ???

// 2. У меня на нижней секции для All tracks for Droplist будет стоять поисковая строка reserch - то есть я хочу через нее искать к примеру все треки по названию артиста или трека в моей коллекции(tracks)  Могу ли я получать из коллекции tracks такую выборку??? доступна ли она будет на  тарифе Blaze, сколько стоит такой запрос? И нужно понимать что у нас стоит погинация на получение данных для нижней секции - то есть нам нужно будет это учитывать при reserch - то есть нам нужно будет обращаться не к кданным которые сохранены в памяти а именно к колекции tracks! - дай мне реализацию такого функционала именно для класса который ходит в сеть по запросу!

// 3. По поводу полей в playlists нам нужно обязательно добавить поле playlistId или возможно {playlistId} (document) уже будет назван как playlistId? playlistId - это реальный id в плейлисте на моем канале youtube в котором будет лежать плейлист с треками - это нужно для того что бы пользователь имел возможность сделать дееп линк на мой плейлист в канале и послушать треки  к примеру без реклаимы и в фоне!
// продумай это!

// 4. Давай поговорим про thumbnailURL для каждого трека!
// смотри какая у нас тактика - я мсначало нахожу трек в сети составляю плэйлист на моем youtube music далее через специальную админку обращаюсь к своему плэйлисту и делаю парсинг данных о треки после чего эти данные сохраняю уже в playlists (collection) + tracks (collection) !
// вопрос вот какой - мои thumbnailURL лежат в базе но вдруг артист поменяет thumbnailURL на youtube music ? получается у меня будет не валидный thumbnailURL ? и могу ли я создать coverImageURL сам из этих картинок по thumbnailURL сохранить эту картинку(coverImage) у себя на Storage и уже на нее добавить ссылку в coverImageURL ? Это законно ?



//отлично ! я разобрал твою кодовую базу по реализации DropListDataSource и теперь мне она понятно и вприципе мне нравится ее логика! теперь прежде чем перейти к реализации сущности -  firestore: DropListFirestoreServiceProtocol ! нам нужно поговорить про нашу структуру данных в cloudFirestore и о том какие данные мы будем от туда получать и в какие модели их преобразовывать что бы отобразить на UI! Первое с чего хотелось бы начать это эще раз проговарить какие мы данные отображаем в нижней секции для каждого item в средней секции! для item средней секции Droplist мы получаем обьекты которые отображаются в ячейки нижней секции как картинка и два текстовых поля, одно из текстовых полей лежит поверх картинки а второе текстовое поле лежит под картинкой на нашем UI ячейки - по сути это один плейлист и по нажатию на эту ячейку мы переходим на View который является плеером и в нем будут отображены те музыкальные треки которые лежали в этом плэйлисте! так же нужно сказать что наш картинка плэйлиста (imageURL то что на скрин шоте - этого поля в реальности не будет) она не известна нам зарание( ну или как ты сам мне сказал лучше не хранить данные артистов с youtube music у себя в базе) и мы должны ее скомпелировать из картинок треков которые лежат  в коллекции tracks в документе каждого трека под полем thumbnailURL то есть поидее мы должны скомпелировать из этих thumbnailURL картинку для нашего плэйлиста! давай еще раз получается наш LowerItem будет иметь стрктуру как на скрн шотах (только не забудь что imageURL то что на скрин шоте - этого поля в реальности не будет)! вот из каких обектов будет состоять наша нижняя секция для item Droplist средней секции! далее как ты уже понял item средней секции All tracks for Droplist будет состоять из треков всех плйлистов что у нас есть в Droplist - и тут у меня вопрос можем ли мы получить данные для эсекции All tracks for Droplist из того же источника в CloudFirestore из которого мы получаем данные для секции Droplist как на наших сриншотах! Так же хочу сказать что поля для track в CloudeFirestore это не предел и они для продакшена будут расширины новыми полями! В идеале хотелось бы получать данные для  item средней секции такие как GYM и Party ... использую тот же источник что мы используем для  Droplist но делать выборку к примеру по полям которые мы добавим в track в CloudeFirestore то есть там будут поля по которым можно будет идентифицировать к какой категории относится трек к GYM или Party например! Давай создадим универсальную модель для LowerItem учитывая вводные которые я тебе дал + хотелось бы иметь возможность из одного источника root collection Plylists(Droplists) наполнять данными все вкладки для items горизонтальной карусели (если это возможно технически) наша структура root collection Plylists(Droplists) идеально подходит для наполнения данными ленту Droplist Но можно ли будет наполнить из источника root collection Plylists(Droplists) ленту All tracks for Droplist и другие секции? я бы хотел профессионально организовать и потимизировать структуру данных в CloudFirestore для использования в моем приложении! дай мне реализацию как професиональный разработчик для боевого приложения учитывая мои кейсы



// MARK: - ferst version code base + pagination



//import Foundation
//import FirebaseFirestore
//
//// Общая модель, которую будет принимать DroplistCompositView
//struct DropData {
//    let topSections: [TopSectionModel]        // верхняя секция (небольшой объём)
//    let carouselItems: [CarouselItem]         // средняя секция (категории)
//    let initialLowerSection: LowerSectionPage // первая порция для дефолтного carousel item
//}
//
//// Верхняя секция
//struct TopSectionModel: Identifiable {
//    let id: String
//    let title: String
//    let items: [TopItem]
//}
//
//struct TopItem: Identifiable, Decodable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//}
//
//// Элемент карусели (категория)
//struct CarouselItem: Identifiable, Decodable, Equatable {
//    let id: String
//    let title: String
//    let type: CarouselItemType
//}
//
//enum CarouselItemType: String, Decodable {
//    case droplist
//    case allTracks
//    case gym
//    case party
//    case rnb
//    // ... другие типы
//}
//
//// Нижняя секция — одна страница результатов + курсор для следующей
//struct LowerSectionPage {
//    let items: [LowerItem]
//    let lastDocumentSnapshot: DocumentSnapshot? // Firestore cursor
//    let hasMore: Bool
//}
//
//struct LowerItem: Identifiable, Decodable {
//    let id: String
//    let title: String
//    let subtitle: String?
//    let imageURL: URL?
//    // другие поля
//}





//import Foundation
//import FirebaseFirestore
//
//protocol DropListFirestoreServiceProtocol {
//    // Верхняя секция и карусель — небольшие запросы, можно параллельно
//    func fetchTopSections() async throws -> [TopSectionModel]
//    func fetchCarouselItems() async throws -> [CarouselItem]
//    
//    // Пагинация для нижней секции: pageSize и optional cursor (DocumentSnapshot)
//    func fetchLowerItems(for carouselItem: CarouselItem,
//                         pageSize: Int,
//                         after document: DocumentSnapshot?) async throws -> (items: [LowerItem], lastSnapshot: DocumentSnapshot?, hasMore: Bool)
//}




//import Foundation
//import FirebaseFirestore
//
//final class DropListDataSource {
//    private let firestore: DropListFirestoreServiceProtocol
//    private let pageSize: Int
//    
//    init(firestore: DropListFirestoreServiceProtocol, pageSize: Int = 20) {
//        self.firestore = firestore
//        self.pageSize = pageSize
//    }
//    
//    /// Первичная загрузка: topSections + carousel + первая страница для дефолтного item
//    /// defaultSelectedIndex — индекс item в carousel, для которого нужно загрузить первую страницу (обычно 0)
//    func loadInitialDropList(defaultSelectedIndex: Int = 0) async throws -> DropData {
//        // Параллельно загружаем верх и карусель
//        async let topSectionsTask = firestore.fetchTopSections()
//        async let carouselTask = firestore.fetchCarouselItems()
//        
//        let (topSections, carouselItems) = try await (topSectionsTask, carouselTask)
//        
//        // Защита: если carousel пуст — возвращаем пустую DropData
//        guard !carouselItems.isEmpty else {
//            let emptyLower = LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false)
//            return DropData(topSections: topSections, carouselItems: carouselItems, initialLowerSection: emptyLower)
//        }
//        
//        // Выбираем дефолтный item (по индексу или 0)
//        let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
//        let defaultItem = carouselItems[index]
//        
//        // Загружаем первую страницу для defaultItem
//        let (items, lastSnapshot, hasMore) = try await firestore.fetchLowerItems(for: defaultItem, pageSize: pageSize, after: nil)
//        let lowerPage = LowerSectionPage(items: items, lastDocumentSnapshot: lastSnapshot, hasMore: hasMore)
//        
//        return DropData(topSections: topSections, carouselItems: carouselItems, initialLowerSection: lowerPage)
//    }
//    
//    /// Загрузить следующую страницу для конкретного carouselItem
//    func loadNextPage(for item: CarouselItem, after lastSnapshot: DocumentSnapshot?) async throws -> LowerSectionPage {
//        let (items, lastSnapshotNew, hasMore) = try await firestore.fetchLowerItems(for: item, pageSize: pageSize, after: lastSnapshot)
//        return LowerSectionPage(items: items, lastDocumentSnapshot: lastSnapshotNew, hasMore: hasMore)
//    }
//    
//    /// Загрузить первую страницу для выбранного carouselItem (при смене категории)
//    func loadFirstPage(for item: CarouselItem) async throws -> LowerSectionPage {
//        let (items, lastSnapshot, hasMore) = try await firestore.fetchLowerItems(for: item, pageSize: pageSize, after: nil)
//        return LowerSectionPage(items: items, lastDocumentSnapshot: lastSnapshot, hasMore: hasMore)
//    }
//}







//final class HomeContentViewModel: ObservableObject {
//    // ... существующие поля
//    
//    private let dropListDataSource: DropListDataSource
//    // Храним состояние нижней секции для текущего выбранного carouselItem
//    private var lowerSectionStateByItem: [String: LowerSectionPage] = [:] // key = carouselItem.id
//    private var currentSelectedCarouselItem: CarouselItem?
//    
//    init(homeManager: HomeManager,
//         managerCRUDS: CRUDSManager,
//         dropListFirestoreService: DropListFirestoreServiceProtocol) {
//        self.homeManager = homeManager
//        self.managerCRUDS = managerCRUDS
//        self.dropListDataSource = DropListDataSource(firestore: dropListFirestoreService, pageSize: 20)
//        // подписки...
//    }
//    
//    // MARK: - DropList (реализация через data source)
//    
//    private func performFetchDropList(
//        completion: @escaping (Result<DropData, Error>) -> Void
//    ) {
//        Task {
//            do {
//                let dropData = try await dropListDataSource.loadInitialDropList(defaultSelectedIndex: 0)
//                
//                // Сохраняем initial lower page для выбранного item
//                if let firstItem = dropData.carouselItems.first {
//                    currentSelectedCarouselItem = firstItem
//                    lowerSectionStateByItem[firstItem.id] = dropData.initialLowerSection
//                }
//                
//                await MainActor.run {
//                    completion(.success(dropData))
//                }
//            } catch {
//                await MainActor.run {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    private func performGetDropList(
//        completion: @escaping (Result<DropData, Error>) -> Void
//    ) {
//        // getDataDroplist — мягкий refresh: если уже есть DropData, обновляем carousel/topSections and keep UI if fails
//        Task {
//            do {
//                // Попробуем обновить topSections и carousel
//                async let topSectionsTask = dropListDataSource.firestore.fetchTopSections()
//                async let carouselTask = dropListDataSource.firestore.fetchCarouselItems()
//                let (topSections, carouselItems) = try await (topSectionsTask, carouselTask)
//                
//                // Если есть текущий выбранный item — обновим его страницу (first page)
//                var initialLower = LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false)
//                if let selected = currentSelectedCarouselItem {
//                    // Попробуем загрузить первую страницу для текущего выбранного item
//                    let page = try await dropListDataSource.loadFirstPage(for: selected)
//                    lowerSectionStateByItem[selected.id] = page
//                    initialLower = page
//                } else if let first = carouselItems.first {
//                    currentSelectedCarouselItem = first
//                    let page = try await dropListDataSource.loadFirstPage(for: first)
//                    lowerSectionStateByItem[first.id] = page
//                    initialLower = page
//                }
//                
//                let dropData = DropData(topSections: topSections, carouselItems: carouselItems, initialLowerSection: initialLower)
//                await MainActor.run {
//                    completion(.success(dropData))
//                }
//            } catch {
//                // Мягкая ошибка: не переводим UI в errorList, возвращаем failure чтобы вызывающий мог решить как показать toast
//                await MainActor.run {
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//    
//    // Вызов при прокрутке вниз: подгрузить следующую страницу
//    func loadNextPageIfNeeded(for item: CarouselItem) {
//        guard let page = lowerSectionStateByItem[item.id], page.hasMore else { return }
//        // уже загружено, берем lastSnapshot
//        let lastSnapshot = page.lastDocumentSnapshot
//        Task {
//            do {
//                let nextPage = try await dropListDataSource.loadNextPage(for: item, after: lastSnapshot)
//                // объединяем
//                var merged = page.items
//                merged.append(contentsOf: nextPage.items)
//                let newPage = LowerSectionPage(items: merged, lastDocumentSnapshot: nextPage.lastDocumentSnapshot, hasMore: nextPage.hasMore)
//                lowerSectionStateByItem[item.id] = newPage
//                
//                // Если текущий выбранный item — обновляем UI
//                if currentSelectedCarouselItem?.id == item.id {
//                    await MainActor.run {
//                        self.viewState = .contentList(DropData(topSections: [], carouselItems: [], initialLowerSection: newPage))
//                        // Примечание: лучше иметь отдельную структуру DropData для incremental updates,
//                        // здесь для простоты мы обновляем contentList с новой lower page.
//                    }
//                }
//            } catch {
//                print("Failed to load next page: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // При смене item в карусели
//    func didSelectCarouselItem(_ item: CarouselItem) {
//        currentSelectedCarouselItem = item
//        // Если уже есть сохранённая страница — показываем её
//        if let page = lowerSectionStateByItem[item.id] {
//            viewState = .contentList(DropData(topSections: [], carouselItems: [], initialLowerSection: page))
//            return
//        }
//        // Иначе — загружаем первую страницу для этого item
//        Task {
//            do {
//                let page = try await dropListDataSource.loadFirstPage(for: item)
//                lowerSectionStateByItem[item.id] = page
//                await MainActor.run {
//                    self.viewState = .contentList(DropData(topSections: [], carouselItems: [], initialLowerSection: page))
//                }
//            } catch {
//                await MainActor.run {
//                    self.viewState = .errorList(error.localizedDescription)
//                }
//            }
//        }
//    }
//}



//func fetchLowerItems(for carouselItem: CarouselItem, pageSize: Int, after document: DocumentSnapshot?) async throws -> (items: [LowerItem], lastSnapshot: DocumentSnapshot?, hasMore: Bool) {
//    try await withCheckedThrowingContinuation { continuation in
//        var query = db.collection("lowerItems")
//            .whereField("categoryId", isEqualTo: carouselItem.id)
//            .order(by: "createdAt", descending: false)
//            .limit(to: pageSize)
//        if let doc = document {
//            query = query.start(afterDocument: doc)
//        }
//        query.getDocuments { snapshot, error in
//            if let error = error { continuation.resume(throwing: error); return }
//            guard let snapshot = snapshot else { continuation.resume(throwing: AppInternalError.nilSnapshot); return }
//            let items = snapshot.documents.compactMap { try? $0.data(as: LowerItem.self) }
//            let last = snapshot.documents.last
//            let hasMore = items.count == pageSize
//            continuation.resume(returning: (items, last, hasMore))
//        }
//    }
//}

















// MARK: - new implement

//playlists (collection)
// └─ {firestorePlaylistDocId} (document)
//     ├─ playlistId: String                // YouTube playlist ID (обязательно)
//     ├─ title: String
//     ├─ description: String?
//     ├─ curatedTags: [String]?            // категории плейлиста (опционально)
//     ├─ coverImageURL: String?            // URL на Storage (генерируется)
//     ├─ sampleThumbnails: [String]?       // первые 4 thumbnailURL (кэш)
//     ├─ trackCount: Int                   // количество треков
//     ├─ createdAt: Timestamp              // сортировка плейлистов
//     └─ tracks (subcollection)
//         └─ {videoId} (document)
//             ├─ videoId: String
//             ├─ title: String
//             ├─ artist: String
//             ├─ thumbnailURL: String
//             ├─ durationISO8601: String
//             ├─ orderIndex: Int           // порядок в плейлисте
//             ├─ createdAt: Timestamp      // сортировка внутри плейлиста
//


//tracks (collection)
// └─ {videoId} (document)
//     ├─ videoId: String
//     ├─ title: String
//     ├─ artist: String
//     ├─ thumbnailURL: String
//     ├─ durationISO8601: String
//     ├─ tags: [String]                    // ["gym","party","rnb"]
//     ├─ playlists: [String]               // список YouTube playlistId
//     ├─ createdAt: Timestamp              // сортировка и пагинация
//     ├─ searchKeywords: [String]?         // если не используем Algolia





//ROOT
//├── playlists
//│    └── {firestorePlaylistDocId}
//│         ├── playlistId (YouTube)
//│         ├── title
//│         ├── description
//│         ├── curatedTags
//│         ├── coverImageURL
//│         ├── trackCount
//│         ├── createdAt
//│         └── tracks
//│              └── {videoId}
//│                   ├── videoId
//│                   ├── title
//│                   ├── artist
//│                   ├── thumbnailURL
//│                   ├── durationISO8601
//│                   ├── orderIndex
//│                   └── createdAt
//│
//└── tracks
//     └── {videoId}
//          ├── videoId
//          ├── title
//          ├── artist
//          ├── thumbnailURL
//          ├── durationISO8601
//          ├── tags
//          ├── playlists
//          ├── createdAt
//          └── searchKeywords?






// MARK: - 1. Firestore DTO (Data Transfer Objects)


//PlaylistDoc — документ плейлиста
//
//import Foundation
//
//struct PlaylistDoc: Codable, Identifiable {
//    let id: String                     // Firestore document ID (заполняется вручную после decode)
//    let playlistId: String             // YouTube playlist ID
//    let title: String
//    let description: String?
//    let curatedTags: [String]?
//    let coverImageURL: String?
//    let sampleThumbnails: [String]?
//    let trackCount: Int
//    let createdAt: Date
//}




//PlaylistTrackDoc — документ трека внутри плейлиста
//
//struct PlaylistTrackDoc: Codable, Identifiable {
//    let id: String                     // videoId (Firestore doc ID)
//    let videoId: String
//    let title: String
//    let artist: String?
//    let thumbnailURL: String?
//    let durationISO8601: String?
//    let orderIndex: Int
//    let createdAt: Date
//}


//TrackDoc — глобальный трек (коллекция tracks)
//
//struct TrackDoc: Codable, Identifiable {
//    let id: String                     // videoId (Firestore doc ID)
//    let videoId: String
//    let title: String
//    let artist: String?
//    let thumbnailURL: String?
//    let durationISO8601: String?
//    let tags: [String]?
//    let playlists: [String]?           // YouTube playlist IDs
//    let createdAt: Date
//    let searchKeywords: [String]?      // optional (если не используем Algolia)
//}



// MARK: - 2. Domain Models (UI‑модели)

//LowerItem — универсальная модель нижней секции
//
//import Foundation
//
//struct LowerItem: Identifiable {
//    let id: String                     // playlistId или videoId
//    let title: String
//    let subtitle: String?
//    let coverImageURL: URL?            // для плейлистов
//    let sampleThumbnails: [URL]        // для плейлистов
//    let trackCount: Int?               // для плейлистов
//    let isTrack: Bool                  // true → трек, false → плейлист
//}


//Плейлист → LowerItem

//LowerItem(
//    id: playlistDoc.playlistId,
//    title: playlistDoc.title,
//    subtitle: playlistDoc.description,
//    coverImageURL: URL(string: playlistDoc.coverImageURL ?? ""),
//    sampleThumbnails: playlistDoc.sampleThumbnails?.compactMap { URL(string: $0) } ?? [],
//    trackCount: playlistDoc.trackCount,
//    isTrack: false
//)



//Трек → LowerItem

//LowerItem(
//    id: trackDoc.videoId,
//    title: trackDoc.title,
//    subtitle: trackDoc.artist,
//    coverImageURL: nil,
//    sampleThumbnails: [URL(string: trackDoc.thumbnailURL ?? "")].compactMap { $0 },
//    trackCount: nil,
//    isTrack: true
//)





// MARK: - 3. DropData — данные для DroplistCompositView



//struct DropData {
//    let topSections: [TopSectionModel]        // верхняя секция
//    let carouselItems: [CarouselItem]         // средняя секция
//    let initialLowerSection: LowerSectionPage // первая страница нижней секции
//}



// MARK: - 4. LowerSectionPage — страница пагинации

//import FirebaseFirestore
//
//struct LowerSectionPage {
//    let items: [LowerItem]
//    let lastDocumentSnapshot: DocumentSnapshot?
//    let hasMore: Bool
//}



// MARK: - 5. CarouselItem — элементы средней секции

//enum CarouselItemType: String, Codable {
//    case droplist
//    case allTracks
//    case gym
//    case party
//    case rnb
//    // можно расширять
//}
//
//struct CarouselItem: Identifiable, Codable, Equatable {
//    let id: String
//    let title: String
//    let type: CarouselItemType
//}
//




// MARK: - 6. TopSectionModel — верхняя секция (как в GalleryCompositView)

//struct TopSectionModel: Identifiable {
//    let id: String
//    let title: String
//    let items: [TopItem]
//}
//
//struct TopItem: Identifiable {
//    let id: String
//    let title: String
//    let imageURL: URL?
//}








// MARK: -  DropListFirestoreServiceProtocol


//import Foundation
//import FirebaseFirestore
//
//protocol DropListFirestoreServiceProtocol {
//    
//    /// Верхняя секция (баннеры, промо и т.п.)
//    func fetchTopSections() async throws -> [TopSectionModel]
//    
//    /// Элементы горизонтальной карусели (Droplist, All tracks, GYM, Party...)
//    func fetchCarouselItems() async throws -> [CarouselItem]
//    
//    /// Первая страница нижней секции для выбранного item
//    func fetchInitialLowerPage(
//        for item: CarouselItem,
//        pageSize: Int
//    ) async throws -> LowerSectionPage
//    
//    /// Следующая страница нижней секции для выбранного item
//    func fetchNextLowerPage(
//        for item: CarouselItem,
//        after lastSnapshot: DocumentSnapshot,
//        pageSize: Int
//    ) async throws -> LowerSectionPage
//}




//import Foundation
//import FirebaseFirestore
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
//        // Здесь можно сделать реальный запрос к коллекции, например "top_sections"
//        // Пока оставим как заглушку / пример.
//        return []
//    }
//    
//    // MARK: - Carousel Items
//    
//    func fetchCarouselItems() async throws -> [CarouselItem] {
//        // В простейшем варианте карусель статична и не хранится в Firestore.
//        // Если захочешь — можно вынести в коллекцию "drop_carousel".
//        return [
//            CarouselItem(id: "droplist",   title: "Droplist",              type: .droplist),
//            CarouselItem(id: "all_tracks", title: "All tracks for Droplist", type: .allTracks),
//            CarouselItem(id: "gym",        title: "GYM",                   type: .gym),
//            CarouselItem(id: "party",      title: "Party",                 type: .party)
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
//    // MARK: - Private: Playlists Page
//    
//    private func fetchPlaylistsPage(
//        after lastSnapshot: DocumentSnapshot?,
//        pageSize: Int
//    ) async throws -> LowerSectionPage {
//        
//        var query: Query = db.collection("playlists")
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
//                // Пробрасываем Firestore ID в модель
//                playlist = PlaylistDoc(
//                    id: doc.documentID,
//                    playlistId: playlist.playlistId,
//                    title: playlist.title,
//                    description: playlist.description,
//                    curatedTags: playlist.curatedTags,
//                    coverImageURL: playlist.coverImageURL,
//                    sampleThumbnails: playlist.sampleThumbnails,
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
//            let thumbs: [URL] = (playlist.sampleThumbnails ?? [])
//                .compactMap { URL(string: $0) }
//            
//            return LowerItem(
//                id: playlist.playlistId,          // бизнес-ID (YouTube)
//                title: playlist.title,
//                subtitle: playlist.description,
//                coverImageURL: coverURL,
//                sampleThumbnails: thumbs,
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
//    // MARK: - Private: Tracks Page (All / by Tag)
//    
//    private func fetchTracksPage(
//        tag: String?,
//        pageSize: Int,
//        after lastSnapshot: DocumentSnapshot?
//    ) async throws -> LowerSectionPage {
//        
//        var query: Query = db.collection("tracks")
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
//                sampleThumbnails: thumbURL.map { [$0] } ?? [],
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







// MARK: - DropListDataSource


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
//    // MARK: - Dependencies
//    
//    private let firestoreService: DropListFirestoreServiceProtocol
//    private let pageSize: Int
//    
//    // MARK: - Cached State
//    
//    /// Кэш страниц нижней секции для каждого carouselItem.id
//    private var lowerPagesCache: [String: LowerSectionPage] = [:]
//    
//    /// Текущий выбранный item карусели
//    private(set) var currentItem: CarouselItem?
//    
//    // MARK: - Init
//    
//    init(
//        firestoreService: DropListFirestoreServiceProtocol,
//        pageSize: Int = 20
//    ) {
//        self.firestoreService = firestoreService
//        self.pageSize = pageSize
//    }
//    
//    // MARK: - Public API
//    
//    /// Первичная загрузка:
//    /// - topSections
//    /// - carouselItems
//    /// - первая страница нижней секции для defaultSelectedIndex
//    func loadInitialDropList(defaultSelectedIndex: Int = 0) async throws -> DropData {
//        
//        // Загружаем верхнюю секцию и карусель параллельно
//        async let topTask = firestoreService.fetchTopSections()
//        async let carouselTask = firestoreService.fetchCarouselItems()
//        
//        let (topSections, carouselItems) = try await (topTask, carouselTask)
//        
//        guard !carouselItems.isEmpty else {
//            // Если нет элементов карусели — возвращаем пустую структуру
//            let emptyPage = LowerSectionPage(items: [], lastDocumentSnapshot: nil, hasMore: false)
//            return DropData(
//                topSections: topSections,
//                carouselItems: carouselItems,
//                initialLowerSection: emptyPage
//            )
//        }
//        
//        // Определяем дефолтный item
//        let index = min(max(0, defaultSelectedIndex), carouselItems.count - 1)
//        let selected = carouselItems[index]
//        currentItem = selected
//        
//        // Загружаем первую страницу нижней секции
//        let firstPage = try await firestoreService.fetchInitialLowerPage(
//            for: selected,
//            pageSize: pageSize
//        )
//        
//        // Кэшируем
//        lowerPagesCache[selected.id] = firstPage
//        
//        return DropData(
//            topSections: topSections,
//            carouselItems: carouselItems,
//            initialLowerSection: firstPage
//        )
//    }
//    
//    /// Смена item в карусели
//    func selectCarouselItem(_ item: CarouselItem) async throws -> LowerSectionPage {
//        currentItem = item
//        
//        // Если есть кэш — возвращаем мгновенно
//        if let cached = lowerPagesCache[item.id] {
//            return cached
//        }
//        
//        // Иначе загружаем первую страницу
//        let firstPage = try await firestoreService.fetchInitialLowerPage(
//            for: item,
//            pageSize: pageSize
//        )
//        
//        lowerPagesCache[item.id] = firstPage
//        return firstPage
//    }
//    
//    /// Пагинация — загрузка следующей страницы
//    func loadNextPageIfNeeded(for item: CarouselItem) async throws -> LowerSectionPage? {
//        
//        guard let currentPage = lowerPagesCache[item.id] else {
//            // Нет первой страницы — значит UI вызвал пагинацию слишком рано
//            return nil
//        }
//        
//        guard currentPage.hasMore else {
//            // Больше страниц нет
//            return nil
//        }
//        
//        guard let lastSnapshot = currentPage.lastDocumentSnapshot else {
//            // Нет курсора — странно, но защищаемся
//            return nil
//        }
//        
//        // Загружаем следующую страницу
//        let nextPage = try await firestoreService.fetchNextLowerPage(
//            for: item,
//            after: lastSnapshot,
//            pageSize: pageSize
//        )
//        
//        // Объединяем
//        let mergedItems = currentPage.items + nextPage.items
//        
//        let mergedPage = LowerSectionPage(
//            items: mergedItems,
//            lastDocumentSnapshot: nextPage.lastDocumentSnapshot,
//            hasMore: nextPage.hasMore
//        )
//        
//        // Обновляем кэш
//        lowerPagesCache[item.id] = mergedPage
//        
//        return mergedPage
//    }
//    
//    /// Мягкий refresh (pull‑to‑refresh)
//    /// Обновляет только текущий item
//    func refreshCurrentItem() async throws -> LowerSectionPage {
//        guard let item = currentItem else {
//            throw NSError(domain: "DropListDataSource", code: -1, userInfo: [
//                NSLocalizedDescriptionKey: "No current carousel item selected"
//            ])
//        }
//        
//        let firstPage = try await firestoreService.fetchInitialLowerPage(
//            for: item,
//            pageSize: pageSize
//        )
//        
//        lowerPagesCache[item.id] = firstPage
//        return firstPage
//    }
//}
//







// MARK: - HomeContentViewModel


//import Foundation
//import Combine
//import SwiftUI
//import FirebaseFirestore
//
//@MainActor
//final class HomeContentViewModel: ObservableObject {
//    
//    // MARK: - Published UI State
//    
//    @Published var viewState: ViewState = .loading
//    
//    // MARK: - Dependencies
//    
//    private let sessionManager: AppSessionManager        // бывший HomeManager
//    private let managerCRUDS: CRUDSManager
//    private let dropDataSource: DropListDataSource
//    
//    // MARK: - Internal State
//    
//    private var cancellables = Set<AnyCancellable>()
//    private var isInitialLoaded = false
//    
//    // MARK: - Init
//    
//    init(
//        sessionManager: AppSessionManager,
//        managerCRUDS: CRUDSManager,
//        firestoreService: DropListFirestoreServiceProtocol
//    ) {
//        self.sessionManager = sessionManager
//        self.managerCRUDS = managerCRUDS
//        self.dropDataSource = DropListDataSource(
//            firestoreService: firestoreService,
//            pageSize: 20
//        )
//        
//        observeSessionState()
//    }
//    
//    deinit {
//        print("deinit HomeContentViewModel")
//    }
//    
//    // MARK: - Observe AppSessionManager
//    
//    private func observeSessionState() {
//        sessionManager.statePublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] state in
//                self?.handleSessionState(state)
//            }
//            .store(in: &cancellables)
//    }
//    
//    private func handleSessionState(_ state: ViewState) {
//        switch state {
//        case .loading:
//            viewState = .loading
//            
//        case .error(let message):
//            viewState = .error(message)
//            
//        case .myTracks(let tracks):
//            // Треки нужны только для бизнес‑логики (например, сравнение videoId)
//            // UI не показывает myTracks → не меняем viewState
//            sessionManager.cacheMyTracks(tracks)
//            
//            // Первичная загрузка Droplist
//            if !isInitialLoaded {
//                Task { await self.loadInitial() }
//            }
//            
//        case .contentList, .errorList:
//            break
//        }
//    }
//    
//    // MARK: - Initial Load
//    
//    func setupViewModel() {
//        viewState = .loading
//        sessionManager.start()
//        sessionManager.observe()
//    }
//    
//    private func loadInitial() async {
//        do {
//            let dropData = try await dropDataSource.loadInitialDropList(defaultSelectedIndex: 0)
//            viewState = .contentList(dropData)
//            isInitialLoaded = true
//        } catch {
//            viewState = .errorList(error.localizedDescription)
//        }
//    }
//    
//    // MARK: - Retry
//    
//    func retry() {
//        isInitialLoaded = false
//        viewState = .loading
//        sessionManager.retry()
//    }
//    
//    func retryFetchDataDroplist() {
//        Task { await loadInitial() }
//    }
//    
//    // MARK: - Refresh (Pull-to-Refresh)
//    
//    func refreshDropList() {
//        Task {
//            do {
//                let page = try await dropDataSource.refreshCurrentItem()
//                
//                guard case .contentList(let oldData) = viewState else { return }
//                
//                let newData = DropData(
//                    topSections: oldData.topSections,
//                    carouselItems: oldData.carouselItems,
//                    initialLowerSection: page
//                )
//                
//                viewState = .contentList(newData)
//                
//            } catch {
//                print("Refresh failed: \(error.localizedDescription)")
//            }
//        }
//    }
//    
//    // MARK: - Carousel Selection
//    
//    func didSelectCarouselItem(_ item: CarouselItem) {
//        Task {
//            do {
//                let page = try await dropDataSource.selectCarouselItem(item)
//                
//                guard case .contentList(let oldData) = viewState else { return }
//                
//                let newData = DropData(
//                    topSections: oldData.topSections,
//                    carouselItems: oldData.carouselItems,
//                    initialLowerSection: page
//                )
//                
//                viewState = .contentList(newData)
//                
//            } catch {
//                viewState = .errorList(error.localizedDescription)
//            }
//        }
//    }
//    
//    // MARK: - Pagination
//    
//    func loadNextPageIfNeeded(for item: CarouselItem) {
//        Task {
//            do {
//                guard let newPage = try await dropDataSource.loadNextPageIfNeeded(for: item) else { return }
//                
//                guard case .contentList(let oldData) = viewState else { return }
//                
//                let newData = DropData(
//                    topSections: oldData.topSections,
//                    carouselItems: oldData.carouselItems,
//                    initialLowerSection: newPage
//                )
//                
//                viewState = .contentList(newData)
//                
//            } catch {
//                print("Pagination failed: \(error.localizedDescription)")
//            }
//        }
//    }
//}
//





// MARK: - DroplistCompositView


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
//            AsyncImage(url: item.sampleThumbnails.first) { img in
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





// MARK: - AppSessionManager


//import Foundation
//import Combine
//import FirebaseAuth
//import FirebaseFirestore
//
///// Главный менеджер сессии приложения.
///// Отвечает за:
///// - Firebase Auth (анонимная авторизация)
///// - Firestore listener (myTracks)
///// - глобальные ошибки
///// - retry‑механику
///// - единый реактивный statePublisher
/////
///// Это SSOT (Single Source of Truth) для HomeContentViewModel.
//@MainActor
//final class AppSessionManager {
//    
//    // MARK: - Published State
//    
//    private let stateSubject = PassthroughSubject<ViewState, Never>()
//    var statePublisher: AnyPublisher<ViewState, Never> {
//        stateSubject.eraseToAnyPublisher()
//    }
//    
//    // MARK: - Dependencies
//    
//    private let authService: AuthServiceProtocol
//    private let firestoreService: FirestoreTracksServiceProtocol
//    
//    // MARK: - Internal State
//    
//    private var cancellables = Set<AnyCancellable>()
//    private var isObserving = false
//    private var isRetrying = false
//    
//    // MARK: - Init
//    
//    init(
//        authService: AuthServiceProtocol,
//        firestoreService: FirestoreTracksServiceProtocol
//    ) {
//        self.authService = authService
//        self.firestoreService = firestoreService
//    }
//    
//    deinit {
//        print("deinit AppSessionManager")
//    }
//    
//    // MARK: - Public API
//    
//    func start() {
//        stateSubject.send(.loading)
//    }
//    
//    /// Запускает реактивную цепочку:
//    /// Auth → Firestore listener → ViewState
//    func observe() {
//        guard !isObserving else { return }
//        isObserving = true
//        
//        observeSession()
//    }
//    
//    /// Глобальный retry (после ошибки)
//    func retry() {
//        guard !isRetrying else { return }
//        isRetrying = true
//        
//        stateSubject.send(.loading)
//        
//        // Сбрасываем Firestore listener
//        firestoreService.cancelListener()
//        
//        // Перезапускаем цепочку
//        observeSession()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            self.isRetrying = false
//        }
//    }
//    
//    /// Кэшируем myTracks (если нужно)
//    func cacheMyTracks(_ tracks: [BookCloud]) {
//        // Здесь можно хранить в памяти, если потребуется
//    }
//    
//    // MARK: - Core Reactive Chain
//    
//    private func observeSession() {
//        
//        authService.authenticate()
//            .flatMap { [weak self] resultOrNil -> AnyPublisher<ViewState, Never> in
//                guard let self = self else {
//                    return Just(.error(AppInternalError.entityDeallocated.localizedDescription))
//                        .eraseToAnyPublisher()
//                }
//                
//                // user == nil → переходное состояние
//                guard let result = resultOrNil else {
//                    self.firestoreService.cancelListener()
//                    return Just(.loading).eraseToAnyPublisher()
//                }
//                
//                switch result {
//                    
//                case .success(let userId):
//                    let path = "users/\(userId)/data"
//                    
//                    let publisher: AnyPublisher<Result<[BookCloud], Error>, Never> =
//                        self.firestoreService.observeCollection(at: path)
//                    
//                    return publisher
//                        .map { result in
//                            switch result {
//                            case .success(let books):
//                                return .myTracks(books)
//                                
//                            case .failure(let error):
//                                return self.handleError(
//                                    error,
//                                    context: .AppSessionManager_observeBooks_firestoreService
//                                )
//                            }
//                        }
//                        .eraseToAnyPublisher()
//                    
//                case .failure(let error):
//                    return Just(
//                        self.handleError(
//                            error,
//                            context: .AppSessionManager_authService_authenticate
//                        )
//                    )
//                    .eraseToAnyPublisher()
//                }
//            }
//            .sink { [weak self] state in
//                self?.stateSubject.send(state)
//            }
//            .store(in: &cancellables)
//    }
//    
//    // MARK: - Error Handling
//    
//    private func handleError(_ error: Error, context: ErrorContext) -> ViewState {
//        print("🔥 AppSessionManager Error [\(context.rawValue)]: \(error.localizedDescription)")
//        
//        // Firestore listener должен быть сброшен
//        firestoreService.cancelListener()
//        
//        // Показываем глобальную ошибку
//        return .error(error.localizedDescription)
//    }
//}
//
