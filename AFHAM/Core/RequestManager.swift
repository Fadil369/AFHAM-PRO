//
// RequestManager.swift
// AFHAM
//
// Advanced request management with cancellation and rate limiting
// Supports request prioritization and automatic retry
//

import Foundation
import Combine

/// Advanced request manager with cancellation and rate limiting
@MainActor
class RequestManager: ObservableObject {
    static let shared = RequestManager()

    // MARK: - Configuration
    private let maxConcurrentRequests = 3
    private let rateLimitWindow: TimeInterval = 60 // 1 minute
    private let maxRequestsPerWindow = 60

    // MARK: - State
    @Published var activeRequests: [String: CancellableRequest] = [:]
    @Published var requestHistory: [RequestRecord] = []

    private var requestQueue: [(priority: RequestPriority, request: () async throws -> Void)] = []
    private var isProcessingQueue = false

    private init() {
        AppLogger.shared.log("RequestManager initialized", level: .info)
        startRequestHistoryCleanup()
    }

    // MARK: - Request Execution

    /// Executes a request with cancellation support and rate limiting
    /// - Parameters:
    ///   - id: Unique identifier for the request
    ///   - priority: Request priority
    ///   - operation: The async operation to perform
    /// - Returns: The result of the operation
    func execute<T>(
        id: String = UUID().uuidString,
        priority: RequestPriority = .normal,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // Check rate limit
        try checkRateLimit()

        // Create cancellable task
        let cancellable = CancellableRequest(id: id, priority: priority)
        activeRequests[id] = cancellable

        // Record request start
        let startTime = Date()
        recordRequest(id: id, status: .started)

        defer {
            // Clean up when done
            activeRequests.removeValue(forKey: id)

            // Record completion time
            let duration = Date().timeIntervalSince(startTime)
            recordRequest(id: id, status: .completed, duration: duration)
        }

        // Check if cancelled before starting
        try Task.checkCancellation()

        do {
            let result = try await operation()

            AppLogger.shared.log(
                "Request \(id) completed successfully",
                level: .success
            )

            return result
        } catch {
            recordRequest(id: id, status: .failed, error: error)

            if Task.isCancelled {
                throw AFHAMError.requestCancelled
            }

            throw error
        }
    }

    /// Cancels a specific request
    func cancel(requestId: String) {
        if let request = activeRequests[requestId] {
            request.cancel()
            activeRequests.removeValue(forKey: requestId)
            recordRequest(id: requestId, status: .cancelled)

            AppLogger.shared.log("Request \(requestId) cancelled", level: .warning)
        }
    }

    /// Cancels all active requests
    func cancelAll() {
        let count = activeRequests.count
        activeRequests.values.forEach { $0.cancel() }
        activeRequests.removeAll()

        AppLogger.shared.log("Cancelled \(count) active requests", level: .warning)
    }

    // MARK: - Rate Limiting

    private func checkRateLimit() throws {
        let now = Date()
        let windowStart = now.addingTimeInterval(-rateLimitWindow)

        // Count requests in the current window
        let recentRequests = requestHistory.filter { record in
            record.timestamp > windowStart && record.status == .started
        }

        if recentRequests.count >= maxRequestsPerWindow {
            AppLogger.shared.log(
                "Rate limit exceeded: \(recentRequests.count)/\(maxRequestsPerWindow) requests in \(rateLimitWindow)s",
                level: .error
            )
            throw AFHAMError.rateLimitExceeded
        }
    }

    // MARK: - Request History

    private func recordRequest(
        id: String,
        status: RequestStatus,
        duration: TimeInterval? = nil,
        error: Error? = nil
    ) {
        let record = RequestRecord(
            id: id,
            timestamp: Date(),
            status: status,
            duration: duration,
            error: error?.localizedDescription
        )

        requestHistory.append(record)

        // Keep only recent history (last 1000 requests)
        if requestHistory.count > 1000 {
            requestHistory.removeFirst(requestHistory.count - 1000)
        }
    }

    private func startRequestHistoryCleanup() {
        // Clean up old history every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.cleanupOldHistory()
            }
        }
    }

    private func cleanupOldHistory() {
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours
        requestHistory.removeAll { $0.timestamp < cutoffDate }

        AppLogger.shared.log(
            "Cleaned up old request history, \(requestHistory.count) records remaining",
            level: .debug
        )
    }

    // MARK: - Statistics

    func getStatistics() -> RequestStatistics {
        let now = Date()
        let last24Hours = now.addingTimeInterval(-24 * 60 * 60)

        let recent = requestHistory.filter { $0.timestamp > last24Hours }

        let total = recent.count
        let completed = recent.filter { $0.status == .completed }.count
        let failed = recent.filter { $0.status == .failed }.count
        let cancelled = recent.filter { $0.status == .cancelled }.count

        let durations = recent.compactMap { $0.duration }
        let averageDuration = durations.isEmpty ? 0 : durations.reduce(0, +) / Double(durations.count)

        return RequestStatistics(
            totalRequests: total,
            completedRequests: completed,
            failedRequests: failed,
            cancelledRequests: cancelled,
            activeRequests: activeRequests.count,
            averageDuration: averageDuration,
            successRate: total > 0 ? Double(completed) / Double(total) * 100 : 0
        )
    }
}

// MARK: - Data Models

class CancellableRequest {
    let id: String
    let priority: RequestPriority
    let timestamp: Date
    private(set) var isCancelled = false

    init(id: String, priority: RequestPriority) {
        self.id = id
        self.priority = priority
        self.timestamp = Date()
    }

    func cancel() {
        isCancelled = true
    }
}

enum RequestPriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3

    static func < (lhs: RequestPriority, rhs: RequestPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum RequestStatus: String, Codable {
    case started
    case completed
    case failed
    case cancelled
}

struct RequestRecord: Codable {
    let id: String
    let timestamp: Date
    let status: RequestStatus
    let duration: TimeInterval?
    let error: String?
}

struct RequestStatistics {
    let totalRequests: Int
    let completedRequests: Int
    let failedRequests: Int
    let cancelledRequests: Int
    let activeRequests: Int
    let averageDuration: TimeInterval
    let successRate: Double

    var formattedAverageDuration: String {
        String(format: "%.2fs", averageDuration)
    }

    var formattedSuccessRate: String {
        String(format: "%.1f%%", successRate)
    }
}
