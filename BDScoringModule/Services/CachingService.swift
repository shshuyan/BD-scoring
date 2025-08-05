import Foundation
import os.log

// MARK: - Cache Entry
private class CacheEntry<T> {
    let value: T
    let timestamp: Date
    let expirationTime: TimeInterval
    
    init(value: T, expirationTime: TimeInterval) {
        self.value = value
        self.timestamp = Date()
        self.expirationTime = expirationTime
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}

// MARK: - Cache Configuration
struct CacheConfiguration {
    let maxSize: Int
    let defaultTTL: TimeInterval
    
    static let `default` = CacheConfiguration(maxSize: 1000, defaultTTL: 300) // 5 minutes
    static let comparables = CacheConfiguration(maxSize: 500, defaultTTL: 1800) // 30 minutes
    static let companyData = CacheConfiguration(maxSize: 200, defaultTTL: 600) // 10 minutes
    static let reports = CacheConfiguration(maxSize: 100, defaultTTL: 3600) // 1 hour
}

// MARK: - Caching Service
@MainActor
class CachingService: ObservableObject {
    static let shared = CachingService()
    
    private let logger = Logger(subsystem: "BDScoringModule", category: "Caching")
    private var caches: [String: Any] = [:]
    private let cacheQueue = DispatchQueue(label: "cache.operations", qos: .utility)
    
    @Published var cacheStats: [String: CacheStats] = [:]
    
    private init() {
        setupPeriodicCleanup()
    }
    
    // MARK: - Cache Operations
    func get<T>(_ key: String, from cacheType: String = "default") -> T? {
        return cacheQueue.sync {
            guard let cache = getCache(cacheType, type: T.self) else { return nil }
            
            if let entry = cache[key] {
                if entry.isExpired {
                    cache.removeValue(forKey: key)
                    updateStats(for: cacheType, hit: false, expired: true)
                    return nil
                } else {
                    updateStats(for: cacheType, hit: true)
                    return entry.value
                }
            } else {
                updateStats(for: cacheType, hit: false)
                return nil
            }
        }
    }
    
    func set<T>(_ key: String, value: T, ttl: TimeInterval? = nil, in cacheType: String = "default") {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            let cache = self.getOrCreateCache(cacheType, type: T.self)
            let config = self.getConfiguration(for: cacheType)
            let actualTTL = ttl ?? config.defaultTTL
            
            cache[key] = CacheEntry(value: value, expirationTime: actualTTL)
            
            // Enforce cache size limits
            if cache.count > config.maxSize {
                self.evictOldestEntries(from: cache, targetSize: Int(Double(config.maxSize) * 0.8))
            }
            
            self.updateStats(for: cacheType, set: true)
        }
    }
    
    func remove(_ key: String, from cacheType: String = "default") {
        cacheQueue.async { [weak self] in
            guard let cache = self?.getCache(cacheType, type: Any.self) else { return }
            cache.removeValue(forKey: key)
        }
    }
    
    func clear(_ cacheType: String = "default") {
        cacheQueue.async { [weak self] in
            guard let cache = self?.getCache(cacheType, type: Any.self) else { return }
            cache.removeAll()
            self?.resetStats(for: cacheType)
        }
    }
    
    func clearAll() {
        cacheQueue.async { [weak self] in
            self?.caches.removeAll()
            DispatchQueue.main.async {
                self?.cacheStats.removeAll()
            }
        }
    }
    
    // MARK: - Cache Management
    private func getCache<T>(_ cacheType: String, type: T.Type) -> [String: CacheEntry<T>]? {
        return caches[cacheType] as? [String: CacheEntry<T>]
    }
    
    private func getOrCreateCache<T>(_ cacheType: String, type: T.Type) -> [String: CacheEntry<T>] {
        if let existingCache = caches[cacheType] as? [String: CacheEntry<T>] {
            return existingCache
        } else {
            let newCache: [String: CacheEntry<T>] = [:]
            caches[cacheType] = newCache
            return newCache
        }
    }
    
    private func getConfiguration(for cacheType: String) -> CacheConfiguration {
        switch cacheType {
        case "comparables":
            return .comparables
        case "companyData":
            return .companyData
        case "reports":
            return .reports
        default:
            return .default
        }
    }
    
