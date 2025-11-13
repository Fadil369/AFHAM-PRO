# 🧪 AFHAM Comprehensive Testing Checklist

## 🚀 Pre-Testing Setup

### ✅ Prerequisites
- [ ] Xcode 15.0+ installed
- [ ] iOS 17+ simulator or device
- [ ] Gemini API key obtained from [Google AI Studio](https://aistudio.google.com/app/apikey)
- [ ] Environment variable set: `export GEMINI_API_KEY='your_key_here'`

### 🔧 Configuration Check
```bash
# Run setup script
chmod +x AFHAM/Testing/setup_tests.sh
./AFHAM/Testing/setup_tests.sh
```

---

## 📱 Phase 1: App Launch & Basic Navigation

### ✅ App Launch
- [ ] App launches without crashes
- [ ] No immediate error messages
- [ ] Main interface loads properly
- [ ] Tab bar shows all 4 tabs (Documents, Chat, Voice, Settings)

### ✅ Tab Navigation
- [ ] Documents tab loads correctly
- [ ] Chat tab shows empty state
- [ ] Voice assistant tab loads
- [ ] Settings tab displays options

**Expected Result:** Smooth navigation between all tabs without crashes.

---

## 📄 Phase 2: File Upload Testing

### ✅ Document Picker Interface
- [ ] Tap "+" button in Documents tab
- [ ] Document picker appears
- [ ] Can browse device files
- [ ] Shows supported file types only

### ✅ File Upload Process
**Test with PDF:**
- [ ] Select a PDF file
- [ ] Upload progress indicator appears
- [ ] Upload completes successfully
- [ ] Document appears in documents list
- [ ] Document metadata is correct (name, size, date)

**Test with Image:**
- [ ] Select a JPG/PNG image
- [ ] OCR processing indicator shows
- [ ] Image appears in documents list
- [ ] Can preview image

**Test with Text File:**
- [ ] Select a .txt file
- [ ] Text file uploads successfully
- [ ] Content is indexed for search

### ✅ Error Handling
- [ ] Try unsupported file type (.exe, .zip)
- [ ] Appropriate error message shows
- [ ] App doesn't crash on invalid files
- [ ] Network error handling (if applicable)

**Expected Result:** All supported file types upload successfully with proper progress feedback.

---

## 💬 Phase 3: Chat Interface Testing

### ✅ Basic Chat Functionality
- [ ] Text input field works correctly
- [ ] Send button enables/disables appropriately
- [ ] Can type and edit messages before sending
- [ ] Input clears after sending message

### ✅ AI Response Testing
**Basic Questions:**
- [ ] Send: "What is this document about?"
- [ ] Loading indicator appears (animated dots)
- [ ] AI response appears in chat bubble
- [ ] Response is relevant to uploaded documents

**Follow-up Questions:**
- [ ] Send: "Can you summarize the main points?"
- [ ] Send: "What are the key findings?"
- [ ] Each response builds on document context

### ✅ Citations & Sources
- [ ] AI responses show citations section
- [ ] Can expand/collapse citations
- [ ] Citations show relevant text excerpts
- [ ] Source attribution is accurate

### ✅ Chat UI Elements
- [ ] User messages appear on right (LTR) or left (RTL)
- [ ] AI messages appear on opposite side
- [ ] Message timestamps are correct
- [ ] Chat scrolls automatically to newest message
- [ ] Can scroll to see older messages

**Expected Result:** Natural conversation flow with accurate, cited responses about uploaded documents.

---

## 🎙️ Phase 4: Voice Assistant Testing

### ✅ Permissions Setup
- [ ] Tap microphone button
- [ ] Speech recognition permission request appears
- [ ] Grant speech recognition permission
- [ ] Microphone permission request appears  
- [ ] Grant microphone access
- [ ] No crashes after granting permissions

### ✅ English Voice Recognition
- [ ] Tap microphone button
- [ ] Voice visualization appears (animated waves/circles)
- [ ] Speak: "Tell me about this document"
- [ ] Text appears in real-time as you speak
- [ ] Voice input converts to chat message
- [ ] AI responds to voice question

### ✅ Arabic Voice Recognition
- [ ] Switch app language to Arabic
- [ ] Tap microphone button  
- [ ] Speak in Arabic: "أخبرني عن هذا المستند"
- [ ] Arabic text appears correctly (RTL)
- [ ] Voice recognition accuracy is good
- [ ] AI responds in Arabic

### ✅ Voice Features
- [ ] Can interrupt speaking by tapping stop
- [ ] Voice input works with background noise
- [ ] Multiple voice commands work in sequence
- [ ] Voice assistant works with different document types

**Expected Result:** Accurate voice recognition in both languages with proper UI feedback.

---

## 🌐 Phase 5: Bilingual Support Testing

### ✅ Language Switching
- [ ] Go to Settings tab
- [ ] Change language from English to Arabic
- [ ] UI switches to RTL layout
- [ ] All text displays in Arabic
- [ ] Navigation and buttons work correctly

### ✅ Arabic Interface
- [ ] Arabic text renders correctly
- [ ] RTL text alignment works
- [ ] Arabic navigation titles
- [ ] Arabic error messages
- [ ] Arabic voice recognition works

### ✅ Mixed Language Content
- [ ] Upload English document
- [ ] Ask question in Arabic
- [ ] AI responds appropriately  
- [ ] Upload Arabic document
- [ ] Ask question in English
- [ ] Cross-language understanding works

**Expected Result:** Seamless language switching with proper RTL support and bilingual AI responses.

---

## 🚀 Phase 6: Advanced Features Testing

### ✅ Multiple Documents
- [ ] Upload 3-5 different documents
- [ ] Ask: "Compare these documents"
- [ ] Ask: "What's common across all files?"
- [ ] AI references multiple sources
- [ ] Citations show different documents

### ✅ Complex Queries
- [ ] Ask detailed analytical questions
- [ ] Request specific information extraction
- [ ] Test reasoning across document content
- [ ] Verify accuracy of complex responses

### ✅ Document Types
**Medical Documents:**
- [ ] Upload medical report/lab results
- [ ] Ask medical questions
- [ ] Verify medical terminology understanding
- [ ] Check for healthcare compliance features

**Technical Documents:**
- [ ] Upload technical manual/specification
- [ ] Ask technical questions
- [ ] Test understanding of technical terms
- [ ] Verify appropriate technical responses

**Arabic Documents:**
- [ ] Upload Arabic PDF/text
- [ ] Ask questions in Arabic
- [ ] Verify Arabic content understanding
- [ ] Check Arabic-Arabic query/response

**Expected Result:** High-quality responses across different document types and complexity levels.

---

## ⚠️ Phase 7: Error Handling & Edge Cases

### ✅ Network Issues
- [ ] Turn off WiFi during upload
- [ ] Appropriate offline message shows
- [ ] App gracefully handles network errors
- [ ] Resume functionality works when online

### ✅ API Issues
- [ ] Test with invalid/expired API key
- [ ] Clear error message about API configuration
- [ ] App doesn't crash on API failures
- [ ] Retry mechanisms work

### ✅ Large Files
- [ ] Upload large PDF (10MB+)
- [ ] Upload progress shows correctly
- [ ] Large file processing completes
- [ ] Performance remains acceptable

### ✅ Memory & Performance
- [ ] Upload many documents (10+)
- [ ] App memory usage stays reasonable
- [ ] UI remains responsive
- [ ] No memory leaks observed

### ✅ Edge Cases
- [ ] Very long chat conversations (50+ messages)
- [ ] Rapid successive messages
- [ ] Special characters in questions
- [ ] Empty documents or corrupted files

**Expected Result:** Graceful error handling without crashes or data loss.

---

## 📊 Phase 8: Performance & User Experience

### ✅ Response Times
- [ ] Document upload: < 30 seconds for typical files
- [ ] AI responses: < 10 seconds for simple questions
- [ ] Voice recognition: Real-time text display
- [ ] UI transitions: Smooth and immediate

### ✅ User Experience
- [ ] Loading indicators provide clear feedback
- [ ] Error messages are helpful and actionable
- [ ] UI is intuitive without instructions
- [ ] App feels responsive and modern

### ✅ Accessibility
- [ ] VoiceOver works with main UI elements
- [ ] Text sizes respect accessibility settings
- [ ] Color contrast is sufficient
- [ ] Voice features work for accessibility users

**Expected Result:** Professional, responsive app suitable for healthcare environments.

---

## ✅ Final Acceptance Criteria

### 🎯 Critical Success Metrics
- [ ] **File Upload Success Rate**: 95%+ for supported formats
- [ ] **AI Response Accuracy**: Relevant responses with proper citations
- [ ] **Voice Recognition Accuracy**: 90%+ for clear speech in quiet environment
- [ ] **Crash Rate**: 0 crashes during normal usage scenarios
- [ ] **Bilingual Support**: Full functionality in both Arabic and English
- [ ] **Performance**: All operations complete within acceptable time limits

### 🏥 Healthcare-Specific Requirements
- [ ] Medical document processing works correctly
- [ ] Arabic medical terminology supported
- [ ] Citation accuracy for clinical information
- [ ] Professional UI suitable for healthcare settings

---

## 🚨 Common Issues & Quick Fixes

| Issue | Likely Cause | Solution |
|-------|--------------|----------|
| "API key not configured" | Environment variable not set | Set `GEMINI_API_KEY` in Xcode scheme |
| Voice recognition crashes | Missing permissions | Grant microphone + speech permissions |
| Upload fails | File format not supported | Check `AFHAMConfig.supportedFileTypes` |
| No AI responses | No documents uploaded | Upload at least one document first |
| Arabic text issues | RTL layout problems | Check language settings and locale |
| Slow responses | Network/API latency | Check internet connection |

---

## 📞 Support & Escalation

### ✅ Before Reporting Issues
- [ ] Followed all setup steps
- [ ] Tested on clean app install
- [ ] Verified API key configuration
- [ ] Checked device permissions

### 🆘 How to Report Issues
1. **Describe the exact steps** to reproduce
2. **Include error messages** (screenshots helpful)
3. **Specify device/simulator** and iOS version
4. **Note expected vs actual behavior**
5. **Attach relevant files** (if safe to share)

### 📧 Contact Information
- **Technical Issues**: Create GitHub issue with full details
- **Feature Requests**: Use GitHub discussions
- **Critical Bugs**: Include crash logs and reproduction steps

---

*✅ **Testing Complete!** If all items are checked, AFHAM is ready for deployment.*