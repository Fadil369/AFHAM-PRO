// AFHAM - Content Creator & Repurposing
// AGENT: AI-powered content transformation
// BILINGUAL: Generate content in both languages

import SwiftUI
import Foundation

// MARK: - Content Type Definitions
enum ContentType: String, CaseIterable {
    case summary = "Summary"
    case article = "Article"
    case socialPost = "Social Media Post"
    case presentation = "Presentation Outline"
    case email = "Email"
    case translation = "Translation"
    case explanation = "Simple Explanation"
    case quiz = "Quiz/Questions"
    
    var arabicName: String {
        switch self {
        case .summary: return "ملخص"
        case .article: return "مقالة"
        case .socialPost: return "منشور وسائل التواصل"
        case .presentation: return "مخطط عرض تقديمي"
        case .email: return "بريد إلكتروني"
        case .translation: return "ترجمة"
        case .explanation: return "شرح مبسط"
        case .quiz: return "اختبار / أسئلة"
        }
    }
    
    var icon: String {
        switch self {
        case .summary: return "doc.text"
        case .article: return "newspaper"
        case .socialPost: return "bubble.left.and.bubble.right"
        case .presentation: return "rectangle.stack"
        case .email: return "envelope"
        case .translation: return "globe"
        case .explanation: return "lightbulb"
        case .quiz: return "questionmark.circle"
        }
    }
    
    func prompt(isArabic: Bool) -> String {
        switch self {
        case .summary:
            return isArabic ? 
                "قم بإنشاء ملخص شامل للمحتوى التالي، مع التركيز على النقاط الرئيسية:" :
                "Create a comprehensive summary of the following content, focusing on key points:"
        case .article:
            return isArabic ?
                "اكتب مقالة مفصلة وجذابة بناءً على المحتوى التالي:" :
                "Write a detailed and engaging article based on the following content:"
        case .socialPost:
            return isArabic ?
                "أنشئ منشوراً جذاباً لوسائل التواصل الاجتماعي (مع هاشتاجات) من المحتوى التالي:" :
                "Create an engaging social media post (with hashtags) from the following content:"
        case .presentation:
            return isArabic ?
                "أنشئ مخطط عرض تقديمي مع شرائح ونقاط رئيسية من المحتوى التالي:" :
                "Create a presentation outline with slides and key points from the following content:"
        case .email:
            return isArabic ?
                "اكتب بريداً إلكترونياً احترافياً بناءً على المحتوى التالي:" :
                "Write a professional email based on the following content:"
        case .translation:
            return isArabic ?
                "ترجم المحتوى التالي إلى الإنجليزية مع الحفاظ على المعنى والسياق:" :
                "Translate the following content to Arabic while maintaining meaning and context:"
        case .explanation:
            return isArabic ?
                "اشرح المحتوى التالي بطريقة بسيطة وسهلة الفهم:" :
                "Explain the following content in a simple and easy-to-understand way:"
        case .quiz:
            return isArabic ?
                "أنشئ 5-10 أسئلة اختبار (مع الإجابات) بناءً على المحتوى التالي:" :
                "Create 5-10 quiz questions (with answers) based on the following content:"
        }
    }
}

// MARK: - Content Creator ViewModel
@MainActor
class ContentCreatorViewModel: ObservableObject {
    @Published var selectedContentType: ContentType = .summary
    @Published var selectedDocument: DocumentMetadata?
    @Published var additionalInstructions = ""
    @Published var generatedContent = ""
    @Published var isGenerating = false
    @Published var showDocumentPicker = false
    
    private let geminiManager: GeminiFileSearchManager
    
    init(geminiManager: GeminiFileSearchManager) {
        self.geminiManager = geminiManager
    }
    
    // AGENT: Generate content based on selected type
    func generateContent(language: String) async {
        guard let document = selectedDocument else { return }
        
        isGenerating = true
        defer { isGenerating = false }
        
        let isArabic = language == "ar"
        
        // Build prompt
        var prompt = selectedContentType.prompt(isArabic: isArabic)
        prompt += "\n\n"
        
        if !additionalInstructions.isEmpty {
            prompt += isArabic ?
                "تعليمات إضافية: \(additionalInstructions)\n\n" :
                "Additional instructions: \(additionalInstructions)\n\n"
        }
        
        prompt += isArabic ?
            "استخدم المعلومات من المستند: \(document.fileName)" :
            "Use information from the document: \(document.fileName)"
        
        do {
            let (content, _) = try await geminiManager.queryDocuments(
                question: prompt,
                language: language
            )
            
            generatedContent = content
        } catch {
            generatedContent = isArabic ?
                "عذراً، حدث خطأ في إنشاء المحتوى. الرجاء المحاولة مرة أخرى." :
                "Sorry, an error occurred while generating content. Please try again."
        }
    }
    
