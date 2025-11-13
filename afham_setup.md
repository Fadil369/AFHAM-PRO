# AFHAM - أفهم (Understand)
## Advanced Multimodal RAG System for iOS

### 🎯 Overview
AFHAM is a native iOS application that combines Google's Gemini File Search with Apple Intelligence to create a powerful RAG (Retrieval-Augmented Generation) system. The app enables users to upload documents, chat with them, use voice assistance, and generate various types of content—all in Arabic and English.

---

## 🏗️ Architecture

### Core Components

1. **Gemini File Search Integration**
   - Direct file upload and indexing
   - Semantic search capabilities
   - Citation-based responses
   - Multi-format document support

2. **Apple Native Services**
   - Speech Recognition (SFSpeech)
   - Text-to-Speech (AVSpeechSynthesis)
   - Natural Language Processing
   - Vision Framework (future: OCR)

3. **BrainSAIT Design System**
   - Glass morphism UI
   - Bilingual RTL/LTR support
   - Brand colors and gradients
   - Smooth animations

---

## 📁 Project Structure

```
AFHAM/
├── AFHAMApp.swift                  # Main app entry point
├── Models/
│   ├── DocumentMetadata.swift      # Document data models
│   ├── ChatMessage.swift           # Chat message models
│   └── Citation.swift              # Citation models
├── Managers/
│   ├── GeminiFileSearchManager.swift  # Gemini API integration
│   └── VoiceAssistantManager.swift    # Voice I/O handling
├── ViewModels/
│   ├── ChatViewModel.swift         # Chat logic
│   └── ContentCreatorViewModel.swift  # Content generation
├── Views/
│   ├── DocumentsView.swift         # Document management
│   ├── ChatView.swift              # Chat interface
│   ├── VoiceAssistantView.swift    # Voice interface
│   ├── ContentCreatorView.swift    # Content generation
│   └── SettingsView.swift          # App settings
├── Components/
│   ├── DocumentCard.swift          # Document UI component
│   ├── MessageBubble.swift         # Chat bubble component
│   ├── ContentTypeCard.swift       # Content type selector
│   └── VoiceVisualization.swift    # Voice animation
└── Resources/
    ├── Assets.xcassets             # App assets
    └── Localizations/              # Arabic/English strings
```

---

## 🚀 Setup Instructions

### Prerequisites

1. **Xcode 15.0+**
2. **iOS 17.0+ SDK**
3. **Google Gemini API Key**
   - Get from: https://ai.google.dev/
   - Free tier: 15 RPM, 1 million tokens/day

### Step 1: Create Xcode Project

```bash
# Create new iOS App project
# Product Name: AFHAM
# Organization: BrainSAIT
# Interface: SwiftUI
# Language: Swift
# Minimum iOS: 17.0
```

### Step 2: Configure Info.plist

Add required permissions:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>AFHAM needs speech recognition to understand your voice commands</string>

<key>NSMicrophoneUsageDescription</key>
<string>AFHAM needs microphone access for voice input</string>

<key>Privacy - Speech Recognition Usage Description</key>
<string>AFHAM يحتاج للتعرف على الكلام لفهم أوامرك الصوتية</string>

<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>ar</string>
</array>

