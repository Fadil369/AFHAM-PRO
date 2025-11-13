// AFHAM - Main App Entry Point
// Complete iOS App with Gemini File Search + Apple Intelligence

import SwiftUI

@main
struct AFHAMMainApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            AFHAMApp()
                .environmentObject(appState)
                .preferredColorScheme(.dark) // NEURAL: Dark mode by default
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // NEURAL: Configure UI appearance
        configureAppearance()

        // SECURITY: Initialize secure API key management
        initializeSecureAPIKey()

        // BRAINSAIT: Initialize analytics and logging
        AppLogger.shared.log("AFHAM App Launched", level: .success)
    }

    private func initializeSecureAPIKey() {
        #if DEBUG
        // In debug mode, try to load from environment variable
        try? SecureAPIKeyManager.shared.setKeyFromEnvironment()
        SecureAPIKeyManager.shared.printKeyStatus()
        #endif

        // Check if API key is configured
        if !AFHAMConstants.isConfigured {
            AppLogger.shared.log(
                "⚠️ API Key not configured. Please configure it in Settings.",
                level: .warning
            )
        } else {
            AppLogger.shared.log(
                "✅ API Key configured securely",
                level: .success
            )
        }
    }
    
    private func configureAppearance() {
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AFHAMColors.midnightBlue)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
}

// MARK: - App State Management
@MainActor
class AppState: ObservableObject {
    @Published var isOnboarding = false
    @Published var hasCompletedSetup = false
    @Published var currentUser: User?
    
    struct User {
        let id: UUID
        let name: String
        let preferredLanguage: String
        let subscriptionTier: SubscriptionTier
    }
    
    enum SubscriptionTier {
        case free
        case pro
        case enterprise
        
        var maxDocuments: Int {
            switch self {
            case .free: return 10
            case .pro: return 100
            case .enterprise: return 1000
            }
        }
        
        var maxFileSize: Int64 {
            switch self {
            case .free: return 10_000_000 // 10 MB
            case .pro: return 50_000_000 // 50 MB
            case .enterprise: return 100_000_000 // 100 MB
            }
        }
    }
    
    init() {
        loadUserPreferences()
    }
    
    private func loadUserPreferences() {
        // Load from UserDefaults or Keychain
        hasCompletedSetup = UserDefaults.standard.bool(forKey: "HasCompletedSetup")
    }
}

// MARK: - AFHAM Configuration Extension
// Extends AFHAMConstants with secure API key management
extension AFHAMConstants {
    // API Configuration - Secure key management
    // SECURITY: API key stored securely in Keychain
    static var geminiAPIKey: String {
        return SecureAPIKeyManager.shared.getGeminiAPIKey() ?? ""
    }

    // Check if API key is configured
    static var isConfigured: Bool {
        return SecureAPIKeyManager.shared.isGeminiKeyConfigured
    }
}

// MARK: - SECURITY: Secure API Key Management
// Note: This class should be moved to AFHAM/Core/SecureAPIKeyManager.swift and added to Xcode project
// For now, keeping it here for build compatibility
class SecureAPIKeyManager {
    static let shared = SecureAPIKeyManager()
    private init() {}
    
    private let keychainService = "com.brainsait.afham.keychain"
    private let geminiAPIKeyAccount = "gemini_api_key"
    
