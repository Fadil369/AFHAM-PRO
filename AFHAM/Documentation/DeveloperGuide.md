# AFHAM Developer Guide
*Complete Development Documentation for BrainSAIT Healthcare AI Platform*

## 🎯 Overview

AFHAM is a SwiftUI-based iOS application that integrates Google's Gemini AI with Apple Intelligence for advanced document analysis and healthcare data processing. This guide covers architecture, development setup, API integration, and deployment procedures.

---

## 🏗️ Architecture Overview

### Core Architecture Pattern
```
AFHAM Application Architecture

┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────────┬─────────────────┬─────────────────┐   │
│  │   SwiftUI Views │   View Models   │   Localization  │   │
│  └─────────────────┴─────────────────┴─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                     │
│  ┌─────────────────┬─────────────────┬─────────────────┐   │
│  │    Managers     │    Services     │   Processors    │   │
│  │  • Gemini       │  • Voice        │  • FHIR         │   │
│  │  • Offline      │  • Analytics    │  • Privacy      │   │
│  │  • Collab       │  • Compliance   │  • Validation   │   │
│  └─────────────────┴─────────────────┴─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                              │
│  ┌─────────────────┬─────────────────┬─────────────────┐   │
│  │   Core Data     │    Keychain     │   File System   │   │
│  │  • Documents    │  • API Keys     │  • Cache        │   │
│  │  • User Data    │  • Encryption   │  • Offline      │   │
│  └─────────────────┴─────────────────┴─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   External Integrations                     │
│  ┌─────────────────┬─────────────────┬─────────────────┐   │
│  │   Gemini API    │    Apple APIs   │    NPHIES       │   │
│  │  • File Search  │  • Speech       │  • FHIR R4      │   │
│  │  • Generation   │  • Vision       │  • Compliance   │   │
│  └─────────────────┴─────────────────┴─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure
```
AFHAM/
├── App/                    # App entry point and configuration
├── Core/                   # Core managers and utilities
├── Features/              # Feature-specific modules
│   ├── Chat/              # Chat and voice interaction
│   ├── Content/           # Content generation
│   ├── UI/               # Main UI components
│   ├── Advanced/         # Advanced features (offline, collaboration)
│   └── Healthcare/       # NPHIES/FHIR compliance
├── Resources/            # Assets and localizations
└── Documentation/        # Development guides
```

---

## 🛠️ Development Setup

### Prerequisites
- **Xcode**: 15.0+ (latest recommended)
- **iOS Deployment Target**: 17.0+
- **Swift Version**: 5.9+
- **macOS**: 14.0+ (Sonoma)
- **Developer Account**: Apple Developer Program membership

### Initial Setup

1. **Clone Repository**
```bash
git clone https://github.com/brainsait/afham-ios.git
cd afham-ios
```

2. **Install Dependencies**
```bash
# If using CocoaPods
pod install

# If using Swift Package Manager (SPM)
swift package resolve
```

3. **Configure API Keys**
```bash
# Copy environment template
cp Config/Environment.plist.template Config/Environment.plist

# Edit with your keys
open Config/Environment.plist
```

4. **Open Project**
```bash
open AFHAM.xcodeproj
# or if using CocoaPods
open AFHAM.xcworkspace
```

### Required API Keys

#### Google Gemini API
```swift
// Get from: https://makersuite.google.com/app/apikey
let geminiAPIKey = "YOUR_GEMINI_API_KEY"
```

#### Apple Developer Configuration
- **Team ID**: Required for code signing
- **Bundle ID**: `com.brainsait.afham`
- **Capabilities**: 
  - Speech Recognition
  - Microphone Access
  - Document Picker
  - Background App Refresh

### Build Configuration

#### Debug Configuration
```swift
// AFHAMConfig+Debug.swift
extension AFHAMConfig {
    #if DEBUG
    static let geminiAPIKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY_DEBUG"] ?? "debug_key"
    static let enableVerboseLogging = true
    static let useNPHIESSandbox = true
    #endif
}
```

#### Release Configuration
```swift
// AFHAMConfig+Release.swift
extension AFHAMConfig {
    #if !DEBUG
    static let geminiAPIKey = KeychainHelper.loadAPIKey() ?? ""
    static let enableVerboseLogging = false
    static let useNPHIESSandbox = false
    #endif
}
```

---

## 🔧 Code Architecture

### Core Managers

#### GeminiFileSearchManager
```swift
@MainActor
class GeminiFileSearchManager: ObservableObject {
    // Handles document upload, processing, and querying
    func uploadAndIndexDocument(fileURL: URL) async throws -> DocumentMetadata
    func queryDocuments(question: String, language: String) async throws -> (answer: String, citations: [Citation])
}
```

#### LocalizationManager
```swift
class LocalizationManager: ObservableObject {
    // Type-safe localization with Arabic/English support
    func localized(_ key: LocalizationKey) -> String
    func setLanguage(_ language: AppLanguage)
}
```

#### VoiceAssistantManager
```swift
@MainActor
class VoiceAssistantManager: NSObject, ObservableObject, SFSpeechRecognizerDelegate {
    // Voice recognition and text-to-speech
    func startListening()
    func stopListening()
    func speak(_ text: String, language: String)
}
```

### Data Models

#### DocumentMetadata
```swift
struct DocumentMetadata: Codable, Identifiable {
    let id: UUID
    let fileName: String
    let fileSize: Int64
    let uploadDate: Date
    let language: String
    let documentType: String
    var geminiFileID: String?
    var processingStatus: ProcessingStatus
}
```

#### ChatMessage
```swift
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let language: String
    var citations: [Citation]?
}
```

### SwiftUI Views

#### Main App Structure
```swift
struct AFHAMApp: View {
    @StateObject private var geminiManager = GeminiFileSearchManager()
    @StateObject private var voiceManager = VoiceAssistantManager()
    @State private var currentLanguage: AppLanguage = .arabic
    
