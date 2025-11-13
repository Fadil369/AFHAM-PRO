# AFHAM - Supported Document Types

## Overview

AFHAM supports a wide variety of document formats for analysis and processing. This document provides details about supported file types and their configurations.

## Supported File Formats

### Document Formats

| Format | Extension | UTI | Support Level |
|--------|-----------|-----|---------------|
| **PDF** | .pdf | com.adobe.pdf | ✅ Full Support |
| **Microsoft Word** | .docx, .doc | org.openxmlformats.wordprocessingml.document | ✅ Full Support |
| **Microsoft Excel** | .xlsx, .xls | org.openxmlformats.spreadsheetml.sheet | ✅ Full Support |
| **Microsoft PowerPoint** | .pptx, .ppt | org.openxmlformats.presentationml.presentation | ✅ Full Support |
| **Plain Text** | .txt | public.plain-text | ✅ Full Support |
| **Rich Text** | .rtf | public.rtf | ✅ Full Support |
| **HTML** | .html, .htm | public.html | ✅ Full Support |
| **XML** | .xml | public.xml | ✅ Full Support |
| **JSON** | .json | public.json | ✅ Full Support |
| **Markdown** | .md | net.daringfireball.markdown | ✅ Full Support |
| **CSV** | .csv | public.comma-separated-values-text | ✅ Full Support |

## Document Handling Configuration

### Opening Documents in Place

```xml
<key>LSSupportsOpeningDocumentsInPlace</key>
<false/>
```

**AFHAM copies documents for analysis** rather than editing them in place. This ensures:
- Original documents remain unchanged
- PDPL compliance (data is encrypted locally)
- Better security and audit trail
- No accidental modifications

### Document Role

All documents are opened with **Viewer** role:
- **CFBundleTypeRole**: Viewer
- **LSHandlerRank**: Alternate

This means AFHAM:
- Can read and analyze documents
- Does not modify original files
- Is an alternate handler (not default)
- Respects user's preferred document apps

## File Size Limits

| Plan | Maximum File Size | Notes |
|------|------------------|-------|
| **Free** | 10 MB | Basic document analysis |
| **Pro** | 50 MB | Advanced features |
| **Enterprise** | 100 MB | Full feature set |

## Best Practices

### 1. Supported Content

✅ **Recommended**:
- Text-based documents (PDFs, Word, etc.)
- Structured data (Excel, CSV, JSON)
- Web content (HTML, XML)
- Source code (Markdown, text files)

⚠️ **Limited Support**:
- Scanned PDFs (OCR quality depends on scan)
- Image-heavy documents (text extraction may be limited)
- Password-protected files (must be unlocked first)

❌ **Not Supported**:
- Encrypted documents without password
- Corrupted files
- Proprietary formats not listed above

### 2. Document Preparation

For best results:
- **PDFs**: Use text-based PDFs (not scanned images)
- **Word/Excel**: Save in modern formats (.docx, .xlsx)
- **Large Files**: Compress or split if near size limit
- **Multiple Documents**: Upload one at a time for accuracy

### 3. Security Considerations

- **Sensitive Documents**: Encrypted locally with AES-256
- **PDPL Compliance**: Automatic data retention policies
- **Healthcare Data**: FHIR/NPHIES compliance for medical records
- **Audit Trail**: All document access is logged

## Healthcare-Specific Formats

### FHIR Resources

AFHAM supports FHIR R4 resources in JSON/XML:

```json
{
  "resourceType": "Patient",
  "id": "example",
  "name": [{"given": ["محمد"], "family": "أحمد"}]
}
```

### Clinical Documents

- **CDA (Clinical Document Architecture)**: XML format
- **HL7 Messages**: v2.x and v3 formats
- **DICOM**: Metadata extraction (image analysis coming soon)

## Document Import Methods

### 1. File Picker

```swift
// User selects file from Files app
.fileImporter(isPresented: $showingImporter,
              allowedContentTypes: [.pdf, .text, .plainText])
```

### 2. Share Sheet

- Share documents from other apps
- AFHAM appears in Share menu
- Automatic format detection

### 3. Drag & Drop (iPad)

- Drag documents from Files app
- Drop into AFHAM interface
- Multi-file support

### 4. URL Schemes

```
afham://open?file=document.pdf
```

## Technical Details

### UTI (Uniform Type Identifiers)

AFHAM uses standard Apple UTIs for document types:

```swift
// Example UTI usage
let supportedTypes: [UTType] = [
    .pdf,                    // com.adobe.pdf
    .plainText,              // public.plain-text
    .html,                   // public.html
    .json,                   // public.json
    // ... more types
]
```

### Content Type Detection

AFHAM automatically detects file types using:
1. File extension
2. MIME type
3. Content analysis
4. UTI validation

## Error Handling

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| File too large | Exceeds plan limit | Upgrade plan or compress file |
| Unsupported format | Format not in list | Convert to supported format |
| Corrupted file | File damaged | Try recovering or use backup |
| No text content | Image-only PDF | Use OCR or text extraction tool |
| Permission denied | File access restricted | Check file permissions |

### Error Messages

AFHAM provides bilingual error messages:

**English**: "Unable to open document. File format not supported."
**Arabic**: "تعذر فتح المستند. صيغة الملف غير مدعومة."

## Future Support

### Planned Formats (v1.1+)

- [ ] **Images**: .jpg, .png, .heic (with OCR)
- [ ] **Audio**: .mp3, .m4a (transcription)
- [ ] **Video**: .mp4, .mov (subtitle extraction)
- [ ] **Archives**: .zip, .rar (batch processing)
- [ ] **CAD**: .dwg, .dxf (engineering documents)

### Advanced Features

- [ ] OCR for scanned documents
- [ ] Handwriting recognition
- [ ] Multi-language document detection
- [ ] Automatic translation
- [ ] Document comparison

## API Integration

### Gemini AI Support

AFHAM uses Google Gemini 2.0 Flash for:
- Text extraction
- Document understanding
- Content analysis
- Question answering

### Supported Input Formats

Gemini API accepts:
- Plain text (up to 1M tokens)
- PDF (text extraction)
- Images (OCR in progress)

## Compliance & Standards

### PDPL (Saudi Arabia)

- All documents encrypted locally
- User consent for processing
- Data retention policies enforced
- Audit logs maintained

### HIPAA Ready

- Healthcare documents handled securely
- PHI encrypted at rest and in transit
- Access controls enforced
- Audit trail for medical records

### FHIR R4

- Standard healthcare data exchange
- NPHIES compatibility
- Saudi healthcare system integration

## Support

For document format issues:
- **Email**: support@brainsait.com
- **Documentation**: https://docs.brainsait.com/afham/documents
- **Community**: https://community.brainsait.com

---

**© 2025 BrainSAIT Technologies Ltd.**

*Supporting intelligent document understanding across formats*
