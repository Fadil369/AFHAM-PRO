# AFHAM Enhanced Voice Assistant Features

## 🎙️ Overview
The Enhanced Voice Assistant brings advanced voice capabilities to AFHAM with Voice Activity Detection (VAD), voice command recognition, text-to-speech, and superior Arabic language support.

---

## ✨ Key Features

### 1. **Voice Activity Detection (VAD)**
- **Real-time speech detection** with audio level visualization
- Automatic silence detection (2-second threshold)
- dB-based threshold detection (-50dB for speech, -55dB for silence)
- Visual feedback with animated waveforms

```swift
class VoiceActivityDetector: ObservableObject {
    @Published var isSpeaking = false
    @Published var audioLevel: Float = 0.0
    
    private let threshold: Float = -50.0
    private let silenceThreshold: Float = -55.0
    private let maxSilenceDuration: TimeInterval = 2.0
}
```

### 2. **Voice Command Recognition**
Bilingual voice commands with automatic detection and execution:

#### Arabic Commands (الأوامر العربية)
- `افتح المستند` - Open document
- `أغلق المستند` - Close document
- `ابحث` - Search
- `اقرأ` - Read text
- `توقف` - Stop reading
- `الصفحة التالية` - Next page
- `الصفحة السابقة` - Previous page
- `ملخص` - Summary
- `ترجم` - Translate

#### English Commands
- `open document` - Open document
- `close document` - Close document
- `search` - Search
- `read` - Read text
- `stop` - Stop reading
- `next page` - Next page
- `previous page` - Previous page
- `summary` - Summary
- `translate` - Translate

### 3. **Text-to-Speech (TTS)**
- **High-quality voice synthesis** with enhanced/premium voices
- Customizable speech parameters:
  - **Rate**: 0.0 - 1.0 (speed)
  - **Pitch**: 0.5 - 2.0 (tone)
  - **Volume**: 0.0 - 1.0 (loudness)
- Natural speech with automatic pauses
- Arabic and English voice support
- Interruption handling

```swift
func speak(text: String, language: String, rate: Float? = nil, pitch: Float? = nil, volume: Float? = nil)
```

### 4. **Continuous Mode**
- Hands-free operation with automatic re-listening
- Perfect for extended dictation or command sequences
- Auto-restart after 0.5s pause
- Smart silence detection

### 5. **Enhanced Arabic Support**
- Optimized for `ar-SA` (Saudi Arabic) locale
- Premium Arabic voice selection
- Right-to-left (RTL) UI support
- Arabic command recognition with dialect handling

### 6. **Audio Feedback**
- System sound effects for UX enhancement:
  - **Begin recording** (Sound ID: 1113)
  - **End recording** (Sound ID: 1114)
  - **Success** (Sound ID: 1057)
  - **Error** (Sound ID: 1053)
- Haptic feedback for command recognition

---

## 🏗️ Architecture

### Components

#### `VoiceActivityDetector`
- Processes audio buffers in real-time
- Calculates RMS (Root Mean Square) for audio levels
- Publishes `isSpeaking` and `audioLevel` states

#### `EnhancedVoiceAssistantManager`
- Main voice assistant orchestrator
- Conforms to `SFSpeechRecognizerDelegate`, `AVSpeechSynthesizerDelegate`
- Manages speech recognition and synthesis
- Handles permissions (microphone, speech recognition)
- Thread-safe with `@MainActor` isolation

#### `VoiceCommand` Enum
- Defines all available voice commands
- Maps commands to actions
- Supports bilingual command strings

#### `VoiceSettingsView`
- User settings interface
- Speech customization controls
- Voice testing functionality

#### `EnhancedVoiceDemo`
- Comprehensive demo UI
- Visual feedback components
- Feature showcase

---

## 🔧 Integration Guide