    var body: some View {
        TabView {
            DocumentsView()
            ChatView()
            VoiceAssistantView()
            ContentCreatorView()
            SettingsView()
        }
    }
}
```

#### Bilingual Support
```swift
// Use throughout the app for automatic localization
Text(.localized(.appTitle))
    .environment(\.locale, Locale(identifier: currentLanguage.locale))
    .environment(\.layoutDirection, currentLanguage == .arabic ? .rightToLeft : .leftToRight)
```

---

## 🔌 API Integration

### Gemini API Integration

#### File Upload
```swift
private func uploadFileToGemini(fileData: Data, fileName: String) async throws -> String {
    let endpoint = "\(baseURL)/files"
    
    var request = URLRequest(url: URL(string: endpoint)!)
    request.httpMethod = "POST"
    request.addValue(AFHAMConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
    
    // Multipart form data implementation
    let boundary = UUID().uuidString
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    // Add metadata and file data...
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
    
    return json["name"] as! String
}
```

#### Query Processing
```swift
func queryDocuments(question: String, language: String) async throws -> (answer: String, citations: [Citation]) {
    let endpoint = "\(baseURL)/models/\(AFHAMConfig.geminiModel):generateContent"
    
    let body: [String: Any] = [
        "contents": [
            ["parts": [["text": question]]]
        ],
        "tools": [
            ["fileSearch": ["fileSearchStoreNames": [storeID]]]
        ]
    ]
    
    // Process request and extract citations...
    return (answer, citations)
}
```

### Apple Framework Integration

#### Speech Recognition
```swift
private func setupSpeechRecognition() {
    SFSpeechRecognizer.requestAuthorization { status in
        DispatchQueue.main.async {
            self.isAuthorized = status == .authorized
        }
    }
}

func startListening() {
    let request = SFSpeechAudioBufferRecognitionRequest()
    recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, error in
        if let result = result {
            self.recognizedText = result.bestTranscription.formattedString
        }
    }
}
```

#### Document Picker
```swift
struct DocumentPicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: AFHAMConfig.supportedFileTypes)
        picker.delegate = context.coordinator
        return picker
    }
}
```

---

## 🏥 Healthcare Integration (NPHIES/FHIR)

### FHIR Resource Creation

#### Patient Resource
```swift
func createPatientResource(_ patientData: PatientData) async throws -> FHIRPatient {
    let patient = FHIRPatient(
        id: UUID().uuidString,
        identifier: [
            FHIRIdentifier(
                system: "\(brainSAITOIDSaudi).patient",
                value: patientData.nationalId
            )
        ],
        name: [
            FHIRHumanName(
                family: patientData.familyName,
                given: patientData.givenNames,
                text: patientData.fullName
            )
        ],
        gender: patientData.gender.fhirValue,
        birthDate: patientData.birthDate
    )
    
    try await validateFHIRResource(patient)
    return patient
}
```

#### NPHIES Submission
```swift
func submitToNPHIES(_ resource: FHIRResource) async throws -> NPHIESResponse {
    // Validate NPHIES compliance
    try await validateNPHIESCompliance(resource)
    
    let request = createNPHIESRequest(resource)
    let response = try await submitRequest(request)
    
    // Audit logging for compliance
    await auditLogger.logNPHIESSubmission(resource.resourceType, resourceId: resource.id, success: response.success)
    
    return response
}
```

### BrainSAIT OID Usage
```swift
// Saudi Arabia namespace
private let brainSAITOIDSaudi = "1.3.6.1.4.1.61026.2"

