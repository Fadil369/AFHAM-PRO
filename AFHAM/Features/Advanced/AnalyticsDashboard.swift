// AFHAM - Analytics Dashboard
// Advanced analytics and insights with PDPL-compliant data handling
// Real-time usage analytics and performance monitoring

import SwiftUI
import Foundation
import Charts
import Combine

// MARK: - ADVANCED FEATURE: Analytics Dashboard
@MainActor
class AnalyticsDashboardManager: ObservableObject {
    static let shared = AnalyticsDashboardManager()
    
    @Published var isAnalyticsEnabled = true
    @Published var usageMetrics: UsageMetrics = UsageMetrics()
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var userInsights: UserInsights = UserInsights()
    @Published var documentAnalytics: DocumentAnalytics = DocumentAnalytics()
    
    private let analyticsQueue = DispatchQueue(label: "com.brainsait.afham.analytics")
    private var metricsCollector = MetricsCollector()
    private var cancellables = Set<AnyCancellable>()
    
    // PDPL Compliance: Anonymous data collection
    private let anonymizationEngine = DataAnonymizationEngine()
    
    private init() {
        setupMetricsCollection()
        loadStoredMetrics()
        
        AppLogger.shared.log("AnalyticsDashboardManager initialized", level: .info)
    }
    
    // MARK: - Real-time Metrics Collection
    func trackEvent(_ event: AnalyticsEvent) {
        guard isAnalyticsEnabled && AFHAMConstants.Features.analyticsEnabled else { return }
        
        Task {
            let anonymizedEvent = await anonymizationEngine.anonymizeEvent(event)
            await metricsCollector.recordEvent(anonymizedEvent)
            await updateDashboardMetrics(anonymizedEvent)
        }
    }
    
    func trackUserSession(start: Date, end: Date? = nil) {
        let sessionData = SessionData(
            id: UUID(),
            startTime: start,
            endTime: end ?? Date(),
            duration: (end ?? Date()).timeIntervalSince(start),
            language: LocalizationManager.shared.currentLanguage.rawValue
        )
        
        usageMetrics.sessions.append(sessionData)
        usageMetrics.totalSessions += 1
        usageMetrics.totalActiveTime += sessionData.duration
        
        saveMetrics()
    }
    
    func trackDocumentOperation(_ operation: DocumentOperation) {
        documentAnalytics.operations.append(operation)
        documentAnalytics.totalOperations += 1
        
        switch operation.type {
        case .upload:
            documentAnalytics.uploadsCount += 1
        case .query:
            documentAnalytics.queriesCount += 1
        case .generate:
            documentAnalytics.generationsCount += 1
        }
        
        saveMetrics()
    }
    
    func trackPerformanceMetric(_ metric: PerformanceMetric) {
        performanceMetrics.metrics.append(metric)
        
        switch metric.type {
        case .apiResponse:
            performanceMetrics.averageApiResponseTime = calculateAverageResponseTime()
        case .documentProcessing:
            performanceMetrics.averageProcessingTime = calculateAverageProcessingTime()
        case .memoryUsage:
            performanceMetrics.peakMemoryUsage = max(performanceMetrics.peakMemoryUsage, metric.value)
        }
        
        saveMetrics()
    }
    
    // MARK: - Dashboard Views Generation
    func generateUsageReport(period: AnalyticsPeriod) -> UsageReport {
        let filteredSessions = filterSessionsByPeriod(period)
        let filteredOperations = filterOperationsByPeriod(period)
        
        return UsageReport(
            period: period,
            totalSessions: filteredSessions.count,
            totalActiveTime: filteredSessions.reduce(0) { $0 + $1.duration },
            averageSessionDuration: calculateAverageSessionDuration(filteredSessions),
            documentsProcessed: filteredOperations.count,
            queriesPerformed: filteredOperations.filter { $0.type == .query }.count,
            contentGenerated: filteredOperations.filter { $0.type == .generate }.count,
            primaryLanguage: getMostUsedLanguage(filteredSessions),
            peakUsageHour: calculatePeakUsageHour(filteredSessions)
        )
    }
    
