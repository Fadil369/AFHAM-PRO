# AFHAM v1.1.0 - Onboarding & Testing Guide

**For**: Beta Testers, QA Team, and Early Users  
**Version**: 1.1.0  
**Last Updated**: November 14, 2025

---

## 📋 Testing Scope

This guide covers validation of three major new features:
1. 🎤 **Voice Assistant** - Document-grounded voice queries
2. 📸 **Intelligent Capture** - Multi-modal OCR scanning
3. 🎨 **Modular Workspace** - Content transformation pipelines

---

## 🎯 Testing Objectives

### Primary Goals
- ✅ Verify all 6 tabs are functional
- ✅ Confirm document auto-sync across features
- ✅ Validate bilingual support (AR/EN)
- ✅ Test end-to-end workflows
- ✅ Identify UI/UX issues

### Success Criteria
- All tabs accessible without crashes
- Voice queries return document-grounded answers
- Capture produces accurate OCR results
- Workspace transformations complete successfully
- Bilingual switching works seamlessly

---

## 📱 App Structure Overview

### Tab Bar Navigation

```
┌─────────────────────────────────────────┐
│              AFHAM v1.1.0               │
├─────────────────────────────────────────┤
│                                         │
│          [MAIN CONTENT AREA]            │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  📄   💬   🎤   📸   🎨   ⚙️           │
│ Docs Chat Voice Cap Work Set           │
└─────────────────────────────────────────┘
```

### Tab Details

| Icon | Tab | Purpose | New in v1.1? |
|------|-----|---------|--------------|
| 📄 | Documents | Library & file management | No (Enhanced) |
| 💬 | Chat | AI conversations | No (Enhanced) |
| 🎤 | Voice | Voice assistant | ✅ **NEW** |
| 📸 | Capture | Document scanning | ✅ **NEW** |
| 🎨 | Workspace | Content transformation | ✅ **NEW** |
| ⚙️ | Settings | App configuration | No (Enhanced) |

---

## 🧪 Test Scenarios

### Scenario 1: Voice Assistant Flow (15 minutes)

**Objective**: Validate voice queries retrieve document context

**Prerequisites**:
- Microphone permission granted
- Speech recognition enabled
- At least one document uploaded

**Steps**:
1. **Upload Test Document**
   ```
   Tab: Documents (📄)
   Action: Upload sample prescription/lab report
   Wait: Until "Processing complete" appears
   Screenshot: [DOC-001] Document uploaded
   ```

2. **Access Voice Tab**
   ```
   Tab: Voice (🎤)
   Expected: Microphone button visible
   Screenshot: [VOICE-001] Voice tab initial state
   ```

3. **Perform English Query**
   ```
   Action: Tap microphone button
   Speak: "What medications are in my prescription?"
   Wait: For response (< 5 seconds)
   Expected: 
     - Transcription appears
     - Response contains medication names
     - Citations reference uploaded document
     - TTS plays automatically
   Screenshot: [VOICE-002] English query result
   ```

4. **Test Arabic Query**
   ```
   Action: Clear previous result
   Speak: "ما هي الأدوية الموصوفة؟"
   Expected:
     - Arabic transcription displays (RTL)
     - Response in Arabic
     - Same document citations
     - Arabic TTS voice
   Screenshot: [VOICE-003] Arabic query result
   ```

5. **Verify Citations**
   ```
   Action: Tap citation link
   Expected: Navigate to source document
   Screenshot: [VOICE-004] Citation navigation
   ```

**Validation Points**:
- [ ] Microphone activates on button press
- [ ] Real-time transcription visible
- [ ] Response time < 5 seconds
- [ ] Citations link to correct documents
- [ ] TTS auto-plays in correct language
- [ ] Clear button resets state
- [ ] No crashes or freezes

**Known Issues to Watch For**:
- First query may take longer (cold start)
- Background music may interfere with TTS
- Arabic dialect variations affect accuracy

---

### Scenario 2: Intelligent Capture Flow (10 minutes)

**Objective**: Scan document and verify OCR accuracy

**Prerequisites**:
- Camera permission granted
- Physical document available (or test image)

**Steps**:
1. **Access Capture Tab**
   ```
   Tab: Capture (📸)
   Expected: Camera preview appears
   Screenshot: [CAPTURE-001] Capture tab initial
   ```