### Basic Setup

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var voiceManager = EnhancedVoiceAssistantManager()
    
    var body: some View {
        VStack {
            // Your UI
        }
        .environmentObject(voiceManager)
    }
}
```

### Starting Voice Recognition

```swift
Button("Start Listening") {
    Task {
        do {
            try await voiceManager.startListening()
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### Stopping Voice Recognition

```swift
Button("Stop Listening") {
    voiceManager.stopListening()
}
```

### Speaking Text

```swift
Button("Speak") {
    voiceManager.speak(
        text: "مرحباً بك في أفهم",
        language: "ar-SA",
        rate: 0.5,
        pitch: 1.0,
        volume: 1.0
    )
}
```

### Switching Languages

```swift
Button("Switch Language") {
    voiceManager.switchLanguage(to: "en-US")
}
```

### Enabling Continuous Mode

```swift
Toggle("Continuous Mode", isOn: $voiceManager.continuousMode)
```

---

## 🎨 UI Components

### Voice Activity Indicator
Visual representation of audio levels with animated circles:

```swift
VoiceActivityIndicator(
    isListening: voiceManager.isListening,
    audioLevel: voiceManager.audioLevel,
    isArabic: true
)
```

### Voice Command Card
Display available commands:

```swift
VoiceCommandCard(command: .openDocument)
```

### Settings View
Complete settings interface:

```swift
VoiceSettingsView(voiceManager: voiceManager)
```

---

## 🔐 Permissions

### Required Info.plist Keys

```xml
<key>NSMicrophoneUsageDescription</key>
<string>AFHAM needs microphone access for voice commands and dictation</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>AFHAM uses speech recognition to understand your voice commands</string>
```

### Permission Checking
Automatic permission requests with proper error handling:

```swift
private func checkPermissions() async throws {
    // Check speech recognition
    let speechStatus = await SFSpeechRecognizer.requestAuthorization()
    guard speechStatus == .authorized else {
        throw VoiceError.speechNotAuthorized
    }
    
    // Check microphone
    let micStatus = await AVAudioSession.sharedInstance().requestRecordPermission()
    guard micStatus else {
        throw VoiceError.microphoneNotAuthorized
    }
}
```

---

## 📊 Published Properties

Monitor voice assistant state:

```swift
@Published var isListening: Bool          // Currently recording
@Published var isSpeaking: Bool           // Currently speaking
@Published var recognizedText: String     // Latest transcription
@Published var currentLanguage: String    // Active language ("ar-SA" or "en-US")
@Published var audioLevel: Float          // Audio level 0.0-1.0
@Published var errorMessage: String?      // Last error message
@Published var detectedCommand: VoiceCommand? // Last detected command
@Published var continuousMode: Bool       // Continuous listening enabled
@Published var autoSpeak: Bool            // Auto-announce responses
@Published var speechRate: Float          // TTS speed
@Published var speechPitch: Float         // TTS pitch
@Published var speechVolume: Float        // TTS volume
```

---

## 🎯 Use Cases

### 1. **Medical Documentation**
```swift
// Dictate patient notes in Arabic
voiceManager.continuousMode = true
try await voiceManager.startListening()
// Doctor speaks continuously...
// Automatic transcription with medical commands
```

### 2. **Hands-Free Navigation**
```swift
// Enable voice commands for document navigation
// User says: "الصفحة التالية" (next page)
// System detects command and navigates
```

### 3. **Accessibility**
```swift
// Read document content aloud
voiceManager.speak(
    text: documentText,
    language: "ar-SA",
    rate: 0.4  // Slower for better comprehension
)
```

### 4. **Multilingual Support**
```swift
// Seamless switching between Arabic and English
if userPreferredLanguage == "ar" {
    voiceManager.switchLanguage(to: "ar-SA")
} else {
    voiceManager.switchLanguage(to: "en-US")
}
```

---

## 🐛 Error Handling

### Error Types

```swift
enum VoiceError: LocalizedError {
    case speechNotAuthorized      // Speech recognition permission denied
    case microphoneNotAuthorized  // Microphone permission denied
    case requestCreationFailed    // Recognition request failed
    case invalidAudioFormat       // Invalid audio configuration
}
```

### Error Recovery

```swift
if let error = voiceManager.errorMessage {
    // Display error to user
    // Automatic cleanup and audio feedback (error sound)
}
```

---

## 🧪 Testing

### Demo View
Run the comprehensive demo:

```swift
EnhancedVoiceDemo()
```

### Unit Testing
```swift
func testVoiceActivityDetection() {
    let detector = VoiceActivityDetector()
    let buffer = createTestAudioBuffer()
    detector.processAudioBuffer(buffer)
    XCTAssertEqual(detector.audioLevel > 0, true)
}
```

---

## ⚡ Performance

- **On-device recognition** when available (iOS 13+)
- Efficient audio buffer processing (1024 samples)
- Minimal latency with `shouldReportPartialResults`
- Smart memory management with weak references
- Thread-safe with proper isolation

---

## 🔮 Future Enhancements

- [ ] Custom wake word detection ("Hey AFHAM")
- [ ] Voice biometrics for user identification
- [ ] Offline speech recognition
- [ ] Custom command training
- [ ] Multi-language mixing in single session
- [ ] Voice emotion detection
- [ ] Speaker diarization (multi-speaker support)
- [ ] Noise cancellation improvements
- [ ] Medical terminology dictionary
- [ ] PDPL-compliant voice data handling

---

## 📱 Requirements

- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Frameworks**: 
  - `Speech`
  - `AVFoundation`
  - `AudioToolbox`

---

## 📚 References

- [Apple Speech Framework](https://developer.apple.com/documentation/speech)
- [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfoundation/avspeechsynthesizer)
- [Arabic Voice Recognition Best Practices](https://developer.apple.com/documentation/speech/recognizing_speech_in_live_audio)

---

## 🤝 Contributing

When enhancing voice features:

1. Test with both Arabic and English
2. Verify permission flows
3. Test on physical devices (simulator has limitations)
4. Consider PDPL compliance for voice data
5. Add appropriate error handling
6. Update this documentation

---

## 📄 License

Part of AFHAM project - see main LICENSE file.

---

**Last Updated**: November 2025  
**Version**: 1.0.0  
**Maintainer**: AFHAM Development Team
