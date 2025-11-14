# AFHAM Intelligent Capture - Feature Documentation

## Overview

The **Intelligent Capture** feature transforms AFHAM into a powerful multimodal document scanning and analysis system. It seamlessly captures physical artifacts (medical reports, insurance contracts, pharmacy labels, spreadsheets, food stickers) and transforms them into structured data, insights, and next actions while preserving PDPL compliance.

## Architecture

### Component Overview

```
IntelligentCapture/
├── Models/
│   ├── IntelligentCaptureModels.swift      # Core data models
│   ├── CapturedDocument                     # Document metadata
│   ├── CapturedInsight                      # Unified analysis result
│   └── Template-specific models
├── Camera/
│   └── CameraIntakeManager.swift            # AVCaptureSession + VisionKit
├── Processing/
│   ├── AppleVisionProcessor.swift           # On-device OCR & PHI detection
│   ├── DeepSeekOCRClient.swift             # Cloud OCR API
│   ├── OpenAIVisionClient.swift            # Semantic analysis API
│   └── CloudVisionClients.swift            # Gemini Vision integration
├── Templates/
│   └── MedicalTemplateEngine.swift         # Domain-specific analysis
├── Orchestration/
│   └── IntelligentCaptureManager.swift     # Main coordinator
├── UI/
│   ├── IntelligentCaptureViews.swift       # SwiftUI views
│   └── ExportManager.swift                 # Multi-format export
└── Integration/
    └── IntelligentCaptureIntegration.swift # App integration layer
```

### Data Flow

```
1. Camera Capture (AVCaptureSession)
   ↓
2. Document Detection & Perspective Correction (Vision Framework)
   ↓
3. Apple Vision OCR (On-device, always available)
   ├── Text extraction
   ├── Document classification
   └── PHI detection & redaction
   ↓
4. Cloud OCR (DeepSeek) [If online]
   └── High-fidelity text extraction with tables
   ↓
5. Multimodal Analysis (Parallel)
   ├── OpenAI Vision → Semantic understanding, action items
   └── Gemini Vision → Bilingual analysis, compliance checks
   ↓
6. Template-Specific Analysis
   └── Lab reports, prescriptions, insurance claims, etc.
   ↓
7. Result Aggregation
   └── CapturedInsight with unified text, summary, and actions
   ↓
8. Export (FHIR, PDF, CSV, JSON, WhatsApp)
```

## Key Features

### 1. **Multimodal OCR Pipeline**

- **Apple Vision** (On-device): Low-latency text recognition, always available offline
- **DeepSeek OCR** (Cloud): High-fidelity text extraction with table structure
- **OpenAI Vision**: Semantic understanding, summarization, entity extraction
- **Gemini Vision**: Bilingual insights (AR/EN), compliance checking, medical coding

### 2. **Document Types Supported**

| Document Type | Template Analysis | Key Features |
|--------------|-------------------|--------------|
| Medical Report | ✅ | Diagnosis extraction, procedure coding |
| Lab Report | ✅ | Value interpretation, abnormal flagging, visualizations |
| Prescription | ✅ | Medication parsing, dosage validation, usage instructions |
| Insurance Claim | ✅ | Claim status detection, denial analysis |
| Pharmacy Label | ✅ | Drug info extraction, safety warnings |
| Food Label | ✅ | Nutrition facts, dietary insights |
| Contract | ⚠️ | General text extraction |
| Spreadsheet | ⚠️ | Table structure preservation |
| Generic | ⚠️ | Basic OCR without specialized analysis |

### 3. **PDPL Compliance**

- **Automatic PHI Detection**: Detects patient names, IDs, dates, phone numbers, medical record numbers
- **Consent-Based Processing**: Requires explicit user consent before processing PHI
- **Redaction**: Automatically redacts detected PHI before cloud transmission
- **Audit Logging**: All capture events logged via ComplianceAuditLogger
- **Encryption**: All local storage encrypted using AES-256-GCM

### 4. **Offline Resilience**

- **Apple Vision Always Available**: On-device OCR works completely offline
- **Job Queue System**: Cloud analysis jobs queued when offline
- **Automatic Retry**: Jobs automatically processed when connectivity returns
- **Deferred Analysis Badge**: UI indicates when cloud analysis is pending

