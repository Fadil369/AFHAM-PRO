// AFHAM Tests
// Unit tests for AFHAM functionality with PDPL compliance testing

import XCTest
@testable import AFHAM

final class AFHAMTests: XCTestCase {
    
    // MARK: - Localization Tests
    func testLocalizationManager() {
        let manager = LocalizationManager.shared
        
        // Test default language
        XCTAssertEqual(manager.currentLanguage, .arabic)
        
        // Test language switching
        manager.setLanguage(.english)
        XCTAssertEqual(manager.currentLanguage, .english)
        
        manager.setLanguage(.arabic)
        XCTAssertEqual(manager.currentLanguage, .arabic)
    }
    
    func testLocalizationKeys() {
        let manager = LocalizationManager.shared
        
        // Test Arabic localization
        manager.setLanguage(.arabic)
        XCTAssertEqual(manager.localized(.appTitle), "أفهم")
        XCTAssertEqual(manager.localized(.documents), "المستندات")
        XCTAssertEqual(manager.localized(.chat), "المحادثة")
        
        // Test English localization
        manager.setLanguage(.english)
        XCTAssertEqual(manager.localized(.appTitle), "AFHAM")
        XCTAssertEqual(manager.localized(.documents), "Documents")
        XCTAssertEqual(manager.localized(.chat), "Chat")
    }
    
    // MARK: - Constants Tests
    func testAFHAMConstants() {
        // Test app information
        XCTAssertEqual(AFHAMConstants.App.name, "AFHAM")
        XCTAssertEqual(AFHAMConstants.App.arabicName, "أفهم")
        XCTAssertEqual(AFHAMConstants.App.version, "1.0.0")
        
        // Test file size limits
        XCTAssertEqual(AFHAMConstants.Files.maxFileSize, 100_000_000)
        XCTAssertEqual(AFHAMConstants.Files.maxFileSizeFree, 10_000_000)
        
        // Test supported extensions
        XCTAssertTrue(AFHAMConstants.Files.supportedExtensions.contains("pdf"))
        XCTAssertTrue(AFHAMConstants.Files.supportedExtensions.contains("docx"))
    }
    
    // MARK: - Error Handling Tests
    func testAFHAMError() {
        let apiKeyError = AFHAMError.apiKeyMissing
        XCTAssertNotNil(apiKeyError.errorDescription)
        XCTAssertNotNil(apiKeyError.localizedArabic)
        
        let fileSizeError = AFHAMError.fileSizeTooLarge(150_000_000)
        XCTAssertTrue(fileSizeError.errorDescription?.contains("150.0 MB") ?? false)
    }
    
    // MARK: - File Validation Tests
    func testFileValidator() async {
        // Test file size validation
        XCTAssertThrowsError(try FileValidator.validate(url: URL(fileURLWithPath: "/fake/path"), maxSize: 1000)) { error in
            if case AFHAMError.fileUploadFailed(let reason) = error {
                XCTAssertEqual(reason, "File does not exist")
            } else {
                XCTFail("Expected fileUploadFailed error")
            }
        }
        
        // Test MIME type detection
        let pdfURL = URL(fileURLWithPath: "test.pdf")
        XCTAssertEqual(FileValidator.getMimeType(for: pdfURL), "application/pdf")
        
        let docxURL = URL(fileURLWithPath: "test.docx")
        XCTAssertEqual(FileValidator.getMimeType(for: docxURL), "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
    }
    
    // MARK: - Color Tests
    func testColors() {
        // Test hex color initialization
        let color = AFHAMColors.medicalBlue
        XCTAssertNotNil(color)
        
        // Test color constants
        XCTAssertNotEqual(AFHAMColors.midnightBlue, AFHAMColors.medicalBlue)
    }
    
    // MARK: - Content Type Tests
    func testContentTypes() {
        let blogPost = AFHAMConstants.ContentType.blogPost
        XCTAssertEqual(blogPost.rawValue, "Blog Post")
        XCTAssertEqual(blogPost.arabicName, "مقال مدونة")
        XCTAssertEqual(blogPost.icon, "doc.text")
        
        // Test all content types have Arabic translations
        for contentType in AFHAMConstants.ContentType.allCases {
            XCTAssertFalse(contentType.arabicName.isEmpty)
            XCTAssertFalse(contentType.icon.isEmpty)
        }
    }
    
    // MARK: - Device Info Tests
    func testDeviceInfo() {
        XCTAssertFalse(DeviceInfo.modelName.isEmpty)
        XCTAssertFalse(DeviceInfo.systemVersion.isEmpty)
        XCTAssertNotEqual(DeviceInfo.screenSize, .zero)
    }
    
    // MARK: - Performance Tests
    func testLocalizationPerformance() {
        let manager = LocalizationManager.shared
        
        measure {
            for _ in 0..<1000 {
                _ = manager.localized(.appTitle)
                _ = manager.localized(.documents)
                _ = manager.localized(.chat)
            }
        }
    }
    
    // MARK: - PDPL Compliance Tests
    func testDataRetentionCompliance() {
        // Test that data retention periods are set
        XCTAssertGreaterThan(AFHAMConstants.Security.dataRetentionPeriod, 0)
        XCTAssertGreaterThan(AFHAMConstants.Security.logRetentionPeriod, 0)
        XCTAssertGreaterThan(AFHAMConstants.Security.auditLogRetentionPeriod, 0)
        
        // Test that audit logs are retained longer than regular logs
        XCTAssertGreaterThan(AFHAMConstants.Security.auditLogRetentionPeriod, AFHAMConstants.Security.logRetentionPeriod)
    }
    
    func testEncryptionRequirements() {
        // Test encryption settings
        XCTAssertEqual(AFHAMConstants.Security.encryptionAlgorithm, "AES-256-GCM")
        XCTAssertEqual(AFHAMConstants.Security.keySize, 256)
        XCTAssertTrue(AFHAMConstants.Security.encryptLocalStorage)
        XCTAssertTrue(AFHAMConstants.Security.anonymizeAnalytics)
    }
    
    func testPrivacyRequirements() {
        // Test privacy settings
        XCTAssertTrue(AFHAMConstants.Security.requiresExplicitConsent)
        
        // Test that analytics can be disabled
        var features = AFHAMConstants.Features.self
        XCTAssertNotNil(features.analyticsEnabled)
    }
    
    // MARK: - Voice Assistant Tests
    func testVoiceConfiguration() {
        // Test voice settings
        XCTAssertGreaterThan(AFHAMConstants.Voice.defaultRate, 0)
        XCTAssertLessThanOrEqual(AFHAMConstants.Voice.defaultRate, 1.0)
        XCTAssertGreaterThan(AFHAMConstants.Voice.recognitionTimeout, 0)
        
        // Test supported languages
        XCTAssertTrue(AFHAMConstants.Voice.supportedVoiceLanguages.keys.contains("ar-SA"))
        XCTAssertTrue(AFHAMConstants.Voice.supportedVoiceLanguages.keys.contains("en-US"))
    }
    
    // MARK: - Network Configuration Tests
    func testNetworkConfiguration() {
        // Test network timeouts
        XCTAssertGreaterThan(AFHAMConstants.Network.timeoutInterval, 0)
        XCTAssertGreaterThan(AFHAMConstants.API.timeout, 0)
        
        // Test rate limiting
        XCTAssertGreaterThan(AFHAMConstants.API.maxRequestsPerMinute, 0)
        XCTAssertGreaterThan(AFHAMConstants.API.rateLimitWindowSeconds, 0)
    }
}