<key>CFBundleDevelopmentRegion</key>
<string>en</string>
```

### Step 3: Add API Key

In `AFHAMConfig.swift`:

```swift
static let geminiAPIKey = "YOUR_GEMINI_API_KEY_HERE"
```

⚠️ **Security Note**: For production, use:
- Environment variables
- Keychain storage
- Backend proxy for API calls

### Step 4: Configure Capabilities

In Xcode Project Settings → Signing & Capabilities:

1. **Add Capability**: Background Modes
   - ✅ Audio, AirPlay, and Picture in Picture
   - ✅ Background fetch

2. **Add Capability**: Speech Recognition

---

## 🎨 Features

### 1. Document Management
- ✅ Multi-format upload (PDF, DOCX, TXT, etc.)
- ✅ Automatic indexing with Gemini File Search
- ✅ Language detection (Arabic/English)
- ✅ Status tracking (uploading → processing → ready)
- ✅ File metadata and organization

### 2. Intelligent Chat
- ✅ RAG-powered Q&A with documents
- ✅ Citation support with source references
- ✅ Bilingual conversation (Arabic/English)
- ✅ Context-aware responses
- ✅ Message history

### 3. Voice Assistant
- ✅ Real-time speech recognition
- ✅ Natural voice synthesis
- ✅ Bilingual voice I/O
- ✅ Voice visualization
- ✅ Hands-free operation

### 4. Content Creator
- ✅ 8 content types:
  - Summary / ملخص
  - Article / مقالة
  - Social Post / منشور
  - Presentation / عرض تقديمي
  - Email / بريد
  - Translation / ترجمة
  - Explanation / شرح
  - Quiz / اختبار
- ✅ Document-based generation
- ✅ Custom instructions
- ✅ Export & share

---

## 🔧 API Integration Details

### Gemini File Search Workflow

```mermaid
graph LR
    A[Upload File] --> B[Create File Search Store]
    B --> C[Upload to Gemini Files API]
    C --> D[Import to File Search Store]
    D --> E[Document Ready]
    E --> F[Query with File Search]
    F --> G[Get Response with Citations]
```

### Key Endpoints

1. **Create File Search Store**
```
POST /v1beta/fileSearchStores
```

2. **Upload File**
```
POST /v1beta/files
Content-Type: multipart/form-data
```

3. **Import to Store**
```
POST /v1beta/{fileSearchStore}:importFile
```

4. **Query with File Search**
```
POST /v1beta/models/gemini-2.0-flash-exp:generateContent
{
  "contents": [...],
  "tools": [{
    "fileSearch": {
      "fileSearchStoreNames": [...]
    }
  }]
}
```

---

## 🌍 Localization

### Arabic Support

1. **RTL Layout**: Automatic via SwiftUI environment
2. **Fonts**: 
   - Arabic: SF Arabic (system)
   - English: SF Pro (system)
3. **Date/Time**: Locale-aware formatting
4. **Number Formatting**: Arabic/Western numerals

### Adding New Translations

Create `Localizable.strings` files:

```
AFHAM/Resources/Localizations/
├── en.lproj/
│   └── Localizable.strings
└── ar.lproj/
    └── Localizable.strings
```

Example:
```swift
// en.lproj/Localizable.strings
"documents_title" = "My Documents";
"upload_button" = "Upload Document";

// ar.lproj/Localizable.strings
"documents_title" = "مستنداتي";
"upload_button" = "رفع مستند";
```

---

## 🎯 Performance Optimization

### Document Processing
- Maximum file size: 100 MB
- Chunk size: 200 tokens (configurable)
- Overlap: 20 tokens
- Indexing: Asynchronous with progress

### API Rate Limits
- **Free Tier**: 15 RPM, 1M tokens/day
- **Paid Tier 1**: 360 RPM, 4M tokens/day
- **Recommendation**: Implement request queuing

### Memory Management
- Use `@MainActor` for UI updates
- Lazy loading for document lists
- Image caching for document thumbnails
- Clear audio buffers after voice processing

---

## 🔒 Security & Compliance

### HIPAA Compliance (if handling PHI)
1. Encrypt files before upload
2. Use secure storage (Keychain)
3. Audit all access
4. Implement user authentication
5. Add session timeout

### Best Practices
- ✅ Never log API keys
- ✅ Validate file types before upload
- ✅ Sanitize user input
- ✅ Use HTTPS only
- ✅ Implement rate limiting
- ✅ Add error boundaries

---

## 📊 Testing Strategy

### Unit Tests
```swift
// Test Gemini API integration
func testFileUpload() async throws {
    let manager = GeminiFileSearchManager()
    let testFile = createTestFile()
    let metadata = try await manager.uploadAndIndexDocument(fileURL: testFile)
    XCTAssertEqual(metadata.processingStatus, .ready)
}