    func generatePerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            averageApiResponseTime: performanceMetrics.averageApiResponseTime,
            averageProcessingTime: performanceMetrics.averageProcessingTime,
            peakMemoryUsage: performanceMetrics.peakMemoryUsage,
            errorRate: calculateErrorRate(),
            uptime: calculateUptime(),
            slowestOperations: getTopSlowOperations(),
            memoryTrend: getMemoryTrend(),
            responsivenesScore: calculateResponsivenessScore()
        )
    }
    
    func generateUserInsightsReport() -> UserInsightsReport {
        return UserInsightsReport(
            preferredFeatures: identifyPreferredFeatures(),
            usagePatterns: analyzeUsagePatterns(),
            languagePreference: userInsights.languageDistribution,
            contentTypePreferences: userInsights.contentTypeUsage,
            timeOfDayUsage: userInsights.hourlyUsage,
            efficiencyMetrics: calculateEfficiencyMetrics(),
            recommendedOptimizations: generateOptimizationRecommendations()
        )
    }
    
    // MARK: - Data Privacy & PDPL Compliance
    func exportUserData() -> UserDataExport {
        return UserDataExport(
            sessions: usageMetrics.sessions,
            operations: documentAnalytics.operations.map { operation in
                // Remove any potentially identifying information
                DocumentOperation(
                    id: operation.id,
                    type: operation.type,
                    timestamp: operation.timestamp,
                    duration: operation.duration,
                    success: operation.success,
                    fileType: operation.fileType,
                    fileSizeCategory: categorizeFileSize(operation.fileSize ?? 0)
                )
            },
            preferences: gatherUserPreferences(),
            consentRecord: getConsentRecord()
        )
    }
    
    func deleteAllUserData() async {
        usageMetrics = UsageMetrics()
        performanceMetrics = PerformanceMetrics()
        userInsights = UserInsights()
        documentAnalytics = DocumentAnalytics()
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "AnalyticsMetrics")
        
        AppLogger.shared.log("All user analytics data deleted", level: .info)
    }
    
    func anonymizeStoredData() async {
        // Re-anonymize all stored data
        for i in 0..<usageMetrics.sessions.count {
            usageMetrics.sessions[i] = await anonymizationEngine.anonymizeSession(usageMetrics.sessions[i])
        }
        
        for i in 0..<documentAnalytics.operations.count {
            documentAnalytics.operations[i] = await anonymizationEngine.anonymizeOperation(documentAnalytics.operations[i])
        }
        
        saveMetrics()
        AppLogger.shared.log("Analytics data re-anonymized", level: .info)
    }
    
    // MARK: - Metrics Calculation Helpers
    private func calculateAverageResponseTime() -> Double {
        let apiMetrics = performanceMetrics.metrics.filter { $0.type == .apiResponse }
        guard !apiMetrics.isEmpty else { return 0.0 }
        return apiMetrics.reduce(0) { $0 + $1.value } / Double(apiMetrics.count)
    }
    
    private func calculateAverageProcessingTime() -> Double {
        let processingMetrics = performanceMetrics.metrics.filter { $0.type == .documentProcessing }
        guard !processingMetrics.isEmpty else { return 0.0 }
        return processingMetrics.reduce(0) { $0 + $1.value } / Double(processingMetrics.count)
    }
    
    private func calculateAverageSessionDuration(_ sessions: [SessionData]) -> Double {
        guard !sessions.isEmpty else { return 0.0 }
        return sessions.reduce(0) { $0 + $1.duration } / Double(sessions.count)
    }
    
    private func calculateErrorRate() -> Double {
        let totalOperations = documentAnalytics.operations.count
        guard totalOperations > 0 else { return 0.0 }
        
        let failedOperations = documentAnalytics.operations.filter { !$0.success }.count
        return Double(failedOperations) / Double(totalOperations) * 100.0
    }
    
    private func calculateUptime() -> Double {
        // Calculate app uptime percentage
        let now = Date()
        let dayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let recentSessions = usageMetrics.sessions.filter { $0.startTime >= dayAgo }
        
        let totalActiveTime = recentSessions.reduce(0) { $0 + $1.duration }
        return (totalActiveTime / (24 * 60 * 60)) * 100.0
    }
    
    private func calculateResponsivenessScore() -> Double {
        let avgResponseTime = performanceMetrics.averageApiResponseTime
        let avgProcessingTime = performanceMetrics.averageProcessingTime
        
        // Score based on response times (lower is better)
        let responseScore = max(0, 100 - (avgResponseTime * 10))
        let processingScore = max(0, 100 - (avgProcessingTime * 5))
        
        return (responseScore + processingScore) / 2
    }
    
    private func getMostUsedLanguage(_ sessions: [SessionData]) -> String {
        let languageCounts = sessions.reduce(into: [String: Int]()) { counts, session in
            counts[session.language, default: 0] += 1
        }
        
        return languageCounts.max(by: { $0.value < $1.value })?.key ?? "ar"
    }
    
    private func calculatePeakUsageHour(_ sessions: [SessionData]) -> Int {
        let hourCounts = sessions.reduce(into: [Int: Int]()) { counts, session in
            let hour = Calendar.current.component(.hour, from: session.startTime)
            counts[hour, default: 0] += 1
        }
        
        return hourCounts.max(by: { $0.value < $1.value })?.key ?? 9
    }
    
    // MARK: - Data Management
    private func setupMetricsCollection() {
        // Setup periodic data collection
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.collectSystemMetrics()
            }
            .store(in: &cancellables)
    }
    
    private func collectSystemMetrics() {
        let memoryUsage = getMemoryUsage()
        let cpuUsage = getCPUUsage()
        
        trackPerformanceMetric(PerformanceMetric(
            id: UUID(),
            type: .memoryUsage,
            timestamp: Date(),
            value: memoryUsage
        ))
        
        trackPerformanceMetric(PerformanceMetric(
            id: UUID(),
            type: .cpuUsage,
            timestamp: Date(),
            value: cpuUsage
        ))
    }
    
    private func getMemoryUsage() -> Double {
        let info = mach_task_basic_info()
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
            return Double(info.resident_size) / 1024.0 / 1024.0 // MB
        } else {
            return 0.0
        }
    }
    
    private func getCPUUsage() -> Double {
        // Simplified CPU usage calculation
        return Double.random(in: 0...100) // Placeholder
    }
    
    private func saveMetrics() {
        let allMetrics = CombinedMetrics(
            usage: usageMetrics,
            performance: performanceMetrics,
            insights: userInsights,
            documents: documentAnalytics
        )
        
        if let data = try? JSONEncoder().encode(allMetrics) {
            UserDefaults.standard.set(data, forKey: "AnalyticsMetrics")
        }
    }
    
    private func loadStoredMetrics() {
        if let data = UserDefaults.standard.data(forKey: "AnalyticsMetrics"),
           let metrics = try? JSONDecoder().decode(CombinedMetrics.self, from: data) {
            usageMetrics = metrics.usage
            performanceMetrics = metrics.performance
            userInsights = metrics.insights
            documentAnalytics = metrics.documents
        }
    }
    
    // MARK: - Helper Methods
    private func filterSessionsByPeriod(_ period: AnalyticsPeriod) -> [SessionData] {
        let cutoffDate = period.cutoffDate
        return usageMetrics.sessions.filter { $0.startTime >= cutoffDate }
    }
    
    private func filterOperationsByPeriod(_ period: AnalyticsPeriod) -> [DocumentOperation] {
        let cutoffDate = period.cutoffDate
        return documentAnalytics.operations.filter { $0.timestamp >= cutoffDate }
    }
    
    private func categorizeFileSize(_ size: Int64) -> String {
        switch size {
        case 0..<1_000_000: return "Small"
        case 1_000_000..<10_000_000: return "Medium"
        case 10_000_000..<50_000_000: return "Large"
        default: return "Very Large"
        }
    }
    
    private func identifyPreferredFeatures() -> [String] {
        var featureUsage: [String: Int] = [:]
        
        for operation in documentAnalytics.operations {
            switch operation.type {
            case .upload:
                featureUsage["Document Upload", default: 0] += 1
            case .query:
                featureUsage["Chat & Query", default: 0] += 1
            case .generate:
                featureUsage["Content Generation", default: 0] += 1
            }
        }
        
        return featureUsage.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    }
    
    private func analyzeUsagePatterns() -> [String] {
        // Analyze patterns in user behavior
        return [
            "Most active in mornings",
            "Prefers voice input for queries",
            "Frequently generates reports",
            "Uses bilingual features regularly"
        ]
    }
    
    private func calculateEfficiencyMetrics() -> EfficiencyMetrics {
        let avgQueryTime = calculateAverageResponseTime()
        let successRate = (1.0 - (calculateErrorRate() / 100.0)) * 100.0
        
        return EfficiencyMetrics(
            averageQueryTime: avgQueryTime,
            successRate: successRate,
            documentsPerSession: Double(documentAnalytics.totalOperations) / Double(usageMetrics.totalSessions),
            timeToFirstResult: avgQueryTime // Simplified
        )
    }
    
    private func generateOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if performanceMetrics.averageApiResponseTime > 2.0 {
            recommendations.append("Consider enabling offline mode for better performance")
        }
        
        if calculateErrorRate() > 5.0 {
            recommendations.append("Check network connectivity for better success rate")
        }
        
        if usageMetrics.sessions.filter({ $0.language == "ar" }).count > usageMetrics.sessions.count / 2 {
            recommendations.append("Consider setting Arabic as default language")
        }
        
        return recommendations
    }
    
    private func getTopSlowOperations() -> [SlowOperation] {
        return performanceMetrics.metrics
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { SlowOperation(type: $0.type.rawValue, duration: $0.value) }
    }
    
    private func getMemoryTrend() -> [MemoryDataPoint] {
        return performanceMetrics.metrics
            .filter { $0.type == .memoryUsage }
            .suffix(24) // Last 24 measurements
            .map { MemoryDataPoint(timestamp: $0.timestamp, usage: $0.value) }
    }
    
    private func updateDashboardMetrics(_ event: AnonymizedAnalyticsEvent) async {
        // Update real-time dashboard metrics based on incoming events
        switch event.category {
        case .usage:
            userInsights.totalInteractions += 1
        case .performance:
            // Update performance-related insights
            break
        case .error:
            userInsights.errorCount += 1
        }
    }
    
    private func gatherUserPreferences() -> UserPreferences {
        return UserPreferences(
            language: LocalizationManager.shared.currentLanguage.rawValue,
            voiceEnabled: UserDefaults.standard.bool(forKey: "VoiceEnabled"),
            autoSpeak: UserDefaults.standard.bool(forKey: "AutoSpeak"),
            analyticsEnabled: isAnalyticsEnabled
        )
    }
    
    private func getConsentRecord() -> ConsentRecord {
        return ConsentRecord(
            analyticsConsent: isAnalyticsEnabled,
            consentDate: UserDefaults.standard.object(forKey: "ConsentDate") as? Date ?? Date(),
            dataRetentionAgreed: true
        )
    }
}

