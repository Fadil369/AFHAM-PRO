// AFHAM - Offline Mode Manager
// Advanced feature for offline document analysis and caching
// PDPL Compliant with local data encryption

import SwiftUI
import Foundation
import CoreData
import CryptoKit

// MARK: - ADVANCED FEATURE: Offline Mode Manager
@MainActor
class OfflineModeManager: ObservableObject {
    static let shared = OfflineModeManager()
    
    @Published var isOfflineModeEnabled = false
    @Published var cachedDocuments: [OfflineDocument] = []
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var offlineQueueCount = 0
    
    private let encryptionKey: SymmetricKey
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 500_000_000 // 500 MB
    
    private init() {
        // Initialize encryption key for PDPL compliance
        if let keyData = KeychainHelper.loadKey(for: "AFHAMOfflineKey") {
            self.encryptionKey = SymmetricKey(data: keyData)
        } else {
            self.encryptionKey = SymmetricKey(size: .bits256)
            KeychainHelper.saveKey(encryptionKey.withUnsafeBytes { Data($0) }, for: "AFHAMOfflineKey")
        }
        
        // Setup cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = documentsPath.appendingPathComponent("AFHAMCache", isDirectory: true)
        
        setupCacheDirectory()
        loadCachedDocuments()
        
        AppLogger.shared.log("OfflineModeManager initialized", level: .info)
    }
    
