# AFHAM Technical Architecture

*Comprehensive technical overview for developers and architects*

## 🏗️ System Architecture

### Core Components
```
┌─────────────────────────────────────────────────────────┐
│                    AFHAM iOS App                        │
├─────────────────────────────────────────────────────────┤
│  UI Layer (SwiftUI)                                     │
│  ├── Chat Interface (afham_chat.swift)                  │
│  ├── Content Views (afham_content.swift)                │
│  └── Main UI (afham_ui.swift)                           │
├─────────────────────────────────────────────────────────┤
│  Business Logic Layer                                   │
│  ├── Chat ViewModel                                     │
│  ├── Voice Assistant Manager                            │
│  ├── Document Manager                                   │
│  └── Analytics Dashboard                                │
├─────────────────────────────────────────────────────────┤
│  Core Services (afham_main.swift)                       │
│  ├── GeminiFileSearchManager                            │
│  ├── VoiceAssistantManager                              │
│  ├── LocalizationManager                                │
│  └── NPHIESCompliance                                   │
├─────────────────────────────────────────────────────────┤
│  External Integrations                                  │
│  ├── Google Gemini API                                  │
│  ├── Speech Framework                                   │
│  ├── NPHIES Services                                    │
│  └── BrainSAIT Analytics                                │
└─────────────────────────────────────────────────────────┘
```

## 🔧 Technical Stack

### iOS Technologies
- **UI Framework**: SwiftUI (iOS 17+)
- **Async Programming**: Swift Concurrency (async/await)
- **Speech Processing**: Speech Framework + AVFoundation
- **Networking**: URLSession with async/await
- **Storage**: Core Data + Keychain Services
- **Localization**: Foundation Internationalization

### External Services
- **AI Processing**: Google Gemini Pro
- **Document Storage**: Google Drive API
- **Healthcare Standards**: NPHIES/FHIR R4
- **Analytics**: Custom BrainSAIT telemetry

## 📊 Data Flow Architecture

### Document Processing Pipeline
```
Document Upload → Gemini File API → Vector Indexing → Search Ready
      ↓               ↓                 ↓              ↓
   Validation    Format Conversion   Embedding     Query Processing
```

### Chat Message Flow
```
User Input → Intent Analysis → Context Retrieval → LLM Processing → Response
    ↓             ↓               ↓                 ↓             ↓
Voice/Text    Language Det.   Document Search    Gemini API    UI Update
```

### Healthcare Data Flow (NPHIES)
```
Medical Doc → FHIR Validation → NPHIES Compliance → Secure Processing
     ↓            ↓                    ↓                  ↓
  OCR/Parse   Structure Check     Privacy Audit      Clinical AI
```

## 🏛️ Design Patterns

### MVVM Architecture
```swift
// View
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        // UI implementation
    }
}

// ViewModel
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let geminiManager = GeminiFileSearchManager()
    
    func sendMessage(_ content: String) async {
        // Business logic
    }
}

// Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let citations: [Citation]
}
```

### Dependency Injection
```swift
protocol DocumentManagerProtocol {
    func uploadDocument(fileURL: URL) async throws -> DocumentInfo
}

class GeminiFileSearchManager: DocumentManagerProtocol {
    // Implementation
}

// Injection in views
struct ContentView: View {
    let documentManager: DocumentManagerProtocol
    
    init(documentManager: DocumentManagerProtocol = GeminiFileSearchManager()) {
        self.documentManager = documentManager
    }
}
```

## 🔐 Security Architecture

### Data Protection Layers
1. **Transport Security**: TLS 1.3, Certificate Pinning
2. **API Authentication**: Secure token management
3. **Local Storage**: Keychain for sensitive data
4. **PDPL Compliance**: Data minimization, consent tracking
5. **Healthcare Security**: HIPAA-equivalent safeguards

### Privacy by Design
```swift
struct PrivacyManager {
    // No PHI in logs
    func sanitizeForLogging(_ input: String) -> String
    
    // Consent tracking
    func trackConsent(for purpose: DataPurpose) -> Bool
    
    // Data retention
    func scheduleDataDeletion(after duration: TimeInterval)
}
```

## 🌐 Localization Architecture

### Multi-language Support
```swift
enum SupportedLanguage: String, CaseIterable {
    case english = "en"
    case arabic = "ar"
    
    var isRTL: Bool {
        return self == .arabic
    }
}

@MainActor
class LocalizationManager: ObservableObject {
    @Published var currentLanguage: SupportedLanguage = .english
    
    func localizedString(for key: String) -> String {
        // Implementation
    }
}
```

