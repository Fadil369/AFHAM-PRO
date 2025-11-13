// AFHAM - Constants and Configuration
// Centralized configuration with PDPL compliance and BrainSAIT standards

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - BRAINSAIT: Core Constants
struct AFHAMConstants {
    
    // MARK: - App Information
    struct App {
        static let name = "AFHAM"
        static let arabicName = "أفهم"
        static let version = "1.0.0"
        static let buildNumber = "1"
        static let bundleIdentifier = "com.brainsait.afham"
        static let company = "BrainSAIT"
        static let website = "https://brainsait.com"
        static let supportEmail = "support@brainsait.com"
    }
    
    // MARK: - API Configuration
    struct API {
        static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta"
        static let geminiModel = "gemini-2.0-flash-exp"
        static let timeout: TimeInterval = 30.0
        static let maxRetries = 3
        static let maxConcurrentUploads = 3
        
        // Rate limiting
        static let maxRequestsPerMinute = 60
        static let rateLimitWindowSeconds: TimeInterval = 60
    }
    
    // MARK: - File Handling
    struct Files {
        static let maxFileSize: Int64 = 100_000_000 // 100 MB
        static let maxFileSizeFree: Int64 = 10_000_000 // 10 MB
        static let maxFileSizePro: Int64 = 50_000_000 // 50 MB
        static let maxFileSizeEnterprise: Int64 = 100_000_000 // 100 MB
        
        static let supportedExtensions = ["pdf", "txt", "doc", "docx", "rtf", "html", "json", "xml", "xlsx", "pptx"]
        
        static let supportedUTTypes: [UTType] = [
            .pdf, .plainText, .rtf, .html, .json, .xml,
            UTType(filenameExtension: "doc") ?? .data,
            UTType(filenameExtension: "docx") ?? .data,
            UTType(filenameExtension: "xlsx") ?? .data,
            UTType(filenameExtension: "pptx") ?? .data
        ]
        
        static let mimeTypes: [String: String] = [
            "pdf": "application/pdf",
            "txt": "text/plain",
            "doc": "application/msword",
            "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            "rtf": "text/rtf",
            "html": "text/html",
            "json": "application/json",
            "xml": "application/xml",
            "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        ]
    }
    
    // MARK: - UI Configuration
    struct UI {
        // Animation Durations
        static let shortAnimation: Double = 0.2
        static let mediumAnimation: Double = 0.3
        static let longAnimation: Double = 0.5
        
        // Spacing
        static let smallSpacing: CGFloat = 8
        static let mediumSpacing: CGFloat = 16
        static let largeSpacing: CGFloat = 24
        static let extraLargeSpacing: CGFloat = 32
        
        // Corner Radius
        static let smallCornerRadius: CGFloat = 8
        static let mediumCornerRadius: CGFloat = 12
        static let largeCornerRadius: CGFloat = 16
        static let circularCornerRadius: CGFloat = 999
        
        // Shadows
        static let lightShadowRadius: CGFloat = 2
        static let mediumShadowRadius: CGFloat = 4
        static let heavyShadowRadius: CGFloat = 8
        
        // Icons
        static let smallIconSize: CGFloat = 16
        static let mediumIconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 32
        static let extraLargeIconSize: CGFloat = 48
        
        // Buttons
        static let buttonHeight: CGFloat = 48
        static let smallButtonHeight: CGFloat = 36
        static let largeButtonHeight: CGFloat = 56
        
        // Content
        static let maxContentWidth: CGFloat = 600
        static let cardMaxWidth: CGFloat = 350
        static let messageMaxWidth: CGFloat = 280
    }
    
    // MARK: - Typography
    struct Typography {
        // Font Sizes
        static let captionSize: CGFloat = 12
        static let footnoteSize: CGFloat = 13
        static let subheadlineSize: CGFloat = 15
        static let calloutSize: CGFloat = 16
        static let bodySize: CGFloat = 17
        static let headlineSize: CGFloat = 17
        static let titleSize: CGFloat = 20
        static let title2Size: CGFloat = 22
        static let title3Size: CGFloat = 20
        static let largeTitleSize: CGFloat = 34
        