// Sudan namespace  
private let brainSAITOIDSudan = "1.3.6.1.4.1.61026.1"

// Usage in identifiers
FHIRIdentifier(
    system: "\(brainSAITOIDSaudi).patient",
    value: patientId
)
```

---

## 🔒 Privacy & Security Implementation

### Data Encryption (PDPL Compliant)

#### AES-256 Encryption
```swift
private func encryptData(_ data: Data) throws -> Data {
    let key = SymmetricKey(size: .bits256)
    let sealedBox = try AES.GCM.seal(data, using: key)
    return sealedBox.combined!
}

private func decryptData(_ encryptedData: Data) throws -> Data {
    let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
    return try AES.GCM.open(sealedBox, using: encryptionKey)
}
```

#### Keychain Storage
```swift
struct KeychainHelper {
    static func saveAPIKey(_ key: String) {
        let data = key.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "GeminiAPIKey",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "GeminiAPIKey",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == noErr, let data = dataTypeRef as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
}
```

### Audit Logging
```swift
actor ComplianceAuditLogger {
    private var auditEntries: [AuditEntry] = []
    
    func logDataAccess(_ resourceType: String, resourceId: String) {
        let entry = AuditEntry(
            timestamp: Date(),
            action: .dataAccess,
            resourceType: resourceType,
            resourceId: resourceId,
            userId: getCurrentUserId()
        )
        auditEntries.append(entry)
    }
    
    func exportAuditLog() -> [AuditEntry] {
        return auditEntries
    }
}
```

---

## 🧪 Testing Strategy

### Unit Testing

#### Manager Testing
```swift
class GeminiFileSearchManagerTests: XCTestCase {
    var manager: GeminiFileSearchManager!
    
    override func setUp() {
        super.setUp()
        manager = GeminiFileSearchManager()
    }
    
    func testDocumentUpload() async throws {
        let testURL = Bundle.main.url(forResource: "test", withExtension: "pdf")!
        let metadata = try await manager.uploadAndIndexDocument(fileURL: testURL)
        
        XCTAssertNotNil(metadata.geminiFileID)
        XCTAssertEqual(metadata.processingStatus, .ready)
    }
    
    func testQueryProcessing() async throws {
        let (answer, citations) = try await manager.queryDocuments(
            question: "What is the main topic?",
            language: "en"
        )
        
        XCTAssertFalse(answer.isEmpty)
        XCTAssertGreaterThan(citations.count, 0)
    }
}
```

#### Localization Testing
```swift
class LocalizationManagerTests: XCTestCase {
    func testLocalizationKeys() {
        let manager = LocalizationManager.shared
        
        // Test Arabic
        manager.setLanguage(.arabic)
        XCTAssertEqual(manager.localized(.appTitle), "أفهم")
        
        // Test English
        manager.setLanguage(.english)
        XCTAssertEqual(manager.localized(.appTitle), "AFHAM")
    }
}
```

### UI Testing
```swift
class AFHAMUITests: XCTestCase {
    func testDocumentUpload() {
        let app = XCUIApplication()
        app.launch()
        
        app.tabBars.buttons["Documents"].tap()
        app.buttons["Add"].tap()
        
        // Simulate document selection
        let documentPicker = app.otherElements["DocumentPicker"]
        XCTAssertTrue(documentPicker.waitForExistence(timeout: 5))
    }
    
    func testVoiceRecognition() {
        let app = XCUIApplication()
        app.launch()
        
        app.tabBars.buttons["Chat"].tap()
        app.buttons["VoiceInput"].tap()
        
        XCTAssertTrue(app.staticTexts["Listening..."].waitForExistence(timeout: 2))
    }
}
```

### Performance Testing
```swift
class PerformanceTests: XCTestCase {
    func testDocumentProcessingPerformance() {
        measure {
            // Measure document processing time
            let manager = GeminiFileSearchManager()
            let testURL = Bundle.main.url(forResource: "large_test", withExtension: "pdf")!
            
            let expectation = self.expectation(description: "Document processing")
            Task {
                _ = try await manager.uploadAndIndexDocument(fileURL: testURL)
                expectation.fulfill()
            }
            
            waitForExpectations(timeout: 30)
        }
    }
}
```

---

## 📦 Build & Deployment

### Build Configurations

#### Debug Build
```bash
# Build for simulator
xcodebuild -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build

# Build for device (requires provisioning profile)
xcodebuild -scheme AFHAM -destination 'generic/platform=iOS' build
```

#### Release Build
```bash
# Archive for App Store
xcodebuild -scheme AFHAM -destination 'generic/platform=iOS' archive -archivePath ./build/AFHAM.xcarchive

# Export for App Store
xcodebuild -exportArchive -archivePath ./build/AFHAM.xcarchive -exportPath ./build -exportOptionsPlist ./ExportOptions.plist
```

### ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

### Continuous Integration

#### GitHub Actions Workflow
```yaml
name: iOS Build and Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-14
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode Version
      run: sudo xcode-select -s /Applications/Xcode_15.0.app/Contents/Developer
    