2. **Scan Prescription**
   ```
   Action: Point camera at prescription
   Expected:
     - Edge detection highlights document
     - Auto-focus adjusts
     - Quality indicator shows green
   Screenshot: [CAPTURE-002] Document detection
   ```

3. **Capture & Process**
   ```
   Action: Tap capture button
   Wait: OCR processing (5-10 seconds)
   Expected:
     - Processing indicator appears
     - Extracted text displays
     - Confidence score shown
   Screenshot: [CAPTURE-003] OCR results
   ```

4. **Review Medical Template**
   ```
   Expected:
     - Template type detected (e.g., "Prescription")
     - Structured fields extracted:
       * Patient name
       * Medication names
       * Dosages
       * Prescriber info
   Screenshot: [CAPTURE-004] Template extraction
   ```

5. **Save to Documents**
   ```
   Action: Tap "Save"
   Expected:
     - Document appears in Documents tab
     - Immediately available for Voice queries
   Screenshot: [CAPTURE-005] Saved document
   ```

**Validation Points**:
- [ ] Camera preview renders correctly
- [ ] Edge detection works reliably
- [ ] OCR accuracy > 90% for printed text
- [ ] Medical templates recognized
- [ ] Saved documents sync to Voice
- [ ] Multi-page scanning works
- [ ] Export options functional

**Test Documents**:
- ✅ Prescription (typed)
- ✅ Lab report
- ✅ Insurance card
- ⚠️ Handwritten notes (lower accuracy expected)

---

### Scenario 3: Workspace Transformation (20 minutes)

**Objective**: Transform document into presentation

**Prerequisites**:
- Document uploaded in Documents tab
- Familiarity with pipeline concepts

**Steps**:
1. **Open Workspace**
   ```
   Tab: Workspace (🎨)
   Expected: Canvas view with pipelines
   Screenshot: [WORKSPACE-001] Initial canvas
   ```

2. **Select Source Document**
   ```
   Action: Tap "Select Document"
   Choose: Medical training document
   Expected: Document loaded into pipeline
   Screenshot: [WORKSPACE-002] Document selected
   ```

3. **Configure Presentation Pipeline**
   ```
   Pipeline: Presentation Generator
   Settings:
     - Theme: Medical Blue
     - Layout: Auto-select
     - Language: Bilingual (AR/EN)
   Screenshot: [WORKSPACE-003] Pipeline config
   ```

4. **Generate Preview**
   ```
   Action: Tap "Generate"
   Wait: Processing (10-30 seconds)
   Expected:
     - Progress indicator
     - Slide previews appear
     - Bilingual content visible
   Screenshot: [WORKSPACE-004] Generated slides
   ```

5. **Review & Edit**
   ```
   Action: Open slide editor
   Modify: Add custom image
   Expected:
     - Visual editor opens
     - Asset recommendations shown
     - Real-time preview updates
   Screenshot: [WORKSPACE-005] Slide editing
   ```

6. **Export**
   ```
   Format: PDF
   Action: Tap "Export"
   Expected:
     - Export options appear
     - PDF generation succeeds
     - Share sheet appears
   Screenshot: [WORKSPACE-006] Export options
   ```

**Validation Points**:
- [ ] Pipeline selector works
- [ ] Document import succeeds
- [ ] Transformation completes without errors
- [ ] Preview quality acceptable
- [ ] Editor tools functional
- [ ] Export produces valid files
- [ ] Multiple formats supported

**Pipeline Types to Test**:
- ✅ Presentation Generator
- ✅ Script Creator
- ✅ Chatbot Knowledge Builder
- ✅ Localization Tools

---

### Scenario 4: Cross-Feature Integration (15 minutes)

**Objective**: Verify document auto-sync across all features

**Steps**:
1. **Upload via Capture**
   ```
   Tab: Capture (📸)
   Action: Scan a document
   Save: To library
   ```

2. **Query via Voice**
   ```
   Tab: Voice (🎤)
   Ask: "What document did I just capture?"
   Expected: Captured document content in response
   ```

3. **Transform in Workspace**
   ```
   Tab: Workspace (🎨)
   Action: Select same document
   Transform: To presentation
   Expected: Transformation succeeds
   ```