    private func evictOldestEntries<T>(from cache: [String: CacheEntry<T>], targetSize: Int) {
        let sortedEntries = cache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(cache.count - targetSize)
        
        for (key, _) in entriesToRemove {
            cache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Cache Statistics
    private func updateStats(for cacheType: String, hit: Bool = false, set: Bool = false, expired: Bool = false) {
        DispatchQueue.main.async { [weak self] in
            var stats = self?.cacheStats[cacheType] ?? CacheStats()
            
            if hit {
                stats.hits += 1
            } else if !set {
                stats.misses += 1
            }
            
            if set {
                stats.sets += 1
            }
            
            if expired {
                stats.expirations += 1
            }
            
            self?.cacheStats[cacheType] = stats
        }
    }
    
    private func resetStats(for cacheType: String) {
        DispatchQueue.main.async { [weak self] in
            self?.cacheStats[cacheType] = CacheStats()
        }
    }
    
    // MARK: - Periodic Cleanup
    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.cleanupExpiredEntries()
        }
    }
    
    private func cleanupExpiredEntries() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            for (cacheType, cacheObj) in self.caches {
                if let cache = cacheObj as? [String: CacheEntry<Any>] {
                    let expiredKeys = cache.compactMap { (key, entry) in
                        entry.isExpired ? key : nil
                    }
                    
                    for key in expiredKeys {
                        cache.removeValue(forKey: key)
                    }
                    
                    if !expiredKeys.isEmpty {
                        self.logger.info("Cleaned up \(expiredKeys.count) expired entries from \(cacheType) cache")
                    }
                }
            }
        }
    }
}

// MARK: - Cache Statistics
struct CacheStats {
    var hits: Int = 0
    var misses: Int = 0
    var sets: Int = 0
    var expirations: Int = 0
    
    var hitRate: Double {
        let total = hits + misses
        return total > 0 ? Double(hits) / Double(total) : 0.0
    }
    
    var totalOperations: Int {
        return hits + misses + sets
    }
}

// MARK: - Cacheable Protocol
protocol Cacheable {
    var cacheKey: String { get }
    var cacheTTL: TimeInterval { get }
}

// MARK: - Cache Extensions for Common Operations
extension CachingService {
    // Company data caching
    func cacheCompanyData(_ data: CompanyData, for companyId: String) {
        set("company_\(companyId)", value: data, in: "companyData")
    }
    
    func getCachedCompanyData(for companyId: String) -> CompanyData? {
        return get("company_\(companyId)", from: "companyData")
    }
    
    // Comparables caching
    func cacheComparables(_ comparables: [Comparable], for criteria: String) {
        set("comparables_\(criteria)", value: comparables, in: "comparables")
    }
    
    func getCachedComparables(for criteria: String) -> [Comparable]? {
        return get("comparables_\(criteria)", from: "comparables")
    }
    
    // Scoring results caching
    func cacheScoringResult(_ result: ScoringResult, for companyId: String, configHash: String) {
        let key = "scoring_\(companyId)_\(configHash)"
        set(key, value: result, ttl: 1800, in: "default") // 30 minutes for scoring results
    }
    
    func getCachedScoringResult(for companyId: String, configHash: String) -> ScoringResult? {
        let key = "scoring_\(companyId)_\(configHash)"
        return get(key, from: "default")
    }
    
    // Report caching
    func cacheReport(_ report: Report, for reportId: String) {
        set("report_\(reportId)", value: report, in: "reports")
    }
    
    func getCachedReport(for reportId: String) -> Report? {
        return get("report_\(reportId)", from: "reports")
    }
}

// MARK: - Performance Optimized Database Query Extensions
extension CachingService {
    func withCache<T>(_ key: String, cacheType: String = "default", ttl: TimeInterval? = nil, operation: () async throws -> T) async rethrows -> T {
        // Try to get from cache first
        if let cachedValue: T = get(key, from: cacheType) {
            return cachedValue
        }
        
        // Execute operation and cache result
        let result = try await operation()
        set(key, value: result, ttl: ttl, in: cacheType)
        return result
    }
    
    func withCache<T>(_ key: String, cacheType: String = "default", ttl: TimeInterval? = nil, operation: () throws -> T) rethrows -> T {
        // Try to get from cache first
        if let cachedValue: T = get(key, from: cacheType) {
            return cachedValue
        }
        
        // Execute operation and cache result
        let result = try operation()
        set(key, value: result, ttl: ttl, in: cacheType)
        return result
    }
}