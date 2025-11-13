//
// AFHAM - BrainSAIT Healthcare AI Platform
// Copyright © 2025 BrainSAIT Ltd. All rights reserved.
//

import XCTest
@testable import AFHAM

/// Comprehensive test suite for AFHAM iOS application
/// Covers core functionality, advanced features, healthcare compliance, and security
class AFHAMTests: XCTestCase {

    // MARK: - Test Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    // MARK: - Core Functionality Tests

    func testDocumentManager_Initialization() throws {
        let manager = DocumentManager()
        XCTAssertNotNil(manager, "DocumentManager should initialize successfully")
        XCTAssertTrue(manager.supportedFormats.contains(.pdf), "Should support PDF format")
        XCTAssertTrue(manager.supportedFormats.contains(.word), "Should support Word format")
    }

    func testDocumentManager_ProcessDocument() async throws {
        let manager = DocumentManager()
        let testData = "Sample test document content".data(using: .utf8)!

        let result = try await manager.processDocument(data: testData, format: .text)

        XCTAssertNotNil(result, "Processing should return a result")
        XCTAssertFalse(result.content.isEmpty, "Processed content should not be empty")
    }

    func testVoiceAssistant_StartListening() throws {
        let assistant = VoiceAssistant()

        XCTAssertFalse(assistant.isListening, "Should not be listening initially")

        assistant.startListening()

        XCTAssertTrue(assistant.isListening, "Should be listening after start")
    }

    func testVoiceAssistant_LanguageSupport() throws {
        let assistant = VoiceAssistant()

        XCTAssertTrue(assistant.supportedLanguages.contains("ar-SA"), "Should support Arabic")
        XCTAssertTrue(assistant.supportedLanguages.contains("en-US"), "Should support English")
    }

    // MARK: - Localization Tests

    func testLocalization_ArabicSupport() throws {
        let manager = LocalizationManager()

        manager.currentLanguage = .arabic

        let welcomeText = manager.localizedString("welcome")
        XCTAssertTrue(welcomeText.contains("مرحبا") || welcomeText.contains("أهلا"),
                     "Should return Arabic translation")
    }

    func testLocalization_EnglishSupport() throws {
        let manager = LocalizationManager()

        manager.currentLanguage = .english

        let welcomeText = manager.localizedString("welcome")
        XCTAssertTrue(welcomeText.contains("Welcome") || welcomeText.contains("Hello"),
                     "Should return English translation")
    }

    func testLocalization_RTL_Support() throws {
        let manager = LocalizationManager()

        manager.currentLanguage = .arabic

        XCTAssertTrue(manager.isRTL, "Arabic should use RTL layout")

        manager.currentLanguage = .english

        XCTAssertFalse(manager.isRTL, "English should use LTR layout")
    }

    // MARK: - Security & Encryption Tests

    func testEncryption_AES256() throws {
        let encryptionManager = EncryptionManager()
        let testData = "Sensitive patient data".data(using: .utf8)!

        let encrypted = try encryptionManager.encrypt(testData)

        XCTAssertNotEqual(encrypted, testData, "Encrypted data should differ from original")

        let decrypted = try encryptionManager.decrypt(encrypted)

        XCTAssertEqual(decrypted, testData, "Decrypted data should match original")
    }

    func testEncryption_KeyStorage() throws {
        let encryptionManager = EncryptionManager()

        let key = try encryptionManager.generateEncryptionKey()

        XCTAssertEqual(key.count, 32, "AES-256 key should be 32 bytes")

        try encryptionManager.storeKeyInKeychain(key, forIdentifier: "test_key")

        let retrievedKey = try encryptionManager.retrieveKeyFromKeychain(forIdentifier: "test_key")

        XCTAssertEqual(key, retrievedKey, "Retrieved key should match stored key")
    }

    // MARK: - PDPL Compliance Tests

    func testPDPL_ConsentManagement() throws {
        let consentManager = ConsentManager()

        XCTAssertFalse(consentManager.hasUserConsent(for: .dataProcessing),
                      "Should not have consent initially")

        consentManager.recordConsent(for: .dataProcessing)

        XCTAssertTrue(consentManager.hasUserConsent(for: .dataProcessing),
                     "Should have consent after recording")
    }

    func testPDPL_DataRetention() throws {
        let retentionManager = DataRetentionManager()

        XCTAssertEqual(retentionManager.standardRetentionPeriod, 90,
                      "Standard retention should be 90 days")
        XCTAssertEqual(retentionManager.auditLogRetentionPeriod, 365,
                      "Audit log retention should be 365 days")
    }