// Test language detection
func testLanguageDetection() {
    let arabicText = "مرحبا بك"
    let language = detectLanguage(from: arabicText)
    XCTAssertEqual(language, "ar")
}
```

### UI Tests
```swift
func testDocumentUploadFlow() throws {
    let app = XCUIApplication()
    app.launch()
    
    app.buttons["Add Document"].tap()
    // Select test file
    app.buttons["Upload"].tap()
    
    let documentCard = app.otherElements["DocumentCard"]
    XCTAssertTrue(documentCard.waitForExistence(timeout: 5))
}
```

---

## 🚢 Deployment

### TestFlight Distribution

1. **Archive Build**
   - Product → Archive
   - Validate App
   - Distribute App → TestFlight

2. **Beta Testing**
   - Internal testing: Team members
   - External testing: Beta testers
   - Collect feedback

### App Store Submission

1. **Prepare Metadata**
   - App name: AFHAM - أفهم
   - Subtitle: Understand Your Documents
   - Keywords: RAG, AI, Documents, Arabic
   - Description: Bilingual (Arabic/English)

2. **Screenshots**
   - 6.7" iPhone 15 Pro Max
   - 6.5" iPhone 11 Pro Max
   - 5.5" iPhone 8 Plus
   - Arabic and English versions

3. **Privacy Policy**
   - Data collection disclosure
   - Third-party services (Google Gemini)
   - User rights and data deletion

---

## 🎨 BrainSAIT Design Guidelines

### Color Palette
```swift
Midnight Blue: #1a365d  // Primary backgrounds
Medical Blue:  #2b6cb8  // Interactive elements
Signal Teal:   #0ea5e9  // Accents & highlights
Deep Orange:   #ea580c  // Call-to-action
Professional Gray: #64748b // Secondary text
```

### Typography
- Headings: System Bold, 32-28pt
- Body: System Regular, 17pt
- Captions: System Regular, 12pt

### Glass Morphism
```swift
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.1))
        .background(.ultraThinMaterial)
)
```

---

## 📈 Future Enhancements

### Phase 2 Features
- [ ] OCR for images (Vision Framework)
- [ ] Offline mode with local embeddings
- [ ] Multi-document comparison
- [ ] Advanced search filters
- [ ] Document annotations
- [ ] Collaboration features

### Phase 3 Features
- [ ] macOS version (Catalyst)
- [ ] iPad optimization
- [ ] Apple Watch companion
- [ ] Siri integration
- [ ] CloudKit sync
- [ ] Custom AI models

---

## 🐛 Troubleshooting

### Common Issues

**1. Speech Recognition Not Working**
- Check microphone permissions
- Verify SFSpeechRecognizer authorization
- Test with different languages

**2. File Upload Fails**
- Check file size (<100MB)
- Verify API key
- Check network connection
- Review Gemini API quotas

**3. RTL Layout Issues**
- Ensure `.environment(\.layoutDirection, .rightToLeft)`
- Use leading/trailing instead of left/right
- Test with Arabic system language

**4. API Rate Limits**
- Implement exponential backoff
- Add request queue
- Cache frequent queries
- Upgrade Gemini tier

---

## 📚 Resources

### Documentation
- [Gemini File Search API](https://ai.google.dev/gemini-api/docs/file-search)
- [Apple Speech Framework](https://developer.apple.com/documentation/speech)
- [SwiftUI Localization](https://developer.apple.com/documentation/xcode/localization)

### BrainSAIT Resources
- Company OID: 1.3.6.1.4.1.61026
- Design System: BrainSAIT Apps Suite
- Support: support@brainsait.com

---

## 📄 License

Copyright © 2024 BrainSAIT. All rights reserved.

---

## 👨‍💻 Development Team

**El Fadil** - Founder & Lead Developer  
BrainSAIT Healthcare AI Technology  
Saudi Arabia

---

## 🙏 Acknowledgments

- Google Gemini API Team
- Apple Developer Relations
- BrainSAIT Early Testers
- Arabic NLP Community

---

**Built with ❤️ in Saudi Arabia**
