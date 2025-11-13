# Repository Guidelines

## Project Structure & Module Organization
AFHAM is a SwiftUI-first iOS 17+ app. Core runtime code sits at the repo root: `afham_main.swift` hosts `AFHAMConfig`, networking, and data models; `afham_chat.swift`, `afham_content.swift`, and `afham_ui.swift` contain chat, content-generation, and UI layers; `afham_entry.swift` ties them into the app target. Use `afham_setup.md` for the canonical folder map when wiring these files into an Xcode project (e.g., Models, Managers, ViewModels, Views, Resources). Keep Arabic/English assets under `Resources/Localizations` inside the Xcode workspace and mirror any new Swift files in both the Xcode group tree and the repo root for traceability.

## Build, Test, and Development Commands
Run the project in Xcode 15+ with the AFHAM scheme targeting an iPhone 15 Pro simulator. Command-line builds should match CI:
```bash
xcodebuild -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
xcodebuild -scheme AFHAM -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```
Use `swift package update` only after validating that dependency pins still satisfy App Store requirements. Reference `afham_setup.md` for provisioning, speech permissions, and capability switches.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines with 4-space indentation, `UpperCamelCase` for types, `lowerCamelCase` for properties/functions, and `SCREAMING_SNAKE_CASE` for constants. Group related declarations with `// MARK:` comments as seen in `afham_main.swift`. Keep BrainSAIT design tokens centralized in `AFHAMConfig` and prefer dependency injection over singletons for new managers. Localize all user-facing strings (English default, Arabic mirror) and annotate bilingual UI with direction-aware modifiers.

## Testing Guidelines
Build UI logic as testable view models and place unit tests under `Tests/AFHAMTests` (create if absent). Favor XCTest plus async-await expectations for Gemini workflows. Name tests using `test<Feature><Expectation>()`, and gate pull requests unless unit tests and snapshot tests (if added) pass via `xcodebuild test`. Aim for ≥80% coverage on managers that touch Gemini File Search, speech, or PDPL-sensitive data flows.

## Commit & Pull Request Guidelines
Match the existing conventional format (`type: concise summary`), e.g., `chore: stabilize analytics typings`. Each PR should include: purpose statement, key screenshots or simulator recordings for UI work, linked Linear/Jira ticket or GitHub issue, and a checklist covering localization, accessibility, and PDPL safeguards. Highlight any new API keys or permissions so COMPLIANCELINC reviewers can trace audit impacts.

## Security & Configuration Tips
Store Gemini API keys via Xcode secrets or Keychain; never hardcode production values in `AFHAMConfig`. Ensure PDPL/NPHIES compliance by logging only anonymized identifiers and stripping PHI from debug prints. When sharing builds, scrub derived data and confirm Info.plist contains bilingual consent strings. Escalate architectural questions to MASTERLINC before touching regulated data flows.
