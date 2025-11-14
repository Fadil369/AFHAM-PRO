# Modular Docs Workspace Canvas

Comprehensive document transformation and repurposing platform for AFHAM, featuring AI-powered content creation, localization, and multi-channel publishing.

## 🎯 Overview

The Modular Docs Workspace Canvas transforms the traditional document workspace into an intelligent, visual canvas where documents can be seamlessly repurposed across multiple formats, languages, and platforms. Each document gets its own interactive panel with quick transformation actions, live previews, and collaborative review capabilities.

## ✨ Key Features

### 1. **Modular Panel System**
- **Individual Document Panels**: Each uploaded file gets its own dedicated panel
- **Quick Actions**: One-click transformations (Summarize, Translate, Convert to Slides, Generate Script)
- **Live Previews**: See repurposed output side-by-side with source content
- **Flexible Layouts**: Grid, list, or custom canvas arrangements
- **Panel Controls**: Expand/collapse, resize, reposition, and remove

### 2. **Multi-Output Pipelines**
- **Chain Transformations**: Link multiple operations (e.g., Summarize → Translate → Social Post)
- **Visual Stepper UI**: Horizontal pipeline view showing each stage
- **Editable Stages**: Modify output at any pipeline stage
- **8 Pre-Configured Presets**:
  - Investor Brief
  - Patient Leaflet
  - Training Slide Deck
  - Social Media Campaign
  - Multilingual FAQ
  - Compliance Report
  - Podcast Script
  - WhatsApp Brief

### 3. **Modal-Specific Editors**

#### **Slide Deck Editor**
- Split-screen: thumbnails, editor, live preview
- Multiple themes (Professional, Training, Medical, Creative)
- Layout templates (Title, Title+Body, Two-Column, Image+Text)
- Speaker notes and presenter view
- Auto-formatting for presentations

#### **Script Editor (Teleprompter)**
- Edit mode with section management
- Teleprompter mode with auto-scroll
- Timing calculations (words per minute)
- Speaker annotations
- Duration tracking per section
- Configurable font size and scroll speed

#### **Chatbot Snippet Editor**
- Structured fields: Intent, Response, Alternatives
- Citation management
- Metadata (category, tags, confidence score)
- Validation status workflow (Pending → Approved/Rejected)
- JSON export for chatbot systems

### 4. **Localization Layers**
- **Side-by-Side Panels**: Arabic and English synchronized
- **Synchronized Scrolling**: Navigate both languages together
- **Tone Switching**: Instant adjustment (Formal, Friendly, Clinical, Conversational)
- **Terminology Glossary**:
  - Lock medical terms for consistency
  - Context-aware suggestions
  - Import/export glossaries
- **TTLINC Validation**:
  - **T**erminology compliance
  - **T**one appropriateness
  - **L**anguage quality
  - **I**ntent preservation
  - **N**on-compliant wording detection
  - **C**itation accuracy

### 5. **Platform-Ready Exports**

Export templates for 8 major platforms:

| Platform | Format | Auto-Fill Features |
|----------|--------|-------------------|
| **LinkedIn Carousel** | Multi-slide | Title, hashtags, CTAs |
| **WhatsApp Brief** | 500-char text | Brief summary, footers |
| **Apple Pages** | Rich document | Metadata, branding |
| **FHIR Patient Instructions** | JSON | Healthcare-compliant format |
| **PDF Document** | PDF-ready | Headers, footers, formatting |
| **HTML Page** | Standalone web | CSS, metadata, responsive |
| **CMS Push** | JSON API | Structured data, tags |
| **Email Template** | Email format | Subject, body, signatures |

**Features**:
- One-click export with metadata auto-fill
- Compliance footers (PDPL, medical disclaimers)
- Copy to clipboard or share directly
- Customizable templates per platform

### 6. **Collaborative Review Mode**

#### **Comments System**
- **Inline Comments**: Tag specific paragraphs or sections
- **Comment Types**: Questions, Suggestions, Issues, Praise
- **Status Tracking**: Open, In Progress, Resolved
- **Threading**: Reply to comments
- **Filters**: View by status (All, Open, Resolved)

