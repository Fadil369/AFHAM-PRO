// AFHAM - Advanced Localization Manager
// Comprehensive bilingual support for Arabic/English with PDPL compliance

import Foundation
import SwiftUI

// MARK: - BILINGUAL: Enhanced Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: AppLanguage = .arabic
    @AppStorage("preferred_language") private var storedLanguage: String = "ar"
    
    enum AppLanguage: String, CaseIterable {
        case arabic = "ar"
        case english = "en"
        
        var displayName: String {
            switch self {
            case .arabic: return "العربية"
            case .english: return "English"
            }
        }
        
        var code: String { rawValue }
        var isRTL: Bool { self == .arabic }
        var speechCode: String {
            switch self {
            case .arabic: return "ar-SA"
            case .english: return "en-US"
            }
        }
    }
    
    private init() {
        currentLanguage = AppLanguage(rawValue: storedLanguage) ?? .arabic
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        storedLanguage = language.rawValue
        AppLogger.shared.log("Language changed to: \(language.displayName)", level: .info)
    }
    
    // MARK: - String Localization
    func localized(_ key: LocalizationKey) -> String {
        return key.localized(for: currentLanguage)
    }
    
    func localized(_ key: LocalizationKey, language: AppLanguage) -> String {
        return key.localized(for: language)
    }
}

// MARK: - Localization Keys with Type Safety
enum LocalizationKey {
    // MARK: - App Navigation
    case appTitle
    case documents
    case chat
    case content
    case settings
    
    // MARK: - Document Management
    case noDocuments
    case noDocumentsDescription
    case uploadDocument
    case addDocument
    case selectDocument
    case changeDocument
    case selectDocumentPrompt
    case documentUploaded
    case documentProcessing
    case documentReady
    case documentError
    case uploadingStatus
    case processingStatus
    case readyStatus
    case errorStatus
    
    // MARK: - Chat Interface
    case startConversation
    case startConversationDescription
    case thinking
    case typing
    case sources
    case askQuestion
    case voiceInput
    case stopListening
    case startListening
    
    // MARK: - Content Creation
    case contentType
    case generateContent
    case generatedContent
    case additionalInstructions
    case additionalInstructionsPlaceholder
    case selectContentType
    case contentGenerated
    case copyContent
    case shareContent
    
    // MARK: - Settings
    case language
    case about
    case version
    case company
    case voiceSettings
    case autoSpeak
    case voiceSpeed
    case privacySettings
    case dataCollection
    case analytics
    
    // MARK: - Common Actions
    case loading
    case error
    case success
    case cancel
    case done
    case ok
    case retry
    case save
    case delete
    case edit
    case share
    case copy
    case paste
    case search
    case filter
    case sort
    case refresh
    case close
    case back
    case next
    case previous
    case more
    case less
    case show
    case hide
    
    // MARK: - Content Types
    case blogPost
    case socialMediaPost
    case emailTemplate
    case presentation
    case report
    case summary
    case translation
    case newsletter
    case pressRelease
    case productDescription
    
    // MARK: - Error Messages
    case apiKeyMissing
    case fileUploadFailed
    case documentProcessingFailed
    case queryFailed
    case voiceRecognitionFailed
    case unsupportedFileType
    case fileSizeTooLarge
    case networkError
    case permissionDenied
    case microphoneAccessDenied
    case speechRecognitionUnavailable
    
    // MARK: - Voice Assistant
    case voiceAssistant
    case listening
    case speakYourQuestion
    case tapToSpeak
    case tapToStop
    case voiceRecognized
    case voiceProcessing
    case voiceError
    
    // MARK: - File Management
    case fileSize
    case fileName
    case fileType
    case uploadDate
    case lastModified
    case documentDetails
    case supportedFormats
    case maxFileSize
    
    // MARK: - Accessibility
    case documentCard
    case messageFromUser
    case messageFromAssistant
    case voiceButton
    case uploadButton
    case languageSelector
    case contentTypeSelector

    // MARK: - Custom Keys (for dynamic content)
    case customKey(String)

    func localized(for language: LocalizationManager.AppLanguage) -> String {
        switch language {
        case .arabic:
            return arabicValue
        case .english:
            return englishValue
        }
    }

