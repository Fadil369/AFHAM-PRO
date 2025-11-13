# Contributing to AFHAM

Thank you for your interest in contributing to AFHAM! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Getting Started](#getting-started)
3. [Development Workflow](#development-workflow)
4. [Coding Standards](#coding-standards)
5. [Testing Guidelines](#testing-guidelines)
6. [Documentation](#documentation)
7. [Pull Request Process](#pull-request-process)
8. [Security](#security)
9. [Healthcare Compliance](#healthcare-compliance)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful of differing viewpoints and experiences.

### Our Standards

- **Be Professional**: Maintain professional communication at all times
- **Be Respectful**: Treat everyone with respect and kindness
- **Be Collaborative**: Work together towards common goals
- **Be Patient**: Help others learn and grow

---

## Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9+
- Git
- Apple Developer account (for testing on device)

### Setting Up Development Environment

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/afham-pro-core.git
   cd afham-pro-core
   ```

2. **Install dependencies**
   ```bash
   # Install Ruby dependencies for Fastlane
   bundle install

   # Install Swift dependencies
   swift package resolve
   ```

3. **Configure environment**
   ```bash
   # Copy configuration template
   cp Config/Environment.plist.template Config/Environment.plist

   # Add your API keys to Environment.plist
   ```

4. **Open in Xcode**
   ```bash
   open AFHAM.xcodeproj
   ```

---

## Development Workflow

### Branching Strategy

We use Git Flow for branch management:

- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical production fixes
- `release/*`: Release preparation

### Creating a Feature Branch

```bash
# Start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
git add .
git commit -m "feat: add new feature"

# Push to your fork
git push origin feature/your-feature-name
```

### Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `security`: Security improvements
- `compliance`: PDPL/NPHIES compliance updates

**Examples:**
```bash
feat(chat): add voice recognition support for Arabic

fix(encryption): resolve AES-256 key generation issue

docs(readme): update installation instructions

security(pdpl): implement data retention policies
```

---

## Coding Standards

### Swift Style Guide

We follow the [Swift.org API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

#### Naming Conventions

```swift
// Types: PascalCase
class DocumentManager { }
struct UserProfile { }
enum NetworkError { }

// Variables and functions: camelCase
var documentCount: Int
func processDocument(_ data: Data) { }

// Constants: camelCase
let maxFileSize = 100_000_000

// Enums: camelCase for cases
enum DocumentType {
    case pdf
    case word
    case excel
}
```

#### Code Organization

```swift
// MARK: - Type Definition

class DocumentManager {

    // MARK: - Properties

    private let storage: Storage
    private var documents: [Document] = []

    // MARK: - Initialization

    init(storage: Storage) {
        self.storage = storage
    }

    // MARK: - Public Methods

    func processDocument(_ data: Data) async throws -> Document {
        // Implementation
    }

    // MARK: - Private Methods

    private func validateDocument(_ data: Data) -> Bool {
        // Implementation
    }
}
```

#### Documentation

All public APIs must be documented:

```swift
/// Processes a document and extracts its content
///
/// This method analyzes the provided document data and extracts
/// meaningful information using AI-powered analysis.
///
/// - Parameters:
///   - data: The raw document data
///   - format: The document format (PDF, Word, etc.)
/// - Returns: A processed Document object with extracted content
/// - Throws: `DocumentError` if processing fails
func processDocument(_ data: Data, format: DocumentFormat) async throws -> Document {
    // Implementation
}
```

### SwiftLint Configuration

We use SwiftLint for automated code style checking. The configuration is in `.swiftlint.yml`.

Run SwiftLint before committing:

```bash
swiftlint
```

Fix auto-fixable issues:

```bash
swiftlint --fix
```

### Security Best Practices

1. **Never commit API keys or secrets**
   ```swift
   // ❌ Bad
   let apiKey = "sk_live_abc123"

   // ✅ Good
   let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"]
   ```

2. **Use Keychain for sensitive data**
   ```swift
   // ✅ Store API keys in Keychain
   try KeychainManager.save(apiKey, forKey: "gemini_api_key")
   ```

3. **Encrypt sensitive user data**
   ```swift
   // ✅ Encrypt before storing
   let encrypted = try EncryptionManager.encrypt(userData)
   try storage.save(encrypted)
   ```

4. **Validate all user input**
   ```swift
   // ✅ Validate input
   guard !userInput.isEmpty, userInput.count <= maxLength else {
       throw ValidationError.invalidInput
   }
   ```

---

## Testing Guidelines

### Test Coverage Requirements

- **Unit Tests**: Minimum 80% code coverage
- **Integration Tests**: All API endpoints and workflows
- **UI Tests**: Critical user flows
- **Performance Tests**: Key operations

### Writing Tests

```swift
import XCTest
@testable import AFHAM

class DocumentManagerTests: XCTestCase {

    var sut: DocumentManager!
    var mockStorage: MockStorage!

    override func setUp() async throws {
        try await super.setUp()
        mockStorage = MockStorage()
        sut = DocumentManager(storage: mockStorage)
    }

    override func tearDown() async throws {
        sut = nil
        mockStorage = nil
        try await super.tearDown()
    }

    func testProcessDocument_ValidPDF_ReturnsDocument() async throws {
        // Given
        let testData = createTestPDF()

        // When
        let document = try await sut.processDocument(testData, format: .pdf)

        // Then
        XCTAssertNotNil(document)
        XCTAssertFalse(document.content.isEmpty)
    }
}
```

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test
xcodebuild test -scheme AFHAM -only-testing:AFHAMTests/DocumentManagerTests

# Generate coverage report
xcodebuild test -scheme AFHAM -enableCodeCoverage YES
```

---

## Documentation

### Code Documentation

- Document all public APIs
- Include parameter descriptions
- Add usage examples for complex functionality
- Document error conditions

### User Documentation

Update relevant documentation:
- `AFHAM/Documentation/UserGuide.md`
- `AFHAM/Documentation/DeveloperGuide.md`
- `README.md` (if adding major features)

### API Documentation

Generate API documentation:

```bash
# Generate documentation with Jazzy
jazzy --config .jazzy.yaml

# View documentation
open docs/API/index.html
```

---

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout feature/your-feature
   git rebase develop
   ```

2. **Run all tests**
   ```bash
   xcodebuild test -scheme AFHAM
   ```

3. **Run SwiftLint**
   ```bash
   swiftlint
   ```

4. **Update documentation**
   - Add/update code comments
   - Update user documentation if needed
   - Add changelog entry

5. **Security check**
   ```bash
   # Run security scan
   bundle exec brakeman
   ```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Security improvement
- [ ] Compliance update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] UI tests added/updated
- [ ] Manual testing completed

## Compliance
- [ ] PDPL compliance verified
- [ ] NPHIES compatibility checked
- [ ] Security review completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Tests pass locally
- [ ] SwiftLint passes
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs automatically
2. **Code Review**: At least one maintainer review required
3. **Security Review**: For security-related changes
4. **Compliance Review**: For healthcare/privacy features
5. **Final Approval**: Project maintainer approval

---

## Security

### Reporting Security Issues

**Do not open public issues for security vulnerabilities.**

Email security concerns to: security@brainsait.com

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Guidelines

1. **Data Protection**
   - Always encrypt sensitive data (AES-256)
   - Use Keychain for credentials
   - Implement proper access controls

2. **API Security**
   - Use HTTPS only
   - Implement request signing
   - Rate limit API calls
   - Validate all inputs

3. **Authentication**
   - Use OAuth 2.0 when possible
   - Implement secure token storage
   - Support biometric authentication

4. **Privacy**
   - Minimize data collection
   - Implement PDPL requirements
   - Provide user data controls
   - Support data deletion requests

---

## Healthcare Compliance

### PDPL Requirements

When handling personal data:

1. **User Consent**
   ```swift
   // Request explicit consent
   let consent = try await ConsentManager.requestConsent(for: .dataProcessing)
   guard consent.granted else { return }
   ```

2. **Data Encryption**
   ```swift
   // Encrypt sensitive data
   let encrypted = try EncryptionManager.encrypt(userData, using: .aes256)
   ```

3. **Data Retention**
   ```swift
   // Respect retention periods
   let retentionPeriod: TimeInterval = 90 * 24 * 60 * 60 // 90 days
   DataManager.setRetentionPeriod(retentionPeriod)
   ```

4. **Audit Logging**
   ```swift
   // Log data access
   AuditLogger.log(event: .dataAccess, userId: user.id, resource: "patient_record")
   ```

### NPHIES/FHIR Compliance

When implementing healthcare features:

1. **FHIR Resources**
   - Use standard FHIR R4 resources
   - Validate against FHIR schemas
   - Include required elements

2. **NPHIES Integration**
   - Follow NPHIES API specifications
   - Use correct endpoints
   - Implement proper authentication

3. **Healthcare Standards**
   - Support SNOMED CT
   - Support ICD-10
   - Use BrainSAIT OID: `1.3.6.1.4.1.61026`

---

## Questions?

- **Technical Questions**: developer@brainsait.com
- **Healthcare Compliance**: compliance@brainsait.com
- **Security**: security@brainsait.com
- **General**: contribute@brainsait.com

---

## License

By contributing to AFHAM, you agree that your contributions will be licensed under the same terms as the project.

---

**Thank you for contributing to AFHAM!**

*Together, we're transforming healthcare through intelligent document understanding.*
