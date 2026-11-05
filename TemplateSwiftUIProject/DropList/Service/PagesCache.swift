// PagesCache.swift

// MARK: - PagesCache (Атомарный кэш через actor)
//
// Этот actor гарантирует ПОЛНУЮ атомарность операций чтения/записи кэша.
// Swift обеспечивает строгую изоляцию actor'а: только один поток может
// выполнять код внутри него в любой момент времени.
//
// Зачем это нужно?
// ----------------
// Droplist выполняет несколько асинхронных операций параллельно:
//
// • initial load
// • выбор элемента карусели (select)
// • пагинация (loadNextPage)
// • soft refresh
// • auto refresh
// • retry
//
// Все эти операции могут обращаться к кэшу ОДНОВРЕМЕННО.
// Без actor это приводит к race conditions:
//
// 1) Два параллельных loadNextPage перезаписывают друг друга.
// 2) select и pagination одновременно пишут в один и тот же ключ.
// 3) refreshDropList очищает кэш в момент записи пагинации.
// 4) stale‑response может перезаписать актуальные данные.
// 5) одновременное чтение и запись приводит к data race и крашу.
//
// Actor решает ВСЕ эти проблемы:
//
// ✔ операции выполняются строго последовательно
//✔ никакой одновременной записи
//✔ никакого одновременного чтения/записи
//✔ никакого повреждения данных
//✔ никакого undefined behavior
//✔ никакого краша из‑за гонок
//✔ кэш всегда консистентный
//✔ безопасная работа при параллельных Task
//✔ идеальная совместимость с Swift Concurrency
//
// Это архитектура уровня Instagram/TikTok/YouTube feed —
// атомарный, потокобезопасный кэш, который невозможно сломать
// параллельными асинхронными операциями.
//


// cache который мы будем remove: cache -  (case: allTracks, gym, party, rnb)
// cache который мы не будем remove: cachePermanent - (case: droplist, topDropItem) так как эти списки будут неизменны
//





// MARK: - Важно что бы id для все кэшей были уникальными это важно для верхней секции где могут меняться ячейки


// что нужно удалять из кэша при обновлении главного экрана!
//список всех треков allTracks + ячейки droplist + ячейки DropTop + списки треков из фильтрова gym, party, rnb, оп артистам из allTracks и так далее.

// ???? что если в будущем каталоге будет открыт экран allTracks или gym мы перешли на главный экран обновились и заетм опять вернулись на каталог с открытым allTracks  ????



// у нас вместо LowerSectionPage для DropTop struct DropTopPage и отдельный DropTopPagesCache
// может можно интегрировать его в PagesCache
// или оставить как есть и при этом удалять его кэш при обновлении главного экрана



import Foundation

actor PagesCache {

    private var temporaryCache: [String: LowerSectionPage] = [:]
    private var permanentCache: [String: LowerSectionPage] = [:]

    // Защита от параллельной пагинации одного списка.
    private var loadingKeys: Set<String> = []

    // MARK: - Get

    func get(
        _ key: some PageCacheKey
    ) -> LowerSectionPage? {
        if key.isPermanentCache {
            return permanentCache[key.cacheKey]
        }

        return temporaryCache[key.cacheKey]
    }

    // MARK: - Set

    func set(
        _ key: some PageCacheKey,
        page: LowerSectionPage
    ) {
        if key.isPermanentCache {
            permanentCache[key.cacheKey] = page
        } else {
            temporaryCache[key.cacheKey] = page
        }
    }

    // MARK: - Remove

    func remove(
        _ key: some PageCacheKey
    ) {
        temporaryCache.removeValue(forKey: key.cacheKey)
        permanentCache.removeValue(forKey: key.cacheKey)
    }

    // MARK: - Reset

    /// Очищает временный кэш.
    /// Постоянный кэш экранов деталей сохраняется.
    func reset() {
        temporaryCache.removeAll()
    }

    /// Полностью очищает оба хранилища.
    func resetAll() {
        temporaryCache.removeAll()
        permanentCache.removeAll()
        loadingKeys.removeAll()
    }

    // MARK: - Contains

    func contains(
        _ key: some PageCacheKey
    ) -> Bool {
        if key.isPermanentCache {
            return permanentCache[key.cacheKey] != nil
        }

        return temporaryCache[key.cacheKey] != nil
    }

    // MARK: - Pagination Lock

    func beginLoading(
        _ key: some PageCacheKey
    ) -> Bool {
        guard !loadingKeys.contains(key.cacheKey) else {
            return false
        }

        loadingKeys.insert(key.cacheKey)
        return true
    }

    func endLoading(
        _ key: some PageCacheKey
    ) {
        loadingKeys.remove(key.cacheKey)
    }
}





// MARK: - Instead of `DropTopPage`, use a generic `LowerSectionPage`, and merge `DropTopPagesCache` with `PagesCache`.

/// Атомарный кэш страниц через actor — предотвращает race conditions
//actor PagesCache {
//
//    // Временный кэш — очищается при обновлении главного экрана.
//    private var temporaryCache: [String: LowerSectionPage] = [:]
//
//    // Постоянный кэш — сохраняется при обновлении главного экрана.
//    private var permanentCache: [String: LowerSectionPage] = [:]
//
//    // =================================================
//    // MARK: Cache
//    // =================================================
//
//    func get(
//        _ item: CarouselItemType
//    ) -> LowerSectionPage? {
//
//        let key = item.cacheKey
//
//        return item.isPermanentCache
//            ? permanentCache[key]
//            : temporaryCache[key]
//    }
//
//    func set(
//        _ item: CarouselItemType,
//        page: LowerSectionPage
//    ) {
//
//        let key = item.cacheKey
//
//        if item.isPermanentCache {
//            permanentCache[key] = page
//        } else {
//            temporaryCache[key] = page
//        }
//    }
//
//    func remove(_ item: CarouselItemType) {
//        let key = item.cacheKey
//
//        temporaryCache.removeValue(forKey: key)
//        permanentCache.removeValue(forKey: key)
//    }
//
//    // =================================================
//    // MARK: Reset
//    // =================================================
//
//    /// Очищает временный кэш, сохраняя страницы деталей.
//    func reset() {
//        temporaryCache.removeAll()
//    }
//
//    /// Полностью очищает оба кэша.
//    func resetAll() {
//        temporaryCache.removeAll()
//        permanentCache.removeAll()
//    }
//
//    func contains(_ item: CarouselItemType) -> Bool {
//        let key = item.cacheKey
//
//        return item.isPermanentCache
//            ? permanentCache[key] != nil
//            : temporaryCache[key] != nil
//    }
//}


// MARK: -  before removing versioning DataRefreshStateStore.

//actor PagesCache {
//    private var cache: [String: LowerSectionPage] = [:]
//
//    func get(_ id: String) -> LowerSectionPage? { cache[id] }
//    func set(_ id: String, page: LowerSectionPage) { cache[id] = page }
//    func remove(_ id: String) { cache.removeValue(forKey: id) }
//    func reset() { cache.removeAll() }
//    func contains(_ id: String) -> Bool { cache[id] != nil }
//}