    func testPDPL_DataDeletion() async throws {
        let dataManager = DataManager()
        let testUserID = "test_user_123"

        // Create test data
        try await dataManager.storeUserData(userId: testUserID, data: ["name": "Test User"])

        // Request deletion
        try await dataManager.deleteAllUserData(userId: testUserID)

        // Verify deletion
        let userData = try? await dataManager.retrieveUserData(userId: testUserID)
        XCTAssertNil(userData, "User data should be completely deleted")
    }

    // MARK: - Healthcare Compliance Tests

    func testNPHIES_FHIRResourceCreation() throws {
        let fhirManager = FHIRResourceHandler()

        let patient = try fhirManager.createPatient(
            nationalId: "1234567890",
            name: "محمد أحمد",
            birthDate: Date()
        )

        XCTAssertNotNil(patient.id, "Patient should have an ID")
        XCTAssertEqual(patient.resourceType, "Patient", "Resource type should be Patient")
    }

    func testNPHIES_EligibilityCheck() async throws {
        let nphiesManager = NPHIESManager()

        let eligibility = try await nphiesManager.checkEligibility(
            nationalId: "1234567890",
            payerId: "NPHIES_TEST"
        )

        XCTAssertNotNil(eligibility, "Eligibility check should return result")
    }

    func testHealthcare_OIDNamespace() throws {
        let oidManager = OIDManager()

        XCTAssertEqual(oidManager.brainsaitOID, "1.3.6.1.4.1.61026",
                      "BrainSAIT OID should be correct")
    }

    // MARK: - Advanced Features Tests

    func testOfflineMode_DocumentCaching() async throws {
        let offlineManager = OfflineModeManager()
        let testDocument = Document(id: "test_doc", content: "Test content")

        try await offlineManager.cacheDocument(testDocument)

        let cachedDoc = try await offlineManager.retrieveCachedDocument(id: "test_doc")

        XCTAssertEqual(cachedDoc?.id, testDocument.id, "Cached document should match original")
    }

    func testOfflineMode_SyncManagement() async throws {
        let offlineManager = OfflineModeManager()

        XCTAssertFalse(offlineManager.isSyncing, "Should not be syncing initially")

        await offlineManager.startSync()

        // Wait for sync to complete
        try await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertFalse(offlineManager.isSyncing, "Should complete syncing")
    }

    func testCollaboration_TeamWorkspace() async throws {
        let collabManager = CollaborationManager()

        let workspace = try await collabManager.createWorkspace(
            name: "Test Workspace",
            ownerId: "user_123"
        )

        XCTAssertNotNil(workspace.id, "Workspace should have an ID")
        XCTAssertEqual(workspace.name, "Test Workspace", "Workspace name should match")
    }

    func testCollaboration_DocumentSharing() async throws {
        let collabManager = CollaborationManager()

        try await collabManager.shareDocument(
            documentId: "doc_123",
            withUser: "user_456",
            permission: .readOnly
        )

        let permissions = try await collabManager.getDocumentPermissions(documentId: "doc_123")

        XCTAssertTrue(permissions.contains(where: { $0.userId == "user_456" }),
                     "User should have permissions")
    }

    func testAnalytics_MetricsCollection() async throws {
        let analytics = AnalyticsDashboard()

        await analytics.trackEvent(name: "document_processed", properties: ["type": "pdf"])

        let metrics = try await analytics.getMetrics(for: .daily)

        XCTAssertNotNil(metrics, "Metrics should be available")
    }

    func testAnalytics_PrivacyCompliance() throws {
        let analytics = AnalyticsDashboard()

        XCTAssertTrue(analytics.isAnonymizationEnabled, "Analytics should anonymize data by default")
        XCTAssertFalse(analytics.collectsPII, "Analytics should not collect PII")
    }

    // MARK: - Performance Tests

    func testPerformance_DocumentProcessing() throws {
        let manager = DocumentManager()
        let testData = String(repeating: "Test content ", count: 1000).data(using: .utf8)!

        measure {
            Task {
                _ = try? await manager.processDocument(data: testData, format: .text)
            }
        }
    }

    func testPerformance_Encryption() throws {
        let encryptionManager = EncryptionManager()
        let testData = Data(repeating: 0, count: 1_000_000) // 1MB

        measure {
            _ = try? encryptionManager.encrypt(testData)
        }
    }

    func testPerformance_VoiceRecognition() throws {
        let assistant = VoiceAssistant()

        measure {
            assistant.startListening()
            assistant.stopListening()
        }
    }

    // MARK: - Integration Tests

