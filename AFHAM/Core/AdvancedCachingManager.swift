//
// AdvancedCachingManager.swift
// AFHAM
//
// Advanced multi-level caching system with encryption
// Memory + Disk caching with intelligent eviction
// PDPL Compliant with automatic data retention
//

import Foundation
import CryptoKit

/// Advanced caching manager with memory and encrypted disk storage
@MainActor
class AdvancedCachingManager {
    static let shared = AdvancedCachingManager()

    // MARK: - Configuration
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50 MB
    private let maxDiskCacheSize: Int64 = 500 * 1024 * 1024 // 500 MB
    private let cacheExpirationTime: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let cleanupInterval: TimeInterval = 24 * 60 * 60 // 24 hours

    // MARK: - Storage
    private var memoryCache = NSCache<NSString, CacheEntry>()
    private let diskCacheURL: URL
    private let encryptionKey: SymmetricKey

    // MARK: - Statistics
    @Published var cacheHits: Int = 0
    @Published var cacheMisses: Int = 0
    @Published var memoryUsage: Int = 0
    @Published var diskUsage: Int64 = 0

    private init() {
        // Setup disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDir.appendingPathComponent("AFHAMCache", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Generate or load encryption key
        encryptionKey = Self.getOrCreateEncryptionKey()

        // Configure memory cache
        memoryCache.countLimit = 100 // 100 items
        memoryCache.totalCostLimit = maxMemoryCacheSize

        // Setup memory warning observer
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }

        // Schedule periodic cleanup
        schedulePeriodicCleanup()