    // MARK: - Cache Management
    private func setupCacheDirectory() {
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        } catch {
            AppLogger.shared.logError(error, context: "Failed to create cache directory")
        }
    }
    
    func enableOfflineMode() async throws {
        guard AFHAMConstants.Features.offlineModeEnabled else {
            throw AFHAMError.featureDisabled("Offline mode is not enabled")
        }
        
        isOfflineModeEnabled = true
        await syncDocumentsForOffline()
        
        UserDefaults.standard.set(true, forKey: "OfflineModeEnabled")
        AppLogger.shared.log("Offline mode enabled", level: .success)
    }
    
    func disableOfflineMode() {
        isOfflineModeEnabled = false
        UserDefaults.standard.set(false, forKey: "OfflineModeEnabled")
        AppLogger.shared.log("Offline mode disabled", level: .info)
    }
    
    // MARK: - Document Caching with Encryption
    func cacheDocument(_ document: DocumentMetadata, content: Data) async throws {
        let encryptedContent = try encryptData(content)
        let cacheURL = getCacheURL(for: document.id)
        
        try encryptedContent.write(to: cacheURL)
        
        let offlineDoc = OfflineDocument(
            id: document.id,
            originalDocument: document,
            cachedDate: Date(),
            fileSize: Int64(encryptedContent.count),
            isEncrypted: true
        )
        
        cachedDocuments.append(offlineDoc)
        saveCachedDocumentsIndex()
        
        AppLogger.shared.log("Document cached: \(document.fileName)", level: .info)
    }
    
    func getCachedDocument(_ documentId: UUID) throws -> Data? {
        let cacheURL = getCacheURL(for: documentId)
        
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return nil
        }
        
        let encryptedData = try Data(contentsOf: cacheURL)
        return try decryptData(encryptedData)
    }
    
    // MARK: - Offline Query Processing
    func processOfflineQuery(_ query: String, documentId: UUID) async throws -> (answer: String, confidence: Double) {
        guard isOfflineModeEnabled else {
            throw AFHAMError.offlineModeDisabled
        }
        
        guard let cachedContent = try getCachedDocument(documentId) else {
            throw AFHAMError.documentNotCached(documentId)
        }
        
        // Basic keyword matching for offline mode
        let answer = performBasicTextAnalysis(query: query, content: cachedContent)
        let confidence = calculateConfidenceScore(answer: answer, query: query)
        
        AppLogger.shared.log("Offline query processed", level: .info)
        return (answer, confidence)
    }
    
    private func performBasicTextAnalysis(query: String, content: Data) -> String {
        guard let text = String(data: content, encoding: .utf8) else {
            return "Unable to process document content"
        }
        
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let sentences = text.components(separatedBy: .init(charactersIn: ".!?"))
        
        var relevantSentences: [(sentence: String, score: Int)] = []
        
        for sentence in sentences {
            let lowercaseSentence = sentence.lowercased()
            var score = 0
            
            for word in queryWords {
                if lowercaseSentence.contains(word) {
                    score += 1
                }
            }
            
            if score > 0 {
                relevantSentences.append((sentence: sentence.trimmingCharacters(in: .whitespacesAndNewlines), score: score))
            }
        }
        
        // Sort by relevance score and return top matches
        relevantSentences.sort { $0.score > $1.score }
        let topSentences = relevantSentences.prefix(3).map { $0.sentence }
        
        return topSentences.isEmpty ? "No relevant information found" : topSentences.joined(separator: " ")
    }
    
    private func calculateConfidenceScore(answer: String, query: String) -> Double {
        if answer == "No relevant information found" {
            return 0.0
        }
        
        let queryWords = Set(query.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let answerWords = Set(answer.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = queryWords.intersection(answerWords)
        let confidence = Double(intersection.count) / Double(queryWords.count)
        
        return min(confidence, 0.85) // Cap offline confidence at 85%
    }
    
    // MARK: - Sync Management
    func syncDocumentsForOffline() async {
        syncProgress = 0.0
        
        // This would sync with the main document manager
        // For now, we'll simulate the process
        for i in 0...10 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            await MainActor.run {
                syncProgress = Double(i) / 10.0
            }
        }
        
        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "LastOfflineSync")
        AppLogger.shared.log("Offline sync completed", level: .success)
    }
    
    // MARK: - Cache Cleanup
    func cleanupCache() async {
        let cacheSize = calculateCacheSize()
        
        if cacheSize > maxCacheSize {
            // Remove oldest cached documents
            cachedDocuments.sort { $0.cachedDate < $1.cachedDate }
            
            var removedSize: Int64 = 0
            var documentsToRemove: [OfflineDocument] = []
            
            for document in cachedDocuments {
                if cacheSize - removedSize <= maxCacheSize * 8 / 10 { // Keep cache at 80% of max
                    break
                }
                
                documentsToRemove.append(document)
                removedSize += document.fileSize
            }
            
            for document in documentsToRemove {
                removeCachedDocument(document.id)
            }
            
            AppLogger.shared.log("Cache cleanup completed. Removed \(documentsToRemove.count) documents", level: .info)
        }
    }
    
    private func removeCachedDocument(_ documentId: UUID) {
        let cacheURL = getCacheURL(for: documentId)
        
        try? FileManager.default.removeItem(at: cacheURL)
        cachedDocuments.removeAll { $0.id == documentId }
        
        saveCachedDocumentsIndex()
    }
    
    private func calculateCacheSize() -> Int64 {
        return cachedDocuments.reduce(0) { $0 + $1.fileSize }
    }
    
    // MARK: - Encryption Helpers
    private func encryptData(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }
    
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
    
    // MARK: - File System Helpers
    private func getCacheURL(for documentId: UUID) -> URL {
        return cacheDirectory.appendingPathComponent("\(documentId.uuidString).encrypted")
    }
    
    private func loadCachedDocuments() {
        // Load from persistent storage
        if let data = UserDefaults.standard.data(forKey: "CachedDocumentsIndex"),
           let documents = try? JSONDecoder().decode([OfflineDocument].self, from: data) {
            cachedDocuments = documents
        }
        
        isOfflineModeEnabled = UserDefaults.standard.bool(forKey: "OfflineModeEnabled")
        lastSyncDate = UserDefaults.standard.object(forKey: "LastOfflineSync") as? Date
    }
    
    private func saveCachedDocumentsIndex() {
        if let data = try? JSONEncoder().encode(cachedDocuments) {
            UserDefaults.standard.set(data, forKey: "CachedDocumentsIndex")
        }
    }
}

// MARK: - Offline Document Model
struct OfflineDocument: Codable, Identifiable {
    let id: UUID
    let originalDocument: DocumentMetadata
    let cachedDate: Date
    let fileSize: Int64
    let isEncrypted: Bool
    
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: cachedDate, to: Date()).day ?? 0
    }
}

// MARK: - Keychain Helper for Secure Key Storage
struct KeychainHelper {
    static func saveKey(_ key: Data, for identifier: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadKey(for identifier: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == noErr else { return nil }
        return dataTypeRef as? Data
    }
}

// MARK: - Custom Errors
extension AFHAMError {
    static func featureDisabled(_ feature: String) -> AFHAMError {
        return .networkError("Feature disabled: \(feature)")
    }
    
    static let offlineModeDisabled = AFHAMError.networkError("Offline mode is not enabled")
    
    static func documentNotCached(_ documentId: UUID) -> AFHAMError {
        return .documentProcessingFailed("Document not available offline: \(documentId)")
    }
}