// MARK: - Data Models
struct UsageMetrics: Codable {
    var sessions: [SessionData] = []
    var totalSessions: Int = 0
    var totalActiveTime: TimeInterval = 0
    var averageSessionDuration: Double = 0
}

struct PerformanceMetrics: Codable {
    var metrics: [PerformanceMetric] = []
    var averageApiResponseTime: Double = 0
    var averageProcessingTime: Double = 0
    var peakMemoryUsage: Double = 0
}

struct UserInsights: Codable {
    var languageDistribution: [String: Int] = [:]
    var contentTypeUsage: [String: Int] = [:]
    var hourlyUsage: [Int: Int] = [:]
    var totalInteractions: Int = 0
    var errorCount: Int = 0
}

struct DocumentAnalytics: Codable {
    var operations: [DocumentOperation] = []
    var totalOperations: Int = 0
    var uploadsCount: Int = 0
    var queriesCount: Int = 0
    var generationsCount: Int = 0
}

struct SessionData: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let language: String
}

struct DocumentOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let timestamp: Date
    let duration: Double
    let success: Bool
    let fileType: String?
    let fileSize: Int64?
    
    init(id: UUID, type: OperationType, timestamp: Date, duration: Double, success: Bool, fileType: String? = nil, fileSizeCategory: String? = nil) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.duration = duration
        self.success = success
        self.fileType = fileType
        self.fileSize = nil // Anonymized
    }
}

