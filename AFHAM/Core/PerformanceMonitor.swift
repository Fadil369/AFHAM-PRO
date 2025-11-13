//
// PerformanceMonitor.swift
// AFHAM
//
// Real-time performance monitoring and metrics collection
// Tracks CPU, memory, network, and operation performance
//

import Foundation
import os.signpost

/// Performance monitoring system for real-time metrics
@MainActor
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    // MARK: - Published Metrics
    @Published var currentCPUUsage: Double = 0
    @Published var currentMemoryUsage: Int64 = 0
    @Published var peakMemoryUsage: Int64 = 0
    @Published var networkActivityCount: Int = 0
    @Published var operationMetrics: [OperationMetric] = []

    // MARK: - Configuration
    private let updateInterval: TimeInterval = 2.0 // Update every 2 seconds
    private var updateTimer: Timer?

    // Performance thresholds
    private let memoryWarningThreshold: Int64 = 250 * 1024 * 1024 // 250 MB
    private let cpuWarningThreshold: Double = 80.0 // 80%

    // OS Signposts for advanced profiling
    private let log = OSLog(subsystem: "com.brainsait.afham", category: "Performance")
    private var signpostID: OSSignpostID {
        OSSignpostID(log: log)
    }

    private init() {
        startMonitoring()
        AppLogger.shared.log("PerformanceMonitor initialized", level: .info)
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateMetrics()
            }
        }

        // Immediate first update
        updateMetrics()
    }

    private func updateMetrics() {
        // Update CPU usage
        currentCPUUsage = getCPUUsage()

        // Update memory usage
        let memory = getMemoryUsage()
        currentMemoryUsage = memory
        peakMemoryUsage = max(peakMemoryUsage, memory)

        // Check for performance issues
        checkPerformanceThresholds()

        // Clean old operation metrics (keep last 100)
        if operationMetrics.count > 100 {
            operationMetrics.removeFirst(operationMetrics.count - 100)
        }
    }

    private func checkPerformanceThresholds() {
        if currentMemoryUsage > memoryWarningThreshold {
            AppLogger.shared.log(
                "⚠️ High memory usage: \(currentMemoryUsage / 1024 / 1024) MB",
                level: .warning
            )
        }

        if currentCPUUsage > cpuWarningThreshold {
            AppLogger.shared.log(
                "⚠️ High CPU usage: \(String(format: "%.1f", currentCPUUsage))%",
                level: .warning
            )
        }
    }

    // MARK: - Operation Tracking

    /// Measures the execution time of an operation
    func measure<T>(
        operation operationName: String,
        block: () throws -> T
    ) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getMemoryUsage()

        // OS Signpost begin
        os_signpost(.begin, log: log, name: "Operation", "%{public}s", operationName)

        defer {
            // OS Signpost end
            os_signpost(.end, log: log, name: "Operation", "%{public}s", operationName)

            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let endMemory = getMemoryUsage()
            let memoryDelta = endMemory - startMemory

            recordOperation(
                name: operationName,
                duration: duration,
                memoryDelta: memoryDelta
            )
        }

        return try block()
    }

    /// Measures the execution time of an async operation
    func measureAsync<T>(
        operation operationName: String,
        block: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getMemoryUsage()

        os_signpost(.begin, log: log, name: "Operation", "%{public}s", operationName)

        defer {
            os_signpost(.end, log: log, name: "Operation", "%{public}s", operationName)

            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let endMemory = getMemoryUsage()
            let memoryDelta = endMemory - startMemory

            recordOperation(
                name: operationName,
                duration: duration,
                memoryDelta: memoryDelta
            )
        }

        return try await block()
    }

    private func recordOperation(name: String, duration: TimeInterval, memoryDelta: Int64) {
        let metric = OperationMetric(
            name: name,
            duration: duration,
            timestamp: Date(),
            memoryDelta: memoryDelta
        )

        operationMetrics.append(metric)

        AppLogger.shared.log(
            "⏱️ \(name): \(String(format: "%.3f", duration))s, memory: \(memoryDelta / 1024) KB",
            level: .debug
        )
    }

    // MARK: - Network Activity

    func trackNetworkRequest(started: Bool) {
        if started {
            networkActivityCount += 1
        } else {
            networkActivityCount = max(0, networkActivityCount - 1)
        }
    }

    // MARK: - System Metrics

    private func getCPUUsage() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let threadResult = task_threads(mach_task_self_, &threadList, &threadCount)

        guard threadResult == KERN_SUCCESS,
              let threads = threadList else {
            return 0.0
        }

        var totalCPU: Double = 0.0

        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

            let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                }
            }

            guard infoResult == KERN_SUCCESS else { continue }

            let threadBasic = threadInfo as thread_basic_info

            if threadBasic.flags & TH_FLAGS_IDLE == 0 {
                totalCPU += Double(threadBasic.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), vm_size_t(Int(threadCount) * MemoryLayout<thread_t>.stride))

        return totalCPU
    }

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    // MARK: - Statistics

    func getStatistics() -> PerformanceStatistics {
        let recentOperations = operationMetrics.suffix(50)

        let averageDuration = recentOperations.isEmpty
            ? 0
            : recentOperations.reduce(0.0) { $0 + $1.duration } / Double(recentOperations.count)

        let slowestOperation = recentOperations.max { $0.duration < $1.duration }

        return PerformanceStatistics(
            currentCPU: currentCPUUsage,
            currentMemory: currentMemoryUsage,
            peakMemory: peakMemoryUsage,
            averageOperationDuration: averageDuration,
            slowestOperation: slowestOperation?.name,
            slowestOperationDuration: slowestOperation?.duration ?? 0,
            activeNetworkRequests: networkActivityCount,
            totalOperations: operationMetrics.count
        )
    }

    /// Exports performance data for analysis
    func exportPerformanceData() -> PerformanceReport {
        return PerformanceReport(
            timestamp: Date(),
            statistics: getStatistics(),
            operations: operationMetrics,
            deviceInfo: getDeviceInfo()
        )
    }

    private func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            model: DeviceInfo.modelName,
            systemVersion: DeviceInfo.systemVersion,
            isSimulator: DeviceInfo.isSimulator,
            screenSize: DeviceInfo.screenSize
        )
    }

    // MARK: - Cleanup

    deinit {
        updateTimer?.invalidate()
    }
}