### 5. **Medical Template Engine**

#### Lab Report Analysis
- Extracts lab values with units and normal ranges
- Flags abnormal values (low, high, critical)
- Provides clinical interpretations
- Generates bar chart visualizations
- Recommends follow-up actions

#### Prescription Analysis
- Parses medication names, dosages, frequencies
- Extracts usage instructions and duration
- Provides medication safety reminders

#### Insurance Claim Analysis
- Identifies policy numbers, claim amounts
- Detects denial status
- Suggests appeal actions

#### Food Label Analysis
- Extracts nutrition facts (calories, sodium, fat, etc.)
- Assesses nutrient levels against daily values
- Provides dietary recommendations

### 6. **Export Formats**

| Format | Use Case | Output |
|--------|----------|--------|
| **FHIR Observation** | Healthcare interoperability | JSON following HL7 FHIR R4 spec |
| **PDF Report** | Professional documentation | Formatted PDF with image, text, findings |
| **CSV** | Data analysis | Spreadsheet-compatible tabular data |
| **JSON** | Developer integration | Complete CapturedInsight serialization |
| **WhatsApp Summary** | Quick sharing | Concise text with emojis for messaging |
| **Plain Text** | Basic export | Unformatted text extraction |

### 7. **Bilingual Support (AR/EN)**

- **UI Localization**: All UI elements translated
- **OCR Language Hints**: Optimized for Arabic and English
- **Bilingual Summaries**: Gemini Vision provides parallel AR/EN analysis
- **RTL Support**: Proper right-to-left rendering for Arabic

## API Integration

### Required API Keys

Configure via Settings → Intelligent Capture:

1. **DeepSeek OCR API**
   - Purpose: High-fidelity text extraction
   - Endpoint: `https://api.deepseek.com/v1/ocr`
   - Optional: Falls back to Apple Vision if unavailable

2. **OpenAI API**
   - Purpose: Semantic analysis and reasoning
   - Model: `gpt-4-vision-preview`
   - Endpoint: `https://api.openai.com/v1/chat/completions`
   - Optional: Analysis will be limited without it

3. **Google Gemini API**
   - Purpose: Bilingual insights and compliance
   - Model: `gemini-pro-vision`
   - Endpoint: Already configured via existing AFHAM Gemini integration
   - Note: Uses existing AFHAM Gemini API key

### API Key Storage

All API keys stored securely in iOS Keychain via `SecureAPIKeyManager`:

```swift
// Set keys
SecureAPIKeyManager.shared.setDeepSeekAPIKey("sk-...")
SecureAPIKeyManager.shared.setOpenAIAPIKey("sk-...")

// Keys automatically loaded by IntelligentCaptureManager
```

## Usage Guide

### Basic Capture Flow

1. **Open Intelligent Capture Tab**
   - Tap "Capture" icon in tab bar

2. **Select Document Type**
   - Scroll horizontal carousel at bottom
   - Choose: Medical Report, Lab Report, Prescription, etc.

3. **Capture Document**
   - Point camera at document
   - Green box appears when document detected
   - Tap large white circle to capture
   - Wait for perspective correction

4. **Processing**
   - Stage 1: On-device OCR (instant)
   - Stage 2: DeepSeek OCR (2-5s)
   - Stage 3: Multimodal analysis (5-10s)
   - Stage 4: Template analysis (instant)

5. **Review Results**
   - **Summary Tab**: Overview, confidence, action items
   - **Text Tab**: Full extracted text (selectable)
   - **Insights Tab**: AI analysis, bilingual summary, compliance
   - **Analysis Tab**: Template-specific findings

6. **Export**
   - Tap share icon (top right)
   - Choose format: FHIR, PDF, CSV, JSON, WhatsApp, Text
   - Share via standard iOS share sheet

### Multi-Page Documents

1. Enable batch mode: Tap "Multi-Page" button
2. Capture each page sequentially
3. Page count displayed in UI
4. Tap "Multi-Page" again to finalize batch
5. All pages combined in single analysis

### PHI Handling

**Without Consent:**
- PHI detected and redacted before cloud processing
- Only redacted text sent to cloud APIs
- Original text preserved locally with encryption

