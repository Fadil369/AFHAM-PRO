# AFHAM Voice Assistant - Feature Guide & Testing

**Version**: 1.1.0  
**Last Updated**: November 14, 2025

---

## 🎤 Overview

The AFHAM Voice Assistant provides **real-time, bilingual voice interaction** with your personal document library. Speak naturally in Arabic or English and receive instant answers enriched with citations from uploaded documents.

### Key Features

✅ **Real-Time Streaming** - Instant speech recognition and response  
✅ **Document-Grounded Answers** - Automatically pulls context from your uploads  
✅ **Bilingual Support** - Seamless Arabic/English conversation  
✅ **Citation-Rich Responses** - References specific documents and pages  
✅ **Auto-Sync** - All Documents and Workspace uploads are instantly available  

---

## 🏗️ Architecture

### Data Flow

```
User Speech (AR/EN)
    ↓
VoiceAssistantManager (Speech-to-Text)
    ↓
VoiceAssistantView.processVoiceInput()
    ↓
GeminiFileSearchManager.queryDocuments(question, language)
    ↓
Gemini API + Document Index
    ↓
Response with Citations
    ↓
VoiceAssistantManager.speak() (Text-to-Speech)
    ↓
Audio Output (AR/EN)
```

### Key Components

#### 1. **VoiceAssistantView** (`AFHAM/Features/Chat/afham_chat.swift:368`)
- Main UI for voice interaction
- Handles speech visualization
- Processes recognized text
- Displays responses with citations

#### 2. **VoiceAssistantManager** (`AFHAM/Core/afham_main.swift:418`)
- Manages Speech Recognition (SFSpeechRecognizer)
- Handles Text-to-Speech (AVSpeechSynthesizer)
- Real-time audio processing
- Language-aware voice selection

#### 3. **GeminiFileSearchManager** (`AFHAM/Core/afham_main.swift`)
- Document indexing and retrieval
- Query processing with context
- Citation extraction
- Bilingual response generation

### Document Integration

```swift
// From VoiceAssistantView.processVoiceInput()
let (answer, citations) = try await geminiManager.queryDocuments(
    question: voiceManager.recognizedText,
    language: isArabic ? "ar" : "en"
)

// Auto-speak response in user's language
voiceManager.speak(
    text: answer,
    language: isArabic ? "ar-SA" : "en-US"
)
```

**Key Point**: Any document uploaded via:
- 📄 Documents tab
- 🎨 Modular Workspace
- 📸 Intelligent Capture

...is immediately available for voice queries. **No extra setup required.**

---

## 🧪 Testing Guide

### Prerequisites

1. **Device/Simulator**:
   - Physical device recommended (simulator has microphone limitations)
   - **Minimum**: iPhone 12 or newer
   - **Recommended**: iPhone 14 Pro or newer for optimal performance
   - **iOS Version**: 17.0 or later
2. **Permissions**: Microphone and Speech Recognition enabled
3. **Network**: Wi-Fi or cellular for Gemini API calls
4. **Language**: System language set (Settings → General → Language & Region)

### Test Scenario 1: Basic Voice Query

**Steps:**
1. Launch AFHAM
2. Navigate to **Voice** tab (🎤)
3. Tap the microphone button
4. Speak: "What is AFHAM?" (English) or "ما هو أفهم؟" (Arabic)
5. Wait for response

**Expected Result:**
- ✅ Speech recognized and displayed
- ✅ Response appears in text
- ✅ Response auto-plays in spoken language
- ✅ Clear and trash buttons functional

### Test Scenario 2: Document-Grounded Query

**Steps:**
1. Go to **Documents** tab
2. Upload a medical document (PDF/image)
3. Wait for processing to complete
4. Switch to **Voice** tab
5. Ask: "Summarize my uploaded document" or "اختصر الملف الذي رفعته"

**Expected Result:**
- ✅ Response references uploaded document
- ✅ Includes specific citations (page numbers, excerpts)
- ✅ Accurate content extraction
- ✅ Response in query language