    - name: Install Dependencies
      run: swift package resolve
    
    - name: Run Tests
      run: xcodebuild test -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
    
    - name: Build Archive
      if: github.ref == 'refs/heads/main'
      run: |
        xcodebuild archive \
          -scheme AFHAM \
          -destination 'generic/platform=iOS' \
          -archivePath ./build/AFHAM.xcarchive
```

### App Store Deployment

#### Version Management
```swift
// Version.swift
struct AppVersion {
    static let current = "1.0.0"
    static let build = "1"
    static let minimumOSVersion = "17.0"
}
```

#### Release Checklist
- [ ] Update version number
- [ ] Run full test suite
- [ ] Update privacy policy URLs
- [ ] Verify API key configuration
- [ ] Test on physical devices
- [ ] Generate release notes
- [ ] Submit for App Store review

---

## 🔍 Debugging & Monitoring

### Logging System
```swift
class AppLogger {
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
        """
        
        print(logMessage)
        
        #if DEBUG
        // Console logging for debug
        #else
        // Remote logging for production
        sendToAnalytics(logMessage)
        #endif
    }
}
```

### Performance Monitoring
```swift
struct PerformanceMonitor {
    static func measureTime<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        
        AppLogger.shared.log("⏱️ \(operation) took \(String(format: "%.3f", duration))s", level: .debug)
        return result
    }
}

// Usage
let result = PerformanceMonitor.measureTime("Document Processing") {
    return processDocument(data)
}
```

### Crash Reporting
```swift
// Integrate with your preferred crash reporting service
import Crashlytics

class CrashReporter {
    static func setup() {
        Crashlytics.configure()
    }
    
    static func recordError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        Crashlytics.record(error: error, userInfo: additionalInfo)
    }
}
```

---

## 🚀 Advanced Features Development

### Offline Mode Implementation
```swift
// Enable document caching and offline processing
class OfflineModeManager: ObservableObject {
    func cacheDocument(_ document: DocumentMetadata, content: Data) async throws {
        let encryptedContent = try encryptData(content)
        let cacheURL = getCacheURL(for: document.id)
        try encryptedContent.write(to: cacheURL)
    }
    
    func processOfflineQuery(_ query: String, documentId: UUID) async throws -> String {
        guard let cachedContent = try getCachedDocument(documentId) else {
            throw AFHAMError.documentNotCached(documentId)
        }
        
        // Perform basic text analysis offline
        return performBasicTextAnalysis(query: query, content: cachedContent)
    }
}
```

### Collaboration Features
```swift
// Real-time document sharing and collaborative analysis
class CollaborationManager: ObservableObject {
    func shareDocument(_ document: DocumentMetadata, with users: [String]) async throws -> String {
        let shareId = UUID().uuidString
        
        // Validate sharing permissions (PDPL compliance)
        try validateSharingPermissions(document)
        
        // Send secure invitations
        for user in users {
            try await sendSecureInvitation(user, shareId: shareId)
        }
        
        return shareId
    }
}
```

---

## 📚 Resources & References

### Documentation
- [Apple SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Google Gemini API Reference](https://ai.google.dev/docs)
- [FHIR R4 Specification](https://hl7.org/fhir/R4/)
- [NPHIES Technical Specifications](https://nphies.sa)

### Code Examples
- [AFHAM GitHub](https://github.com/Fadil369/AFHAM-PRO)
- [Sample FHIR Resources](https://github.com/Fadil369/AFHAM-PRO/tree/main/samples)
- [SwiftUI Best Practices](https://afham.brainsait.io/docs/best-practices)

### Support
- **Developer Support**: dev-support@brainsait.com
- **Technical Documentation**: afham.brainsait.io/docs
- **API Status**: afham.brainsait.io/status
- **Community Forum**: afham.brainsait.io/developers

---

*© 2024 BrainSAIT Technologies. All rights reserved.*