**With Consent:**
- Toggle "Allow PHI Processing" in settings menu
- Full text (including PHI) sent to cloud for better analysis
- Still encrypted in local storage
- Audit logged

## Configuration

### AFHAMConstants.IntelligentCapture

```swift
struct IntelligentCapture {
    // Feature toggles
    static let enableAppleVision = true
    static let enableDeepSeekOCR = true
    static let enableOpenAIVision = true
    static let enableGeminiVision = true

    // Image quality
    static let imageCompressionQuality: CGFloat = 0.9
    static let maxImageDimension: CGFloat = 4096

    // OCR settings
    static let ocrLanguages = ["en-US", "ar-SA"]
    static let ocrConfidenceThreshold = 0.7

    // Offline mode
    static let offlineRetentionDays = 7
    static let maxOfflineQueueSize = 100
    static let offlineProcessingBatchSize = 5

    // PHI Detection
    static let enablePHIDetection = true
    static let requireConsentForPHI = true

    // Cache
    static let maxCachedInsights = 50
    static let cacheExpirationDays = 30
}
```

## File Structure

### Core Files Created

```
/AFHAM/Features/IntelligentCapture/
├── IntelligentCaptureModels.swift          (~680 lines)
│   ├── Data models for documents, OCR results, insights
│   └── FHIR-compatible structures
│
├── CameraIntakeManager.swift               (~550 lines)
│   ├── AVCaptureSession setup
│   ├── Document detection with Vision
│   └── Perspective correction
│
├── AppleVisionProcessor.swift              (~520 lines)
│   ├── On-device OCR (VNRecognizeTextRequest)
│   ├── Document classification
│   ├── PHI detection and redaction
│   └── Barcode/QR code detection
│
├── CloudVisionClients.swift                (~580 lines)
│   ├── DeepSeekOCRClient
│   ├── OpenAIVisionClient
│   ├── GeminiFileSearchManager extension
│   └── API request/response handling
│
├── IntelligentCaptureManager.swift         (~650 lines)
│   ├── Main orchestration logic
│   ├── Pipeline coordination
│   ├── Result aggregation
│   └── Offline queue management
│
├── MedicalTemplateEngine.swift             (~720 lines)
│   ├── Template-specific analysis
│   ├── Lab value interpretation
│   ├── Medication parsing
│   └── Compliance checking
│
├── IntelligentCaptureViews.swift           (~820 lines)
│   ├── Main capture UI
│   ├── Camera preview
│   ├── Results display
│   └── History view
│
├── ExportManager.swift                     (~450 lines)
│   ├── FHIR export
│   ├── PDF generation
│   ├── CSV/JSON export
│   └── Share sheet integration
│
└── IntelligentCaptureIntegration.swift     (~350 lines)
    ├── App state management
    ├── API key configuration
    └── Settings UI

/AFHAM/Core/
└── AFHAMConstants.swift                    (updated)
    └── IntelligentCapture configuration

/AFHAM/Resources/Localizations/
├── en.lproj/Localizable.strings            (updated +50 keys)
└── ar.lproj/Localizable.strings            (updated +50 keys)
```

**Total Lines of Code: ~4,500**

## Dependencies

### Frameworks Used

- **AVFoundation**: Camera capture and session management
- **Vision**: On-device OCR and document detection
- **VisionKit**: Enhanced document scanning (iOS 15+)
- **CoreML**: On-device machine learning
- **NaturalLanguage**: Language detection and entity recognition
- **PDFKit**: PDF generation for export
- **UIKit**: Graphics rendering and share sheets
- **SwiftUI**: Modern declarative UI
- **Combine**: Reactive programming

### External APIs

- **DeepSeek OCR**: Cloud-based OCR with table extraction
- **OpenAI Vision**: GPT-4 Vision for semantic analysis
- **Google Gemini**: Multimodal AI for bilingual insights
- **AFHAM Backend**: Existing Gemini integration

## Security Considerations

### Data Protection

1. **Local Storage**: All captured insights encrypted with AES-256-GCM
2. **API Keys**: Stored in iOS Keychain (hardware-encrypted)
3. **PHI Redaction**: Automatic detection and masking before cloud transmission
4. **Network Security**: TLS 1.3 for all API communications
5. **Certificate Pinning**: Prevents MITM attacks (via existing CertificatePinningManager)