### RTL Support Implementation
```swift
struct BilingualText: View {
    let key: String
    @EnvironmentObject var localization: LocalizationManager
    
    var body: some View {
        Text(localization.localizedString(for: key))
            .environment(\.layoutDirection, 
                         localization.currentLanguage.isRTL ? .rightToLeft : .leftToRight)
    }
}
```

## 🚀 Performance Optimizations

### Async/Await Pattern
```swift
// Concurrent document processing
func processMultipleDocuments(_ urls: [URL]) async throws -> [DocumentInfo] {
    try await withThrowingTaskGroup(of: DocumentInfo.self) { group in
        for url in urls {
            group.addTask {
                try await self.uploadDocument(fileURL: url)
            }
        }
        
        var results: [DocumentInfo] = []
        for try await result in group {
            results.append(result)
        }
        return results
    }
}
```

### Memory Management
```swift
// Large document handling
class DocumentProcessor {
    private let cache = NSCache<NSString, DocumentInfo>()
    
    init() {
        cache.countLimit = 50
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB
    }
    
    func processDocument(_ url: URL) async throws -> DocumentInfo {
        let key = url.path as NSString
        
        if let cached = cache.object(forKey: key) {
            return cached
        }
        
        let result = try await performProcessing(url)
        cache.setObject(result, forKey: key, cost: result.sizeBytes)
        return result
    }
}
```

## 🔄 State Management

### Global App State
```swift
@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var activeDocuments: [DocumentInfo] = []
    @Published var networkStatus: NetworkStatus = .connected
    
    // Centralized state updates
    func updateAuthenticationStatus(_ status: Bool) {
        isAuthenticated = status
    }
}
```

### Local View State
```swift
struct ChatView: View {
    @State private var messageText = ""
    @State private var isLoading = false
    @State private var showingDocumentPicker = false
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        // Implementation
    }
}
```

## 📊 Analytics & Monitoring

### Event Tracking
```swift
enum AnalyticsEvent: String {
    case documentUploaded = "document_uploaded"
    case messageSet = "message_sent"
    case voiceQueryStarted = "voice_query_started"
    case errorOccurred = "error_occurred"
}

class AnalyticsDashboard {
    static func trackEvent(_ event: AnalyticsEvent, 
                          properties: [String: Any] = [:]) {
        // Track with privacy compliance
    }
}
```

### Performance Monitoring
```swift
class PerformanceMonitor {
    static func measureExecutionTime<T>(
        operation: String,
        block: () async throws -> T
    ) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            AnalyticsDashboard.trackEvent(.performanceMeasurement, 
                                        properties: [
                                            "operation": operation,
                                            "duration": timeElapsed
                                        ])
        }
        return try await block()
    }
}
```

## 🧪 Testing Strategy

### Unit Testing
```swift
@MainActor
class ChatViewModelTests: XCTestCase {
    var viewModel: ChatViewModel!
    var mockDocumentManager: MockDocumentManager!
    
    override func setUp() {
        mockDocumentManager = MockDocumentManager()
        viewModel = ChatViewModel(documentManager: mockDocumentManager)
    }
    
    func testSendMessage() async throws {
        await viewModel.sendMessage("Test message")
        XCTAssertEqual(viewModel.messages.count, 2) // User + AI response
    }
}
```

### Integration Testing
```swift
class GeminiIntegrationTests: XCTestCase {
    func testDocumentUploadAndQuery() async throws {
        let manager = GeminiFileSearchManager()
        let testFile = Bundle.main.url(forResource: "test", withExtension: "pdf")!
        
        let docInfo = try await manager.uploadFile(fileURL: testFile)
        XCTAssertFalse(docInfo.fileId.isEmpty)
        
        let response = try await manager.queryWithContext("Summarize", 
                                                         documents: [docInfo])
        XCTAssertFalse(response.content.isEmpty)
    }
}
```

## 📈 Scalability Considerations

### Horizontal Scaling Points
- Document processing can be distributed
- Chat sessions are stateless
- Analytics can be batched and queued
- Cache layers for frequently accessed documents

### Performance Bottlenecks
- Gemini API rate limits
- Document upload size limits
- Speech processing latency
- UI responsiveness during large operations

## 🔮 Future Architecture

### Planned Enhancements
- **Offline Mode**: Local LLM for basic queries
- **Collaboration**: Real-time document sharing
- **Advanced Analytics**: Usage patterns and insights
- **Plugin System**: Third-party integrations

### Migration Strategy
- Maintain backward compatibility
- Gradual feature rollout
- A/B testing for major changes
- Progressive data migration

---

**Contact & Support**
- **Technical Support**: support@brainsait.io
- **Architecture Questions**: https://docs.brainsait.io/afham
- **Developer Community**: https://community.brainsait.io

*© 2024 BrainSAIT Technologies. All rights reserved.*