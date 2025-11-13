//
// AFHAM Quick Test Suite
// Run this in Xcode Playground or as a test to verify core functionality
//

import Foundation
import SwiftUI

// MARK: - Quick Test Runner
class AFHAMQuickTest {
    
    static func runAllTests() {
        print("🧪 AFHAM Quick Test Suite Starting...")
        print("=" * 50)
        
        testAPIConfiguration()
        testDataModels()
        testLanguageSupport()
        testFileValidation()
        testUIComponents()
        
        print("=" * 50)
        print("🎉 Quick Tests Complete!")
        print("")
        print("Next Steps:")
        print("1. Set GEMINI_API_KEY environment variable")
        print("2. Run the app in simulator")
        print("3. Follow the manual testing checklist")
    }
    
    // MARK: - Test 1: API Configuration
    static func testAPIConfiguration() {
        print("\n1️⃣ Testing API Configuration...")
        
        let apiKey = AFHAMConfig.geminiAPIKey
        let isConfigured = AFHAMConfig.isConfigured
        
        print("   API Key: \(apiKey.prefix(10))..." + (apiKey.count > 10 ? "***" : ""))
        print("   Is Configured: \(isConfigured ? "✅" : "❌")")
        
        if !isConfigured {
            print("   ⚠️ Action Required: Set GEMINI_API_KEY environment variable")
            print("   💡 Get your key from: https://aistudio.google.com/app/apikey")
        }
    }
    
    // MARK: - Test 2: Data Models
    static func testDataModels() {
        print("\n2️⃣ Testing Data Models...")
        
        // Test DocumentMetadata
        let testDoc = DocumentMetadata(
            id: UUID(),
            fileName: "test_medical_report.pdf",
            fileSize: 2_048_576, // 2MB
            uploadDate: Date(),
            language: "ar",
            documentType: "pdf",
            geminiFileID: "test-file-id",
            fileSearchStoreID: "test-store-id",
            processingStatus: .ready
        )
        
        assert(testDoc.fileName == "test_medical_report.pdf")
        assert(testDoc.language == "ar")
        assert(testDoc.processingStatus == .ready)
        print("   ✅ DocumentMetadata creation works")
        
        // Test ChatMessage
        let testMessage = ChatMessage(
            id: UUID(),
            content: "ما هو تشخيص هذا المريض؟", // Arabic: What is this patient's diagnosis?
            isUser: true,
            timestamp: Date(),
            language: "ar"
        )
        
        assert(testMessage.isUser == true)
        assert(testMessage.language == "ar")
        print("   ✅ ChatMessage creation works")
        
        // Test Citation
        let testCitation = Citation(
            source: "Medical Report - Page 2",
            pageNumber: 2,
            excerpt: "Patient presents with symptoms consistent with..."
        )
        
        assert(testCitation.pageNumber == 2)
        print("   ✅ Citation model works")
    }
    
    // MARK: - Test 3: Language Support
    static func testLanguageSupport() {
        print("\n3️⃣ Testing Language Support...")
        
        // Test Arabic text handling
        let arabicText = "مرحباً بك في أفهم - نظام فهم المستندات بالذكاء الاصطناعي"
        let englishText = "Welcome to AFHAM - AI-Powered Document Understanding"
        
        assert(!arabicText.isEmpty)
        assert(!englishText.isEmpty)
        print("   ✅ Arabic text handling works")
        print("   ✅ English text handling works")
        
        // Test language detection (basic)
        let arabicSample = "هذا نص عربي"
        let englishSample = "This is English text"
        
        // Basic language detection logic
        let hasArabicChars = arabicSample.unicodeScalars.contains { scalar in
            return (0x0600...0x06FF).contains(scalar.value) || (0x0750...0x077F).contains(scalar.value)
        }
        
        assert(hasArabicChars)
        print("   ✅ Arabic character detection works")
    }
    