        // Line Heights
        static let captionLineHeight: CGFloat = 16
        static let bodyLineHeight: CGFloat = 22
        static let headlineLineHeight: CGFloat = 22
        static let titleLineHeight: CGFloat = 25
    }
    
    // MARK: - Voice & Speech
    struct Voice {
        static let defaultRate: Float = 0.5
        static let minRate: Float = 0.1
        static let maxRate: Float = 1.0
        static let defaultVolume: Float = 1.0
        static let defaultPitch: Float = 1.0
        
        // Speech Recognition
        static let recognitionTimeout: TimeInterval = 10.0
        static let silenceTimeout: TimeInterval = 2.0
        static let maxRecognitionDuration: TimeInterval = 60.0
        
        // Supported Languages
        static let supportedVoiceLanguages = [
            "ar-SA": "Arabic (Saudi Arabia)",
            "en-US": "English (United States)"
        ]
    }
    
    // MARK: - Analytics & Logging
    struct Analytics {
        static let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
        static let batchSize = 50
        static let maxRetentionDays = 30
        
        // Event Categories
        enum Category: String {
            case user = "user"
            case document = "document"
            case chat = "chat"
            case voice = "voice"
            case content = "content"
            case error = "error"
            case performance = "performance"
        }
        
        // Event Actions
        enum Action: String {
            case upload = "upload"
            case download = "download"
            case view = "view"
            case create = "create"
            case delete = "delete"
            case share = "share"
            case search = "search"
            case error = "error"
            case success = "success"
        }
    }
    
    // MARK: - Network Configuration
    struct Network {
        static let timeoutInterval: TimeInterval = 30.0
        static let cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData
        static let allowsCellularAccess = true
        static let waitsForConnectivity = true
        
        // Retry Configuration
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
        static let exponentialBackoffMultiplier: Double = 2.0
    }
    
    // MARK: - Security & Privacy (PDPL Compliant)
    struct Security {
        // Encryption
        static let encryptionAlgorithm = "AES-256-GCM"
        static let keySize = 256
        static let ivSize = 12
        
        // Session Management
        static let sessionTimeout: TimeInterval = 24 * 60 * 60 // 24 hours
        static let maxInactivePeriod: TimeInterval = 30 * 60 // 30 minutes
        
        // Data Retention (PDPL Compliant)
        static let dataRetentionPeriod: TimeInterval = 90 * 24 * 60 * 60 // 90 days
        static let logRetentionPeriod: TimeInterval = 30 * 24 * 60 * 60 // 30 days
        static let auditLogRetentionPeriod: TimeInterval = 365 * 24 * 60 * 60 // 1 year
        
        // Privacy
        static let requiresExplicitConsent = true
        static let anonymizeAnalytics = true
        static let encryptLocalStorage = true
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let voiceAssistantEnabled = true
        static let contentCreatorEnabled = true
        static let offlineModeEnabled = false
        static let advancedSearchEnabled = false
        static let collaborationEnabled = false
        static let analyticsEnabled = true
        static let crashReportingEnabled = true
        static let performanceMonitoringEnabled = true
        
        // Beta Features
        static let multiLanguageTranslation = false
        static let documentSummarization = true
        static let smartSuggestions = false
        static let voiceCloning = false
    }
    
    // MARK: - Content Types
    enum ContentType: String, CaseIterable {
        case blogPost = "Blog Post"
        case socialMediaPost = "Social Media Post"
        case emailTemplate = "Email Template"
        case presentation = "Presentation"
        case report = "Report"
        case summary = "Summary"
        case translation = "Translation"
        case newsletter = "Newsletter"
        case pressRelease = "Press Release"
        case productDescription = "Product Description"
        
