# AFHAM - Complete Build & Deployment Guide

*Production-Ready Build Instructions for BrainSAIT Healthcare AI Platform*

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Development Build](#development-build)
4. [Testing](#testing)
5. [Staging/TestFlight](#stagingtestflight)
6. [Production Build](#production-build)
7. [App Store Submission](#app-store-submission)
8. [Troubleshooting](#troubleshooting)
9. [CI/CD Automation](#cicd-automation)

---

## Prerequisites

### System Requirements

```
✅ macOS 14.0 (Sonoma) or later
✅ Xcode 15.0 or later
✅ Command Line Tools for Xcode
✅ Homebrew (package manager)
✅ Ruby 2.7 or later
✅ Bundler
```

### Installation

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ruby (using rbenv)
brew install rbenv ruby-build
rbenv install 3.2.2
rbenv global 3.2.2

# Install Bundler
gem install bundler

# Install CocoaPods
sudo gem install cocoapods
```

### Required Accounts

- ✅ Apple Developer Program membership ($99/year)
- ✅ App Store Connect access
- ✅ Google Cloud Platform account (for Gemini API)
- ✅ GitHub account (for CI/CD)

---

## Initial Setup

### 1. Clone and Configure Repository

```bash
# Clone repository
git clone https://github.com/brainsait/afham-pro-core.git
cd afham-pro-core

# Install Ruby dependencies
bundle install

# Install Swift Package dependencies
swift package resolve

# Install CocoaPods (if using)
pod install
```

### 2. Configure API Keys

Create `Config/Environment.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_GEMINI_API_KEY_HERE</string>
    <key>NPHIES_API_ENDPOINT</key>
    <string>https://nphies.sa/api</string>
    <key>ENVIRONMENT</key>
    <string>development</string>
</dict>
</plist>
```

**⚠️ IMPORTANT**: Never commit this file! It's already in `.gitignore`.

### 3. Configure Signing

#### Option A: Automatic Signing (Recommended for Development)

1. Open `AFHAM.xcodeproj` in Xcode
2. Select the AFHAM target
3. Go to "Signing & Capabilities"
4. Enable "Automatically manage signing"
5. Select your Team

#### Option B: Manual Signing (For CI/CD)

```bash
# Use Fastlane Match for certificate management
fastlane match development
fastlane match appstore
```

---

## Development Build

### Quick Build (Xcode)

```bash
# Open project
open AFHAM.xcodeproj

# Or build from command line
xcodebuild -project AFHAM.xcodeproj \
           -scheme AFHAM \
           -configuration Debug \
           -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
           build
```

### Using Fastlane

```bash
# Build for testing
fastlane build_for_testing

# Run on simulator
fastlane ios build_and_run
```

### Development Configuration

```swift
// In AFHAMConstants.swift
#if DEBUG
    static let apiEndpoint = "https://api-dev.brainsait.com"
    static let enableLogging = true
    static let mockData = true
#endif
```

---

## Testing

### Running Tests

```bash
# All tests
fastlane test

# Unit tests only
xcodebuild test -project AFHAM.xcodeproj \
                -scheme AFHAM \
                -only-testing:AFHAMTests

# UI tests only
xcodebuild test -project AFHAM.xcodeproj \
                -scheme AFHAM \
                -only-testing:AFHAMUITests

# With code coverage
xcodebuild test -project AFHAM.xcodeproj \
                -scheme AFHAM \
                -enableCodeCoverage YES \
                -resultBundlePath TestResults.xcresult
```

### Code Quality Checks

```bash
# SwiftLint
swiftlint lint --strict

# Security scan
fastlane security_scan

# Dependency check
bundle audit check --update
```

### Coverage Requirements

```
✅ Unit Tests: >80% coverage
✅ Integration Tests: All critical flows
✅ UI Tests: Main user journeys
✅ Performance Tests: Key operations
```

---

## Staging/TestFlight

### 1. Prepare for Beta

```bash
# Update version number
agvtool next-version -all

# Or use Fastlane
fastlane bump_build_number
```

### 2. Build Archive

```bash
# Using Xcode
# Product > Archive

# Using command line
xcodebuild -project AFHAM.xcodeproj \
           -scheme AFHAM \
           -configuration Release \
           -archivePath ./build/AFHAM.xcarchive \
           archive
```

### 3. Upload to TestFlight

```bash
# Using Fastlane (Recommended)
fastlane beta

# Manual upload
xcodebuild -exportArchive \
           -archivePath ./build/AFHAM.xcarchive \
           -exportPath ./build \
           -exportOptionsPlist ExportOptions.plist

# Upload with altool
xcrun altool --upload-app \
             -f ./build/AFHAM.ipa \
             -u YOUR_APPLE_ID \
             -p @keychain:AC_PASSWORD
```

### 4. TestFlight Configuration

1. Log in to App Store Connect
2. Go to TestFlight tab
3. Add internal testers
4. Configure external testing
5. Add beta app description
6. Submit for beta review

---

## Production Build

### Pre-Release Checklist

```
✅ All tests passing (unit, integration, UI)
✅ Code coverage >80%
✅ SwiftLint passes with no warnings
✅ Security scan clean
✅ PDPL compliance verified
✅ NPHIES integration tested
✅ Arabic/English localization complete
✅ App icons and launch screens set
✅ Privacy policy updated
✅ App Store metadata ready
✅ Screenshots prepared (all languages)
✅ Version number incremented
```

### 1. Update Version

```bash
# Update marketing version
agvtool new-marketing-version 1.0.0

# Update build number
agvtool next-version -all

# Verify
agvtool what-version
agvtool what-marketing-version
```

### 2. Production Build

```bash
# Using Fastlane (Recommended)
fastlane release

# Manual build
xcodebuild -project AFHAM.xcodeproj \
           -scheme AFHAM \
           -configuration Release \
           -archivePath ./build/AFHAM.xcarchive \
           archive \
           CODE_SIGN_IDENTITY="Apple Distribution" \
           PROVISIONING_PROFILE_SPECIFIER="AFHAM Production"
```

### 3. Validate Build

```bash
# Validate archive
xcodebuild -validateArchive \
           -archivePath ./build/AFHAM.xcarchive

# Test on device
# Install on multiple test devices
# Verify all features work correctly
```

### 4. Export IPA

Create `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

Export:

```bash
xcodebuild -exportArchive \
           -archivePath ./build/AFHAM.xcarchive \
           -exportPath ./build/Release \
           -exportOptionsPlist ExportOptions.plist
```

---

## App Store Submission

### 1. Prepare Metadata

Create `fastlane/metadata` directory with:

```
metadata/
├── ar-SA/              # Arabic metadata
│   ├── name.txt
│   ├── description.txt
│   ├── keywords.txt
│   └── privacy_url.txt
├── en-US/              # English metadata
│   ├── name.txt
│   ├── description.txt
│   ├── keywords.txt
│   └── privacy_url.txt
└── screenshots/
    ├── ar-SA/
    └── en-US/
```

### 2. Prepare Screenshots

Required sizes:
- 6.7" (iPhone 15 Pro Max): 1290 x 2796
- 6.5" (iPhone 14 Pro Max): 1284 x 2778
- 5.5" (iPhone 8 Plus): 1242 x 2208
- 12.9" iPad Pro: 2048 x 2732

```bash
# Generate screenshots
fastlane screenshots
```

### 3. Upload to App Store Connect

```bash
# Using Fastlane (with metadata)
fastlane deliver

# Or just upload binary
fastlane upload_to_app_store

# Manual upload
xcrun altool --upload-app \
             -f ./build/Release/AFHAM.ipa \
             -u YOUR_APPLE_ID \
             -p @keychain:AC_PASSWORD
```

### 4. App Store Connect Configuration

1. **App Information**
   - Name: AFHAM - أفهم
   - Subtitle: Intelligent Document Understanding
   - Category: Medical / Productivity
   - Content Rights: BrainSAIT Technologies

2. **Pricing and Availability**
   - Price: Free with IAP / Premium
   - Availability: Saudi Arabia (initially)
   - Pre-orders: Optional

3. **App Privacy**
   - Data collection details
   - Data usage
   - Third-party tracking

4. **Version Information**
   - What's new in this version
   - Keywords (100 characters max)
   - Support URL
   - Marketing URL

5. **Build Selection**
   - Select the uploaded build
   - Add version information

6. **Rating**
   - Complete questionnaire
   - Expected rating: 4+

7. **Submit for Review**
   - Review information
   - Demo account (if needed)
   - Notes for reviewer
   - Submit

---

## Troubleshooting

### Common Issues

#### Issue: Code Signing Errors

```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset code signing
security delete-identity -c "Apple Development"
security delete-identity -c "Apple Distribution"

# Re-download certificates
fastlane match nuke development
fastlane match development
```

#### Issue: Swift Package Resolution

```bash
# Reset package cache
rm -rf ~/Library/Caches/org.swift.swiftpm

# Reset packages in project
rm -rf .build
swift package reset
swift package resolve
```

#### Issue: Simulator Not Working

```bash
# Reset simulator
xcrun simctl erase all

# Rebuild
xcodebuild clean build -project AFHAM.xcodeproj -scheme AFHAM
```

#### Issue: Build Too Large

```bash
# Check app size
du -sh build/AFHAM.app

# Optimize images
# Use Asset Catalogs
# Enable App Thinning
# Remove unused resources
```

---

## CI/CD Automation

### GitHub Actions Setup

The project includes two workflows:

#### 1. Continuous Integration (`.github/workflows/ios-ci.yml`)

Triggers: Push to `main`, `develop`, PRs

```yaml
- Code checkout
- Swift Package resolution
- SwiftLint check
- Build
- Run tests
- Generate coverage report
- Upload artifacts
```

#### 2. Security Scanning (`.github/workflows/security-scan.yml`)

Triggers: Daily at 2 AM UTC, Manual

```yaml
- Dependency vulnerability scan
- Code security analysis
- SAST scanning
- License compliance check
- Report generation
```

### Setting Up GitHub Actions

1. **Add Secrets** (Settings > Secrets and variables > Actions)

```
APPLE_ID: your.email@example.com
APP_STORE_CONNECT_API_KEY: auth_key_content
MATCH_PASSWORD: your_match_password
GEMINI_API_KEY: your_gemini_key
```

2. **Configure Runners** (Optional for self-hosted)

```bash
# On macOS machine
# Download and install GitHub Actions runner
# Configure with repository
./config.sh --url https://github.com/brainsait/afham-pro-core
./run.sh
```

3. **Enable Workflows**

Go to Actions tab and enable workflows.

---

## Build Times

Expected build times:

| Build Type | Time | Notes |
|------------|------|-------|
| Debug (Simulator) | 1-2 min | Fast iteration |
| Debug (Device) | 2-3 min | Code signing overhead |
| Release | 3-5 min | Optimizations |
| Archive | 5-8 min | Full optimization + symbols |
| Full CI Pipeline | 10-15 min | All tests + analysis |

---

## Performance Optimization

### Build Performance

```bash
# Enable build timing
defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES

# Parallelize builds
xcodebuild -parallelizeTargets -jobs 8

# Use build system
xcodebuild -useNewBuildSystem

# Enable module stability
SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO
```

### App Performance

```yaml
Optimizations:
  - ✅ Lazy loading
  - ✅ Image caching (Kingfisher)
  - ✅ Background processing
  - ✅ Memory management
  - ✅ Network efficiency
```

---

## Support & Resources

### Documentation
- [Apple Developer](https://developer.apple.com/documentation/)
- [Fastlane](https://docs.fastlane.tools/)
- [NPHIES Documentation](https://nphies.sa/Practitioner/SitePages/Home.aspx)

### Internal Resources
- Developer Guide: `AFHAM/Documentation/DeveloperGuide.md`
- Contributing: `CONTRIBUTING.md`
- Changelog: `CHANGELOG.md`

### Contact
- **Technical Support**: developer@brainsait.com
- **Build Issues**: devops@brainsait.com
- **Security**: security@brainsait.com

---

## Appendix

### A. Xcode Build Settings

Key settings for production:

```
ENABLE_BITCODE = NO
SWIFT_OPTIMIZATION_LEVEL = -O
DEPLOYMENT_POSTPROCESSING = YES
STRIP_INSTALLED_PRODUCT = YES
DEAD_CODE_STRIPPING = YES
ENABLE_TESTABILITY = NO (Release)
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

### B. Required Capabilities

```
- Speech Recognition
- Camera (for document scanning)
- Photo Library
- Push Notifications (for collaboration)
- Background Modes (for sync)
- App Groups (for widget support)
- Keychain Sharing
```

### C. Info.plist Keys

```xml
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSSpeechRecognitionUsageDescription
NSMicrophoneUsageDescription
ITSAppUsesNonExemptEncryption
```

---

**© 2025 BrainSAIT Technologies. All rights reserved.**

*For the latest build instructions, visit: https://docs.brainsait.com/afham/build*