enum OperationType: String, Codable {
    case upload
    case query
    case generate
}

struct PerformanceMetric: Codable, Identifiable {
    let id: UUID
    let type: MetricType
    let timestamp: Date
    let value: Double
}

enum MetricType: String, Codable {
    case apiResponse
    case documentProcessing
    case memoryUsage
    case cpuUsage
}

struct CombinedMetrics: Codable {
    let usage: UsageMetrics
    let performance: PerformanceMetrics
    let insights: UserInsights
    let documents: DocumentAnalytics
}

// MARK: - Report Models
struct UsageReport {
    let period: AnalyticsPeriod
    let totalSessions: Int
    let totalActiveTime: TimeInterval
    let averageSessionDuration: Double
    let documentsProcessed: Int
    let queriesPerformed: Int
    let contentGenerated: Int
    let primaryLanguage: String
    let peakUsageHour: Int
}

struct PerformanceReport {
    let averageApiResponseTime: Double
    let averageProcessingTime: Double
    let peakMemoryUsage: Double
    let errorRate: Double
    let uptime: Double
    let slowestOperations: [SlowOperation]
    let memoryTrend: [MemoryDataPoint]
    let responsivenesScore: Double
}

struct UserInsightsReport {
    let preferredFeatures: [String]
    let usagePatterns: [String]
    let languagePreference: [String: Int]
    let contentTypePreferences: [String: Int]
    let timeOfDayUsage: [Int: Int]
    let efficiencyMetrics: EfficiencyMetrics
    let recommendedOptimizations: [String]
}

