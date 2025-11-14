// AFHAM - Main UI Implementation
// NEURAL: Glass morphism UI with BrainSAIT colors
// BILINGUAL: RTL/LTR adaptive layouts

import SwiftUI
import UniformTypeIdentifiers

// MARK: - NEURAL: Main App View
struct AFHAMApp: View {
    @StateObject private var geminiManager = GeminiFileSearchManager()
    @StateObject private var voiceManager = VoiceAssistantManager()
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var currentLanguage: AppLanguage = .arabic
    
    enum AppLanguage: String {
        case arabic = "ar"
        case english = "en"
        
        var locale: String {
            switch self {
            case .arabic: return "ar-SA"
            case .english: return "en-US"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // NEURAL: Gradient background
            LinearGradient(
                colors: [
                    AFHAMConfig.midnightBlue,
                    AFHAMConfig.medicalBlue,
                    AFHAMConfig.signalTeal.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // BILINGUAL: RTL/LTR adaptive tab view
            TabView(selection: $selectedTab) {
                DocumentsView()
                    .environmentObject(geminiManager)
                    .environmentObject(voiceManager)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "المستندات" : "Documents",
                            systemImage: "doc.fill"
                        )
                    }
                    .tag(0)
                
                IntelligentCaptureTabView()
                    .environmentObject(appState)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "التقاط ذكي" : "Capture",
                            systemImage: "camera.fill"
                        )
                    }
                    .tag(1)
                
                ChatView()
                    .environmentObject(geminiManager)
                    .environmentObject(voiceManager)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "محادثة" : "Chat",
                            systemImage: "message.fill"
                        )
                    }
                    .tag(2)
                
                VoiceAssistantView()
                    .environmentObject(voiceManager)
                    .environmentObject(geminiManager)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "صوتي" : "Voice",
                            systemImage: "waveform"
                        )
                    }
                    .tag(3)
                
                ContentCreatorView()
                    .environmentObject(geminiManager)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "إنشاء" : "Create",
                            systemImage: "square.and.pencil"
                        )
                    }
                    .tag(4)
                
                ModularCanvasView(fileSearchManager: geminiManager)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "ورشة العمل" : "Workspace",
                            systemImage: "rectangle.3.group.fill"
                        )
                    }
                    .tag(5)
                
                SettingsView(currentLanguage: $currentLanguage)
                    .environmentObject(geminiManager)
                    .environmentObject(voiceManager)
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "الإعدادات" : "Settings",
                            systemImage: "gear"
                        )
                    }
                    .tag(6)
            }
            .environment(\.layoutDirection, currentLanguage == .arabic ? .rightToLeft : .leftToRight)
        }
    }
}

// MARK: - Documents View
struct DocumentsView: View {
    @EnvironmentObject var geminiManager: GeminiFileSearchManager
    @State private var showingFilePicker = false
    @State private var isUploading = false
    @Environment(\.locale) var locale
    
    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // NEURAL: Glass morphism background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with upload button
                    headerView
                    
                    // Documents list
                    if geminiManager.documents.isEmpty {
                        emptyStateView
                    } else {
                        documentsListView
                    }
                }
            }
            .navigationTitle(isArabic ? "مستنداتي" : "My Documents")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilePicker) {
                DocumentPicker { url in
                    Task {
                        isUploading = true
                        do {
                            _ = try await geminiManager.uploadAndIndexDocument(fileURL: url)
                        } catch {
                            print("Upload error: \(error)")
                        }
                        isUploading = false
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                Text(verbatim: String.localized(.appTitle))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text(isArabic ? "نظام متقدم لفهم المستندات" : "Advanced Document Understanding")
                    .font(.system(size: 14))
                    .foregroundColor(AFHAMConfig.professionalGray)
            }

            Spacer()

            Button(action: { showingFilePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(String.localized(.addDocument))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .disabled(isUploading)
        }
        .padding()
        .background(
            Color.white.opacity(0.1)
                .background(.ultraThinMaterial)
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(AFHAMConfig.signalTeal.opacity(0.6))

            Text(String.localized(.noDocuments))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(String.localized(.noDocumentsDescription))
                .font(.body)
                .foregroundColor(AFHAMConfig.professionalGray)
                .multilineTextAlignment(.center)

            Button(action: { showingFilePicker = true }) {
                HStack {
                    Image(systemName: "arrow.up.doc.fill")
                    Text(String.localized(.uploadDocument))
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: 250)
                .padding()
                .background(
                    LinearGradient(
                        colors: [AFHAMConfig.deepOrange, AFHAMConfig.signalTeal],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var documentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(geminiManager.documents) { document in
                    DocumentCard(document: document, isArabic: isArabic)
                }
            }
            .padding()
        }
    }
}

// MARK: - Document Card Component
struct DocumentCard: View {
    let document: DocumentMetadata
    let isArabic: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // File icon
            ZStack {
                Circle()
                    .fill(AFHAMConfig.signalTeal.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: fileIcon)
                    .font(.system(size: 24))
                    .foregroundColor(AFHAMConfig.signalTeal)
            }
            
            VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                Text(document.fileName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(AFHAMConfig.professionalGray)
                    
                    Text("•")
                        .foregroundColor(AFHAMConfig.professionalGray)
                    
                    Text(formatFileSize(document.fileSize))
                        .font(.caption)
                        .foregroundColor(AFHAMConfig.professionalGray)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AFHAMConfig.professionalGray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    private var fileIcon: String {
        switch document.documentType.lowercased() {
        case "pdf": return "doc.richtext.fill"
        case "txt": return "doc.text.fill"
        case "docx", "doc": return "doc.fill"
        default: return "doc.fill"
        }
    }
    
    private var statusIcon: String {
        switch document.processingStatus {
        case .ready: return "checkmark.circle.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.circle.fill"
        default: return "clock.fill"
        }
    }
    
    private var statusColor: Color {
        switch document.processingStatus {
        case .ready: return .green
        case .processing: return AFHAMConfig.signalTeal
        case .error: return AFHAMConfig.deepOrange
        default: return AFHAMConfig.professionalGray
        }
    }
    
    private var statusText: String {
        switch document.processingStatus {
        case .ready: return isArabic ? "جاهز" : "Ready"
        case .processing: return isArabic ? "جاري المعالجة" : "Processing"
        case .error: return isArabic ? "خطأ" : "Error"
        default: return isArabic ? "في الانتظار" : "Pending"
        }
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: AFHAMConfig.supportedFileTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        
        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            onPick(url)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var currentLanguage: AFHAMApp.AppLanguage
    @EnvironmentObject var voiceManager: VoiceAssistantManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(currentLanguage == .arabic ? "اللغة" : "Language")) {
                    Picker(currentLanguage == .arabic ? "لغة التطبيق" : "App Language", selection: $currentLanguage) {
                        Text("العربية").tag(AFHAMApp.AppLanguage.arabic)
                        Text("English").tag(AFHAMApp.AppLanguage.english)
                    }
                    .onChange(of: currentLanguage) { _, newLanguage in
                        voiceManager.switchLanguage(to: newLanguage.locale)
                    }
                }
                
                Section(header: Text(currentLanguage == .arabic ? "معلومات" : "About")) {
                    HStack {
                        Text(currentLanguage == .arabic ? "الإصدار" : "Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text(currentLanguage == .arabic ? "الشركة" : "Company")
                        Spacer()
                        Text("BrainSAIT")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(currentLanguage == .arabic ? "الإعدادات" : "Settings")
        }
    }
}