    func testIntegration_DocumentToChat() async throws {
        let docManager = DocumentManager()
        let chatManager = ChatManager()

        let testData = "Test document for chat integration".data(using: .utf8)!
        let doc = try await docManager.processDocument(data: testData, format: .text)

        let response = try await chatManager.askQuestion(
            "What is this document about?",
            context: doc.content
        )

        XCTAssertFalse(response.isEmpty, "Chat should provide a response")
    }

    func testIntegration_VoiceToChat() async throws {
        let voiceAssistant = VoiceAssistant()
        let chatManager = ChatManager()

        // Simulate voice input
        let transcribedText = "What is AFHAM?"

        let response = try await chatManager.askQuestion(transcribedText, context: nil)

        XCTAssertFalse(response.isEmpty, "Chat should respond to voice query")
    }

    // MARK: - Error Handling Tests

    func testError_InvalidDocument() async throws {
        let manager = DocumentManager()
        let invalidData = Data()

        do {
            _ = try await manager.processDocument(data: invalidData, format: .pdf)
            XCTFail("Should throw error for invalid document")
        } catch {
            XCTAssertTrue(error is DocumentError, "Should throw DocumentError")
        }
    }

    func testError_NetworkFailure() async throws {
        let chatManager = ChatManager()

        // Simulate network failure
        chatManager.simulateNetworkFailure = true

        do {
            _ = try await chatManager.askQuestion("Test question", context: nil)
            XCTFail("Should throw error for network failure")
        } catch {
            XCTAssertTrue(error is NetworkError, "Should throw NetworkError")
        }
    }

    func testError_EncryptionFailure() throws {
        let encryptionManager = EncryptionManager()
        let invalidData = Data()

        XCTAssertThrowsError(try encryptionManager.decrypt(invalidData)) { error in
            XCTAssertTrue(error is EncryptionError, "Should throw EncryptionError")
        }
    }

    // MARK: - Accessibility Tests

    func testAccessibility_VoiceOverLabels() throws {
        let view = MainView()

        XCTAssertNotNil(view.accessibilityLabel, "View should have accessibility label")
        XCTAssertFalse(view.accessibilityLabel!.isEmpty, "Accessibility label should not be empty")
    }

    func testAccessibility_DynamicType() throws {
        // Test that UI scales with dynamic type
        let textView = TextView(text: "Test")

        XCTAssertTrue(textView.adjustsFontForContentSizeCategory,
                     "Text should adjust for dynamic type")
    }

    // MARK: - Localization Tests

    func testLocalization_AllStringsAvailable() throws {
        let manager = LocalizationManager()
        let requiredKeys = ["welcome", "error", "success", "loading", "cancel", "save"]

        for key in requiredKeys {
            let arabic = manager.localizedString(key, language: .arabic)
            let english = manager.localizedString(key, language: .english)

            XCTAssertFalse(arabic.isEmpty, "Arabic translation for '\(key)' should exist")
            XCTAssertFalse(english.isEmpty, "English translation for '\(key)' should exist")
            XCTAssertNotEqual(arabic, english, "Translations should differ")
        }
    }
}

// MARK: - UI Tests

class AFHAMUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testUI_MainScreen_Loads() throws {
        XCTAssertTrue(app.navigationBars["AFHAM"].exists, "Main screen should load")
    }

    func testUI_LanguageSwitch() throws {
        let languageButton = app.buttons["language_selector"]
        XCTAssertTrue(languageButton.exists, "Language selector should exist")

        languageButton.tap()

        let arabicOption = app.buttons["Arabic"]
        XCTAssertTrue(arabicOption.exists, "Arabic option should be available")
    }

    func testUI_DocumentUpload() throws {
        let uploadButton = app.buttons["upload_document"]
        XCTAssertTrue(uploadButton.exists, "Upload button should exist")

        uploadButton.tap()

        // Verify file picker appears
        XCTAssertTrue(app.sheets.firstMatch.exists, "File picker should appear")
    }

    func testUI_ChatInterface() throws {
        let chatTab = app.tabBars.buttons["Chat"]
        chatTab.tap()

        let messageField = app.textFields["message_input"]
        XCTAssertTrue(messageField.exists, "Message input should exist")

        messageField.tap()
        messageField.typeText("Test question")

        let sendButton = app.buttons["send_message"]
        sendButton.tap()

        // Wait for response
        let responseText = app.staticTexts.matching(identifier: "chat_response").firstMatch
        XCTAssertTrue(responseText.waitForExistence(timeout: 5), "Response should appear")
    }
}

// MARK: - Performance Tests

class AFHAMPerformanceTests: XCTestCase {

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testScrollPerformance() throws {
        let app = XCUIApplication()
        app.launch()

        let table = app.tables.firstMatch

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            table.swipeUp(velocity: .fast)
            table.swipeDown(velocity: .fast)
        }
    }
}