### Test Scenario 3: Bilingual Switching

**Steps:**
1. With English locale:
   - Ask: "What documents do I have?"
   - Verify English response

2. Change app language to Arabic:
   - Settings → Language → العربية
   - Return to Voice tab
   - Ask: "ما هي المستندات المتوفرة؟"
   - Verify Arabic response

3. Try mixed query:
   - "Show me documents about diabetes"
   - Verify language detection and appropriate response

**Expected Result:**
- ✅ Correct language detection
- ✅ Response matches query language
- ✅ TTS voice changes with language
- ✅ Same documents accessible in both languages

### Test Scenario 4: Multi-Document Context

**Steps:**
1. Upload 3 different documents (e.g., prescription, lab report, patient history)
2. Ask contextual question: "What medications am I taking?" or "ما هي الأدوية التي أتناولها؟"
3. Verify response synthesizes information from multiple documents

**Expected Result:**
- ✅ Combines data from all relevant documents
- ✅ Lists citations from each source
- ✅ Coherent multi-source answer

### Test Scenario 5: Workspace Integration

**Steps:**
1. Go to **Workspace** tab
2. Create a presentation from a document
3. Switch to **Voice** tab
4. Ask: "What presentations have I created?"

**Expected Result:**
- ✅ Lists workspace outputs
- ✅ References transformation pipelines
- ✅ Provides metadata about created assets

### Test Scenario 6: Error Handling

**Steps:**
1. **No Documents**: Ask document question with empty library
   - Expected: Helpful message explaining no documents available

2. **No Network**: Disable Wi-Fi/cellular, ask question
   - Expected: Error message in appropriate language

3. **Unclear Speech**: Mumble or speak unclearly
   - Expected: "I didn't catch that" message

4. **Interrupted Speech**: Start speaking, then stop abruptly
   - Expected: Graceful timeout and ready for new input

### Test Scenario 7: Performance

**Steps:**
1. Upload large document (50+ pages)
2. Ask complex question requiring full document analysis
3. Measure response time

**Expected Result:**
- ✅ Response within 3-5 seconds for indexed documents
- ✅ Streaming response if available
- ✅ Progress indicator during processing
- ✅ No UI freezing

---

## 🔧 Build Validation

### Local Build Check

```bash
# Clean build
xcodebuild clean build \
  -scheme AFHAM \
  -project AFHAM.xcodeproj \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

# Expected Output:
# ** BUILD SUCCEEDED **
```

### Run on Device

```bash
# For physical device testing (requires developer account)
xcodebuild build \
  -scheme AFHAM \
  -project AFHAM.xcodeproj \
  -sdk iphoneos \
  -configuration Debug \
  -destination 'platform=iOS,name=Your iPhone' \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

### Verify Voice Components

```bash
# Check for voice-related symbols in build
nm -g DerivedData/Build/Products/Debug-iphonesimulator/AFHAM.app/AFHAM | \
  grep -i "voice\|speech\|audio"

