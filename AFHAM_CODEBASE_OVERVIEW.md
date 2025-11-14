# AFHAM Codebase - Comprehensive Architecture Overview

## Executive Summary
AFHAM (أفهم - "Understand") is an advanced iOS multimodal RAG (Retrieval-Augmented Generation) system combining Google Gemini File Search with Apple Intelligence. It's designed for Arabic/English bilingual healthcare and enterprise document analysis with enterprise-grade security.

**Total Swift Files:** 23 files  
**Total Lines of Code:** ~9,926 LOC  
**Deployment Target:** iOS 17+  
**Architecture:** MVVM + State Management  
**Key Technologies:** SwiftUI, Combine, AVFoundation, CryptoKit, NaturalLanguage, Vision

---

## 1. PROJECT STRUCTURE & MAIN MODULES

### Root Directory Organization
```
/home/user/AFHAM-PRO/
├── AFHAM/                      # Main source code
│   ├── App/                    # Application entry point
│   ├── Core/                   # Core infrastructure
│   ├── Features/               # Feature modules
│   ├── Resources/              # Assets, localizations
│   ├── Testing/                # Test files
│   └── Documentation/          # Technical docs
├── Tests/                      # Unit test suite
├── .github/workflows/          # CI/CD configuration
├── Package.swift               # Swift package manifest
├── Podfile                     # CocoaPods dependencies
└── README.md                   # Project documentation
```

### Core Module Breakdown

#### **1.1 App Module** - `/AFHAM/App/`
**Purpose:** Application lifecycle and initialization

| File | Size | Purpose |
|------|------|---------|
| `afham_entry.swift` | ~650 LOC | Main app entry point, AppState management, AppLogger, SecureAPIKeyManager |

**Key Classes:**
- `AFHAMMainApp` - @main entry point with dark mode default
- `AppState` - User preferences and subscription tiers (Free/Pro/Enterprise)
- `SecureAPIKeyManager` - Keychain-based API key storage
- `AppLogger` - Structured logging with file/function context
- `NetworkMonitor` - Network connectivity monitoring
- `FileValidator` - File validation and MIME type mapping
- `PerformanceMonitor` - Operation timing and profiling

---

#### **1.2 Core Infrastructure Module** - `/AFHAM/Core/`

| File | LOC | Purpose |
|------|-----|---------|
| `afham_main.swift` | 678 | Main features: Gemini integration, Voice assistant, File search |
| `AFHAMConstants.swift` | 417 | Centralized configuration and constants |
| `RequestManager.swift` | 262 | Request lifecycle, cancellation, rate limiting |
| `SecureAPIKeyManager.swift` | 190 | Keychain integration for secure key storage |
| `LocalizationManager.swift` | 507 | Bilingual support (Arabic/English) |
| `CertificatePinningManager.swift` | 256 | SSL/TLS certificate pinning (MITM prevention) |
| `AdvancedCachingManager.swift` | 411 | Multi-level caching (memory + encrypted disk) |
| `PerformanceMonitor.swift` | 362 | Performance metrics and timing |
| `InputValidator.swift` | 295 | Input validation and sanitization |
| `VoiceManagerBridge.swift` | 7 | Voice manager interface |

**Key Infrastructure Classes:**

1. **RequestManager**
   - Concurrent request management (max 3 concurrent)
   - Rate limiting (60 requests/minute)
   - Request prioritization (low/normal/high/critical)
   - Request history tracking (24-hour retention)
   - Statistics collection

2. **GeminiFileSearchManager** (in afham_main.swift)
   - File upload to Gemini Files API
   - File search store creation/management
   - Query with retry logic (exponential backoff)
   - Language detection (Arabic/English)
   - Citation extraction

3. **VoiceAssistantManager** (in afham_main.swift)
   - Speech recognition (SFSpeechRecognizer)
   - Text-to-speech synthesis (AVSpeechSynthesizer)
   - Audio engine management
   - Language switching support

---

#### **1.3 Features Module** - `/AFHAM/Features/`

##### **A. Chat Features** - `/Features/Chat/`
| File | LOC | Purpose |
|------|-----|---------|
| `afham_chat.swift` | 588 | Chat interface, real-time messaging, voice input |

