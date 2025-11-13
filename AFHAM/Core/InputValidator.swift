//
// InputValidator.swift
// AFHAM
//
// Comprehensive input validation and sanitization
// Prevents injection attacks and ensures data integrity
// OWASP compliant validation rules
//

import Foundation
import UniformTypeIdentifiers

/// Comprehensive input validation manager
class InputValidator {
    static let shared = InputValidator()

    private init() {}

    // MARK: - File Validation

    /// Validates file upload with comprehensive security checks
    func validateFile(at url: URL, maxSize: Int64? = nil) throws -> FileValidationResult {
        // Check file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AFHAMError.fileUploadFailed("File does not exist")
        }

        // Get file attributes
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)

        guard let fileSize = attributes[.size] as? Int64 else {
            throw AFHAMError.fileUploadFailed("Could not determine file size")
        }

        // Validate file size
        let sizeLimit = maxSize ?? AFHAMConstants.Files.maxFileSize
        guard fileSize > 0 else {
            throw AFHAMError.fileUploadFailed("File is empty")
        }

        guard fileSize <= sizeLimit else {
            throw AFHAMError.fileSizeTooLarge(fileSize)
        }

        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        guard !fileExtension.isEmpty else {
            throw AFHAMError.unsupportedFileType("No file extension")
        }

        guard AFHAMConstants.Files.supportedExtensions.contains(fileExtension) else {
            throw AFHAMError.unsupportedFileType(fileExtension)
        }

        // Validate MIME type by reading file header (magic bytes)
        try validateFileMagicBytes(url, expectedExtension: fileExtension)

        // Sanitize filename
        let sanitizedFilename = sanitizeFilename(url.lastPathComponent)

        // Check for path traversal attempts
        guard !containsPathTraversal(url.path) else {
            throw AFHAMError.securityError("Path traversal detected in filename")
        }

        AppLogger.shared.log(
            "File validated: \(sanitizedFilename), size: \(fileSize) bytes",
            level: .success
        )

        return FileValidationResult(
            isValid: true,
            originalFilename: url.lastPathComponent,
            sanitizedFilename: sanitizedFilename,
            fileSize: fileSize,
            fileExtension: fileExtension,
            mimeType: getMimeType(for: fileExtension)
        )
    }

    /// Validates file magic bytes match the expected file type
    private func validateFileMagicBytes(_ url: URL, expectedExtension: String) throws {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw AFHAMError.fileUploadFailed("Could not read file")
        }

        defer { try? fileHandle.close() }

        let headerData = fileHandle.readData(ofLength: 16)

        // Define magic bytes for common file types
        let magicBytes: [String: [UInt8]] = [
            "pdf": [0x25, 0x50, 0x44, 0x46], // %PDF
            "docx": [0x50, 0x4B, 0x03, 0x04], // ZIP format
            "xlsx": [0x50, 0x4B, 0x03, 0x04], // ZIP format
            "pptx": [0x50, 0x4B, 0x03, 0x04], // ZIP format
            "doc": [0xD0, 0xCF, 0x11, 0xE0], // OLE format
            "rtf": [0x7B, 0x5C, 0x72, 0x74], // {\rt
        ]

        if let expected = magicBytes[expectedExtension] {
            let actual = Array(headerData.prefix(expected.count))

            guard actual == expected else {
                throw AFHAMError.securityError(
                    "File type mismatch: extension is .\(expectedExtension) but content doesn't match"
                )
            }
        }
    }

    // MARK: - String Validation

    /// Validates and sanitizes user input text
    func validateText(_ text: String, maxLength: Int = 10000, allowEmpty: Bool = false) throws -> String {
        // Check if empty
        if !allowEmpty && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw AFHAMError.queryFailed("Input cannot be empty")
        }

        // Check length
        guard text.count <= maxLength else {
            throw AFHAMError.queryFailed("Input exceeds maximum length of \(maxLength) characters")
        }

        // Check for SQL injection patterns
        guard !containsSQLInjection(text) else {
            throw AFHAMError.securityError("Potential SQL injection detected")
        }

        // Check for XSS patterns
        guard !containsXSS(text) else {
            throw AFHAMError.securityError("Potential XSS attack detected")
        }

        // Check for command injection
        guard !containsCommandInjection(text) else {
            throw AFHAMError.securityError("Potential command injection detected")
        }

        // Sanitize the text
        let sanitized = sanitizeText(text)

        AppLogger.shared.log("Text validated and sanitized", level: .debug)

        return sanitized
    }

    /// Validates API key format
    func validateAPIKey(_ key: String) throws {
        // Remove whitespace
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check not empty
        guard !trimmed.isEmpty else {
            throw AFHAMError.invalidAPIKey
        }

        // Check length (Gemini keys are typically 39 characters)
        guard trimmed.count >= 30 && trimmed.count <= 50 else {
            throw AFHAMError.invalidAPIKey
        }

        // Check format (alphanumeric and limited special chars)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            throw AFHAMError.invalidAPIKey
        }

        AppLogger.shared.log("API key format validated", level: .success)
    }

    // MARK: - Security Checks

    private func containsSQLInjection(_ text: String) -> Bool {
        let sqlPatterns = [
            "(?i)(select|insert|update|delete|drop|create|alter)\\s",
            "(?i)(union|join)\\s+.*\\s+(select|from)",
            "(?i)(--)|(;)|(\\/\\*)",
            "(?i)(exec|execute)\\s*\\(",
            "(?i)(xp_cmdshell|sp_executesql)"
        ]

        return sqlPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func containsXSS(_ text: String) -> Bool {
        let xssPatterns = [
            "(?i)<script[^>]*>.*?</script>",
            "(?i)javascript:",
            "(?i)onerror\\s*=",
            "(?i)on\\w+\\s*=",
            "(?i)<iframe[^>]*>",
            "(?i)<object[^>]*>",
            "(?i)<embed[^>]*>"
        ]

        return xssPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func containsCommandInjection(_ text: String) -> Bool {
        let commandPatterns = [
            "(?i)(\\||;|&|\\$\\(|`)",
            "(?i)(rm|mv|cp)\\s+-[rf]",
            "(?i)\\.\\.[\\\\/]",
            "(?i)(curl|wget|nc|netcat)\\s"
        ]

        return commandPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private func containsPathTraversal(_ path: String) -> Bool {
        let traversalPatterns = [
            "\\.\\./",
            "\\.\\.\\\\",
            "%2e%2e%2f",
            "%2e%2e/",
            "..%2f",
            "%2e%2e%5c"
        ]

        return traversalPatterns.contains { pattern in
            path.lowercased().contains(pattern.lowercased())
        }
    }

    // MARK: - Sanitization

    private func sanitizeFilename(_ filename: String) -> String {
        // Remove path separators
        var sanitized = filename.replacingOccurrences(of: "/", with: "_")
        sanitized = sanitized.replacingOccurrences(of: "\\", with: "_")

        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")

        // Remove control characters
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()

        // Limit length
        if sanitized.count > 255 {
            let ext = (sanitized as NSString).pathExtension
            let name = (sanitized as NSString).deletingPathExtension
            let truncated = String(name.prefix(255 - ext.count - 1))
            sanitized = truncated + "." + ext
        }

        return sanitized
    }

    private func sanitizeText(_ text: String) -> String {
        var sanitized = text

        // Remove null bytes
        sanitized = sanitized.replacingOccurrences(of: "\0", with: "")

        // Normalize unicode
        sanitized = sanitized.precomposedStringWithCanonicalMapping

        // Remove zero-width characters (potential obfuscation)
        let zeroWidthChars = [
            "\u{200B}", // Zero width space
            "\u{200C}", // Zero width non-joiner
            "\u{200D}", // Zero width joiner
            "\u{FEFF}"  // Zero width no-break space
        ]

        for char in zeroWidthChars {
            sanitized = sanitized.replacingOccurrences(of: char, with: "")
        }

        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func getMimeType(for extension: String) -> String {
        return AFHAMConstants.Files.mimeTypes[extension.lowercased()] ?? "application/octet-stream"
    }
}

// MARK: - Validation Result

struct FileValidationResult {
    let isValid: Bool
    let originalFilename: String
    let sanitizedFilename: String
    let fileSize: Int64
    let fileExtension: String
    let mimeType: String
}