### Privacy Controls

- User consent required for PHI processing
- Explicit permission requests for camera access
- Audit logging for all capture events
- Configurable data retention (7-30 days)
- Local-first processing (Apple Vision always on-device)

## Performance

### Typical Processing Times

| Stage | Duration | Network Required |
|-------|----------|------------------|
| Camera capture | Instant | No |
| Perspective correction | ~500ms | No |
| Apple Vision OCR | 1-2s | No |
| DeepSeek OCR | 2-5s | Yes |
| OpenAI Vision | 3-8s | Yes |
| Gemini Vision | 3-8s | Yes |
| Template analysis | ~200ms | No |
| **Total (online)** | **8-15s** | Yes |
| **Total (offline)** | **2-3s** | No |

### Resource Usage

- **Memory**: ~150MB peak during processing
- **Storage**: ~500KB per captured insight (with image)
- **Network**: ~1-2MB per document (image upload)
- **Battery**: Moderate impact during camera use

## Troubleshooting

### Common Issues

#### Camera Not Starting
```
Error: "Camera access not authorized"
Solution: Go to iOS Settings → Privacy → Camera → AFHAM → Enable
```

#### OCR Quality Poor
```
Issue: Blurry or low-quality text extraction
Solutions:
- Ensure good lighting
- Hold device steady
- Move closer to document
- Enable flash for dark environments
```

#### Cloud Analysis Failing
```
Error: "DeepSeek OCR unavailable"
Solutions:
1. Check API key configuration in Settings
2. Verify internet connectivity
3. Check API quota/billing status
4. Use offline mode (Apple Vision only)
```

#### PHI Not Detected
```
Issue: Sensitive information not redacted
Solutions:
- Apple Vision PHI detection is pattern-based
- Review redacted text before sharing
- Manually redact if needed
- Enable "Allow PHI Processing" for better accuracy
```

## Future Enhancements

### Planned Features

1. **Document Comparison**: Side-by-side comparison of lab reports over time
2. **Medication Interaction Checking**: Cross-reference prescriptions
3. **Insurance Claim Tracking**: Monitor claim status over time
4. **Health Trends**: Visualize lab values across multiple reports
5. **Voice Annotations**: Add voice notes to captured documents
6. **Batch Processing**: Process multiple documents in parallel
7. **Cloud Sync**: Sync captured insights across devices
8. **Machine Learning**: On-device document classification with CoreML
9. **Accessibility**: VoiceOver support for results
10. **Export Templates**: Customizable export formats

### Under Consideration

- Integration with HealthKit for lab results
- NPHIES direct submission for insurance claims
- Telegram/Signal export options
- Custom medical template builder
- Multi-user support for healthcare teams

## Testing

### Manual Testing Checklist

- [ ] Camera capture works in portrait/landscape
- [ ] Document detection highlights correctly
- [ ] Perspective correction straightens images
- [ ] OCR extracts text accurately
- [ ] Document classification correct for each type
- [ ] PHI detection catches patient names, IDs
- [ ] Redaction masks sensitive data
- [ ] Offline mode shows deferred analysis badge
- [ ] Offline queue processes when back online
- [ ] Template analysis provides correct insights
- [ ] Export generates valid FHIR/PDF/CSV
- [ ] Bilingual summaries in both AR/EN
- [ ] Multi-page capture combines pages
- [ ] History view shows previous captures
- [ ] API key configuration saves correctly

### Test Documents

Recommended test documents:
1. Sample lab report (CBC)
2. Sample prescription (with dosage)
3. Sample insurance claim (approval/denial)
4. Food nutrition label
5. Arabic medical report
6. Multi-page medical record

## Support

### Documentation

- Main README: `/AFHAM_CODEBASE_OVERVIEW.md`
- API Integration: See `CloudVisionClients.swift` comments
- Data Models: See `IntelligentCaptureModels.swift` comments

### Contact

- **Email**: support@brainsait.com
- **Company**: BrainSAIT
- **Website**: https://brainsait.com

## License

Copyright © 2024 BrainSAIT. All rights reserved.

Part of the AFHAM (أفهم) AI Health Assistant platform.

---

**Version**: 1.0.0
**Last Updated**: 2025-01-14
**Author**: BrainSAIT Development Team
