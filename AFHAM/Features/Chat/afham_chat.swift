// AFHAM - Chat and Voice Assistant Views
// AGENT: AI-powered conversation with real-time voice
// BILINGUAL: Full Arabic/English support

import SwiftUI
import AVFoundation
import Speech

// MARK: - Chat View Manager
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput = ""
    @Published var isLoading = false
    @Published var selectedLanguage: String = "ar"
    
    private let geminiManager: GeminiFileSearchManager
    
    init(geminiManager: GeminiFileSearchManager) {
        self.geminiManager = geminiManager
    }
    
    // AGENT: Send message and get response
    func sendMessage() async {
        guard !currentInput.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            content: currentInput,
            isUser: true,
            timestamp: Date(),
            language: selectedLanguage
        )
        
        messages.append(userMessage)
        let question = currentInput
        currentInput = ""
        isLoading = true
        
        do {
            let (answer, citations) = try await geminiManager.queryDocuments(
                question: question,
                language: selectedLanguage
            )
            
            let aiMessage = ChatMessage(
                id: UUID(),
                content: answer,
                isUser: false,
                timestamp: Date(),
                language: selectedLanguage,
                citations: citations
            )
            
            messages.append(aiMessage)
        } catch {
            let errorMessage = ChatMessage(
                id: UUID(),
                content: selectedLanguage == "ar" ? 
                    "عذراً، حدث خطأ في معالجة طلبك" : 
                    "Sorry, there was an error processing your request",
                isUser: false,
                timestamp: Date(),
                language: selectedLanguage
            )
            messages.append(errorMessage)
        }
        
        isLoading = false
    }
}

// MARK: - Chat View
struct ChatView: View {
    @EnvironmentObject var geminiManager: GeminiFileSearchManager
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.locale) var locale
    
    init() {
        let manager = GeminiFileSearchManager()
        _viewModel = StateObject(wrappedValue: ChatViewModel(geminiManager: manager))
    }
    
    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // NEURAL: Background gradient
                LinearGradient(
                    colors: [
                        AFHAMConfig.midnightBlue,
                        AFHAMConfig.medicalBlue.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if viewModel.messages.isEmpty {
                                    emptyChatView
                                } else {
                                    ForEach(viewModel.messages) { message in
                                        MessageBubble(message: message, isArabic: isArabic)
                                            .id(message.id)
                                    }
                                }
                                
                                if viewModel.isLoading {
                                    LoadingIndicator(isArabic: isArabic)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input area
                    inputAreaView
                }
            }
            .navigationTitle(isArabic ? "محادثة مع المستندات" : "Chat with Documents")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            viewModel.selectedLanguage = isArabic ? "ar" : "en"
        }
    }
    
    private var emptyChatView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(AFHAMConfig.signalTeal.opacity(0.6))
            
            Text(.localized(.startConversation))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(isArabic ? 
                "اسأل أي سؤال عن مستنداتك" : 
                "Ask any question about your documents"
            )
            .font(.body)
            .foregroundColor(AFHAMConfig.professionalGray)
            .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding()
    }
    
    private var inputAreaView: some View {
        HStack(spacing: 12) {
            // Text input
            TextField(
                isArabic ? "اكتب رسالتك..." : "Type your message...",
                text: $viewModel.currentInput,
                axis: .vertical
            )
            .textFieldStyle(.plain)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.15))
                    .background(.ultraThinMaterial)
            )
            .foregroundColor(.white)
            .multilineTextAlignment(isArabic ? .trailing : .leading)
            
            // Send button
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(
                        viewModel.currentInput.isEmpty ? 
                            AFHAMConfig.professionalGray : 
                            AFHAMConfig.signalTeal
                    )
            }
            .disabled(viewModel.currentInput.isEmpty || viewModel.isLoading)
        }
        .padding()
        .background(
            Color.black.opacity(0.3)
                .background(.ultraThinMaterial)
        )
    }
}

// MARK: - Message Bubble Component
struct MessageBubble: View {
    let message: ChatMessage
    let isArabic: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.isUser ? .white : .primary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                message.isUser ? 
                                    LinearGradient(
                                        colors: [AFHAMConfig.signalTeal, AFHAMConfig.medicalBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ).opacity(0.8) :
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    )
                    .multilineTextAlignment(message.isUser ? 
                        (isArabic ? .trailing : .leading) : 
                        (isArabic ? .trailing : .leading)
                    )
                
                // Citations (if any)
                if let citations = message.citations, !citations.isEmpty {
                    CitationsView(citations: citations, isArabic: isArabic)
                }
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(AFHAMConfig.professionalGray)
            }
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: isArabic ? "ar" : "en")
        return formatter.string(from: date)
    }
}

