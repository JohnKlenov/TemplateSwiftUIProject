//
//  DropTopPagesCache.swift
//  TemplateSwiftUIProject
//
//  Created by Evgenyi on 06.10.2026.
//


actor DropTopPagesCache {
    
    private var cache: [String: DropTopPage] = [:]
    private var loadingKeys: Set<String> = []
    
    // =========================================================
    // MARK: Cache
    // =========================================================
    
    func get(_ key: String) -> DropTopPage? {
        cache[key]
    }
    
    func set(
        _ key: String,
        page: DropTopPage
    ) {
        cache[key] = page
    }
    
    func remove(_ key: String) {
        cache.removeValue(forKey: key)
        loadingKeys.remove(key)
    }
    
    func reset() {
        cache.removeAll()
        loadingKeys.removeAll()
    }
    
    func contains(_ key: String) -> Bool {
        cache[key] != nil
    }
    
    // =========================================================
    // MARK: Pagination Lock
    // =========================================================
    
    /// Возвращает true только если для этого tag
    /// сейчас ещё не выполняется pagination.
    func beginLoading(_ key: String) -> Bool {
        guard !loadingKeys.contains(key) else {
            return false
        }
        
        loadingKeys.insert(key)
        return true
    }
    
    func endLoading(_ key: String) {
        loadingKeys.remove(key)
    }
}