#### **Revision History**
- **Version Tracking**: Automatic version numbering
- **Change Descriptions**: Document what changed
- **Restore Capability**: Revert to any previous version
- **Branch Variants**: Create alternative versions for different audiences
- **Diff View**: Compare versions side-by-side

### 7. **Smart Asset Recommendations**

AI-powered detection and transformation suggestions:

#### **Detected Asset Types**
- 📊 **Tables** → Bar charts, data grids, dashboard cards
- 📸 **Figures** → Infographics, diagrams, icon sets
- 💬 **Quotes** → Pull quotes, testimonials, social cards
- 📈 **Charts** → Interactive visualizations, trend lines

#### **Recommendation Engine**
- Confidence scoring (0-100%)
- Multiple transformation options per asset
- BrainSAIT brand-compliant visuals
- PDPL-safe placeholder generation
- Preview before applying

### 8. **Validation & Guidance Checklist**

Comprehensive pre-deployment validation:

#### **Validation Categories**

1. **Localization** ✓
   - Translation completeness
   - Glossary term application
   - RTL support (Arabic)

2. **Citations** ✓
   - Coverage ≥ 70%
   - Citation accuracy
   - Format compliance

3. **Privacy & Compliance** ✓
   - PDPL compliance (Saudi regulations)
   - PII redaction
   - Consent documentation

4. **Tone & Language** ✓
   - Tone appropriateness
   - No prohibited medical terms
   - Readability score

5. **Technical Quality** ✓
   - Valid formatting
   - Working links
   - Complete metadata

#### **Export Summary**
- Deployment readiness indicator
- Channels breakdown
- Language coverage
- Approval status
- Validation report export

## 🏗️ Architecture

### File Structure

```
AFHAM/Features/DocsWorkspace/ModularCanvas/
├── ModularCanvasArchitecture.swift    # Core data models
├── ModularCanvasViewModel.swift       # State management
├── ModularCanvasView.swift            # Main UI
├── DocumentPanelView.swift            # Panel components
├── PipelineStepperView.swift          # Pipeline UI
├── ModalEditors/
│   ├── SlideEditorView.swift         # Presentation editor
│   ├── ScriptEditorView.swift        # Teleprompter editor
│   └── ChatbotEditorView.swift       # Chatbot editor
├── LocalizationView.swift             # Translation UI
├── ExportTemplatesView.swift          # Platform exports
├── CollaborativeReviewView.swift      # Comments & revisions
├── SmartAssetRecommendationsView.swift # Asset detection
├── ValidationChecklistView.swift      # Quality checks
└── README.md                          # This file
```

### Core Models

#### **DocumentPanel**
```swift
struct DocumentPanel: Identifiable {
    let id: UUID
    var documentMetadata: DocumentMetadata
    var position: CGPoint
    var quickActions: [QuickAction]
    var activeTransformations: [TransformationPipeline]
    var previewMode: PreviewMode
    var comments: [Comment]
    var revisionHistory: [Revision]
}
```

#### **TransformationPipeline**
```swift
struct TransformationPipeline: Identifiable {
    let id: UUID
    var name: String
    var stages: [TransformationStage]
    var currentStageIndex: Int
    var output: TransformationOutput?
    var preset: PipelinePreset?
}
```

## 🚀 Usage

### Basic Workflow

1. **Upload Documents**
   ```swift
   // Documents are automatically added as panels
   // via GeminiFileSearchManager integration
   ```

2. **Create Transformation**
   ```swift
   // Option 1: Quick Action
   viewModel.executeQuickAction(.summarize, on: panel)

   // Option 2: Pipeline Preset
   viewModel.createPipeline(preset: .investorBrief, for: panel)
   ```

3. **Review & Validate**
   ```swift
   // Validation runs automatically
   // View checklist in right panel
   ```

4. **Export**
   ```swift
   // Export to platform
   let url = viewModel.exportPipeline(pipeline, as: template)
   ```

### Integration Example

```swift
import SwiftUI

struct DocsView: View {
    @EnvironmentObject var fileSearchManager: GeminiFileSearchManager

    var body: some View {
        ModularCanvasView(fileSearchManager: fileSearchManager)
    }
}
```

## 🎨 Design System

### BrainSAIT Brand Colors
- Primary Blue: `#007AFF`
- Success Green: `#34C759`
- Warning Orange: `#FF9500`
- Error Red: `#FF3B30`
- Purple (Assets): `#AF52DE`

