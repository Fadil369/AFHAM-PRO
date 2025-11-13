# AFHAM (أفهم) - Advanced Document Understanding
*BrainSAIT Healthcare AI Platform for iOS*

[![Build Status](https://github.com/Fadil369/AFHAM-PRO/workflows/iOS%20CI%2FCD%20Pipeline/badge.svg)](https://github.com/Fadil369/AFHAM-PRO/actions)
[![Security Scan](https://github.com/Fadil369/AFHAM-PRO/workflows/Security%20&%20Vulnerability%20Scanning/badge.svg)](https://github.com/Fadil369/AFHAM-PRO/actions)
[![PDPL Compliant](https://img.shields.io/badge/PDPL-Compliant-green.svg)](https://sdaia.gov.sa/en/NDMO/Pages/default.aspx)
[![NPHIES Ready](https://img.shields.io/badge/NPHIES-FHIR%20R4-blue.svg)](https://nphies.sa)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![iOS 17.0+](https://img.shields.io/badge/iOS-17.0%2B-blue.svg)](https://developer.apple.com/ios/)

## 🌟 Overview

AFHAM is a cutting-edge iOS application that revolutionizes document analysis and understanding using advanced AI capabilities. Built with SwiftUI and powered by Google's Gemini AI, AFHAM provides intelligent document processing, voice interaction, and content generation with full Arabic and English support.

### Key Features

- 📄 **Smart Document Analysis**: AI-powered understanding of complex documents
- 🗣️ **Voice Assistant**: Natural language interaction in Arabic and English  
- ✍️ **Content Generation**: Create various content types from your documents
- 🌐 **Bilingual Support**: Complete Arabic/English localization with RTL support
- 🏥 **Healthcare Compliant**: NPHIES/FHIR R4 compliant for medical documents
- 🛡️ **Privacy First**: PDPL compliant with AES-256 encryption
- 📱 **Modern iOS**: Built with SwiftUI for iOS 17+

## 🚀 Quick Start

### Prerequisites

- iOS 17.0 or later
- Xcode 15.0+ (for development)
- Google Gemini API key
- Apple Developer account (for deployment)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Fadil369/AFHAM-PRO.git
cd AFHAM-PRO
```

2. **Install dependencies**
```bash
swift package resolve
```

3. **Configure API keys**
```bash
cp Config/Environment.plist.template Config/Environment.plist
# Edit Environment.plist with your Gemini API key
```

4. **Open in Xcode**
```bash
open AFHAM.xcodeproj
```

5. **Build and run**
```bash
⌘ + R  # Or use Xcode's run button
```

## 🏗️ Architecture

### Project Structure

```
AFHAM/
├── App/                          # App configuration and entry point
│   ├── afham_entry.swift        # Main app entry point
│   └── Info.plist               # App configuration with privacy descriptions
├── Core/                        # Core managers and utilities
│   ├── afham_main.swift         # Document and voice managers
│   ├── AFHAMConstants.swift     # App-wide constants and configuration
│   └── LocalizationManager.swift # Bilingual localization system
├── Features/                    # Feature-specific modules
│   ├── Chat/                    # Chat interface and voice interaction
│   ├── Content/                 # Content generation capabilities
│   ├── UI/                      # Main UI components
│   ├── Advanced/                # Advanced features (offline, collaboration)
│   └── Healthcare/              # NPHIES/FHIR compliance
├── Resources/                   # Assets and localizations
│   ├── Assets.xcassets/         # Images, colors, and icons
│   └── Localizations/           # Arabic and English string resources
├── Tests/                       # Comprehensive test suite
├── Documentation/               # User and developer guides
└── .github/workflows/           # CI/CD pipeline configuration
```

### Technology Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Frontend** | SwiftUI | Native iOS UI framework |
| **AI Engine** | Google Gemini 2.0 Flash | Document analysis and generation |
| **Voice** | Speech Framework | Voice recognition and synthesis |
| **Storage** | Core Data + Keychain | Secure local data storage |
| **Networking** | URLSession | API communication |
| **Security** | CryptoKit | AES-256 encryption |
| **Compliance** | FHIR R4 | Healthcare data standards |
| **Localization** | Foundation | Arabic/English support |

## 📱 Features

### Document Management
- **Supported Formats**: PDF, Word, Excel, PowerPoint, text files
- **File Size Limits**: Up to 100MB (enterprise) / 50MB (pro) / 10MB (free)
- **Smart Processing**: Automatic content extraction and indexing
- **Secure Storage**: Encrypted local storage with cloud backup

### Intelligent Chat
- **Natural Queries**: Ask questions in Arabic or English
- **Contextual Answers**: AI provides relevant responses with citations
- **Voice Interaction**: Hands-free operation with voice commands
- **Multi-turn Conversations**: Maintain context across questions

### Content Generation
- **10+ Content Types**: Blog posts, emails, reports, presentations, and more
- **Customizable Output**: Specify tone, length, and target audience
- **Multilingual**: Generate content in Arabic or English
- **Professional Quality**: Business-ready content with proper formatting

### Healthcare Integration
- **FHIR R4 Support**: Standard healthcare data exchange
- **NPHIES Compliance**: Saudi health information exchange platform
- **BrainSAIT OID**: Official namespace (1.3.6.1.4.1.61026)
- **Audit Trails**: Complete compliance logging

## 🔒 Privacy & Security

AFHAM prioritizes user privacy and data security with comprehensive protection measures:

### Data Protection (PDPL Compliant)
- **AES-256 Encryption**: All sensitive data encrypted locally
- **Minimal Data Collection**: Only essential data is processed
- **User Consent**: Explicit consent for all data processing
- **Data Retention**: Configurable retention periods (30-90 days)
- **Right to Deletion**: Complete data removal on request

### Security Features
- **Keychain Storage**: Secure API key storage
- **SSL/TLS**: Encrypted network communication
- **Code Obfuscation**: Protected against reverse engineering
- **Jailbreak Detection**: Enhanced security for sensitive data

### Healthcare Compliance
- **HIPAA Ready**: Secure handling of health information
- **NPHIES Integration**: Saudi health platform compatibility
- **Audit Logging**: Complete access and modification tracking
- **Data Anonymization**: Patient privacy protection

## 🌍 Localization

AFHAM provides comprehensive bilingual support:

### Languages
- **Arabic**: Primary language with full RTL support
- **English**: Complete secondary language support
- **Cultural Adaptation**: Region-specific content and formats

### Features
- **Dynamic Switching**: Change language without app restart
- **Voice Recognition**: Both languages supported
- **Content Generation**: Bilingual output capabilities
- **UI Elements**: All interface elements localized

## 🧪 Testing

### Test Coverage
- **Unit Tests**: >80% code coverage requirement
- **Integration Tests**: API and workflow testing
- **UI Tests**: User interface and accessibility testing
- **Performance Tests**: Response time and memory usage
- **Security Tests**: Vulnerability scanning and compliance

### Continuous Integration
```bash
# Run all tests
xcodebuild test -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test plans
xcodebuild test -scheme AFHAM -testPlan UnitTestPlan
xcodebuild test -scheme AFHAM -testPlan IntegrationTestPlan
```

## 🚀 Deployment

### Build Requirements
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0
- **Swift Version**: 5.9
- **Provisioning Profile**: Apple Developer Program membership

### Deployment Targets
- **Development**: Local testing and debugging
- **Staging**: Internal testing via TestFlight
- **Production**: App Store distribution

### Automated Deployment
```bash
# Deploy to TestFlight
./scripts/deploy.sh staging

# Deploy to production
./scripts/deploy.sh production
```

## 📊 Performance

### Benchmarks
- **Document Processing**: 2-5 seconds for typical documents
- **Query Response**: <2 seconds average
- **Voice Recognition**: <1 second transcription
- **Memory Usage**: <150MB typical, <300MB peak
- **Battery Impact**: Minimal background usage

### Optimization
- **Lazy Loading**: Content loaded on demand
- **Background Processing**: Non-blocking operations
- **Memory Management**: Automatic resource cleanup
- **Network Efficiency**: Optimized API calls

## 🤝 Contributing

We welcome contributions to AFHAM! Please follow our guidelines:

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Follow Swift coding standards
4. Add comprehensive tests
5. Submit pull request

### Code Quality
- **SwiftLint**: Automated code style checking
- **Documentation**: Comprehensive code documentation
- **Testing**: Maintain >80% test coverage
- **Security**: Follow security best practices

### Review Process
- **Automated CI**: All tests must pass
- **Code Review**: Peer review required
- **Security Scan**: Automated vulnerability checking
- **Compliance Check**: PDPL and NPHIES validation

## 📚 Documentation

### User Documentation
- **[User Guide](AFHAM/Documentation/UserGuide.md)**: Complete user manual
- **[Setup Instructions](afham_setup.md)**: Installation and configuration
- **[API Reference](afham_readme.md)**: Implementation details

### Developer Documentation
- **[Developer Guide](AFHAM/Documentation/DeveloperGuide.md)**: Technical implementation
- **[Architecture Guide](afham_project_config.md)**: System architecture
- **[Repository Guidelines](AGENTS.md)**: Development standards

## 📈 Roadmap

### Upcoming Features
- **Advanced Analytics**: Usage insights and performance metrics
- **Team Collaboration**: Multi-user document analysis
- **Offline Mode**: Full offline document processing
- **Additional Languages**: French, Spanish, and more
- **Advanced AI**: GPT-4 and Claude integration

### Healthcare Enhancements
- **Clinical Decision Support**: AI-powered medical insights
- **Drug Interaction Checking**: Medication safety analysis
- **Lab Result Analysis**: Automated interpretation
- **Patient Data Integration**: Electronic health records

## 🎯 Support

### Getting Help
- **📧 Email**: support@brainsait.com
- **📚 Documentation**: afham.brainsait.io/docs
- **💬 Community**: afham.brainsait.io/community
- **🐛 Issues**: GitHub Issues for bug reports

### Enterprise Support
- **🏢 Enterprise Sales**: enterprise@brainsait.com
- **🤝 Partnerships**: partners@brainsait.com
- **📞 Phone Support**: Available for Enterprise customers
- **🔧 Custom Integration**: Professional services available

## 📄 License

AFHAM is proprietary software developed by BrainSAIT Technologies. All rights reserved.

### Commercial Licensing
- **Individual**: App Store purchase
- **Business**: Contact for enterprise licensing
- **Healthcare**: Special healthcare industry pricing
- **Government**: Government and institutional licensing

## 🏢 About BrainSAIT

BrainSAIT Technologies is a leading healthcare AI company specializing in Arabic language processing and NPHIES-compliant healthcare solutions. We're dedicated to advancing healthcare through innovative AI technologies while ensuring the highest standards of privacy and security.

### Company Information
- **Founded**: 2020
- **Headquarters**: Riyadh, Saudi Arabia
- **Specialization**: Healthcare AI, Arabic NLP, FHIR Integration
- **Certification**: ISO 27001, NPHIES Certified, PDPL Compliant

### Contact Information
- **Website**: [afham.brainsait.io](https://afham.brainsait.io)
- **Email**: info@brainsait.com
- **LinkedIn**: [BrainSAIT Technologies](https://linkedin.com/company/brainsait)
- **Twitter**: [@BrainSAIT](https://twitter.com/brainsait)

---

**© 2024 BrainSAIT Technologies. All rights reserved.**

*AFHAM (أفهم) - Transforming healthcare through intelligent document understanding*