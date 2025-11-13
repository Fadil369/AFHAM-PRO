// AFHAM - Enhanced Voice Assistant Demo View
// Demonstrates all advanced voice features

import SwiftUI

// MARK: - Enhanced Voice Demo View
struct EnhancedVoiceDemo: View {
    @StateObject private var voiceManager = EnhancedVoiceAssistantManager()
    @Environment(\.locale) var locale
    @State private var selectedCommand: VoiceCommand?
    @State private var showingSettings = false
    
    private var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Voice Activity Indicator
                    VoiceActivityIndicator(
                        isListening: voiceManager.isListening,
                        audioLevel: voiceManager.audioLevel,
                        isArabic: isArabic
                    )
                    .padding()
                    
                    // MARK: - Control Buttons
                    VStack(spacing: 12) {
                        // Primary Control
                        Button(action: {
                            Task {
                                if voiceManager.isListening {
                                    voiceManager.stopListening()
                                } else {
                                    try? await voiceManager.startListening()
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: voiceManager.isListening ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                Text(voiceManager.isListening ? 
                                     (isArabic ? "إيقاف الاستماع" : "Stop Listening") :
                                     (isArabic ? "بدء الاستماع" : "Start Listening"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(voiceManager.isListening ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(voiceManager.isSpeaking)
                        
                        // Language Switch
                        Button(action: {
                            let newLang = voiceManager.currentLanguage.starts(with: "ar") ? "en-US" : "ar-SA"
                            voiceManager.switchLanguage(to: newLang)
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                Text(voiceManager.currentLanguage.starts(with: "ar") ? 
                                     "Switch to English" : "التحويل للعربية")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Recognized Text Display
                    if !voiceManager.recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isArabic ? "النص المعترف به:" : "Recognized Text:")
                                .font(.headline)
                            Text(voiceManager.recognizedText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Detected Command
                    if let command = voiceManager.detectedCommand {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(isArabic ? "الأمر المكتشف:" : "Detected Command:")
                                .font(.headline)
                            HStack {
                                Image(systemName: "command")
                                    .foregroundColor(.purple)
                                Text(command.rawValue)
                                    .bold()
                                Spacer()
                                Text("→ \(command.action)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Error Display
                    if let error = voiceManager.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.caption)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Voice Commands Reference
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isArabic ? "الأوامر الصوتية المتاحة:" : "Available Voice Commands:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(VoiceCommand.allCases, id: \.rawValue) { command in
                                VoiceCommandCard(command: command)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // MARK: - Features List
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isArabic ? "المميزات المتقدمة:" : "Advanced Features:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        FeatureRow(
                            icon: "waveform",
                            title: isArabic ? "كشف النشاط الصوتي" : "Voice Activity Detection",
                            description: isArabic ? "كشف تلقائي للكلام والصمت" : "Automatic speech and silence detection"
                        )
                        
                        FeatureRow(
                            icon: "command.circle",
                            title: isArabic ? "التعرف على الأوامر" : "Command Recognition",
                            description: isArabic ? "تنفيذ الأوامر بالعربية والإنجليزية" : "Arabic and English command execution"
                        )
                        
                        FeatureRow(
                            icon: "speaker.wave.3",
                            title: isArabic ? "تحويل النص لكلام" : "Text-to-Speech",
                            description: isArabic ? "قراءة النصوص بصوت عالي الجودة" : "High-quality voice reading"
                        )
                        
                        FeatureRow(
                            icon: "repeat",
                            title: isArabic ? "الوضع المستمر" : "Continuous Mode",
                            description: isArabic ? "استماع متواصل بدون انقطاع" : "Uninterrupted listening"
                        )
                    }
                    .padding(.top)
                    
                    // MARK: - Status Indicators
                    HStack(spacing: 20) {
                        StatusBadge(
                            icon: "mic.fill",
                            label: isArabic ? "الاستماع" : "Listening",
                            isActive: voiceManager.isListening
                        )
                        
                        StatusBadge(
                            icon: "speaker.wave.2.fill",
                            label: isArabic ? "التحدث" : "Speaking",
                            isActive: voiceManager.isSpeaking
                        )
                        
                        StatusBadge(
                            icon: "repeat",
                            label: isArabic ? "مستمر" : "Continuous",
                            isActive: voiceManager.continuousMode
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle(isArabic ? "مساعد صوتي متقدم" : "Enhanced Voice Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    VoiceSettingsView(voiceManager: voiceManager)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(isArabic ? "تم" : "Done") {
                                    showingSettings = false
                                }
                            }
                        }
                }
            }
        }
    }
}

// MARK: - Voice Activity Indicator
struct VoiceActivityIndicator: View {
    let isListening: Bool
    let audioLevel: Float
    let isArabic: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circles
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.blue.opacity(0.2 - Double(index) * 0.05), lineWidth: 2)
                        .frame(width: CGFloat(120 + index * 40), height: CGFloat(120 + index * 40))
                        .scaleEffect(isListening ? 1.0 + CGFloat(index) * 0.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isListening)
                }
                
                // Main microphone
                ZStack {
                    Circle()
                        .fill(isListening ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .scaleEffect(1.0 + CGFloat(audioLevel) * 0.3)
                        .animation(.spring(response: 0.3), value: audioLevel)
                    
                    Image(systemName: "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 200)
            
            // Audio level bars
            if isListening {
                HStack(spacing: 4) {
                    ForEach(0..<20) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index < Int(audioLevel * 20) ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: CGFloat(10 + index * 2))
                    }
                }
                .padding(.horizontal)
            }
            
            Text(isListening ? 
                 (isArabic ? "جاري الاستماع..." : "Listening...") :
                 (isArabic ? "اضغط للبدء" : "Tap to Start"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Voice Command Card
struct VoiceCommandCard: View {
    let command: VoiceCommand
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(command.rawValue)
                .font(.caption)
                .bold()
            Text(command.action)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isActive ? .green : .gray)
            Text(label)
                .font(.caption2)
                .foregroundColor(isActive ? .green : .gray)
        }
        .padding(8)
        .background(isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct EnhancedVoiceDemo_Previews: PreviewProvider {
    static var previews: some View {
        EnhancedVoiceDemo()
            .environment(\.locale, Locale(identifier: "ar"))
        
        EnhancedVoiceDemo()
            .environment(\.locale, Locale(identifier: "en"))
    }
}
