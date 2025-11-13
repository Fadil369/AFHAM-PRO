# 🚀 AFHAM Testing - START HERE

## 🎯 Quick Start (5 Minutes to First Test)

### Step 1: Get Your Gemini API Key
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with Google account
3. Click "Create API Key"
4. Copy the generated key

### Step 2: Set API Key in Xcode
1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** on the left
3. Go to **Environment Variables** tab
4. Click **+** to add new variable:
   - **Name**: `GEMINI_API_KEY`
   - **Value**: `your_api_key_here`
5. Click **Close**

### Step 3: Run the App
1. Select **iPhone 15 Pro** simulator
2. Press **Cmd+R** to build and run
3. Wait for app to launch

### Step 4: First Test Sequence (3 minutes)

#### 📄 Test 1: Upload a Document
- Tap **Documents** tab
- Tap **"+"** button
- Select any PDF file from simulator
- Wait for upload progress to complete
- ✅ **Success**: Document appears in list

#### 💬 Test 2: Chat with Document  
- Tap **Chat** tab
- Type: `"What is this document about?"`
- Tap send button (arrow icon)
- Wait for loading dots animation
- ✅ **Success**: AI responds with document summary

#### 🎙️ Test 3: Voice Assistant
- Tap **microphone** button in chat
- Grant **microphone permission** when prompted
- Grant **speech recognition permission** when prompted
- Speak: `"Tell me more about the key points"`
- ✅ **Success**: Voice converts to text, AI responds

---

## 🧪 Full Testing Suite

### 📋 Use Our Testing Resources

1. **Automated Tests**: Run `AFHAMFeatureTests.swift` in Xcode
2. **Setup Script**: Run `./setup_tests.sh` in terminal  
3. **Quick Tests**: Use `quick_test.swift` for verification
4. **Comprehensive Checklist**: Follow `TESTING_CHECKLIST.md`

### 🎯 Key Features to Test

| Feature | Test Action | Expected Result |
|---------|------------|-----------------|
| **File Upload** | Upload PDF/image | Progress bar → Document in list |
| **AI Chat** | Ask about document | Relevant answer with citations |
| **Voice Input** | Speak question | Voice → text → AI response |
| **Arabic Support** | Switch to Arabic UI | RTL layout, Arabic text |
| **Error Handling** | Invalid file/no internet | Graceful error messages |

---

## 🚨 Common Issues & Quick Fixes

### ❌ "API key not configured"
**Fix**: Set `GEMINI_API_KEY` in Xcode scheme environment variables

### ❌ Voice recognition crashes  
**Fix**: Grant microphone + speech recognition permissions in iOS Settings

### ❌ Upload fails
**Fix**: Use PDF, PNG, JPG, or TXT files (check supported formats)

### ❌ No AI responses
**Fix**: Ensure at least one document is uploaded successfully first

### ❌ Build errors
**Fix**: Clean build folder (Cmd+Shift+K) and rebuild

---

## 📊 Success Metrics

### ✅ Must Pass Tests
- [ ] App launches without crashes
- [ ] File upload completes successfully  
- [ ] AI provides relevant document responses
- [ ] Voice recognition works in English
- [ ] Arabic UI functions properly
- [ ] Error messages are helpful

### 🏥 Healthcare Readiness
- [ ] Medical documents process correctly
- [ ] Arabic medical terms supported
- [ ] Professional UI suitable for clinical use
- [ ] Citations provide source verification
- [ ] Performance acceptable for medical workflows

---

## 📱 Testing Environments

### ✅ Recommended Test Setup
- **Simulator**: iPhone 15 Pro (iOS 17+)
- **Real Device**: iPhone with iOS 17+ (for voice accuracy)
- **Files**: Mix of PDF, images, text files
- **Languages**: Test both English and Arabic

### 📋 Test Data Suggestions
- **Medical PDF**: Lab report, medical record
- **Technical Document**: User manual, specification
- **Arabic Content**: Arabic text document  
- **Image**: Screenshot, scanned document
- **Mixed Content**: English + Arabic text

---

## 🎉 What Success Looks Like

When testing is complete, you should see:

1. **Smooth File Uploads** 
   - Files upload quickly with progress feedback
   - Documents appear in organized list
   - Metadata (size, date) is accurate

2. **Intelligent Chat Responses**
   - AI understands document content
   - Responses include relevant citations
   - Context maintained across conversation

3. **Accurate Voice Recognition**
   - Real-time speech-to-text conversion
   - Works in both Arabic and English
   - Voice commands trigger appropriate responses

4. **Professional Medical UI**
   - Clean, clinical interface design
   - Proper Arabic RTL text handling
   - Loading states keep users informed
   - Error messages are clear and actionable

---

## 🆘 Need Help?

### 🔍 Troubleshooting Steps
1. Check Xcode console for error messages
2. Verify API key is set and valid
3. Ensure all iOS permissions granted
4. Test with different file types/sizes
5. Try restarting simulator/device

### 📞 Get Support
- **Documentation**: Review `TESTING_CHECKLIST.md`
- **Code Issues**: Check `AFHAMFeatureTests.swift`
- **Setup Problems**: Run `setup_tests.sh` script
- **Quick Validation**: Use `quick_test.swift`

---

## 🚀 Ready to Test?

1. **Set your API key** ↗️
2. **Run the app** ▶️  
3. **Upload a document** 📄
4. **Ask it questions** 💬
5. **Try voice input** 🎙️
6. **Test Arabic mode** 🌐

### ⏱️ Time Investment
- **Quick Test**: 5 minutes
- **Core Features**: 15 minutes  
- **Comprehensive Test**: 45 minutes
- **Full Validation**: 90 minutes

**Let's get testing! 🧪✨**