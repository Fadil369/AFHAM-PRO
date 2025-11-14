// AFHAM - Main UI Implementation
// NEURAL: Glass morphism UI with BrainSAIT colors - MODERNIZED
// BILINGUAL: RTL/LTR adaptive layouts
// UI 2.0: Intent-driven home, document capsules, enhanced glass morphism

import SwiftUI
import UniformTypeIdentifiers

// MARK: - NEURAL: Main App View
struct AFHAMApp: View {
    @StateObject private var geminiManager = GeminiFileSearchManager()
    @StateObject private var voiceManager = VoiceAssistantManager()
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
                // NEW: Intent-driven home with mission cards
                HomeView(selectedTab: $selectedTab, currentLanguage: $currentLanguage)
                    .environmentObject(geminiManager)
                    .environment(\.locale, Locale(identifier: currentLanguage.locale))
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "الرئيسية" : "Home",
                            systemImage: "house.fill"
                        )
                    }
                    .tag(0)

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

                SettingsView(currentLanguage: $currentLanguage)
                    .environmentObject(geminiManager)
                    .environmentObject(voiceManager)
                    .tabItem {
                        Label(
                            currentLanguage == .arabic ? "الإعدادات" : "Settings",
                            systemImage: "gear"
                        )
                    }
                    .tag(5)
            }
            .environment(\.layoutDirection, currentLanguage == .arabic ? .rightToLeft : .leftToRight)
        }
    }
}

// MARK: - Intent-Driven Home View
struct HomeView: View {
    @Binding var selectedTab: Int
    @Binding var currentLanguage: AFHAMApp.AppLanguage
    @EnvironmentObject var geminiManager: GeminiFileSearchManager
    @Environment(\.locale) var locale

    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }

    // Mock suggestions - in production, this would come from user activity tracking
    private var suggestions: [MissionSuggestion] {
        var sugs: [MissionSuggestion] = []

        // Add smart suggestions based on recent activity
        if !geminiManager.documents.isEmpty {
            sugs.append(MissionSuggestion(
                type: .ask,
                title: isArabic ? "اسأل عن المستندات الحديثة" : "Ask about recent documents",
                subtitle: isArabic ? "\(geminiManager.documents.count) مستندات جاهزة" : "\(geminiManager.documents.count) documents ready",
                progress: nil,
                badge: isArabic ? "جديد" : "New"
            ))
        }

        return sugs
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.opacity(0.2)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Welcome Header
                        VStack(alignment: isArabic ? .trailing : .leading, spacing: 8) {
                            Text(isArabic ? "مرحباً بك في" : "Welcome to")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AFHAMConfig.professionalGray)

                            Text("AFHAM")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)

                            Text(isArabic ? "نظام متقدم لفهم المستندات" : "Advanced Document Understanding")
                                .font(.system(size: 16))
                                .foregroundColor(AFHAMConfig.professionalGray)
                        }
                        .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Mission Cards
                        MissionGridView(
                            selectedTab: $selectedTab,
                            isArabic: isArabic,
                            suggestions: suggestions
                        )

                        // Recent Activity (if any)
                        if !geminiManager.documents.isEmpty {
                            recentActivitySection
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle(isArabic ? "الرئيسية" : "Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        currentLanguage = currentLanguage == .arabic ? .english : .arabic
                    }) {
                        Image(systemName: "globe")
                            .foregroundColor(AFHAMConfig.signalTeal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(AFHAMConfig.signalTeal)

                Text(isArabic ? "النشاط الأخير" : "Recent Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 20)

            ForEach(geminiManager.documents.prefix(3)) { document in
                HStack(spacing: 12) {
                    Circle()
                        .fill(AFHAMConfig.signalTeal.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "doc.fill")
                                .foregroundColor(AFHAMConfig.signalTeal)
                        )

                    VStack(alignment: isArabic ? .trailing : .leading, spacing: 4) {
                        Text(document.fileName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(isArabic ? "تم الرفع" : "Uploaded")
                            .font(.system(size: 13))
                            .foregroundColor(AFHAMConfig.professionalGray)
                    }

                    Spacer()
                }
                .padding(16)
                .glassMorphism(elevation: .base, cornerRadius: 16, accent: nil)
                .padding(.horizontal, 20)
            }
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
                    
                    // Documents list - MODERNIZED with capsules
                    if geminiManager.documents.isEmpty {
                        emptyStateView
                    } else {
                        // NEW: Horizontal scrollable capsules grouped by status
                        DocumentCapsulesContainerView(
                            documents: geminiManager.documents,
                            isArabic: isArabic,
                            onDocumentTap: { document in
                                // Handle document tap (could navigate to detail view)
                                print("Tapped document: \(document.fileName)")
                            }
                        )
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
