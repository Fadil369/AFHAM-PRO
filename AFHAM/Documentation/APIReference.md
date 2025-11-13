# AFHAM API Reference Guide

*Version 1.0.0 | Last Updated: October 2024*

## Overview

AFHAM (أفهم) provides a comprehensive API for document understanding and healthcare AI interactions. This reference guide covers all available endpoints, methods, and integration patterns.

## Table of Contents

- [Getting Started](#getting-started)
- [Authentication](#authentication)
- [Core APIs](#core-apis)
- [Healthcare Integration](#healthcare-integration)
- [Error Handling](#error-handling)
- [Rate Limits](#rate-limits)
- [Support](#support)

## Getting Started

### Prerequisites
- iOS 17.0+
- Xcode 15.0+
- Valid BrainSAIT API key
- NPHIES compliance configuration (for healthcare use)

### Installation
```swift
import AFHAM

let config = AFHAMConfig.default
let manager = GeminiFileSearchManager()
```

## Authentication

### API Key Configuration
```swift
// Configure your API key
AFHAMConfig.geminiAPIKey = "your_api_key_here"

// For production environments
AFHAMConfig.environment = .production
AFHAMConfig.enableAnalytics = true
```

### Security Best Practices
- Store API keys in Keychain
- Use certificate pinning for production
- Implement token rotation
- Follow PDPL compliance guidelines

## Core APIs

### Document Upload API

#### Upload Document
```swift
func uploadDocument(fileURL: URL) async throws -> DocumentInfo {
    let manager = GeminiFileSearchManager()
    return try await manager.uploadFile(fileURL: fileURL)
}
```

**Parameters:**
- `fileURL`: Local file URL to upload
- Supported formats: PDF, DOCX, TXT, images

**Response:**
```swift
struct DocumentInfo {
    let fileId: String
    let name: String
    let mimeType: String
    let sizeBytes: Int64
    let createdAt: Date
}
```

### Chat API

#### Send Message
```swift
func sendMessage(_ content: String, 
                context: [DocumentInfo] = []) async throws -> ChatResponse {
    let chatModel = ChatViewModel()
    return try await chatModel.sendMessage(content, withContext: context)
}
```

**Parameters:**
- `content`: User message text
- `context`: Array of document references for context

**Response:**
```swift
struct ChatResponse {
    let messageId: String
    let content: String
    let citations: [Citation]
    let confidence: Double
    let timestamp: Date
}
```

### Voice Assistant API

#### Start Voice Recognition
```swift
func startVoiceRecognition() async throws {
    let voiceManager = VoiceAssistantManager()
    try await voiceManager.startListening()
}
```

#### Process Voice Input
```swift
func processVoiceInput(_ audioData: Data) async throws -> VoiceResponse {
    // Implementation for voice processing
}
```

## Healthcare Integration

### NPHIES Compliance
```swift
// Configure NPHIES compliance
AFHAMConfig.enableNPHIESCompliance = true
AFHAMConfig.nphiesEndpoint = "https://nphies.sa/api/v1"

// Process healthcare document
let healthcareManager = NPHIESCompliance()
let result = try await healthcareManager.processDocument(documentId)
```

### FHIR Resource Processing
```swift
struct FHIRProcessor {
    func processPatientData(_ data: Data) async throws -> FHIRResource {
        // FHIR R4 compliant processing
    }
}
```

## Error Handling

### Standard Error Types
```swift
enum AFHAMError: Error {
    case authenticationFailed
    case documentUploadFailed(String)
    case apiRateLimitExceeded
    case networkError(Error)
    case nphiesComplianceViolation(String)
}
```

### Error Response Format
```json
{
  "error": {
    "code": "DOCUMENT_UPLOAD_FAILED",
    "message": "Unable to process document format",
    "details": {
      "supportedFormats": ["pdf", "docx", "txt"],
      "receivedFormat": "xlsx"
    },
    "timestamp": "2024-10-02T10:30:00Z"
  }
}
```

## Rate Limits

### API Limits
- Document uploads: 100 per hour
- Chat messages: 1000 per hour
- Voice queries: 500 per hour

### Handling Rate Limits
```swift
func handleRateLimit(_ error: AFHAMError) {
    switch error {
    case .apiRateLimitExceeded:
        // Implement exponential backoff
        Task {
            try await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
            // Retry request
        }
    default:
        break
    }
}
```

## Localization Support

### Arabic/English Support
```swift
// Set language preference
AFHAMConfig.preferredLanguage = .arabic
LocalizationManager.shared.setLanguage(.arabic)

// Get localized strings
let title = LocalizationManager.shared.localizedString(for: "welcome_message")
```

### RTL Layout Support
```swift
struct RTLSupportedView: View {
    var body: some View {
        Text("مرحبا")
            .environment(\.layoutDirection, .rightToLeft)
    }
}
```

## Analytics and Monitoring

### Performance Metrics
```swift
// Track performance
AnalyticsDashboard.trackEvent(.documentUploaded, properties: [
    "fileSize": fileSize,
    "processingTime": processingTime,
    "success": true
])
```

### Debug Logging
```swift
// Enable debug logging
AFHAMConfig.debugLevel = .verbose

// Custom logging
Logger.shared.debug("Document processed successfully", 
                   metadata: ["documentId": documentId])
```

## Integration Examples

### Basic Document Chat
```swift
class DocumentChatController {
    func setupDocumentChat() async {
        do {
            // Upload document
            let docInfo = try await uploadDocument(fileURL: documentURL)
            
            // Send query
            let response = try await sendMessage("Summarize this document", 
                                               context: [docInfo])
            
            // Display response
            displayResponse(response)
        } catch {
            handleError(error)
        }
    }
}
```

### Healthcare Workflow
```swift
class HealthcareWorkflow {
    func processPatientDocument() async {
        do {
            // Ensure NPHIES compliance
            let compliance = NPHIESCompliance()
            try compliance.validateDocument(documentURL)
            
            // Process with healthcare context
            let result = try await processHealthcareDocument(documentURL)
            
            // Log for audit
            compliance.logActivity(.documentProcessed, 
                                 documentId: result.documentId)
        } catch {
            // Handle compliance violations
            handleComplianceError(error)
        }
    }
}
```

## Support

### Contact Information
- **Email**: support@brainsait.io
- **Documentation**: https://docs.brainsait.io/afham
- **Community**: https://community.brainsait.io

### Getting Help
1. Check the [FAQ section](#faq)
2. Search the [Community Forum](https://community.brainsait.io)
3. Submit a support ticket via email
4. Review the [Developer Guide](DeveloperGuide.md)

### Bug Reports
Include the following information:
- iOS version
- AFHAM version
- Error messages and logs
- Steps to reproduce
- Expected vs actual behavior

### Feature Requests
Submit feature requests through:
- Community forum
- Email with detailed requirements
- GitHub issues (if applicable)

## FAQ

### Common Issues

**Q: Document upload fails with authentication error**
A: Verify your API key is correctly configured and not expired.

**Q: Arabic text appears incorrectly**
A: Ensure RTL layout direction is properly set in your views.

**Q: Voice recognition not working**
A: Check microphone permissions and speech recognition authorization.

**Q: NPHIES compliance errors**
A: Review the [Healthcare Integration](#healthcare-integration) section and ensure proper configuration.

---

*© 2024 BrainSAIT Technologies. All rights reserved.*

For the latest updates and detailed examples, visit: https://docs.brainsait.io/afham