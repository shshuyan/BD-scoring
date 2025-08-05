import Foundation
import os.log

// MARK: - Performance Metrics
struct PerformanceMetrics {
    let operationType: String
    let duration: TimeInterval
    let timestamp: Date
    let memoryUsage: UInt64
    let success: Bool
    let additionalData: [String: Any]
    
    init(operationType: String, duration: TimeInterval, memoryUsage: UInt64 = 0, success: Bool = true, additionalData: [String: Any] = [:]) {
        self.operationType = operationType
        self.duration = duration
        self.timestamp = Date()
        self.memoryUsage = memoryUsage
        self.success = success
        self.additionalData = additionalData
    }
}

// MARK: - Performance Thresholds
struct PerformanceThresholds {
    static let scoringOperation: TimeInterval = 5.0 // 5 seconds max
    static let reportGeneration: TimeInterval = 10.0 // 10 seconds max
    static let batchProcessing: TimeInterval = 30.0 // 30 seconds per company max
    static let comparableSearch: TimeInterval = 2.0 // 2 seconds max
    static let databaseQuery: TimeInterval = 1.0 // 1 second max
}

// MARK: - Performance Monitoring Service
@MainActor
class PerformanceMonitoringService: ObservableObject {
    static let shared = PerformanceMonitoringService()
    
    private let logger = Logger(subsystem: "BDScoringModule", category: "Performance")
    private var metrics: [PerformanceMetrics] = []
    private let metricsQueue = DispatchQueue(label: "performance.metrics", qos: .utility)
    
    @Published var currentOperations: [String: Date] = [:]
    @Published var recentMetrics: [PerformanceMetrics] = []
    @Published var performanceAlerts: [String] = []
    
    private init() {}
    
    // MARK: - Operation Tracking
    func startOperation(_ operationType: String, identifier: String = UUID().uuidString) -> String {
        let operationId = "\(operationType)_\(identifier)"
        currentOperations[operationId] = Date()
        logger.info("Started operation: \(operationType) [\(operationId)]")
        return operationId
    }
    
    func endOperation(_ operationId: String, success: Bool = true, additionalData: [String: Any] = [:]) {
        guard let startTime = currentOperations[operationId] else {
            logger.warning("Attempted to end unknown operation: \(operationId)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let memoryUsage = getMemoryUsage()
        let operationType = String(operationId.split(separator: "_").first ?? "unknown")
        
        let metric = PerformanceMetrics(
            operationType: operationType,
            duration: duration,
            memoryUsage: memoryUsage,
            success: success,
            additionalData: additionalData
        )
        
        metricsQueue.async { [weak self] in
            self?.recordMetric(metric)
        }
        
        currentOperations.removeValue(forKey: operationId)
        
        // Check for performance issues
        checkPerformanceThreshold(metric)
        
        logger.info("Completed operation: \(operationType) in \(String(format: "%.3f", duration))s [\(operationId)]")
    }
    
    // MARK: - Metrics Recording
    private func recordMetric(_ metric: PerformanceMetrics) {
        metrics.append(metric)
        
        // Keep only recent metrics (last 1000)
        if metrics.count > 1000 {
            metrics.removeFirst(metrics.count - 1000)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.recentMetrics = Array((self?.metrics.suffix(50) ?? []).reversed())
        }
    }
    
    // MARK: - Performance Analysis
    func getAveragePerformance(for operationType: String, timeWindow: TimeInterval = 3600) -> (average: TimeInterval, count: Int) {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        let relevantMetrics = metrics.filter { 
            $0.operationType == operationType && $0.timestamp > cutoffTime 
        }
        
        guard !relevantMetrics.isEmpty else { return (0, 0) }
        
        let totalDuration = relevantMetrics.reduce(0) { $0 + $1.duration }
        return (totalDuration / Double(relevantMetrics.count), relevantMetrics.count)
    }
    
    func getPerformanceTrends(for operationType: String, bucketSize: TimeInterval = 300) -> [(timestamp: Date, averageDuration: TimeInterval)] {
        let relevantMetrics = metrics.filter { $0.operationType == operationType }
        
        let grouped = Dictionary(grouping: relevantMetrics) { metric in
            let bucketTimestamp = floor(metric.timestamp.timeIntervalSince1970 / bucketSize) * bucketSize
            return Date(timeIntervalSince1970: bucketTimestamp)
        }
        
        return grouped.map { (timestamp, metrics) in
            let averageDuration = metrics.reduce(0) { $0 + $1.duration } / Double(metrics.count)
            return (timestamp, averageDuration)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    // MARK: - Performance Alerts
    private func checkPerformanceThreshold(_ metric: PerformanceMetrics) {
        let threshold: TimeInterval
        
        switch metric.operationType {
        case "scoring":
            threshold = PerformanceThresholds.scoringOperation
        case "reportGeneration":
            threshold = PerformanceThresholds.reportGeneration
        case "batchProcessing":
            threshold = PerformanceThresholds.batchProcessing
        case "comparableSearch":
            threshold = PerformanceThresholds.comparableSearch
        case "databaseQuery":
            threshold = PerformanceThresholds.databaseQuery
        default:
            return
        }
        
        if metric.duration > threshold {
            let alert = "Performance threshold exceeded for \(metric.operationType): \(String(format: "%.3f", metric.duration))s (threshold: \(String(format: "%.3f", threshold))s)"
            
            DispatchQueue.main.async { [weak self] in
                self?.performanceAlerts.append(alert)
                if (self?.performanceAlerts.count ?? 0) > 20 {
                    self?.performanceAlerts.removeFirst()
                }
            }
            
            logger.warning("\(alert)")
        }
    }
    
    // MARK: - Memory Monitoring
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    // MARK: - Reporting
    func generatePerformanceReport() -> String {
        let operationTypes = Set(metrics.map { $0.operationType })
        var report = "Performance Report\n"
        report += "==================\n\n"
        
        for operationType in operationTypes.sorted() {
            let (average, count) = getAveragePerformance(for: operationType)
            let successRate = Double(metrics.filter { $0.operationType == operationType && $0.success }.count) / Double(count) * 100
            
            report += "\(operationType.capitalized):\n"
            report += "  Average Duration: \(String(format: "%.3f", average))s\n"
            report += "  Total Operations: \(count)\n"
            report += "  Success Rate: \(String(format: "%.1f", successRate))%\n\n"
        }
        
        return report
    }
}

// MARK: - Performance Measurement Extensions
extension PerformanceMonitoringService {
    func measureOperation<T>(_ operationType: String, operation: () throws -> T) rethrows -> T {
        let operationId = startOperation(operationType)
        
        do {
            let result = try operation()
            endOperation(operationId, success: true)
            return result
        } catch {
            endOperation(operationId, success: false, additionalData: ["error": error.localizedDescription])
            throw error
        }
    }
    
    func measureAsyncOperation<T>(_ operationType: String, operation: () async throws -> T) async rethrows -> T {
        let operationId = startOperation(operationType)
        
        do {
            let result = try await operation()
            endOperation(operationId, success: true)
            return result
        } catch {
            endOperation(operationId, success: false, additionalData: ["error": error.localizedDescription])
            throw error
        }
    }
}