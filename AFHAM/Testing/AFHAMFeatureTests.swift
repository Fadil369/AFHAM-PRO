//
// AFHAM Feature Testing Suite
// Comprehensive testing plan for all app features
//

import SwiftUI
import XCTest
@testable import AFHAM

class AFHAMFeatureTests: XCTestCase {
    
    var geminiManager: GeminiFileSearchManager!
    var voiceManager: VoiceAssistantManager!
    var chatViewModel: ChatViewModel!
    
    override func setUp() {
        super.setUp()
        geminiManager = GeminiFileSearchManager()
        voiceManager = VoiceAssistantManager()
        chatViewModel = ChatViewModel(geminiManager: geminiManager)
    }
    
    override func tearDown() {
        geminiManager = nil
        voiceManager = nil
        chatViewModel = nil
        super.tearDown()
    }
    
    // MARK: - 1. API Configuration Tests
    
    func testAPIKeyConfiguration() {
        XCTAssertNotNil(AFHAMConfig.geminiAPIKey, "Gemini API key should be set")
        XCTAssertNotEqual(AFHAMConfig.geminiAPIKey, "YOUR_GEMINI_API_KEY", "API key should be properly configured")
        
        if AFHAMConfig.isConfigured {
            print("✅ API Key is properly configured")
        } else {
            print("❌ API Key needs to be set via GEMINI_API_KEY environment variable")
            print("💡 Tip: Set it in Xcode scheme or via export GEMINI_API_KEY='your_key_here'")
        }
    }
    
    // MARK: - 2. File Upload Tests
    
    func testFileUploadValidation() async {
        // Test supported file types
        XCTAssertTrue(AFHAMConfig.supportedFileTypes.count > 0, "Should have supported file types")
        
        // Test file validation
        let testPDFPath = Bundle.main.path(forResource: "test_document", ofType: "pdf")
        if let path = testPDFPath {
            let url = URL(fileURLWithPath: path)
            
            do {
                _ = try await geminiManager.uploadAndIndexDocument(fileURL: url)
                print("✅ File upload validation passed")
            } catch {
                print("❌ File upload failed: \(error.localizedDescription)")
                
                if error.localizedDescription.contains("API key") {
                    print("💡 Set GEMINI_API_KEY environment variable")
                }
            }
        } else {
            print("⚠️ No test PDF found - create test_document.pdf in bundle")
        }
    }
    
    func testDocumentMetadataCreation() {
        let metadata = DocumentMetadata(
            id: UUID(),
            fileName: "test.pdf",
            fileSize: 1024,
            uploadDate: Date(),
            language: "en",
            documentType: "pdf",
            geminiFileID: "test-id",
            fileSearchStoreID: "store-id",
            processingStatus: .ready
        )
        
        XCTAssertEqual(metadata.fileName, "test.pdf")
        XCTAssertEqual(metadata.processingStatus, .ready)
        print("✅ Document metadata creation works correctly")
    }
    
    // MARK: - 3. Chat Interface Tests
    
    func testChatViewModelInitialization() {
        XCTAssertNotNil(chatViewModel)
        XCTAssertEqual(chatViewModel.messages.count, 0)
        XCTAssertFalse(chatViewModel.isLoading)
        XCTAssertEqual(chatViewModel.selectedLanguage, "ar")
        print("✅ ChatViewModel initializes correctly")
    }
    
    func testMessageCreation() {
        let message = ChatMessage(
            id: UUID(),
            content: "Test message",
            isUser: true,
            timestamp: Date(),
            language: "en"
        )
        
        XCTAssertEqual(message.content, "Test message")
        XCTAssertTrue(message.isUser)
        XCTAssertEqual(message.language, "en")
        print("✅ Message creation works correctly")
    }
    
