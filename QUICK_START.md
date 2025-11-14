# 🚀 AFHAM - Quick Start Guide v1.1.0

Get up and running with AFHAM's new features in less than 10 minutes!

**What's New in v1.1.0:**
- 🎤 Voice Assistant with document intelligence
- 📸 Intelligent Document Capture
- 🎨 Modular Workspace for content transformation

---

## Prerequisites Check

```bash
# Check Xcode version (need 15.0+)
xcodebuild -version

# Check Swift version (need 5.9+)
swift --version

# Check if you have Ruby & Bundler
ruby --version
bundle --version
```

## 5-Minute Setup

### Step 1: Open Project (1 minute)
```bash
# Navigate to your AFHAM project directory
cd /path/to/AFHAM-PRO
# Or if you're already in the project root:
open AFHAM.xcodeproj
```

### Step 2: Configure API Key (2 minutes)
1. Get your Gemini API key from: https://makersuite.google.com/app/apikey
2. Create the Config directory and Environment.plist file:
```bash
# Create Config directory if it doesn't exist
mkdir -p Config

# Create Environment.plist file
cat > Config/Environment.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_API_KEY_HERE</string>
</dict>
</plist>
EOF
```
3. Replace `YOUR_API_KEY_HERE` with your actual Gemini API key:
```bash
# Edit the file and replace the API key
nano Config/Environment.plist
# Or open in Xcode and edit there
```

### Step 3: Select Target (30 seconds)
1. In Xcode, select "AFHAM" scheme
2. Choose iPhone 15 Pro simulator (or your device)

### Step 4: Build & Run (1.5 minutes)
```bash
# Press ⌘+R in Xcode
# Or run from terminal:
xcodebuild -project AFHAM.xcodeproj -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

## First Run Checklist

✅ App launches successfully  
✅ Welcome screen appears  
✅ Language selector works (Arabic/English)  
✅ **NEW:** Voice tab accessible with microphone permission  
✅ **NEW:** Capture tab ready for document scanning  
✅ **NEW:** Workspace tab with transformation tools  
✅ Upload document button visible  
✅ Chat interface accessible  

---

## 🎯 Feature Tour

### 📄 Documents Tab
Your personal document library
- Upload PDFs, images, medical records
- Organize with folders and tags
- Search across all documents
- Share securely with healthcare team

### 💬 Chat Tab
AI-powered conversations
- Ask questions about your documents
- Get answers with citations
- Bilingual support (AR/EN)
- Context-aware responses

### 🎤 Voice Tab (NEW!)
Talk to your documents
```
1. Tap microphone button
2. Speak: "What medications am I taking?"
3. Get instant answer with citations
4. Response auto-plays in your language
```
**Auto-Sync**: All uploads instantly available for voice queries!

### 📸 Capture Tab (NEW!)
Intelligent document scanning
```
1. Point camera at document
2. Auto-detect edges and optimize
3. Multi-page batch scanning
4. OCR extraction with medical templates
```
**Supported**: Prescriptions, lab reports, insurance cards, medical certificates

### 🎨 Workspace Tab (NEW!)
Transform documents into new formats
```
1. Select source document
2. Choose transformation pipeline:
   - Presentation (PPT/Keynote)
   - Training Script
   - Chatbot Knowledge
   - Localization
3. Customize output
4. Export in multiple formats
```

### ⚙️ Settings Tab
Configure your experience
- Language preferences
- Voice settings
- Privacy controls
- Data retention policies

---

## 🧪 Quick Feature Tests

### Test Voice Assistant (2 minutes)
```
1. Upload a document via Documents tab
2. Switch to Voice tab
3. Tap microphone
4. Ask: "Summarize this document"
5. Verify: Response includes content from upload
```

### Test Intelligent Capture (3 minutes)
```
1. Go to Capture tab
2. Point at any document/paper
3. Tap capture button
4. Review extracted text
5. Save to Documents
```

### Test Workspace Transformation (5 minutes)
```
1. Select a document in Documents tab
2. Tap "Transform" → Open in Workspace
3. Choose "Presentation" pipeline
4. Preview generated slides
5. Export as PDF/PPT
```

---

## Troubleshooting

### Common Issues

**Problem**: Build fails with "No such module"
```bash
# Solution: Resolve Swift packages
swift package resolve
```

**Problem**: Code signing error
```bash
# Solution: In Xcode
# 1. Select AFHAM target
# 2. Signing & Capabilities
# 3. Enable "Automatically manage signing"
# 4. Select your team
```

**Problem**: API key not working
```bash
# Solution: Verify Environment.plist
# 1. Check file exists in Config folder
# 2. Verify API key is correct
# 3. Rebuild project (⌘+Shift+K then ⌘+B)
```

**Problem**: Voice Assistant not recognizing speech
```bash
# Solution: Check permissions
# 1. Settings → Privacy → Microphone → Enable for AFHAM
# 2. Settings → Privacy → Speech Recognition → Enable
# 3. Restart app
```

**Problem**: Camera not working in Capture tab
```bash
# Solution: Grant camera permission
# 1. Settings → Privacy → Camera → Enable for AFHAM
# 2. Ensure device has camera (not Mac Catalyst)
# 3. Try physical device instead of simulator
```

**Problem**: Documents not appearing in Voice queries
```bash
# Solution: Wait for indexing
# 1. Upload document via Documents tab
# 2. Wait for "Processing complete" status
# 3. Document auto-syncs to Voice (no manual action needed)
# 4. Retry voice query
```

---

## Next Steps

### For End Users
1. **Voice Assistant Guide**: [`VOICE_ASSISTANT_GUIDE.md`](VOICE_ASSISTANT_GUIDE.md)
2. **Intelligent Capture Guide**: [`AFHAM_INTELLIGENT_CAPTURE_README.md`](AFHAM_INTELLIGENT_CAPTURE_README.md)
3. **Workspace Guide**: [`AFHAM/Features/DocsWorkspace/ModularCanvas/README.md`](AFHAM/Features/DocsWorkspace/ModularCanvas/README.md)

### For Developers
1. **Read Documentation**: [`README.md`](README.md)
2. **Build Guide**: [`BUILD_GUIDE.md`](BUILD_GUIDE.md)
3. **Codebase Overview**: [`AFHAM_CODEBASE_OVERVIEW.md`](AFHAM_CODEBASE_OVERVIEW.md)
4. **Release Notes**: [`RELEASE_NOTES_v1.1.0.md`](RELEASE_NOTES_v1.1.0.md)

### For Testers
1. **Testing Checklist**: See Voice Assistant Guide
2. **Report Issues**: [GitHub Issues](https://github.com/Fadil369/AFHAM-PRO/issues)
3. **Feature Requests**: product@brainsait.com

---

## 📱 App Navigation Reference

```
AFHAM v1.1.0
├── 📄 Documents     → Document library & management
├── 💬 Chat          → AI conversations with context
├── 🎤 Voice         → Voice assistant (NEW!)
├── 📸 Capture       → Document scanning (NEW!)
├── 🎨 Workspace     → Content transformation (NEW!)
└── ⚙️ Settings      → App configuration
```

---

## 🎬 Video Tutorials (Coming Soon)

- Getting Started with Voice Assistant (2 min)
- Document Capture Tutorial (3 min)
- Workspace Transformation Guide (5 min)
- Bilingual Features Overview (4 min)

---

**Need Help?** support@brainsait.com

## Need Help?

- **Email**: developer@brainsait.com
- **Docs**: https://docs.brainsait.com/afham
- **Issues**: https://github.com/brainsait/afham-pro-core/issues

Happy coding! 🎉