    private func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AFHAMError.keychainError("Failed to save to keychain: \(status)")
        }
    }
    
    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
    
    private func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AFHAMError.keychainError("Failed to delete from keychain: \(status)")
        }
    }
    
    func setGeminiAPIKey(_ apiKey: String) throws {
        guard !apiKey.isEmpty else { throw AFHAMError.invalidAPIKey }
        guard apiKey.hasPrefix("AIza") && apiKey.count >= 30 else { throw AFHAMError.invalidAPIKey }
        try save(key: geminiAPIKeyAccount, value: apiKey)
        AppLogger.shared.log("Gemini API key saved securely", level: .success)
    }
    
    func getGeminiAPIKey() -> String? {
        return load(key: geminiAPIKeyAccount)
    }
    
    func deleteGeminiAPIKey() throws {
        try delete(key: geminiAPIKeyAccount)
        AppLogger.shared.log("Gemini API key deleted", level: .info)
    }
    
    var isGeminiKeyConfigured: Bool {
        return getGeminiAPIKey() != nil
    }
    
    func setKeyFromEnvironment() throws {
        #if DEBUG
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] {
            try setGeminiAPIKey(envKey)
            AppLogger.shared.log("API key loaded from environment variable", level: .info)
        }
        #endif
    }
    
    func printKeyStatus() {
        #if DEBUG
        let isConfigured = isGeminiKeyConfigured
        let keyPreview = getGeminiAPIKey()?.prefix(10) ?? "None"
        AppLogger.shared.log("""
        🔐 API Key Status:
        - Configured: \(isConfigured)
        - Preview: \(keyPreview)...
        """, level: .debug)
        #endif
    }
}

// MARK: - BRAINSAIT: Logging System
class AppLogger {
    static let shared = AppLogger()
    
    private init() {}
    
    enum LogLevel: String {
        case debug = "🔍 DEBUG"
        case info = "ℹ️ INFO"
        case warning = "⚠️ WARNING"
        case error = "❌ ERROR"
        case success = "✅ SUCCESS"
    }
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        let logMessage = """
        [\(timestamp)] \(level.rawValue)
        📁 \(filename) - \(function):\(line)
        💬 \(message)
        ────────────────────────────────────────
        """
        
        print(logMessage)
        
        // In production, send to analytics service
        #if DEBUG
        // Keep logs in debug mode
        #else
        // Send to remote logging service
        #endif
    }
    
    func logError(_ error: Error, context: String) {
        log("\(context): \(error.localizedDescription)", level: .error)
    }
}

// MARK: - MEDICAL: Custom Error Types
enum AFHAMError: LocalizedError {
    case apiKeyMissing
    case invalidAPIKey
    case fileUploadFailed(String)
    case documentProcessingFailed(String)
    case queryFailed(String)
    case voiceRecognitionFailed(String)
    case unsupportedFileType(String)
    case fileSizeTooLarge(Int64)
    case networkError(String)
    case keychainError(String)
    case rateLimitExceeded
    case requestCancelled
    case invalidResponse
    case securityError(String)
    case cachingError(String)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Gemini API key is missing. Please configure it in Settings."
        case .invalidAPIKey:
            return "Invalid API key format"
        case .fileUploadFailed(let reason):
            return "File upload failed: \(reason)"
        case .documentProcessingFailed(let reason):
            return "Document processing failed: \(reason)"
        case .queryFailed(let reason):
            return "Query failed: \(reason)"
        case .voiceRecognitionFailed(let reason):
            return "Voice recognition failed: \(reason)"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .fileSizeTooLarge(let size):
            let mb = Double(size) / 1_000_000
            return "File size (\(String(format: "%.1f", mb)) MB) exceeds maximum allowed size"
        case .networkError(let reason):
            return "Network error: \(reason)"
        case .keychainError(let reason):
            return "Keychain error: \(reason)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .requestCancelled:
            return "Request was cancelled"
        case .invalidResponse:
            return "Invalid response from server"
        case .securityError(let reason):
            return "Security error: \(reason)"
        case .cachingError(let reason):
            return "Caching error: \(reason)"
        }
    }

    var localizedArabic: String {
        switch self {
        case .apiKeyMissing:
            return "مفتاح API مفقود. الرجاء تكوينه في الإعدادات."
        case .invalidAPIKey:
            return "تنسيق مفتاح API غير صالح"
        case .fileUploadFailed:
            return "فشل رفع الملف"
        case .documentProcessingFailed:
            return "فشلت معالجة المستند"
        case .queryFailed:
            return "فشل الاستعلام"
        case .voiceRecognitionFailed:
            return "فشل التعرف على الصوت"
        case .unsupportedFileType(let type):
            return "نوع ملف غير مدعوم: \(type)"
        case .fileSizeTooLarge:
            return "حجم الملف يتجاوز الحد الأقصى المسموح"
        case .networkError:
            return "خطأ في الشبكة"
        case .keychainError:
            return "خطأ في سلسلة المفاتيح"
        case .rateLimitExceeded:
            return "تم تجاوز حد المعدل. يرجى المحاولة مرة أخرى لاحقاً."
        case .requestCancelled:
            return "تم إلغاء الطلب"
        case .invalidResponse:
            return "استجابة غير صالحة من الخادم"
        case .securityError:
            return "خطأ أمني"
        case .cachingError:
            return "خطأ في التخزين المؤقت"
        }
    }
}