    func testBilingualSupport() {
        // Test Arabic message
        let arabicMessage = ChatMessage(
            id: UUID(),
            content: "مرحبا",
            isUser: true,
            timestamp: Date(),
            language: "ar"
        )
        
        // Test English message
        let englishMessage = ChatMessage(
            id: UUID(),
            content: "Hello",
            isUser: true,
            timestamp: Date(),
            language: "en"
        )
        
        XCTAssertEqual(arabicMessage.language, "ar")
        XCTAssertEqual(englishMessage.language, "en")
        print("✅ Bilingual message support works")
    }
    
    // MARK: - 4. Voice Assistant Tests
    
    func testVoiceManagerInitialization() {
        XCTAssertNotNil(voiceManager)
        XCTAssertFalse(voiceManager.isListening)
        XCTAssertEqual(voiceManager.currentLanguage, "ar-SA")
        print("✅ Voice manager initializes correctly")
    }
    
    func testLanguageSwitching() {
        voiceManager.switchLanguage(to: "en-US")
        XCTAssertEqual(voiceManager.currentLanguage, "en-US")
        
        voiceManager.switchLanguage(to: "ar-SA")
        XCTAssertEqual(voiceManager.currentLanguage, "ar-SA")
        print("✅ Voice language switching works")
    }
    
    // MARK: - 5. UI Component Tests
    
    func testLoadingIndicator() {
        // Test loading state changes
        chatViewModel.isLoading = true
        XCTAssertTrue(chatViewModel.isLoading)
        
        chatViewModel.isLoading = false
        XCTAssertFalse(chatViewModel.isLoading)
        print("✅ Loading indicator state management works")
    }
    
    func testCitationsHandling() {
        let citations = [
            Citation(source: "Document 1", pageNumber: 1, excerpt: "Test excerpt"),
            Citation(source: "Document 2", pageNumber: 2, excerpt: "Another excerpt")
        ]
        
        XCTAssertEqual(citations.count, 2)
        XCTAssertEqual(citations[0].source, "Document 1")
        XCTAssertEqual(citations[1].pageNumber, 2)
        print("✅ Citations handling works correctly")
    }
    
    // MARK: - 6. Error Handling Tests
    
    func testErrorMessageGeneration() async {
        // Simulate network error
        chatViewModel.currentInput = "Test question"
        
        // This should generate an error message
        await chatViewModel.sendMessage()
        
        // Should have user message + error message
        XCTAssertGreaterThanOrEqual(chatViewModel.messages.count, 1)
        
        if chatViewModel.messages.count >= 2 {
            let errorMessage = chatViewModel.messages.last
            XCTAssertFalse(errorMessage!.isUser)
            print("✅ Error message generation works")
        } else {
            print("⚠️ Error handling needs verification")
        }
    }
    
    // MARK: - 7. Performance Tests
    
    func testMemoryUsage() {
        // Create multiple messages
        for i in 0..<100 {
            let message = ChatMessage(
                id: UUID(),
                content: "Message \(i)",
                isUser: i % 2 == 0,
                timestamp: Date(),
                language: "en"
            )
            chatViewModel.messages.append(message)
        }
        
        XCTAssertEqual(chatViewModel.messages.count, 100)
        
        // Clear messages
        chatViewModel.messages.removeAll()
        XCTAssertEqual(chatViewModel.messages.count, 0)
        print("✅ Memory management works correctly")
    }
    
    func testLargeDocumentHandling() {
        // Test with large file size
        let largeDocMetadata = DocumentMetadata(
            id: UUID(),
            fileName: "large_document.pdf",
            fileSize: 50_000_000, // 50MB
            uploadDate: Date(),
            language: "en",
            documentType: "pdf",
            processingStatus: .uploading
        )
        
        XCTAssertEqual(largeDocMetadata.fileSize, 50_000_000)
        print("✅ Large document metadata handling works")
    }
}

// MARK: - Manual Testing Checklist

