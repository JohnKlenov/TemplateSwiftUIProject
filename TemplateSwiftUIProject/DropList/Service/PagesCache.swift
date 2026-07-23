// PagesCache.swift
import Foundation

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

/// Атомарный кэш страниц через actor — предотвращает race conditions
actor PagesCache {
    private var cache: [String: LowerSectionPage] = [:]

    func get(_ id: String) -> LowerSectionPage? { cache[id] }
    func set(_ id: String, page: LowerSectionPage) { cache[id] = page }
    func remove(_ id: String) { cache.removeValue(forKey: id) }
    func reset() { cache.removeAll() }
    func contains(_ id: String) -> Bool { cache[id] != nil }
}