// MARK: - BILINGUAL: Localization Helper
struct Localized {
    static func string(_ key: String, language: String) -> String {
        let bundle = Bundle.main
        if let path = bundle.path(forResource: language, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            return NSLocalizedString(key, bundle: langBundle, comment: "")
        }
        return NSLocalizedString(key, comment: "")
    }
    
    // Common phrases
    static func loading(language: String) -> String {
        language == "ar" ? "جاري التحميل..." : "Loading..."
    }
    
    static func error(language: String) -> String {
        language == "ar" ? "خطأ" : "Error"
    }
    
    static func success(language: String) -> String {
        language == "ar" ? "نجح" : "Success"
    }
    
    static func cancel(language: String) -> String {
        language == "ar" ? "إلغاء" : "Cancel"
    }
    
    static func done(language: String) -> String {
        language == "ar" ? "تم" : "Done"
    }
}

// MARK: - Network Monitoring
import Network

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: NWInterface.InterfaceType?
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - File Validation
struct FileValidator {
    static func validate(url: URL, maxSize: Int64 = 100_000_000) throws -> Bool {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AFHAMError.fileUploadFailed("File does not exist")
        }
        
        // Check file size
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let fileSize = attributes[.size] as? Int64 {
            guard fileSize <= maxSize else {
                throw AFHAMError.fileSizeTooLarge(fileSize)
            }
        }
        
        // Check file type
        let fileExtension = url.pathExtension.lowercased()
        let supportedExtensions = AFHAMConstants.Files.supportedExtensions
        
        guard supportedExtensions.contains(fileExtension) else {
            throw AFHAMError.unsupportedFileType(fileExtension)
        }
        
        return true
    }
    
    static func getMimeType(for url: URL) -> String {
        let fileExtension = url.pathExtension.lowercased()
        return AFHAMConstants.Files.mimeTypes[fileExtension] ?? "application/octet-stream"
    }
}

// MARK: - Analytics Events
enum AnalyticsEvent {
    case appLaunched
    case documentUploaded(type: String, size: Int64)
    case chatMessageSent(language: String)
    case voiceCommandUsed
    case contentGenerated(type: ContentType)
    case errorOccurred(error: Error)
    
    func track() {
        let eventName: String
        var parameters: [String: Any] = [:]
        
        switch self {
        case .appLaunched:
            eventName = "app_launched"
        case .documentUploaded(let type, let size):
            eventName = "document_uploaded"
            parameters = ["file_type": type, "file_size": size]
        case .chatMessageSent(let language):
            eventName = "chat_message_sent"
            parameters = ["language": language]
        case .voiceCommandUsed:
            eventName = "voice_command_used"
        case .contentGenerated(let type):
            eventName = "content_generated"
            parameters = ["content_type": type.rawValue]
        case .errorOccurred(let error):
            eventName = "error_occurred"
            parameters = ["error": error.localizedDescription]
        }
        
        AppLogger.shared.log("Analytics: \(eventName) - \(parameters)", level: .info)
        
        // In production, send to analytics service (Firebase, Mixpanel, etc.)
    }
}