        var arabicName: String {
            switch self {
            case .blogPost: return "مقال مدونة"
            case .socialMediaPost: return "منشور وسائل التواصل"
            case .emailTemplate: return "قالب بريد إلكتروني"
            case .presentation: return "عرض تقديمي"
            case .report: return "تقرير"
            case .summary: return "ملخص"
            case .translation: return "ترجمة"
            case .newsletter: return "نشرة إخبارية"
            case .pressRelease: return "بيان صحفي"
            case .productDescription: return "وصف المنتج"
            }
        }
        
        var icon: String {
            switch self {
            case .blogPost: return "doc.text"
            case .socialMediaPost: return "bubble.left.and.bubble.right"
            case .emailTemplate: return "envelope"
            case .presentation: return "rectangle.stack"
            case .report: return "chart.bar.doc.horizontal"
            case .summary: return "list.bullet.clipboard"
            case .translation: return "globe"
            case .newsletter: return "newspaper"
            case .pressRelease: return "megaphone"
            case .productDescription: return "tag"
            }
        }
        
        var color: Color {
            switch self {
            case .blogPost: return AFHAMColors.medicalBlue
            case .socialMediaPost: return AFHAMColors.signalTeal
            case .emailTemplate: return AFHAMColors.deepOrange
            case .presentation: return AFHAMColors.professionalGray
            case .report: return AFHAMColors.medicalBlue
            case .summary: return AFHAMColors.signalTeal
            case .translation: return AFHAMColors.deepOrange
            case .newsletter: return AFHAMColors.professionalGray
            case .pressRelease: return AFHAMColors.medicalBlue
            case .productDescription: return AFHAMColors.signalTeal
            }
        }
    }
}

// MARK: - BrainSAIT Brand Colors
struct AFHAMColors {
    // Primary Brand Colors
    static let midnightBlue = Color(hexString: "#1a365d")
    static let medicalBlue = Color(hexString: "#2b6cb8")
    static let signalTeal = Color(hexString: "#0ea5e9")
    static let deepOrange = Color(hexString: "#ea580c")
    static let professionalGray = Color(hexString: "#64748b")
    
    // Semantic Colors
    static let success = Color(hexString: "#10b981")
    static let warning = Color(hexString: "#f59e0b")
    static let error = Color(hexString: "#ef4444")
    static let info = Color(hexString: "#3b82f6")
    
    // Background Colors
    static let primaryBackground = Color(hexString: "#0f172a")
    static let secondaryBackground = Color(hexString: "#1e293b")
    static let tertiaryBackground = Color(hexString: "#334155")
    
    // Text Colors
    static let primaryText = Color.white
    static let secondaryText = Color("#cbd5e1")
    static let tertiaryText = Color(hexString: "#94a3b8")
    
    // Border Colors
    static let primaryBorder = Color(hexString: "#475569")
    static let secondaryBorder = Color(hexString: "#64748b")
    static let focusBorder = signalTeal
    
    // Interactive Colors
    static let buttonPrimary = medicalBlue
    static let buttonSecondary = professionalGray
    static let buttonDanger = error
    static let buttonSuccess = success
    
    // Card Colors
    static let cardBackground = secondaryBackground
    static let cardBorder = primaryBorder
    static let cardShadow = Color.black.opacity(0.2)
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Device Detection
struct DeviceInfo {
    static var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    static var screenSize: CGSize {
        return UIScreen.main.bounds.size
    }
    
    static var isIpad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - UserDefaults Keys
extension UserDefaults {
    enum Key {
        static let preferredLanguage = "preferred_language"
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let voiceSpeed = "voice_speed"
        static let autoSpeak = "auto_speak"
        static let analyticsEnabled = "analytics_enabled"
        static let crashReportingEnabled = "crash_reporting_enabled"
        static let lastSyncDate = "last_sync_date"
        static let userConsent = "user_consent"
        static let dataRetentionConsent = "data_retention_consent"
        static let installDate = "install_date"
        static let launchCount = "launch_count"
        static let lastVersionUsed = "last_version_used"
    }
}