# Should include:
# VoiceAssistantManager
# VoiceAssistantView
# processVoiceInput
# SFSpeechRecognizer
# AVSpeechSynthesizer
```

---

## 📊 Testing Checklist

### Functional Tests
- [ ] Speech recognition activates on button press
- [ ] Real-time transcription displays
- [ ] Query sent to GeminiFileSearchManager
- [ ] Response retrieved with citations
- [ ] Text-to-Speech plays automatically
- [ ] Clear button resets state
- [ ] Trash button clears history

### Language Tests
- [ ] English voice input → English response
- [ ] Arabic voice input → Arabic response
- [ ] Mixed language queries handled gracefully
- [ ] TTS voice quality appropriate for language
- [ ] RTL text displayed correctly for Arabic

### Integration Tests
- [ ] Documents tab uploads reflected in voice queries
- [ ] Workspace outputs queryable via voice
- [ ] Intelligent Capture scans accessible
- [ ] Multi-document context synthesis works
- [ ] Citations link to correct source documents

### Performance Tests
- [ ] Response time < 5 seconds for simple queries
- [ ] No memory leaks after extended use
- [ ] Background/foreground transitions stable
- [ ] Concurrent uploads don't block voice
- [ ] Large document libraries perform well

### Edge Cases
- [ ] No documents uploaded → helpful message
- [ ] Network offline → error handling
- [ ] Microphone permission denied → prompt
- [ ] Speech recognition unavailable → fallback
- [ ] Empty/unclear speech → retry prompt

---

## 🐛 Known Issues & Workarounds

### Issue 1: Delayed First Response
**Symptom**: First voice query takes 10+ seconds  
**Cause**: Cold start of speech recognizer  
**Workaround**: Pre-warm by tapping mic button on app launch

### Issue 2: Background Audio Conflicts
**Symptom**: TTS doesn't play if music is playing  
**Cause**: Audio session configuration  
**Workaround**: Pause other audio before using voice

### Issue 3: Arabic Accent Variation
**Symptom**: Recognition accuracy varies by dialect  
**Cause**: SFSpeechRecognizer training data  
**Workaround**: Speak Modern Standard Arabic for best results

---

## 📱 User-Facing How-To Card

### In-App Guide Content

**Title**: 🎤 Voice Assistant Quick Start

**Body**:
```
Talk to Your Documents

1. Upload documents via Documents, Capture, or Workspace tabs
   → Automatically indexed for voice queries

2. Tap the Voice tab (🎤)
   → Press microphone to start speaking

3. Ask questions in Arabic or English
   → "Summarize my lab results"
   → "اختصر نتائج الفحوصات"

4. Get instant answers with citations
   → References your personal document library
   → Speaks response in your language

Tips:
• All uploads auto-sync to voice assistant
• No extra setup required
• Switch languages anytime
• Ask follow-up questions naturally
```

**Visual**: Screenshot showing Voice tab with sample query/response

---

## 🎬 Demo Recording Guide

### Bilingual Demo Script

#### Scene 1: English Workflow (30 seconds)
```
[Screen: Documents tab]
"I'm uploading my prescription..."

[Screen: Voice tab, tap mic]
"What medications am I taking?"

[Show: Response with citations]
"AFHAM found my prescription and listed all medications with dosages."
```

#### Scene 2: Arabic Workflow (30 seconds)
```
[Screen: نتائج المختبر tab]
"أنا أرفع نتائج الفحوصات..."

[Screen: Voice tab, اضغط الميكروفون]
"ما هي نتائج الفحوصات؟"

[Show: الاستجابة مع المصادر]
"أفهم وجد النتائج وأعطاني الملخص الكامل."
```

#### Scene 3: Context Switching (20 seconds)
```
[Show: Multiple documents in library]
"I have prescriptions, lab results, and medical history uploaded."

[Voice query]
"Give me a health summary based on all my documents."

[Show: Comprehensive response synthesizing all sources]
```

### Recording Specs
- **Resolution**: 1080p minimum
- **Format**: MP4 (H.264)
- **Duration**: 60-90 seconds total
- **Captions**: Arabic and English subtitles
- **Audio**: Clear voice, ambient noise < -40dB

---

## 🔗 Related Documentation

- [AFHAM User Guide](QUICK_START.md)
- [Document Upload Guide](BUILD_GUIDE.md)
- [Modular Workspace Guide](AFHAM/Features/DocsWorkspace/ModularCanvas/README.md)
- [Intelligent Capture Guide](AFHAM_INTELLIGENT_CAPTURE_README.md)

---

## 🚀 Next Steps

### For Developers
1. Run build validation on local machine
2. Test on physical iOS device
3. Record demo clips for marketing
4. Add how-to card to Voice tab UI

### For Testers
1. Complete testing checklist above
2. Report issues to GitHub
3. Provide feedback on UX
4. Test with real medical documents (anonymized)

### For Product Team
1. Review demo clips
2. Create onboarding video
3. Update App Store screenshots
4. Prepare release announcement

---

**Questions?** Contact: support@brainsait.com