        AppLogger.shared.log("AdvancedCachingManager initialized", level: .success)
    }

    // MARK: - Public API

    /// Stores data in cache with optional expiration
    func store(_ data: Data, forKey key: String, expiration: TimeInterval? = nil) async throws {
        let entry = CacheEntry(
            data: data,
            timestamp: Date(),
            expiration: expiration ?? cacheExpirationTime,
            size: data.count
        )

        // Store in memory cache
        memoryCache.setObject(entry, forKey: key as NSString, cost: data.count)
        memoryUsage += data.count

        // Store encrypted on disk
        try await storeToDisk(entry, forKey: key)

        AppLogger.shared.log("Cached \(data.count) bytes for key: \(key)", level: .debug)
    }

    /// Retrieves data from cache
    func retrieve(forKey key: String) async -> Data? {
        // Check memory cache first
        if let entry = memoryCache.object(forKey: key as NSString) {
            if !entry.isExpired {
                cacheHits += 1
                AppLogger.shared.log("Memory cache hit for key: \(key)", level: .debug)
                return entry.data
            } else {
                // Remove expired entry
                memoryCache.removeObject(forKey: key as NSString)
            }
        }

        // Check disk cache
        if let entry = await retrieveFromDisk(forKey: key) {
            if !entry.isExpired {
                // Promote to memory cache
                memoryCache.setObject(entry, forKey: key as NSString, cost: entry.size)
                cacheHits += 1
                AppLogger.shared.log("Disk cache hit for key: \(key)", level: .debug)
                return entry.data
            } else {
                // Remove expired entry
                await removeFromDisk(forKey: key)
            }
        }

        cacheMisses += 1
        AppLogger.shared.log("Cache miss for key: \(key)", level: .debug)
        return nil
    }

    /// Removes data from cache
    func remove(forKey key: String) async {
        memoryCache.removeObject(forKey: key as NSString)
        await removeFromDisk(forKey: key)
    }

    /// Clears all cache
    func clearAll() async {
        memoryCache.removeAllObjects()
        memoryUsage = 0

        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
            diskUsage = 0
            AppLogger.shared.log("All cache cleared", level: .info)
        } catch {
            AppLogger.shared.logError(error, context: "Clear cache")
        }
    }

    /// Gets cache statistics
    func getStatistics() -> CacheStatistics {
        let hitRate = cacheHits + cacheMisses > 0
            ? Double(cacheHits) / Double(cacheHits + cacheMisses) * 100
            : 0

        return CacheStatistics(
            memoryUsage: memoryUsage,
            diskUsage: diskUsage,
            cacheHits: cacheHits,
            cacheMisses: cacheMisses,
            hitRate: hitRate,
            itemCount: memoryCache.countLimit
        )
    }

    // MARK: - Disk Operations

    private func storeToDisk(_ entry: CacheEntry, forKey key: String) async throws {
        let fileURL = cacheFileURL(forKey: key)

        // Encrypt data before writing
        let encryptedData = try encrypt(entry.data)

        // Create metadata
        let metadata = CacheMetadata(
            key: key,
            timestamp: entry.timestamp,
            expiration: entry.expiration,
            size: entry.size
        )

        let metadataData = try JSONEncoder().encode(metadata)

        // Combine metadata and encrypted data
        var combinedData = Data()
        let metadataSize = UInt32(metadataData.count)
        withUnsafeBytes(of: metadataSize) { combinedData.append(contentsOf: $0) }
        combinedData.append(metadataData)
        combinedData.append(encryptedData)

        // Write to disk
        try combinedData.write(to: fileURL, options: .atomic)
        diskUsage += Int64(combinedData.count)

        // Check disk cache size and clean if necessary
        await cleanupDiskCacheIfNeeded()
    }

    private func retrieveFromDisk(forKey key: String) async -> CacheEntry? {
        let fileURL = cacheFileURL(forKey: key)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let combinedData = try Data(contentsOf: fileURL)

            // Read metadata size
            guard combinedData.count >= 4 else { return nil }
            let metadataSize = combinedData.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }

            // Read metadata
            let metadataStart = 4
            let metadataEnd = metadataStart + Int(metadataSize)
            guard combinedData.count >= metadataEnd else { return nil }

            let metadataData = combinedData.subdata(in: metadataStart..<metadataEnd)
            let metadata = try JSONDecoder().decode(CacheMetadata.self, from: metadataData)

            // Read and decrypt data
            let encryptedData = combinedData.suffix(from: metadataEnd)
            let decryptedData = try decrypt(encryptedData)

            return CacheEntry(
                data: decryptedData,
                timestamp: metadata.timestamp,
                expiration: metadata.expiration,
                size: metadata.size
            )
        } catch {
            AppLogger.shared.logError(error, context: "Retrieve from disk cache")
            return nil
        }
    }

    private func removeFromDisk(forKey key: String) async {
        let fileURL = cacheFileURL(forKey: key)
        if let size = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 {
            diskUsage -= size
        }
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func cacheFileURL(forKey key: String) -> URL {
        let hashedKey = SHA256.hash(data: key.data(using: .utf8)!)
        let filename = hashedKey.compactMap { String(format: "%02x", $0) }.joined()
        return diskCacheURL.appendingPathComponent(filename)
    }

    // MARK: - Encryption

    private func encrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
            guard let combined = sealedBox.combined else {
                throw AFHAMError.securityError("Failed to create sealed box")
            }
            return combined
        } catch {
            throw AFHAMError.securityError("Encryption failed: \(error.localizedDescription)")
        }
    }

    private func decrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: encryptionKey)
        } catch {
            throw AFHAMError.securityError("Decryption failed: \(error.localizedDescription)")
        }
    }

    private static func getOrCreateEncryptionKey() -> SymmetricKey {
        let keyIdentifier = "com.brainsait.afham.cacheEncryptionKey"

        // Try to load from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        }

        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }

        // Store in Keychain
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keyIdentifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemAdd(addQuery as CFDictionary, nil)

        return newKey
    }

    // MARK: - Cache Management

    private func handleMemoryWarning() {
        memoryCache.removeAllObjects()
        memoryUsage = 0
        AppLogger.shared.log("Memory cache cleared due to memory warning", level: .warning)
    }

    private func cleanupDiskCacheIfNeeded() async {
        guard diskUsage > maxDiskCacheSize else { return }

        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            // Sort by modification date (oldest first)
            let sortedFiles = files.sorted { url1, url2 in
                let date1 = try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                let date2 = try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                return (date1 ?? Date.distantPast) < (date2 ?? Date.distantPast)
            }

            // Remove oldest files until we're under the limit
            var currentSize = diskUsage
            for fileURL in sortedFiles {
                guard currentSize > maxDiskCacheSize * 80 / 100 else { break } // Keep at 80%

                if let size = try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int64 {
                    try? FileManager.default.removeItem(at: fileURL)
                    currentSize -= size
                    diskUsage -= size
                }
            }

            AppLogger.shared.log("Disk cache cleaned: \(diskUsage) bytes remaining", level: .info)
        } catch {
            AppLogger.shared.logError(error, context: "Cleanup disk cache")
        }
    }

    private func schedulePeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.cleanupExpiredEntries()
            }
        }
    }

    private func cleanupExpiredEntries() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)

            for fileURL in files {
                if let entry = await retrieveFromDisk(forKey: fileURL.lastPathComponent),
                   entry.isExpired {
                    await removeFromDisk(forKey: fileURL.lastPathComponent)
                }
            }

            AppLogger.shared.log("Expired cache entries cleaned", level: .info)
        } catch {
            AppLogger.shared.logError(error, context: "Cleanup expired entries")
        }
    }
}

// MARK: - Data Models

private class CacheEntry {
    let data: Data
    let timestamp: Date
    let expiration: TimeInterval
    let size: Int

    var isExpired: Bool {
        return Date().timeIntervalSince(timestamp) > expiration
    }

    init(data: Data, timestamp: Date, expiration: TimeInterval, size: Int) {
        self.data = data
        self.timestamp = timestamp
        self.expiration = expiration
        self.size = size
    }
}

private struct CacheMetadata: Codable {
    let key: String
    let timestamp: Date
    let expiration: TimeInterval
    let size: Int
}

struct CacheStatistics {
    let memoryUsage: Int
    let diskUsage: Int64
    let cacheHits: Int
    let cacheMisses: Int
    let hitRate: Double
    let itemCount: Int

    var formattedMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory)
    }

    var formattedDiskUsage: String {
        ByteCountFormatter.string(fromByteCount: diskUsage, countStyle: .file)
    }
}