### Typography
- Headlines: SF Pro Display Bold
- Body: SF Pro Text Regular
- Code: SF Mono Regular

### Spacing
- Panel spacing: 16pt
- Section spacing: 24pt
- Component padding: 12-16pt

## 🔌 API Integration

### Gemini File Search Integration

All transformations use the existing `GeminiFileSearchManager`:

```swift
// Summarize
let result = try await fileSearchManager.queryDocuments(
    query: "Summarize this document comprehensively",
    fileIDs: [documentMetadata.geminiFileID],
    storeID: documentMetadata.fileSearchStoreID
)

// Translate
let result = try await fileSearchManager.queryDocuments(
    query: "Translate to Arabic maintaining tone",
    fileIDs: [documentMetadata.geminiFileID],
    storeID: documentMetadata.fileSearchStoreID
)
```

## 🌐 Localization

### Supported Languages
- **English** (en): Left-to-right, formal/conversational tones
- **Arabic** (ar): Right-to-left, formal/friendly/clinical tones

### Terminology Management
- Medical glossary with 500+ locked terms
- Context-aware suggestions
- Import from CSV/JSON
- Export for translation services

## ✅ Quality Assurance

### Validation Levels
1. **Pre-Transform**: Source content quality
2. **Post-Transform**: Output accuracy
3. **Pre-Export**: Platform compliance
4. **Pre-Deployment**: Full checklist

### Compliance Standards
- **PDPL**: Saudi Personal Data Protection Law
- **TTLINC**: Terminology, Tone, Language, Intent, Non-compliance, Citations
- **FHIR**: Healthcare data interoperability
- **Accessibility**: WCAG 2.1 AA compliance

## 📊 Performance Metrics

### Target Performance
- Panel render: < 100ms
- Quick action execution: 2-5 seconds
- Pipeline processing: 5-15 seconds per stage
- Export generation: < 2 seconds

### Optimization Strategies
- Lazy loading for panels
- Caching for transformations
- Incremental validation
- Background processing for exports

## 🔒 Security & Privacy

### Data Handling
- All transformations processed via secure Gemini API
- No local storage of sensitive content
- PII detection and redaction
- Encrypted transmission (TLS 1.3)

### Access Control
- Role-based permissions (Free, Pro, Enterprise)
- Comment author tracking
- Revision audit trail
- Export logging

## 🧪 Testing

### Unit Tests
- ViewModel state management
- Pipeline execution logic
- Validation checks
- Export formatting

### Integration Tests
- Gemini API integration
- File upload/download
- Multi-language support
- Platform exports

### UI Tests
- Panel interactions
- Editor workflows
- Localization panels
- Comment system

## 📈 Future Enhancements

### Planned Features
- [ ] Real-time collaboration (multi-user)
- [ ] AI-powered content suggestions
- [ ] Version control with Git integration
- [ ] Custom pipeline builder (drag-and-drop)
- [ ] Analytics dashboard
- [ ] Template marketplace
- [ ] Voice-to-text for scripts
- [ ] Advanced image generation (DALL-E integration)
- [ ] Workflow automation
- [ ] API for third-party integrations

### Under Consideration
- Offline mode with local transformations
- Custom ML models for specialized content
- Integration with Google Docs/Microsoft Office
- Mobile companion app (iOS/Android)
- Browser extension

## 🤝 Contributing

### Development Guidelines
1. Follow SwiftUI best practices
2. Use `@MainActor` for view models
3. Implement error handling with `AFHAMError`
4. Add inline documentation
5. Write unit tests for new features
6. Update this README for major changes

### Code Style
- Use SwiftLint configuration
- 4-space indentation
- Mark sections with `// MARK: -`
- Maximum line length: 120 characters

## 📝 License

This feature is part of AFHAM and follows the project's licensing terms.

## 📞 Support

For issues, questions, or feature requests:
- **Email**: support@brainsait.com
- **Docs**: https://docs.brainsait.com/afham/modular-canvas
- **Slack**: #afham-workspace

---

**Version**: 1.0.0
**Last Updated**: November 2025
**Maintainer**: AFHAM Development Team
**Status**: Production Ready ✅