4. **Verify in Documents**
   ```
   Tab: Documents (📄)
   Expected:
     - Original scan visible
     - Workspace output visible
     - Both queryable via Voice
   ```

**Validation Points**:
- [ ] Capture → Voice sync < 10 seconds
- [ ] Documents → Workspace access immediate
- [ ] Workspace outputs appear in Documents
- [ ] All uploads queryable via Voice
- [ ] No duplicate entries
- [ ] Metadata preserved across features

---

### Scenario 5: Bilingual Workflow (10 minutes)

**Objective**: Test language switching and RTL support

**Steps**:
1. **English Mode**
   ```
   Settings: Language → English
   Tab: Voice
   Query: "List my documents"
   Expected: English response
   Screenshot: [LANG-001] English mode
   ```

2. **Switch to Arabic**
   ```
   Settings: Language → العربية
   Tab: Voice
   Query: "اعرض مستنداتي"
   Expected:
     - RTL text layout
     - Arabic response
     - Same documents listed
   Screenshot: [LANG-002] Arabic mode
   ```

3. **Test Mixed Content**
   ```
   Document: Bilingual medical report
   Query (AR): "اختصر التقرير"
   Expected:
     - Arabic summary
     - Preserves English medical terms
     - Citations in both languages
   Screenshot: [LANG-003] Bilingual response
   ```

**Validation Points**:
- [ ] Language switch immediate
- [ ] RTL layout correct for Arabic
- [ ] Voice recognition adapts to language
- [ ] TTS voice changes appropriately
- [ ] UI elements translate fully
- [ ] No text truncation or overlap

---

## 📸 Screenshot Checklist

### Required Screenshots for Onboarding

#### Welcome & Setup
- [ ] [ONBOARD-001] Welcome screen
- [ ] [ONBOARD-002] Permission requests
- [ ] [ONBOARD-003] Language selection
- [ ] [ONBOARD-004] API key setup (redacted)

#### Tab Overview
- [ ] [TAB-001] Documents tab (empty state)
- [ ] [TAB-002] Documents tab (with content)
- [ ] [TAB-003] Chat tab
- [ ] [TAB-004] Voice tab (listening)
- [ ] [TAB-005] Voice tab (response)
- [ ] [TAB-006] Capture tab (scanning)
- [ ] [TAB-007] Capture tab (results)
- [ ] [TAB-008] Workspace tab (canvas)
- [ ] [TAB-009] Workspace tab (editor)
- [ ] [TAB-010] Settings tab

#### Feature Details
- [ ] [FEATURE-001] Voice visualization animation
- [ ] [FEATURE-002] OCR edge detection
- [ ] [FEATURE-003] Pipeline selector
- [ ] [FEATURE-004] Citation display
- [ ] [FEATURE-005] Export options
- [ ] [FEATURE-006] Bilingual content side-by-side

#### Error States
- [ ] [ERROR-001] No microphone permission
- [ ] [ERROR-002] No camera permission
- [ ] [ERROR-003] Network error
- [ ] [ERROR-004] Processing failed
- [ ] [ERROR-005] Empty library

---

## 🎬 Demo Video Storyboard

### Video 1: Voice Assistant (60 seconds)

**Scene 1: Setup (10s)**
```
[Show] App home screen
[Tap] Documents tab
[Upload] Sample prescription
[Text] "Documents auto-sync to Voice Assistant"
```

**Scene 2: English Query (20s)**
```
[Tap] Voice tab
[Show] Microphone button pulse
[Speak] "What medications am I taking?"
[Show] Transcription appear
[Show] Response with citations
[Highlight] Document link
```

**Scene 3: Arabic Query (20s)**
```
[Clear] Previous result
[Switch] Language indicator to Arabic
[Speak] "ما هي الأدوية الموصوفة؟"
[Show] Arabic transcription (RTL)
[Show] Arabic response
[Play] Audio icon indicating TTS
```

**Scene 4: Citation Navigation (10s)**
```
[Tap] Citation link
[Transition] To source document
[Highlight] Referenced text
[Text] "Instant verification of answers"
```

### Video 2: Intelligent Capture (45 seconds)

**Scene 1: Scanning (15s)**
```
[Show] Capture tab
[Point] Camera at prescription
[Show] Edge detection overlay
[Tap] Capture button
[Show] Processing animation
```