**Components:**
- `ChatViewModel` - Message management and API integration
- `ChatView` - Message list with RTL/LTR support
- `ChatInputView` - Text and voice input interface
- `MessageCell` - Message rendering with citations

##### **B. Voice Features** - `/Features/Voice/`
| File | LOC | Purpose |
|------|-----|---------|
| `EnhancedVoiceAssistant.swift` | 530 | Advanced voice commands and recognition |
| `EnhancedVoiceDemo.swift` | 356 | Voice feature demonstrations |

**Components:**
- `VoiceActivityDetector` - Real-time audio level detection
- `VoiceCommand` - Enum with bilingual commands (Arabic/English)
- `AudioFeedbackType` - Haptic/audio feedback for voice events

##### **C. Content Creation** - `/Features/Content/`
| File | LOC | Purpose |
|------|-----|---------|
| `afham_content.swift` | 524 | Content generation and repurposing |

**Content Types:**
- Summary, Article, Social Media Post, Presentation, Email, Translation, Simple Explanation, Quiz
- Bilingual prompt generation
- Dynamic prompts based on language

##### **D. Healthcare/Compliance** - `/Features/Healthcare/`
| File | LOC | Purpose |
|------|-----|---------|
| `NPHIESCompliance.swift` | 858 | FHIR R4 compliance + NPHIES integration |

**Components:**
- `NPHIESComplianceManager` - NPHIES platform integration
- FHIR resource creation (Patient, DocumentReference, DiagnosticReport)
- Saudi national ID validation
- Data privacy validation (PDPL compliance)

##### **E. Advanced Features** - `/Features/Advanced/`
| File | LOC | Purpose |
|------|-----|---------|
| `AnalyticsDashboard.swift` | 709 | Usage metrics and performance analytics |
| `CollaborationManager.swift` | 488 | Multi-user document sharing and permissions |
| `OfflineModeManager.swift` | 312 | Encrypted offline document caching |

##### **F. UI Components** - `/Features/UI/`
| File | LOC | Purpose |
|------|-----|---------|
| `afham_ui.swift` | 415 | Main UI views (Documents, Chat, Voice, Content, Settings) |

**Main Views:**
- `AFHAMApp` - Main tab-based navigation
- `DocumentsView` - Document management
- `ChatView` - Chat interface
- `VoiceAssistantView` - Voice interaction
- `ContentCreatorView` - Content generation
- `SettingsView` - App settings and preferences

---

## 2. CAMERA/VISION INTEGRATION

### Current Implementation Status
**Status:** Vision framework imported but not actively integrated for camera capture

### Existing Vision Capabilities
Located in `/AFHAM/Core/afham_main.swift`:

```swift
import Vision
import NaturalLanguage
```

### Available Components

1. **Language Detection** (NaturalLanguage)
   - `NLLanguageRecognizer` for document language detection
   - Detects Arabic vs English from document text
   - Returns ISO language codes (ar/en)

2. **Vision Framework** (Imported, not fully utilized)
   - No active camera integration currently
   - Framework available for OCR/image processing future enhancement
   - Can be extended for:
     - Document scanning from camera
     - Text recognition (Vision.VNRecognizeTextRequest)
     - Document boundary detection
     - Image quality assessment

### Future Enhancement Points
- Camera capture view for document scanning
- Real-time document detection and perspective correction
- OCR integration for handwritten text
- Image-to-text conversion for documents

---

## 3. DATA MODELS & CORE DATA SETUP

### Data Model Architecture
**Note:** Project uses in-memory models with UserDefaults/Keychain persistence, NOT Core Data

### Primary Data Models

#### **3.1 Document Management Models**

```swift
struct DocumentMetadata: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let fileSize: Int64
    let uploadDate: Date
    let language: String // "ar" or "en"
    let documentType: String
    var geminiFileID: String?
    var fileSearchStoreID: String?
    var processingStatus: ProcessingStatus
    
    enum ProcessingStatus: String, Codable {
        case uploading, processing, indexed, ready, error
    }
}
```

#### **3.2 Chat/Message Models**

```swift
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let language: String
    var citations: [Citation]?
    var audioURL: URL?
}

struct Citation: Codable {
    let source: String
    let pageNumber: Int?
    let excerpt: String
}
```

