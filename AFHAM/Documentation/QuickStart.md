# AFHAM Quick Start Guide

*Get up and running with AFHAM in under 10 minutes*

## 🚀 Quick Setup

### 1. Prerequisites
- iOS 17.0+ device or simulator
- Xcode 15.0+
- BrainSAIT API key

### 2. Installation
```bash
# Clone the repository
git clone https://github.com/brainsait/afham.git
cd afham

# Open in Xcode
open AFHAM.xcodeproj
```

### 3. Configure API Key
```swift
// In AFHAMConfig.swift
AFHAMConfig.geminiAPIKey = "your_api_key_here"
```

### 4. Run the App
- Select iPhone 15 Pro simulator
- Press `Cmd+R` to build and run

## 🎯 Your First Document Chat

### Upload a Document
1. Tap the "+" button in the chat interface
2. Select a PDF or image from your device
3. Wait for the upload indicator to complete

### Ask Questions
```
"What is this document about?"
"Summarize the key points"
"Find information about [specific topic]"
```

### Voice Assistant
- Tap and hold the microphone button
- Speak your question in Arabic or English
- Release to process

## 📱 Key Features Demo

### Document Understanding
- **PDF Analysis**: Medical reports, research papers
- **Image OCR**: Handwritten notes, scanned documents
- **Multi-language**: Arabic and English support

### Healthcare Integration
- **NPHIES Compliance**: Automatic healthcare standard validation
- **FHIR Support**: Structured medical data processing
- **PDPL Compliance**: Saudi data protection compliance

### Smart Chat
- **Context-aware**: References uploaded documents
- **Citations**: Shows sources for answers
- **Bilingual**: Switch between Arabic and English

## 🌟 Quick Tips

### Best Practices
- Upload clear, high-resolution documents
- Ask specific questions for better results
- Use voice for hands-free interaction
- Check citations for source verification

### Troubleshooting
- **No response**: Check internet connection
- **Upload fails**: Verify file format (PDF, DOCX, images)
- **Voice not working**: Grant microphone permissions

## 📞 Need Help?

- **Support**: support@brainsait.io
- **Docs**: https://docs.brainsait.io/afham
- **Community**: https://community.brainsait.io

---

*Ready to explore? Check out the [User Guide](UserGuide.md) for detailed features!*