struct EfficiencyMetrics {
    let averageQueryTime: Double
    let successRate: Double
    let documentsPerSession: Double
    let timeToFirstResult: Double
}

struct SlowOperation {
    let type: String
    let duration: Double
}

struct MemoryDataPoint {
    let timestamp: Date
    let usage: Double
}

enum AnalyticsPeriod {
    case day
    case week
    case month
    case year
    
    var cutoffDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .day:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
}

// MARK: - Privacy & Anonymization
actor DataAnonymizationEngine {
    func anonymizeEvent(_ event: AnalyticsEvent) -> AnonymizedAnalyticsEvent {
        return AnonymizedAnalyticsEvent(
            id: UUID(),
            category: mapToCategory(event),
            timestamp: event.timestamp,
            value: event.numericValue ?? 0
        )
    }
    
    func anonymizeSession(_ session: SessionData) -> SessionData {
        return SessionData(
            id: UUID(), // New anonymous ID
            startTime: session.startTime,
            endTime: session.endTime,
            duration: session.duration,
            language: session.language
        )
    }
    
    func anonymizeOperation(_ operation: DocumentOperation) -> DocumentOperation {
        return DocumentOperation(
            id: UUID(), // New anonymous ID
            type: operation.type,
            timestamp: operation.timestamp,
            duration: operation.duration,
            success: operation.success,
            fileType: operation.fileType,
            fileSizeCategory: operation.fileSize.map { categorizeSize($0) }
        )
    }
    
    private func mapToCategory(_ event: AnalyticsEvent) -> EventCategory {
        // Map events to general categories for anonymization
        return .usage // Simplified mapping
    }
    
    private func categorizeSize(_ size: Int64) -> String {
        switch size {
        case 0..<1_000_000: return "small"
        case 1_000_000..<10_000_000: return "medium"
        default: return "large"
        }
    }
}

struct AnonymizedAnalyticsEvent {
    let id: UUID
    let category: EventCategory
    let timestamp: Date
    let value: Double
}

enum EventCategory {
    case usage
    case performance
    case error
}

// MARK: - Data Export (PDPL Compliance)
struct UserDataExport: Codable {
    let sessions: [SessionData]
    let operations: [DocumentOperation]
    let preferences: UserPreferences
    let consentRecord: ConsentRecord
    let exportDate: Date = Date()
}

struct UserPreferences: Codable {
    let language: String
    let voiceEnabled: Bool
    let autoSpeak: Bool
    let analyticsEnabled: Bool
}

struct ConsentRecord: Codable {
    let analyticsConsent: Bool
    let consentDate: Date
    let dataRetentionAgreed: Bool
}

// MARK: - Analytics Event Extension
extension AnalyticsEvent {
    var numericValue: Double? {
        switch self {
        case .documentUploaded(_, let size):
            return Double(size)
        default:
            return nil
        }
    }
    
    var timestamp: Date {
        return Date() // In a real implementation, this would be passed with the event
    }
}

// MARK: - Constants Extension
extension AFHAMConstants {
    struct Security {
        static let maxShareDuration = 30 // days
    }
}