// MARK: - Citations View
struct CitationsView: View {
    let citations: [Citation]
    let isArabic: Bool
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.caption)
                    
                    Text(isArabic ? "المصادر (\(citations.count))" : "Sources (\(citations.count))")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(AFHAMConfig.signalTeal)
            }
            
            if isExpanded {
                ForEach(citations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption2)
                            .foregroundColor(AFHAMConfig.professionalGray)
                        
                        Text(citations[index].excerpt)
                            .font(.caption2)
                            .foregroundColor(AFHAMConfig.professionalGray)
                            .lineLimit(3)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Loading Indicator
struct LoadingIndicator: View {
    let isArabic: Bool
    @State private var dots = ""
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AFHAMConfig.signalTeal)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dots.count == index ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: dots
                        )
                }
                
                Text(isArabic ? "جاري التفكير" : "Thinking")
                    .font(.caption)
                    .foregroundColor(AFHAMConfig.professionalGray)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
            )
            
            Spacer()
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                dots = dots.count >= 3 ? "" : dots + "."
            }
        }
    }
}

// MARK: - Voice Assistant View
struct VoiceAssistantView: View {
    @EnvironmentObject var voiceManager: VoiceAssistantManager
    @EnvironmentObject var geminiManager: GeminiFileSearchManager
    @Environment(\.locale) var locale
    @State private var response = ""
    @State private var isProcessing = false
    
    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // NEURAL: Animated background
                RadialGradient(
                    colors: [
                        AFHAMConfig.signalTeal.opacity(0.3),
                        AFHAMConfig.midnightBlue
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Voice visualization
                    VoiceVisualization(isListening: voiceManager.isListening)
                    
                    // Recognized text
                    if !voiceManager.recognizedText.isEmpty {
                        Text(voiceManager.recognizedText)
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .background(.ultraThinMaterial)
                            )
                            .padding(.horizontal)
                    }
                    
                    // Response
                    if !response.isEmpty {
                        ScrollView {
                            Text(response)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(AFHAMConfig.medicalBlue.opacity(0.3))
                                        .background(.ultraThinMaterial)
                                )
                        }
                        .frame(maxHeight: 200)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Control buttons
                    HStack(spacing: 30) {
                        // Clear button
                        Button(action: {
                            voiceManager.recognizedText = ""
                            response = ""
                        }) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(AFHAMConfig.deepOrange.opacity(0.8))
                                )
                        }
                        
                        // Listen button
                        Button(action: {
                            if voiceManager.isListening {
                                voiceManager.stopListening()
                                processVoiceInput()
                            } else {
                                Task {
                                    try? await voiceManager.startListening()
                                }
                            }
                        }) {
                            Image(systemName: voiceManager.isListening ? "stop.circle.fill" : "mic.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                                .frame(width: 100, height: 100)
                                .background(
                                    Circle()
                                        .fill(
                                            voiceManager.isListening ?
                                                AFHAMConfig.deepOrange :
                                                AFHAMConfig.signalTeal
                                        )
                                        .shadow(color: .white.opacity(0.3), radius: 20)
                                )
                        }
                        .scaleEffect(voiceManager.isListening ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: voiceManager.isListening)
                        
                        // Speak button
                        Button(action: {
                            if !response.isEmpty {
                                voiceManager.speak(
                                    text: response,
                                    language: isArabic ? "ar-SA" : "en-US"
                                )
                            }
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(
                                    Circle()
                                        .fill(AFHAMConfig.medicalBlue.opacity(0.8))
                                )
                        }
                        .disabled(response.isEmpty)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(isArabic ? "المساعد الصوتي" : "Voice Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func processVoiceInput() {
        guard !voiceManager.recognizedText.isEmpty else { return }
        
        isProcessing = true
        
        Task {
            do {
                let (answer, _) = try await geminiManager.queryDocuments(
                    question: voiceManager.recognizedText,
                    language: isArabic ? "ar" : "en"
                )
                response = answer
                
                // Auto-speak response
                voiceManager.speak(
                    text: answer,
                    language: isArabic ? "ar-SA" : "en-US"
                )
            } catch {
                response = isArabic ? 
                    "عذراً، حدث خطأ" : 
                    "Sorry, an error occurred"
            }
            isProcessing = false
        }
    }
}

// MARK: - Voice Visualization
struct VoiceVisualization: View {
    let isListening: Bool
    @State private var amplitude: CGFloat = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        AFHAMConfig.signalTeal.opacity(0.3),
                        lineWidth: 2
                    )
                    .frame(width: 150 + CGFloat(index * 30), height: 150 + CGFloat(index * 30))
                    .scaleEffect(isListening ? 1 + amplitude : 1)
                    .opacity(isListening ? 0.5 : 0.2)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isListening
                    )
            }
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AFHAMConfig.signalTeal,
                            AFHAMConfig.medicalBlue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                )
        }
        .onAppear {
            if isListening {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    amplitude = CGFloat.random(in: 0...0.2)
                }
            }
        }
    }
}
