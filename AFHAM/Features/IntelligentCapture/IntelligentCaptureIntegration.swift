//
//  IntelligentCaptureIntegration.swift
//  AFHAM - Intelligent Capture Integration
//
//  Integration layer to connect Intelligent Capture with main app
//

import Foundation
import SwiftUI

// MARK: - Intelligent Capture App State

/// Manages Intelligent Capture state across the app
@MainActor
class IntelligentCaptureAppState: ObservableObject {

    @Published var captureManager: IntelligentCaptureManager?
    @Published var isInitialized = false

    private let secureAPIKeyManager: SecureAPIKeyManager

    init(secureAPIKeyManager: SecureAPIKeyManager = SecureAPIKeyManager.shared) {
        self.secureAPIKeyManager = secureAPIKeyManager
    }

    /// Initialize Intelligent Capture with API keys
    func initialize(
        appState: AppState,
        requestManager: RequestManager = RequestManager.shared,
        complianceLogger: ComplianceAuditLogger? = nil
    ) async {
        // Retrieve API keys from secure storage
        let deepSeekKey = secureAPIKeyManager.getAPIKey(for: "deepseek")
        let openAIKey = secureAPIKeyManager.getAPIKey(for: "openai")
        let geminiKey = secureAPIKeyManager.getAPIKey(for: "gemini")

        let apiKeys = APIKeys(
            deepSeekKey: deepSeekKey,
            openAIKey: openAIKey,
            geminiKey: geminiKey
        )

        captureManager = IntelligentCaptureManager(
            apiKeys: apiKeys,
            requestManager: requestManager,
            complianceLogger: complianceLogger
        )

        isInitialized = true
    }

    /// Get or create capture manager
    func getCaptureManager(
        appState: AppState,
        requestManager: RequestManager = RequestManager.shared
    ) async -> IntelligentCaptureManager {
        if let manager = captureManager {
            return manager
        }

        await initialize(appState: appState, requestManager: requestManager)
        return captureManager!
    }
}

// MARK: - Intelligent Capture Tab View

/// Wrapper view for Intelligent Capture tab
struct IntelligentCaptureTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var captureAppState = IntelligentCaptureAppState()
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)

                    Text("Initializing Intelligent Capture...")
                        .foregroundColor(.white)
                }
            } else if let captureManager = captureAppState.captureManager {
                IntelligentCaptureView(captureManager: captureManager)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)

                    Text("Intelligent Capture Unavailable")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Please configure API keys in Settings")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Button("Retry") {
                        Task {
                            await initializeCapture()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .task {
            await initializeCapture()
        }
    }

    private func initializeCapture() async {
        await captureAppState.initialize(appState: appState)
        isLoading = false
    }
}

// MARK: - API Key Configuration Extension

extension SecureAPIKeyManager {

    /// Set DeepSeek API key
    func setDeepSeekAPIKey(_ apiKey: String) {
        self.setAPIKey(apiKey, for: "deepseek")
    }

    /// Set OpenAI API key
    func setOpenAIAPIKey(_ apiKey: String) {
        self.setAPIKey(apiKey, for: "openai")
    }

    /// Get DeepSeek API key
    func getDeepSeekAPIKey() -> String? {
        return self.getAPIKey(for: "deepseek")
    }

    /// Get OpenAI API key
    func getOpenAIAPIKey() -> String? {
        return self.getAPIKey(for: "openai")
    }
}

// MARK: - Settings Extension for API Keys

struct IntelligentCaptureSettingsView: View {

    @State private var deepSeekKey: String = ""
    @State private var openAIKey: String = ""
    @State private var showSuccessMessage = false

    let secureManager = SecureAPIKeyManager.shared

    var body: some View {
        Form {
            Section(header: Text("Intelligent Capture API Keys")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DeepSeek OCR API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SecureField("Enter DeepSeek API Key", text: $deepSeekKey)
                        .textContentType(.password)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    SecureField("Enter OpenAI API Key", text: $openAIKey)
                        .textContentType(.password)
                }

                Button("Save API Keys") {
                    saveAPIKeys()
                }
                .disabled(deepSeekKey.isEmpty && openAIKey.isEmpty)
            }

            Section(header: Text("Configuration")) {
                Toggle("Enable Apple Vision", isOn: .constant(AFHAMConstants.IntelligentCapture.enableAppleVision))
                    .disabled(true)

                Toggle("Enable DeepSeek OCR", isOn: .constant(AFHAMConstants.IntelligentCapture.enableDeepSeekOCR))
                    .disabled(true)

                Toggle("Enable OpenAI Vision", isOn: .constant(AFHAMConstants.IntelligentCapture.enableOpenAIVision))
                    .disabled(true)

                Toggle("Enable Gemini Vision", isOn: .constant(AFHAMConstants.IntelligentCapture.enableGeminiVision))
                    .disabled(true)
            }

            Section(header: Text("Privacy")) {
                Toggle("Enable PHI Detection", isOn: .constant(AFHAMConstants.IntelligentCapture.enablePHIDetection))
                    .disabled(true)

                Toggle("Require Consent for PHI", isOn: .constant(AFHAMConstants.IntelligentCapture.requireConsentForPHI))
                    .disabled(true)
            }

            if showSuccessMessage {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("API Keys saved successfully")
                    }
                }
            }
        }
        .navigationTitle("Intelligent Capture Settings")
        .onAppear {
            loadAPIKeys()
        }
    }

    private func loadAPIKeys() {
        deepSeekKey = secureManager.getDeepSeekAPIKey() ?? ""
        openAIKey = secureManager.getOpenAIAPIKey() ?? ""
    }

    private func saveAPIKeys() {
        if !deepSeekKey.isEmpty {
            secureManager.setDeepSeekAPIKey(deepSeekKey)
        }

        if !openAIKey.isEmpty {
            secureManager.setOpenAIAPIKey(openAIKey)
        }

        showSuccessMessage = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessMessage = false
        }
    }
}

// MARK: - Documentation View

struct IntelligentCaptureDocView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Intelligent Capture")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Transform physical documents into structured, multilingual insights using multimodal AI.")
                    .font(.body)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Features")
                        .font(.title2)
                        .fontWeight(.semibold)

                    FeatureRow(
                        icon: "camera.fill",
                        title: "Smart Document Capture",
                        description: "Automatically detect and correct document perspective"
                    )

                    FeatureRow(
                        icon: "doc.text.fill",
                        title: "Multimodal OCR",
                        description: "Extract text using Apple Vision, DeepSeek, OpenAI, and Gemini"
                    )

                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "AI Analysis",
                        description: "Get semantic understanding and actionable insights"
                    )

                    FeatureRow(
                        icon: "globe",
                        title: "Bilingual Support",
                        description: "Process documents in Arabic and English"
                    )

                    FeatureRow(
                        icon: "shield.fill",
                        title: "PDPL Compliant",
                        description: "Automatic PHI detection and redaction"
                    )

                    FeatureRow(
                        icon: "square.and.arrow.down",
                        title: "Export Options",
                        description: "Export as FHIR, PDF, CSV, JSON, or WhatsApp summary"
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Supported Document Types")
                        .font(.title2)
                        .fontWeight(.semibold)

                    ForEach(DocumentType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(.blue)
                            Text(type.displayName)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("How to Use")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("1. Select document type from the bottom carousel")
                    Text("2. Point camera at document")
                    Text("3. Tap capture when green box appears")
                    Text("4. Review extracted text and insights")
                    Text("5. Export in your preferred format")
                }
            }
            .padding()
        }
        .navigationTitle("Documentation")
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