    // Export content
    func exportContent() -> URL? {
        let fileName = "AFHAM_\(selectedContentType.rawValue)_\(Date().timeIntervalSince1970).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try generatedContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }
}

// MARK: - Content Creator View
struct ContentCreatorView: View {
    @EnvironmentObject var geminiManager: GeminiFileSearchManager
    @StateObject private var viewModel: ContentCreatorViewModel
    @Environment(\.locale) var locale
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    
    init() {
        let manager = GeminiFileSearchManager()
        _viewModel = StateObject(wrappedValue: ContentCreatorViewModel(geminiManager: manager))
    }
    
    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // NEURAL: Background
                LinearGradient(
                    colors: [
                        AFHAMConfig.midnightBlue,
                        AFHAMConfig.deepOrange.opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Content Type Selector
                        contentTypeSection
                        
                        // Document Selector
                        documentSelectorSection
                        
                        // Additional Instructions
                        additionalInstructionsSection
                        
                        // Generate Button
                        generateButtonSection
                        
                        // Generated Content
                        if !viewModel.generatedContent.isEmpty {
                            generatedContentSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(isArabic ? "إنشاء المحتوى" : "Content Creator")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShareSheet) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    // MARK: - Content Type Section
    private var contentTypeSection: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            Text(verbatim: String.localized(.contentType))
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(ContentType.allCases, id: \.self) { type in
                    ContentTypeCard(
                        type: type,
                        isSelected: viewModel.selectedContentType == type,
                        isArabic: isArabic
                    ) {
                        viewModel.selectedContentType = type
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Document Selector Section
    private var documentSelectorSection: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            Text(isArabic ? "اختر المستند" : "Select Document")
                .font(.headline)
                .foregroundColor(.white)
            
            if let document = viewModel.selectedDocument {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(AFHAMConfig.signalTeal)
                    
                    Text(document.fileName)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showDocumentPicker = true
                    }) {
                        Text(isArabic ? "تغيير" : "Change")
                            .font(.caption)
                            .foregroundColor(AFHAMConfig.signalTeal)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                )
            } else {
                Button(action: {
                    viewModel.showDocumentPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(isArabic ? "اختر مستنداً" : "Select a Document")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 2
                            )
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            DocumentPickerSheet(
                documents: geminiManager.documents,
                selectedDocument: $viewModel.selectedDocument,
                isArabic: isArabic
            )
        }
    }
    
    // MARK: - Additional Instructions Section
    private var additionalInstructionsSection: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            Text(isArabic ? "تعليمات إضافية (اختياري)" : "Additional Instructions (Optional)")
                .font(.headline)
                .foregroundColor(.white)
            
            TextEditor(text: $viewModel.additionalInstructions)
                .frame(height: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                )
                .foregroundColor(.white)
                .multilineTextAlignment(isArabic ? .trailing : .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
    
    // MARK: - Generate Button Section
    private var generateButtonSection: some View {
        Button(action: {
            Task {
                await viewModel.generateContent(language: isArabic ? "ar" : "en")
            }
        }) {
            HStack(spacing: 12) {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                    Text(isArabic ? "إنشاء المحتوى" : "Generate Content")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
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
        .disabled(viewModel.selectedDocument == nil || viewModel.isGenerating)
        .opacity(viewModel.selectedDocument == nil ? 0.5 : 1.0)
    }
    
    // MARK: - Generated Content Section
    private var generatedContentSection: some View {
        VStack(alignment: isArabic ? .trailing : .leading, spacing: 12) {
            HStack {
                Text(isArabic ? "المحتوى المُنشأ" : "Generated Content")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Share button
                Button(action: {
                    if let url = viewModel.exportContent() {
                        shareURL = url
                        showShareSheet = true
                    }
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AFHAMConfig.signalTeal)
                }
                
                // Copy button
                Button(action: {
                    UIPasteboard.general.string = viewModel.generatedContent
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(AFHAMConfig.signalTeal)
                }
            }
            
            ScrollView {
                Text(viewModel.generatedContent)
                    .foregroundColor(.white)
                    .multilineTextAlignment(isArabic ? .trailing : .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 400)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Content Type Card
struct ContentTypeCard: View {
    let type: ContentType
    let isSelected: Bool
    let isArabic: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : AFHAMConfig.signalTeal)
                
                Text(isArabic ? type.arabicName : type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                            LinearGradient(
                                colors: [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.white.opacity(0.15), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
            )
        }
    }
}

// MARK: - Document Picker Sheet
struct DocumentPickerSheet: View {
    let documents: [DocumentMetadata]
    @Binding var selectedDocument: DocumentMetadata?
    let isArabic: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(documents) { document in
                Button(action: {
                    selectedDocument = document
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(AFHAMConfig.signalTeal)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(document.fileName)
                                .foregroundColor(.primary)
                            
                            Text(document.documentType.uppercased())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedDocument?.id == document.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AFHAMConfig.signalTeal)
                        }
                    }
                }
            }
            .navigationTitle(isArabic ? "اختر مستنداً" : "Select Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isArabic ? "إلغاء" : "Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