#### **3.3 Offline Document Model**

```swift
struct OfflineDocument: Codable, Identifiable {
    let id: UUID
    let originalDocument: DocumentMetadata
    let cachedDate: Date
    let fileSize: Int64
    let isEncrypted: Bool
    var ageInDays: Int { ... }
}
```

#### **3.4 Analytics Models**

```swift
struct UsageMetrics: Codable {
    var sessions: [SessionData] = []
    var totalSessions: Int = 0
    var totalActiveTime: TimeInterval = 0
}

struct SessionData: Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let language: String
}
```

#### **3.5 FHIR/Healthcare Models**

```swift
protocol FHIRResource {
    var id: String { get }
    var resourceType: FHIRResourceType { get }
}

enum FHIRResourceType: String {
    case patient, documentReference, diagnosticReport, organization, practitioner
}

struct FHIRPatient: FHIRResource { ... }
struct FHIRDocumentReference: FHIRResource { ... }
struct FHIRDiagnosticReport: FHIRResource { ... }
```

### Persistence Strategy

| Storage Type | Location | Use Case |
|--------------|----------|----------|
| **Keychain** | iOS Keychain | API keys, encryption keys, sensitive credentials |
| **UserDefaults** | App Sandbox | Preferences, feature flags, metadata |
| **File System** | DocumentDirectory | Cached documents (encrypted) |
| **File System** | CachesDirectory | Temporary data, analytics cache |

### Data Relationships

```
DocumentMetadata
├── geminiFileID (Gemini Files API reference)
├── fileSearchStoreID (Gemini File Search Store reference)
└── processingStatus (Pipeline state)

ChatMessage
├── documentMetadata (implicit via context)
├── citations (grounding metadata from Gemini)
└── audioURL (TTS output)

OfflineDocument
└── originalDocument (full DocumentMetadata copy)

FHIR Resources
├── Identifier (national ID, document ID, etc.)
├── Reference (Patient→Document, Performer, etc.)
└── CodeableConcept (document type, diagnostic codes)
```

---

## 4. API INTEGRATION PATTERNS

### 4.1 Gemini API Integration

#### Base Configuration
```swift
struct AFHAMConfig {
    static var geminiAPIKey: String { /* from SecureAPIKeyManager */ }
    static let geminiModel = "gemini-2.0-flash-exp"
    static let timeout: TimeInterval = 30.0
    static let maxRetries = 3
}
```

#### Gemini API Endpoints Used

**1. Files API** (File Upload)
```
POST https://generativelanguage.googleapis.com/v1beta/files
- Upload documents to Gemini's file storage
- Multipart form-data with metadata
- Returns fileID for reference
```

**2. File Search API** (Semantic Search)
```
POST https://generativelanguage.googleapis.com/v1beta/fileSearchStores
- Create File Search Store (semantic index)
- Import files into store
- Query across multiple documents
```

**3. Generate Content API** (LLM Inference)
```
POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent
- Query documents with file search tool
- Extract grounding/citations
- Support for streaming responses
```

#### Request/Response Handling

**Retry Logic Implementation** (RequestManager.swift)
```
- Max retries: 3
- Exponential backoff: 2^attempt (capped at 10s)
- No retry on 4xx client errors
- Automatic retry on 5xx and network errors
```

**Error Mapping** (APIClient in afham_entry.swift)
```
AFHAMError enum:
- .networkError(reason)
- .queryFailed(reason)
- .fileUploadFailed(reason)
- .rateLimitExceeded
- .requestCancelled
- .invalidResponse
```

#### Rate Limiting
```
MaxRequestsPerMinute: 60
Window: 60 seconds
Tracked via RequestManager.requestHistory
```

### 4.2 NPHIES Healthcare API Integration

#### Endpoints
```
Production: https://nphies.sa/fhir/r4
Sandbox: https://sandbox.nphies.sa/fhir/r4
```

#### Authentication
```
HTTP Header: Authorization: Bearer <NPHIES_TOKEN>
Custom Header: X-BrainSAIT-Client: AFHAM/1.0.0
Content-Type: application/fhir+json
```

#### Supported Operations
- **POST** - Submit FHIR resources (Patient, DocumentReference, DiagnosticReport)
- **GET** - Query resources by type and parameters
- **PUT** - Update existing resources