    var localized: String {
        LocalizationManager.shared.localized(self)
    }
    
    private var englishValue: String {
        switch self {
        // App Navigation
        case .appTitle: return "AFHAM"
        case .documents: return "Documents"
        case .chat: return "Chat"
        case .content: return "Content"
        case .settings: return "Settings"
            
        // Document Management
        case .noDocuments: return "No Documents"
        case .noDocumentsDescription: return "Start by adding a document to analyze"
        case .uploadDocument: return "Upload Document"
        case .addDocument: return "Add"
        case .selectDocument: return "Select Document"
        case .changeDocument: return "Change"
        case .selectDocumentPrompt: return "Select a Document"
        case .documentUploaded: return "Document Uploaded"
        case .documentProcessing: return "Processing"
        case .documentReady: return "Ready"
        case .documentError: return "Error"
        case .uploadingStatus: return "Uploading..."
        case .processingStatus: return "Processing..."
        case .readyStatus: return "Ready"
        case .errorStatus: return "Error"
            
        // Chat Interface
        case .startConversation: return "Start Conversation"
        case .startConversationDescription: return "Ask questions about your documents using text or voice"
        case .thinking: return "Thinking"
        case .typing: return "Typing..."
        case .sources: return "Sources"
        case .askQuestion: return "Ask a question..."
        case .voiceInput: return "Voice Input"
        case .stopListening: return "Stop Listening"
        case .startListening: return "Start Listening"
            
        // Content Creation
        case .contentType: return "Content Type"
        case .generateContent: return "Generate Content"
        case .generatedContent: return "Generated Content"
        case .additionalInstructions: return "Additional Instructions (Optional)"
        case .additionalInstructionsPlaceholder: return "Provide specific requirements or style preferences..."
        case .selectContentType: return "Select Content Type"
        case .contentGenerated: return "Content Generated"
        case .copyContent: return "Copy"
        case .shareContent: return "Share"
            
        // Settings
        case .language: return "Language"
        case .about: return "About"
        case .version: return "Version"
        case .company: return "Company"
        case .voiceSettings: return "Voice Settings"
        case .autoSpeak: return "Auto Speak"
        case .voiceSpeed: return "Voice Speed"
        case .privacySettings: return "Privacy Settings"
        case .dataCollection: return "Data Collection"
        case .analytics: return "Analytics"
            
        // Common Actions
        case .loading: return "Loading..."
        case .error: return "Error"
        case .success: return "Success"
        case .cancel: return "Cancel"
        case .done: return "Done"
        case .ok: return "OK"
        case .retry: return "Retry"
        case .save: return "Save"
        case .delete: return "Delete"
        case .edit: return "Edit"
        case .share: return "Share"
        case .copy: return "Copy"
        case .paste: return "Paste"
        case .search: return "Search"
        case .filter: return "Filter"
        case .sort: return "Sort"
        case .refresh: return "Refresh"
        case .close: return "Close"
        case .back: return "Back"
        case .next: return "Next"
        case .previous: return "Previous"
        case .more: return "More"
        case .less: return "Less"
        case .show: return "Show"
        case .hide: return "Hide"
            
        // Content Types
        case .blogPost: return "Blog Post"
        case .socialMediaPost: return "Social Media Post"
        case .emailTemplate: return "Email Template"
        case .presentation: return "Presentation"
        case .report: return "Report"
        case .summary: return "Summary"
        case .translation: return "Translation"
        case .newsletter: return "Newsletter"
        case .pressRelease: return "Press Release"
        case .productDescription: return "Product Description"
            
        // Error Messages
        case .apiKeyMissing: return "API key is missing. Please configure it in settings."
        case .fileUploadFailed: return "File upload failed"
        case .documentProcessingFailed: return "Document processing failed"
        case .queryFailed: return "Query failed"
        case .voiceRecognitionFailed: return "Voice recognition failed"
        case .unsupportedFileType: return "Unsupported file type"
        case .fileSizeTooLarge: return "File size exceeds maximum allowed"
        case .networkError: return "Network error"
        case .permissionDenied: return "Permission denied"
        case .microphoneAccessDenied: return "Microphone access denied"
        case .speechRecognitionUnavailable: return "Speech recognition unavailable"
            
        // Voice Assistant
        case .voiceAssistant: return "Voice Assistant"
        case .listening: return "Listening..."
        case .speakYourQuestion: return "Speak your question"
        case .tapToSpeak: return "Tap to speak"
        case .tapToStop: return "Tap to stop"
        case .voiceRecognized: return "Voice recognized"
        case .voiceProcessing: return "Processing voice..."
        case .voiceError: return "Voice recognition error"
            
        // File Management
        case .fileSize: return "File Size"
        case .fileName: return "File Name"
        case .fileType: return "File Type"
        case .uploadDate: return "Upload Date"
        case .lastModified: return "Last Modified"
        case .documentDetails: return "Document Details"
        case .supportedFormats: return "Supported Formats"
        case .maxFileSize: return "Maximum File Size"
            
        // Accessibility
        case .documentCard: return "Document"
        case .messageFromUser: return "Message from user"
        case .messageFromAssistant: return "Message from assistant"
        case .voiceButton: return "Voice input button"
        case .uploadButton: return "Upload document button"
        case .languageSelector: return "Language selector"
        case .contentTypeSelector: return "Content type selector"

        // Custom Keys
        case .customKey(let key): return key
        }
    }
    