**Scene 2: Results (15s)**
```
[Display] Extracted text
[Show] Template fields:
  - Patient: John Doe
  - Medication: Metformin 500mg
  - Prescriber: Dr. Smith
[Show] Confidence: 96%
```

**Scene 3: Save & Query (15s)**
```
[Tap] Save button
[Switch] To Voice tab
[Speak] "What did I just scan?"
[Show] Response references captured prescription
[Text] "Instant document intelligence"
```

### Video 3: Workspace Transformation (60 seconds)

**Scene 1: Source Selection (15s)**
```
[Show] Workspace tab
[Tap] "New Pipeline"
[Select] Medical training document
[Choose] "Presentation Generator"
```

**Scene 2: Configuration (15s)**
```
[Show] Pipeline settings
[Select] Theme: Medical Blue
[Toggle] Bilingual: ON
[Tap] "Generate"
```

**Scene 3: Preview (20s)**
```
[Show] Processing progress
[Display] Generated slides
[Swipe] Through preview
[Highlight] Bilingual content
```

**Scene 4: Export (10s)**
```
[Tap] "Export"
[Select] PDF format
[Show] Share sheet
[Text] "Professional content, instantly"
```

---

## 📊 Bug Report Template

### Issue Report Form

```markdown
## Bug Report

**Severity**: [ ] Critical  [ ] High  [ ] Medium  [ ] Low

**Feature**: [ ] Voice  [ ] Capture  [ ] Workspace  [ ] Documents  [ ] Chat  [ ] Settings

**Environment**:
- iOS Version: 
- Device Model: 
- AFHAM Version: 1.1.0
- Language: [ ] English  [ ] Arabic

**Description**:
[Clear description of the issue]

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Behavior**:
[What should happen]

**Actual Behavior**:
[What actually happens]

**Screenshots/Videos**:
[Attach if available]

**Additional Context**:
[Any other relevant information]

**Workaround** (if found):
[Temporary solution]
```

---

## ✅ Final Testing Checklist

### Pre-Release Validation

#### Functional Tests
- [ ] All 6 tabs accessible
- [ ] Tab switching smooth and crash-free
- [ ] Voice queries return accurate results
- [ ] Capture OCR accuracy > 85%
- [ ] Workspace transformations complete
- [ ] Documents sync across features
- [ ] Export produces valid files

#### Language Tests
- [ ] English UI fully functional
- [ ] Arabic UI fully functional (RTL)
- [ ] Language switching immediate
- [ ] Voice recognition accurate for both
- [ ] TTS quality acceptable for both
- [ ] No truncated text in either language

#### Performance Tests
- [ ] App launch time < 3 seconds
- [ ] Voice response time < 5 seconds
- [ ] OCR processing < 10 seconds per page
- [ ] Workspace generation < 30 seconds
- [ ] Smooth scrolling in all views
- [ ] No memory leaks after extended use

#### Integration Tests
- [ ] Capture → Voice sync works
- [ ] Documents → Workspace access works
- [ ] Workspace → Documents save works
- [ ] All uploads queryable via Voice
- [ ] Citations link correctly
- [ ] Multi-document context synthesis

#### Edge Cases
- [ ] Empty library state handled
- [ ] Network offline gracefully handled
- [ ] Permissions denied with clear prompts
- [ ] Large documents (100+ pages) work
- [ ] Concurrent operations don't conflict
- [ ] Background/foreground transitions stable

---

## 📞 Support Contacts

**For Testers**:
- **Slack**: #afham-beta-testing
- **Email**: testing@brainsait.com
- **Bug Reports**: [GitHub Issues](https://github.com/Fadil369/AFHAM-PRO/issues)

**For Developers**:
- **Technical Lead**: eng@brainsait.com
- **Product Manager**: product@brainsait.com

**Emergency**:
- **Critical Bugs**: urgent@brainsait.com
- **Phone**: +966-XXX-XXXX

---

## 📅 Testing Timeline

- **Week 1**: Core functionality validation
- **Week 2**: Bilingual & accessibility testing
- **Week 3**: Performance & stress testing
- **Week 4**: Final QA & bug fixes
- **Target Release**: December 1, 2025

---

**Thank you for testing AFHAM v1.1.0!**  
Your feedback helps us build better healthcare technology.