#### FHIR Compliance
- FHIR R4 standard compliance
- BrainSAIT OID namespace: 1.3.6.1.4.1.61026.2 (Saudi Arabia)
- Support for standard code systems:
  - LOINC (http://loinc.org) - clinical document types
  - SNOMED CT (http://snomed.info/sct) - diagnoses
  - HL7 v2 code systems

### 4.3 Network Configuration

```swift
struct AFHAMConstants.Network {
    static let timeoutInterval: TimeInterval = 30.0
    static let cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData
    static let allowsCellularAccess = true
    static let waitsForConnectivity = true
}
```

### 4.4 API Client Pattern

```swift
struct APIClient {
    static func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }
    
    static func handleAPIError(_ error: Error) -> AFHAMError {
        // Maps URLError codes to AFHAMError
        // Network errors → .networkError
        // Timeout → .networkError("Request timed out")
    }
}
```

---

## 5. COMPLIANCE & SECURITY IMPLEMENTATIONS

### 5.1 COMPLIANCELINC & PDPL Compliance

#### Data Protection (PDPL)
**Stored in AFHAMConstants.Security:**
```swift
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
```

### 5.2 API Key Management

**SecureAPIKeyManager.swift** - Keychain-based key storage

```swift
class SecureAPIKeyManager {
    private let keychainService = "com.brainsait.afham"
    private let geminiKeyIdentifier = "geminiAPIKey"
    
    // Operations:
    func getGeminiAPIKey() -> String?
    func setGeminiAPIKey(_ key: String) throws
    func removeGeminiAPIKey()
    func rotateGeminiAPIKey(newKey: String) throws // With archival
    func isGeminiKeyConfigured: Bool
    func setKeyFromEnvironment() // DEBUG only
    func migrateFromHardcodedKey(_:) // Legacy migration
}
```

**Key Features:**
- Keychain storage with `.afterFirstUnlock` accessibility
- No iCloud sync (keeps data local)
- Automatic old key archival on rotation
- Environment variable loading (DEBUG builds only)
- Debug-only status printing

### 5.3 Certificate Pinning (MITM Prevention)

**CertificatePinningManager.swift**

```swift
class CertificatePinningManager: NSObject, URLSessionDelegate {
    // Pinned domains
    private let pinnedDomains: Set<String> = [
        "generativelanguage.googleapis.com",
        "nphies.sa",
        "sandbox.nphies.sa"
    ]
    
    // Public key pinning for each domain
    private let geminiPinnedKeys: Set<String> = [...]
    private let nphiesPinnedKeys: Set<String> = [...]
    
    func validate(serverTrust: SecTrust, forDomain domain: String) -> Bool {
        // Extract public key from certificate
        // Compare SHA-256 hash against pinned keys
        // Fail if no match found
    }
    
    func createSecureURLSession() -> URLSession {
        // Returns URLSession with certificate pinning delegate
    }
}
```

### 5.4 Encryption Implementation

#### Offline Document Encryption
**OfflineModeManager.swift** - AES-256-GCM encryption

```swift
class OfflineModeManager {
    private let encryptionKey: SymmetricKey // 256-bit
    
    private func encryptData(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
        return sealedBox.combined!
    }
    
    private func decryptData(_ encryptedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: encryptionKey)
    }
}
```

#### Cache Encryption
**AdvancedCachingManager.swift** - Dual-layer caching with encryption

```swift
class AdvancedCachingManager {
    private var memoryCache = NSCache<NSString, CacheEntry>()  // Unencrypted
    private let diskCacheURL: URL  // Encrypted storage
    private let encryptionKey: SymmetricKey
}
```

### 5.5 Audit Logging

**ComplianceAuditLogger (in NPHIESCompliance.swift)**

```swift
actor ComplianceAuditLogger {
    func logResourceCreation(_ resourceType: FHIRResourceType, resourceId: String)
    func logNPHIESSubmission(_ resourceType: FHIRResourceType, resourceId: String, success: Bool)
    func logNPHIESQuery(_ resourceType: FHIRResourceType, parameters: [String: String])
}

enum AuditAction: String, Codable {
    case resourceCreated
    case resourceUpdated
    case resourceDeleted
    case nphiesSubmissionSuccess
    case nphiesSubmissionFailed
    case nphiesQuery
    case complianceViolation
}
```

### 5.6 Healthcare Data Compliance (NPHIES)

**NPHIESComplianceManager.swift**

```swift
class NPHIESComplianceManager: ObservableObject {
    // Saudi national ID validation
    private func isValidSaudiNationalId(_ id: String) -> Bool {
        // Regex: ^[12][0-9]{9}$ (10 digits starting with 1 or 2)
    }
    
    // Data minimization checks
    private func validateDataMinimization(_ resource: FHIRResource)
    
    // Consent validation
    private func validateConsentRequirements(_ resource: FHIRResource) throws
    
    // Security validation
    private func validateSecurityRequirements(_ resource: FHIRResource) throws
    
    // NPHIES profile validation
    private func validateNPHIESCompliance(_ resource: FHIRResource) async throws
}
```

### 5.7 Input Validation

**InputValidator.swift** - Prevents injection attacks

```
Validation categories:
- Text input length limits
- Special character filtering
- SQL/XSS prevention
- URL validation
- Email format validation
- File path traversal prevention
```

---

## 6. UI ARCHITECTURE (SWIFTUI VIEWS STRUCTURE)

### 6.1 View Hierarchy

```
AFHAMMainApp (@main)
└── AFHAMApp (TabView)
    ├── DocumentsView (Tab 0)
    │   ├── DocumentListView
    │   ├── DocumentUploadView
    │   └── DocumentDetailView
    │
    ├── ChatView (Tab 1)
    │   ├── MessageListView
    │   ├── ChatInputView
    │   └── SourceCitationView
    │
    ├── VoiceAssistantView (Tab 2)
    │   ├── VoiceVisualizerView
    │   ├── VoiceCommandsView
    │   └── VoiceActivityView
    │
    ├── ContentCreatorView (Tab 3)
    │   ├── ContentTypeSelector
    │   ├── InstructionsInputView
    │   └── GeneratedContentView
    │
    └── SettingsView (Tab 4)
        ├── LanguageSelector
        ├── APIKeyConfiguration
        ├── VoiceSettings
        ├── PrivacySettings
        └── AboutView
```

### 6.2 UI Components Details

#### **DocumentsView** (`afham_ui.swift`)
- Displays uploaded documents with processing status
- Document card with metadata (filename, size, language, date)
- File picker integration (document browser)
- Document deletion and metadata editing

#### **ChatView** (`afham_chat.swift`)
- Bilingual message display (RTL for Arabic)
- User messages (right-aligned in Arabic)
- AI messages with citations (left-aligned in Arabic)
- Text input field with send button
- Voice input button with listening indicator

#### **VoiceAssistantView** (`afham_ui.swift`)
- Voice activity visualizer (waveform/level meter)
- Microphone permission state
- Voice command display (bilingual)
- Language switching toggle
- Voice activity detection UI

#### **ContentCreatorView** (`afham_content.swift`)
- Content type picker (Summary, Article, Email, etc.)
- Additional instructions text area
- Generate button with loading state
- Generated content display with copy/share buttons

#### **SettingsView** (`afham_ui.swift`)
- Language selector (Arabic/English with RTL support)
- API key configuration input
- Voice speed slider (0.1 to 1.0)
- Auto-speak toggle
- Privacy and consent management
- App version and company info

### 6.3 Styling & Color System

**AFHAMColors (AFHAMConstants.swift)**
```swift
// Primary Brand
- midnightBlue: #1a365d
- medicalBlue: #2b6cb8
- signalTeal: #0ea5e9
- deepOrange: #ea580c
- professionalGray: #64748b

// Semantic
- success: #10b981
- warning: #f59e0b
- error: #ef4444
- info: #3b82f6

// UI Backgrounds
- primaryBackground: #0f172a (dark)
- secondaryBackground: #1e293b
- tertiaryBackground: #334155
```

### 6.4 Layout Specifications

**Spacing** (AFHAMConstants.UI)
```
- smallSpacing: 8
- mediumSpacing: 16
- largeSpacing: 24
- extraLargeSpacing: 32
```

**Typography** (AFHAMConstants.Typography)
```
- captionSize: 12
- bodySize: 17
- headlineSize: 17
- titleSize: 20
- largeTitleSize: 34
```

**Corner Radius**
```
- small: 8
- medium: 12
- large: 16
- circular: 999
```

### 6.5 Localization Integration

**RTL/LTR Support**
```swift
.environment(\.layoutDirection, language == "ar" ? .rightToLeft : .leftToRight)
```

**Text Localization**
```swift
struct LocalizationKey { /* Enum with 200+ keys */ }

// Usage:
Text(LocalizationManager.shared.localized(.appTitle))
// or
Text(.appTitle) // shorthand
```

### 6.6 View Extensions

```swift
extension View {
    func localized(_ key: LocalizationKey) -> Text
    func localizedString(_ key: LocalizationKey) -> String
}

extension String {
    static func localized(_ key: LocalizationKey) -> String
}
```

---

## 7. LOCALIZATION SETUP (ARABIC/ENGLISH SUPPORT)

### 7.1 Localization Manager

**LocalizationManager.swift** - Central localization hub

```swift
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage = .arabic
    @AppStorage("preferred_language") private var storedLanguage: String = "ar"
    
    enum AppLanguage: String, CaseIterable {
        case arabic = "ar"
        case english = "en"
        
        var displayName: String { /* "العربية" or "English" */ }
        var isRTL: Bool { self == .arabic }
        var speechCode: String { /* "ar-SA" or "en-US" */ }
    }
}
```

### 7.2 Localization Key Structure

**LocalizationKey enum** - Type-safe localization

```
Categories (200+ keys total):

1. Navigation (5 keys)
   - appTitle, documents, chat, content, settings

2. Document Management (15 keys)
   - uploadDocument, documentProcessing, documentError, etc.

3. Chat Interface (8 keys)
   - startConversation, askQuestion, thinking, typing

4. Content Creation (8 keys)
   - contentType, generateContent, generatedContent

5. Settings (6 keys)
   - language, voiceSettings, privacySettings

6. Common Actions (20 keys)
   - loading, error, success, cancel, done, save, delete

7. Content Types (10 keys)
   - blogPost, socialMediaPost, emailTemplate, etc.

8. Error Messages (9 keys)
   - apiKeyMissing, fileUploadFailed, networkError

9. Voice Assistant (6 keys)
   - voiceAssistant, listening, speakYourQuestion

10. File Management (6 keys)
    - fileSize, fileName, uploadDate, etc.

11. Accessibility (6 keys)
    - documentCard, messageFromUser, voiceButton
```

### 7.3 Resource Files

**Location:** `/AFHAM/Resources/Localizations/`

```
Localizations/
├── ar.lproj/
│   └── Localizable.strings  (Arabic translations)
└── en.lproj/
    └── Localizable.strings  (English translations)
```

### 7.4 Implementation Pattern

```swift
// Stored in LocalizationKey enum
private var englishValue: String {
    switch self {
    case .appTitle: return "AFHAM"
    case .documents: return "Documents"
    // ... 200+ keys
    }
}

private var arabicValue: String {
    switch self {
    case .appTitle: return "أفهم"
    case .documents: return "المستندات"
    // ... 200+ Arabic translations
    }
}

func localized(for language: AppLanguage) -> String {
    switch language {
    case .arabic: return arabicValue
    case .english: return englishValue
    }
}
```

### 7.5 Voice Language Support

**Voice Assistant Language Codes:**
```
Arabic: ar-SA (Saudi Arabia dialect)
English: en-US (United States)
```

**Speech Recognition Setup:**
```swift
class VoiceAssistantManager {
    @Published var currentLanguage: String = "ar-SA"
    
    func switchLanguage(to language: String) {
        currentLanguage = language
        setupSpeechRecognizer() // Recreate recognizer for new language
    }
}
```

### 7.6 Date/Time Localization

```swift
extension Date {
    func formatted(for language: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == "ar" ? "ar-SA" : "en-US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    func timeAgo(language: String) -> String {
        // Returns "منذ يومين" (2 days ago in Arabic) or "2d ago" (English)
    }
}
```

### 7.7 RTL Layout Support

**Key Configuration:**
- App supports both LTR (English) and RTL (Arabic)
- System automatically mirrors UI elements when RTL is active
- TabView adapts to language direction
- Text fields support RTL text input
- Navigation bar adapts back button position

---

## 8. OFFLINE MODE IMPLEMENTATIONS

### 8.1 Offline Mode Manager

**OfflineModeManager.swift** - Complete offline capability

```swift
@MainActor
class OfflineModeManager: ObservableObject {
    static let shared = OfflineModeManager()
    
    @Published var isOfflineModeEnabled = false
    @Published var cachedDocuments: [OfflineDocument] = []
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var offlineQueueCount = 0
    
    private let encryptionKey: SymmetricKey // AES-256-GCM
    private let cacheDirectory: URL // DocumentDirectory/AFHAMCache
    private let maxCacheSize: Int64 = 500_000_000 // 500 MB
}
```

### 8.2 Offline Features

#### **Document Caching**
```swift
func cacheDocument(_ document: DocumentMetadata, content: Data) async throws {
    // 1. Encrypt with AES-256-GCM
    let encryptedContent = try encryptData(content)
    
    // 2. Write to disk with UUID filename
    let cacheURL = cacheDirectory.appendingPathComponent("\(document.id).encrypted")
    try encryptedContent.write(to: cacheURL)
    
    // 3. Create OfflineDocument metadata
    let offlineDoc = OfflineDocument(
        id: document.id,
        originalDocument: document,
        cachedDate: Date(),
        fileSize: Int64(encryptedContent.count),
        isEncrypted: true
    )
    
    // 4. Persist index to UserDefaults
    cachedDocuments.append(offlineDoc)
    saveCachedDocumentsIndex()
}
```

#### **Offline Query Processing**
```swift
func processOfflineQuery(_ query: String, documentId: UUID) async throws -> (answer: String, confidence: Double) {
    guard let cachedContent = try getCachedDocument(documentId) else {
        throw AFHAMError.documentNotCached(documentId)
    }
    
    // 1. Extract text from cached content
    guard let text = String(data: cachedContent, encoding: .utf8) else {
        throw AFHAMError.documentProcessingFailed("Invalid text format")
    }
    
    // 2. Keyword-based text analysis
    let answer = performBasicTextAnalysis(query: query, content: cachedContent)
    
    // 3. Calculate confidence score (capped at 85%)
    let confidence = calculateConfidenceScore(answer: answer, query: query)
    
    return (answer, confidence)
}
```

#### **Offline Text Analysis Algorithm**
```
1. Split query into words (case-insensitive)
2. Split document into sentences
3. Score each sentence by word matches
4. Return top 3 sentences with highest scores
5. Confidence = (matched words / total query words)
```

### 8.3 Encryption for Offline Documents

**AES-256-GCM Implementation**
```swift
private func encryptData(_ data: Data) throws -> Data {
    let sealedBox = try AES.GCM.seal(data, using: encryptionKey)
    return sealedBox.combined! // Returns IV + ciphertext + tag
}

private func decryptData(_ encryptedData: Data) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
    return try AES.GCM.open(sealedBox, using: encryptionKey)
}
```

**Encryption Key Management**
```swift
// Key stored in Keychain
if let keyData = KeychainHelper.loadKey(for: "AFHAMOfflineKey") {
    self.encryptionKey = SymmetricKey(data: keyData)
} else {
    self.encryptionKey = SymmetricKey(size: .bits256) // Generate new
    KeychainHelper.saveKey(encryptionKey.withUnsafeBytes { Data($0) }, for: "AFHAMOfflineKey")
}
```

### 8.4 Cache Management

#### **Storage Limits**
```
Max Cache Size: 500 MB
Memory Cache: 50 MB
Disk Cache: 500 MB
```

#### **Cache Cleanup**
```swift
func cleanupCache() async {
    let cacheSize = calculateCacheSize()
    
    if cacheSize > maxCacheSize {
        // Remove oldest documents until cache is 80% of max
        cachedDocuments.sort { $0.cachedDate < $1.cachedDate }
        
        var removedSize: Int64 = 0
        for document in cachedDocuments {
            if cacheSize - removedSize <= maxCacheSize * 8 / 10 {
                break
            }
            removeCachedDocument(document.id)
            removedSize += document.fileSize
        }
    }
}
```

### 8.5 Offline State Synchronization

```swift
// Enable offline mode
func enableOfflineMode() async throws {
    isOfflineModeEnabled = true
    await syncDocumentsForOffline() // Simulate sync with progress
    lastSyncDate = Date()
    UserDefaults.standard.set(true, forKey: "OfflineModeEnabled")
}

// Disable offline mode
func disableOfflineMode() {
    isOfflineModeEnabled = false
    UserDefaults.standard.set(false, forKey: "OfflineModeEnabled")
}
```

### 8.6 Offline Mode Integration Points

**Feature Flag Control:**
```swift
AFHAMConstants.Features.offlineModeEnabled // false (disabled in current version)
```

**When Enabled, Affects:**
1. Document upload caching
2. Local query processing fallback
3. Offline badge on documents
4. Sync indicators in UI
5. Settings toggle availability

### 8.7 Offline Data Persistence

**Stored in UserDefaults:**
```
Keys:
- OfflineModeEnabled: Boolean
- CachedDocumentsIndex: [OfflineDocument] (JSON)
- LastOfflineSync: Date
```

**File System Structure:**
```
~/Documents/AFHAMCache/
├── {UUID}.encrypted  (document 1)
├── {UUID}.encrypted  (document 2)
└── {UUID}.encrypted  (document N)
```

---

## TECHNICAL SPECIFICATIONS SUMMARY

### Dependencies
```
SwiftUI, Combine, AVFoundation, AVAudio, Speech, AudioToolbox
Vision, NaturalLanguage, UniformTypeIdentifiers
Foundation, Security, CryptoKit, Network
```

### Supported File Types
```
PDF, TXT, DOC, DOCX, RTF, HTML, JSON, XML, XLSX, PPTX
Max Size: 100 MB (100_000_000 bytes)
```

### API Limits
```
Max Concurrent Uploads: 3
Max Requests/Minute: 60
Request Timeout: 30 seconds
Retry Attempts: 3 with exponential backoff
```

### Performance Metrics
```
Cache Hit/Miss Tracking
Request Duration Monitoring
Memory Usage Tracking
Disk Usage Monitoring
```

### Security Standards
```
API Key: Keychain storage
Communications: TLS 1.2+ with certificate pinning
Local Data: AES-256-GCM encryption
Session: 24-hour timeout with 30-minute inactivity
Data Retention: 90 days (PDPL compliant)
```

---

## FILE PATHS SUMMARY

### Core Modules
- App Entry: `/home/user/AFHAM-PRO/AFHAM/App/afham_entry.swift`
- Main Features: `/home/user/AFHAM-PRO/AFHAM/Core/afham_main.swift`
- Constants: `/home/user/AFHAM-PRO/AFHAM/Core/AFHAMConstants.swift`

### Security
- `/home/user/AFHAM-PRO/AFHAM/Core/SecureAPIKeyManager.swift`
- `/home/user/AFHAM-PRO/AFHAM/Core/CertificatePinningManager.swift`

### Healthcare/Compliance
- `/home/user/AFHAM-PRO/AFHAM/Features/Healthcare/NPHIESCompliance.swift`

### Advanced Features
- `/home/user/AFHAM-PRO/AFHAM/Features/Advanced/OfflineModeManager.swift`
- `/home/user/AFHAM-PRO/AFHAM/Features/Advanced/AnalyticsDashboard.swift`
- `/home/user/AFHAM-PRO/AFHAM/Features/Advanced/CollaborationManager.swift`

### UI/Features
- Chat: `/home/user/AFHAM-PRO/AFHAM/Features/Chat/afham_chat.swift`
- UI: `/home/user/AFHAM-PRO/AFHAM/Features/UI/afham_ui.swift`
- Content: `/home/user/AFHAM-PRO/AFHAM/Features/Content/afham_content.swift`
- Voice: `/home/user/AFHAM-PRO/AFHAM/Features/Voice/EnhancedVoiceAssistant.swift`

### Localization Files
- English: `/home/user/AFHAM-PRO/AFHAM/Resources/Localizations/en.lproj/Localizable.strings`
- Arabic: `/home/user/AFHAM-PRO/AFHAM/Resources/Localizations/ar.lproj/Localizable.strings`