    private var arabicValue: String {
        switch self {
        // App Navigation
        case .appTitle: return "أفهم"
        case .documents: return "المستندات"
        case .chat: return "المحادثة"
        case .content: return "المحتوى"
        case .settings: return "الإعدادات"
            
        // Document Management
        case .noDocuments: return "لا توجد مستندات"
        case .noDocumentsDescription: return "ابدأ بإضافة مستند للتحليل"
        case .uploadDocument: return "رفع مستند"
        case .addDocument: return "إضافة"
        case .selectDocument: return "اختر مستند"
        case .changeDocument: return "تغيير"
        case .selectDocumentPrompt: return "اختر مستنداً"
        case .documentUploaded: return "تم رفع المستند"
        case .documentProcessing: return "معالجة"
        case .documentReady: return "جاهز"
        case .documentError: return "خطأ"
        case .uploadingStatus: return "جاري الرفع..."
        case .processingStatus: return "جاري المعالجة..."
        case .readyStatus: return "جاهز"
        case .errorStatus: return "خطأ"
            
        // Chat Interface
        case .startConversation: return "ابدأ المحادثة"
        case .startConversationDescription: return "اطرح أسئلة حول مستنداتك باستخدام النص أو الصوت"
        case .thinking: return "جاري التفكير"
        case .typing: return "جاري الكتابة..."
        case .sources: return "المصادر"
        case .askQuestion: return "اطرح سؤالاً..."
        case .voiceInput: return "الإدخال الصوتي"
        case .stopListening: return "توقف عن الاستماع"
        case .startListening: return "ابدأ الاستماع"
            
        // Content Creation
        case .contentType: return "نوع المحتوى"
        case .generateContent: return "إنشاء المحتوى"
        case .generatedContent: return "المحتوى المُنشأ"
        case .additionalInstructions: return "تعليمات إضافية (اختياري)"
        case .additionalInstructionsPlaceholder: return "قدم متطلبات محددة أو تفضيلات الأسلوب..."
        case .selectContentType: return "اختر نوع المحتوى"
        case .contentGenerated: return "تم إنشاء المحتوى"
        case .copyContent: return "نسخ"
        case .shareContent: return "مشاركة"
            
        // Settings
        case .language: return "اللغة"
        case .about: return "معلومات"
        case .version: return "الإصدار"
        case .company: return "الشركة"
        case .voiceSettings: return "إعدادات الصوت"
        case .autoSpeak: return "التحدث التلقائي"
        case .voiceSpeed: return "سرعة الصوت"
        case .privacySettings: return "إعدادات الخصوصية"
        case .dataCollection: return "جمع البيانات"
        case .analytics: return "التحليلات"
            
        // Common Actions
        case .loading: return "جاري التحميل..."
        case .error: return "خطأ"
        case .success: return "نجح"
        case .cancel: return "إلغاء"
        case .done: return "تم"
        case .ok: return "حسناً"
        case .retry: return "إعادة المحاولة"
        case .save: return "حفظ"
        case .delete: return "حذف"
        case .edit: return "تعديل"
        case .share: return "مشاركة"
        case .copy: return "نسخ"
        case .paste: return "لصق"
        case .search: return "بحث"
        case .filter: return "تصفية"
        case .sort: return "ترتيب"
        case .refresh: return "تحديث"
        case .close: return "إغلاق"
        case .back: return "رجوع"
        case .next: return "التالي"
        case .previous: return "السابق"
        case .more: return "المزيد"
        case .less: return "أقل"
        case .show: return "إظهار"
        case .hide: return "إخفاء"
            
        // Content Types
        case .blogPost: return "مقال مدونة"
        case .socialMediaPost: return "منشور وسائل التواصل"
        case .emailTemplate: return "قالب بريد إلكتروني"
        case .presentation: return "عرض تقديمي"
        case .report: return "تقرير"
        case .summary: return "ملخص"
        case .translation: return "ترجمة"
        case .newsletter: return "نشرة إخبارية"
        case .pressRelease: return "بيان صحفي"
        case .productDescription: return "وصف المنتج"
            
        // Error Messages
        case .apiKeyMissing: return "مفتاح API مفقود. يرجى تكوينه في الإعدادات."
        case .fileUploadFailed: return "فشل رفع الملف"
        case .documentProcessingFailed: return "فشلت معالجة المستند"
        case .queryFailed: return "فشل الاستعلام"
        case .voiceRecognitionFailed: return "فشل التعرف على الصوت"
        case .unsupportedFileType: return "نوع ملف غير مدعوم"
        case .fileSizeTooLarge: return "حجم الملف يتجاوز الحد الأقصى المسموح"
        case .networkError: return "خطأ في الشبكة"
        case .permissionDenied: return "تم رفض الإذن"
        case .microphoneAccessDenied: return "تم رفض الوصول للميكروفون"
        case .speechRecognitionUnavailable: return "التعرف على الكلام غير متاح"
            
        // Voice Assistant
        case .voiceAssistant: return "المساعد الصوتي"
        case .listening: return "جاري الاستماع..."
        case .speakYourQuestion: return "تحدث بسؤالك"
        case .tapToSpeak: return "اضغط للتحدث"
        case .tapToStop: return "اضغط للتوقف"
        case .voiceRecognized: return "تم التعرف على الصوت"
        case .voiceProcessing: return "معالجة الصوت..."
        case .voiceError: return "خطأ في التعرف على الصوت"
            
        // File Management
        case .fileSize: return "حجم الملف"
        case .fileName: return "اسم الملف"
        case .fileType: return "نوع الملف"
        case .uploadDate: return "تاريخ الرفع"
        case .lastModified: return "آخر تعديل"
        case .documentDetails: return "تفاصيل المستند"
        case .supportedFormats: return "الصيغ المدعومة"
        case .maxFileSize: return "الحد الأقصى لحجم الملف"
            
        // Accessibility
        case .documentCard: return "مستند"
        case .messageFromUser: return "رسالة من المستخدم"
        case .messageFromAssistant: return "رسالة من المساعد"
        case .voiceButton: return "زر الإدخال الصوتي"
        case .uploadButton: return "زر رفع المستند"
        case .languageSelector: return "محدد اللغة"
        case .contentTypeSelector: return "محدد نوع المحتوى"

        // Custom Keys
        case .customKey(let key): return key
        }
    }
}

// MARK: - SwiftUI View Extension for Easy Localization
extension View {
    func localized(_ key: LocalizationKey) -> Text {
        return Text(LocalizationManager.shared.localized(key))
    }
    
    func localizedString(_ key: LocalizationKey) -> String {
        return LocalizationManager.shared.localized(key)
    }
}

// MARK: - String Extension for Easy Access
extension String {
    static func localized(_ key: LocalizationKey) -> String {
        return LocalizationManager.shared.localized(key)
    }
}