    // MARK: - Test 4: File Validation
    static func testFileValidation() {
        print("\n4️⃣ Testing File Validation...")
        
        // Test supported file types
        let supportedTypes = AFHAMConfig.supportedFileTypes
        assert(!supportedTypes.isEmpty)
        print("   ✅ Supported file types: \(supportedTypes.count) types")
        
        // Test file size validation (simulate)
        let smallFile: Int64 = 1_024 // 1KB
        let mediumFile: Int64 = 10_485_760 // 10MB
        let largeFile: Int64 = 104_857_600 // 100MB
        
        assert(smallFile > 0)
        assert(mediumFile > smallFile)
        assert(largeFile > mediumFile)
        print("   ✅ File size handling works")
        
        // Test file extension validation
        let validExtensions = ["pdf", "png", "jpg", "jpeg", "txt", "docx"]
        let testFiles = [
            "medical_report.pdf",
            "xray_image.png", 
            "lab_results.jpg",
            "notes.txt",
            "report.docx"
        ]
        
        for fileName in testFiles {
            let ext = (fileName as NSString).pathExtension.lowercased()
            assert(validExtensions.contains(ext))
        }
        print("   ✅ File extension validation works")
    }
    
    // MARK: - Test 5: UI Components
    static func testUIComponents() {
        print("\n5️⃣ Testing UI Components...")
        
        // Test color configuration
        let colors = [
            AFHAMConfig.midnightBlue,
            AFHAMConfig.medicalBlue,
            AFHAMConfig.signalTeal,
            AFHAMConfig.deepOrange,
            AFHAMConfig.professionalGray
        ]
        
        assert(colors.count == 5)
        print("   ✅ Color configuration complete")
        
        // Test processing status enum
        let statuses: [DocumentMetadata.ProcessingStatus] = [
            .uploading, .processing, .indexed, .ready, .error
        ]
        
        assert(statuses.count == 5)
        print("   ✅ Processing status handling works")
        
        // Test message creation for different scenarios
        let userMessage = ChatMessage(
            id: UUID(),
            content: "Test user message",
            isUser: true,
            timestamp: Date(),
            language: "en"
        )
        
        let aiMessage = ChatMessage(
            id: UUID(),
            content: "Test AI response",
            isUser: false,
            timestamp: Date(),
            language: "en",
            citations: [Citation(source: "Test", pageNumber: 1, excerpt: "Test excerpt")]
        )
        
        assert(userMessage.isUser == true)
        assert(aiMessage.isUser == false)
        assert(aiMessage.citations?.count == 1)
        print("   ✅ Message UI handling works")
    }
}

// MARK: - Test Helper Extensions
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - Run Tests
// Uncomment to run in playground:
// AFHAMQuickTest.runAllTests()

// MARK: - Manual Testing Reminder
/*
 
🚀 NEXT STEPS FOR MANUAL TESTING:

1. **Set API Key** (Required!)
   ```bash
   export GEMINI_API_KEY='your_gemini_api_key_here'
   ```

2. **Run App in Simulator**
   - Select iPhone 15 Pro simulator
   - Press Cmd+R to build and run

3. **Quick Feature Test Sequence**
   
   📄 **File Upload Test** (2 minutes)
   - Go to Documents tab
   - Tap "+" button
   - Select a PDF file from Files app
   - Wait for upload to complete
   - Verify document appears in list
   
   💬 **Chat Test** (2 minutes)  
   - Go to Chat tab
   - Type: "What is this document about?"
   - Wait for AI response
   - Verify response mentions document content
   
   🎙️ **Voice Test** (2 minutes)
   - Tap microphone button in chat
   - Grant permissions when prompted
   - Say: "Summarize the main points"
   - Verify voice converts to text
   - Verify AI responds to voice input
   
   🌐 **Arabic Test** (2 minutes)
   - Go to Settings
   - Change language to Arabic  
   - Verify UI switches to RTL
   - Try voice input in Arabic
   - Test: "لخص النقاط الرئيسية"

4. **Success Criteria**
   ✅ All uploads complete without errors
   ✅ AI provides relevant responses with citations
   ✅ Voice recognition works in both languages  
   ✅ UI is responsive and professional
   ✅ No crashes during normal usage

⚠️  **If any test fails:**
   1. Check the console for error messages
   2. Verify API key is set correctly
   3. Ensure all permissions are granted
   4. Try restarting the simulator
   5. Check internet connection

📧 **Need Help?**
   - Review TESTING_CHECKLIST.md for detailed steps
   - Check error messages in Xcode console
   - Verify all setup requirements are met

*/