// MARK: - Feature Flags
struct FeatureFlags {
    static let voiceAssistantEnabled = AFHAMConstants.Features.voiceAssistantEnabled
    static let contentCreatorEnabled = AFHAMConstants.Features.contentCreatorEnabled
    static let offlineModeEnabled = AFHAMConstants.Features.offlineModeEnabled
    static let advancedSearchEnabled = AFHAMConstants.Features.advancedSearchEnabled
    static let collaborationEnabled = AFHAMConstants.Features.collaborationEnabled
    
    static func isEnabled(_ feature: String) -> Bool {
        switch feature {
        case "voice": return voiceAssistantEnabled
        case "content": return contentCreatorEnabled
        case "offline": return offlineModeEnabled
        case "search": return advancedSearchEnabled
        case "collab": return collaborationEnabled
        default: return false
        }
    }
}

// MARK: - API Client Configuration
struct APIClient {
    static let geminiBaseURL = AFHAMConstants.API.geminiBaseURL
    static let timeout: TimeInterval = AFHAMConstants.API.timeout
    static let maxRetries = AFHAMConstants.API.maxRetries
    
    static func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        config.waitsForConnectivity = AFHAMConstants.Network.waitsForConnectivity
        config.requestCachePolicy = AFHAMConstants.Network.cachePolicy
        
        return URLSession(configuration: config)
    }
    
    static func handleAPIError(_ error: Error) -> AFHAMError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError("No internet connection")
            case .timedOut:
                return .networkError("Request timed out")
            case .cannotFindHost:
                return .networkError("Cannot reach server")
            default:
                return .networkError(urlError.localizedDescription)
            }
        }
        
        return .networkError(error.localizedDescription)
    }
}

// MARK: - Performance Monitoring
struct PerformanceMonitor {
    static func measureTime<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        AppLogger.shared.log("⏱️ \(operation) took \(String(format: "%.3f", duration))s", level: .debug)
        
        return result
    }
    
    static func measureAsyncTime<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        AppLogger.shared.log("⏱️ \(operation) took \(String(format: "%.3f", duration))s", level: .debug)
        
        return result
    }
}

// MARK: - UserDefaults Extension
extension UserDefaults {
    enum Keys {
        static let hasCompletedOnboarding = "HasCompletedOnboarding"
        static let preferredLanguage = "PreferredLanguage"
        static let voiceSpeed = "VoiceSpeed"
        static let autoSpeak = "AutoSpeak"
        static let theme = "Theme"
    }
    
    var preferredLanguage: String {
        get { string(forKey: Keys.preferredLanguage) ?? "ar" }
        set { set(newValue, forKey: Keys.preferredLanguage) }
    }
    
    var voiceSpeed: Float {
        get { float(forKey: Keys.voiceSpeed) != 0 ? float(forKey: Keys.voiceSpeed) : 0.5 }
        set { set(newValue, forKey: Keys.voiceSpeed) }
    }
    
    var autoSpeak: Bool {
        get { bool(forKey: Keys.autoSpeak) }
        set { set(newValue, forKey: Keys.autoSpeak) }
    }
}

// MARK: - String Extensions
extension String {
    var isArabic: Bool {
        let arabicRange = self.rangeOfCharacter(from: .init(charactersIn: "\u{0600}"..."\u{06FF}"))
        return arabicRange != nil
    }
    
    func truncate(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Date Formatting Helper
extension Date {
    func formatted(for language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == "ar" ? "ar-SA" : "en-US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func timeAgo(language: String) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let days = components.day, days > 0 {
            return language == "ar" ? "منذ \(days) يوم" : "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return language == "ar" ? "منذ \(hours) ساعة" : "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return language == "ar" ? "منذ \(minutes) دقيقة" : "\(minutes)m ago"
        } else {
            return language == "ar" ? "الآن" : "Now"
        }
    }
}