// MARK: - Data Models

struct OperationMetric: Identifiable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let timestamp: Date
    let memoryDelta: Int64
}

struct PerformanceStatistics {
    let currentCPU: Double
    let currentMemory: Int64
    let peakMemory: Int64
    let averageOperationDuration: TimeInterval
    let slowestOperation: String?
    let slowestOperationDuration: TimeInterval
    let activeNetworkRequests: Int
    let totalOperations: Int

    var formattedCurrentMemory: String {
        ByteCountFormatter.string(fromByteCount: currentMemory, countStyle: .memory)
    }

    var formattedPeakMemory: String {
        ByteCountFormatter.string(fromByteCount: peakMemory, countStyle: .memory)
    }

    var formattedCPU: String {
        String(format: "%.1f%%", currentCPU)
    }

    var formattedAverageDuration: String {
        String(format: "%.3fs", averageOperationDuration)
    }
}

struct PerformanceReport: Codable {
    let timestamp: Date
    let statistics: PerformanceStatisticsCodable
    let operations: [OperationMetricCodable]
    let deviceInfo: DeviceInfo

    init(timestamp: Date, statistics: PerformanceStatistics, operations: [OperationMetric], deviceInfo: DeviceInfo) {
        self.timestamp = timestamp
        self.statistics = PerformanceStatisticsCodable(from: statistics)
        self.operations = operations.map { OperationMetricCodable(from: $0) }
        self.deviceInfo = deviceInfo
    }
}

struct PerformanceStatisticsCodable: Codable {
    let currentCPU: Double
    let currentMemory: Int64
    let peakMemory: Int64
    let averageOperationDuration: TimeInterval
    let slowestOperation: String?
    let slowestOperationDuration: TimeInterval
    let activeNetworkRequests: Int
    let totalOperations: Int

    init(from stats: PerformanceStatistics) {
        self.currentCPU = stats.currentCPU
        self.currentMemory = stats.currentMemory
        self.peakMemory = stats.peakMemory
        self.averageOperationDuration = stats.averageOperationDuration
        self.slowestOperation = stats.slowestOperation
        self.slowestOperationDuration = stats.slowestOperationDuration
        self.activeNetworkRequests = stats.activeNetworkRequests
        self.totalOperations = stats.totalOperations
    }
}

struct OperationMetricCodable: Codable {
    let name: String
    let duration: TimeInterval
    let timestamp: Date
    let memoryDelta: Int64

    init(from metric: OperationMetric) {
        self.name = metric.name
        self.duration = metric.duration
        self.timestamp = metric.timestamp
        self.memoryDelta = metric.memoryDelta
    }
}