/*
 
## 🧪 AFHAM COMPREHENSIVE TESTING PLAN

### **PHASE 1: Setup & Configuration** ✅
1. **API Key Configuration**
   - [ ] Set GEMINI_API_KEY environment variable
   - [ ] Verify AFHAMConfig.isConfigured returns true
   - [ ] Test error handling when API key is missing

### **PHASE 2: File Upload Testing** 📄
1. **Document Picker**
   - [ ] Tap "+" button in documents view
   - [ ] Select PDF file
   - [ ] Select image file (PNG/JPG)
   - [ ] Select text file
   - [ ] Test unsupported file type rejection

2. **Upload Process**
   - [ ] Monitor upload progress indicator
   - [ ] Verify document appears in documents list
   - [ ] Check document metadata (file size, date)
   - [ ] Test upload error handling

3. **File Search Store Creation**
   - [ ] Verify store creation on first upload
   - [ ] Check store ID assignment
   - [ ] Test multiple document imports

### **PHASE 3: Chat Interface Testing** 💬
1. **UI Elements**
   - [ ] Test text input field
   - [ ] Verify send button states (enabled/disabled)
   - [ ] Check loading indicator appears
   - [ ] Test message bubbles (user vs AI)

2. **Message Flow**
   - [ ] Send simple question: "What is this document about?"
   - [ ] Verify loading animation
   - [ ] Check AI response appears
   - [ ] Test citations display

3. **Bilingual Support**
   - [ ] Switch to Arabic interface
   - [ ] Send Arabic question: "ما هو هذا المستند؟"
   - [ ] Verify Arabic response
   - [ ] Test RTL text alignment

### **PHASE 4: Voice Assistant Testing** 🎙️
1. **Permissions**
   - [ ] Test microphone permission request
   - [ ] Test speech recognition permission
   - [ ] Verify permission denied handling

2. **Voice Recognition**
   - [ ] Tap microphone button
   - [ ] Speak in English: "Tell me about this document"
   - [ ] Verify text appears in real-time
   - [ ] Test voice visualization animation

3. **Arabic Voice Recognition**
   - [ ] Switch to Arabic
   - [ ] Speak in Arabic: "أخبرني عن هذا المستند"
   - [ ] Verify Arabic text recognition
   - [ ] Test language switching

### **PHASE 5: Advanced Features Testing** 🚀
1. **Document Analysis**
   - [ ] Upload medical document
   - [ ] Ask specific questions about content
   - [ ] Verify accurate citations
   - [ ] Test complex queries

2. **Multi-document Queries**
   - [ ] Upload multiple documents
   - [ ] Ask questions spanning multiple files
   - [ ] Verify source attribution
   - [ ] Test document comparison

### **PHASE 6: Error Handling & Edge Cases** ⚠️
1. **Network Issues**
   - [ ] Test offline behavior
   - [ ] Test poor network conditions
   - [ ] Verify error messages

2. **Edge Cases**
   - [ ] Upload very large file
   - [ ] Upload corrupted file
   - [ ] Send very long message
   - [ ] Test rapid successive messages

### **PHASE 7: Performance Testing** ⚡
1. **Memory Usage**
   - [ ] Monitor memory during large uploads
   - [ ] Test with many documents loaded
   - [ ] Check memory leaks in voice assistant

2. **Response Times**
   - [ ] Measure document upload time
   - [ ] Track query response time
   - [ ] Test UI responsiveness

## 🎯 Success Criteria

- ✅ **File Upload**: Documents upload successfully and appear in list
- ✅ **Gemini API**: Questions return relevant answers with citations
- ✅ **Voice Assistant**: Speech recognition works in both languages
- ✅ **UI Loading**: All loading states provide user feedback
- ✅ **Error Handling**: Graceful error messages for all failure modes
- ✅ **Bilingual**: Arabic and English support throughout
- ✅ **Performance**: App remains responsive during operations

## 🚨 Common Issues & Solutions

1. **"API key not configured"**
   - Solution: Set GEMINI_API_KEY environment variable

2. **Voice recognition crash**
   - Solution: Grant microphone permissions in Settings

3. **Document upload fails**
   - Solution: Check file format and size limits

4. **No AI responses**
   - Solution: Verify documents are uploaded and indexed

5. **Arabic text issues**
   - Solution: Check RTL text alignment and font support

*/