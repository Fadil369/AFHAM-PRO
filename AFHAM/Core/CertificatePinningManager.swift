//
// CertificatePinningManager.swift
// AFHAM
//
// SSL/TLS Certificate Pinning for enhanced security
// Prevents man-in-the-middle attacks
// Supports public key pinning and certificate pinning
//

import Foundation
import Security
import CryptoKit

/// Certificate pinning manager to prevent MITM attacks
class CertificatePinningManager: NSObject {
    static let shared = CertificatePinningManager()

    // MARK: - Configuration

    /// Pinned public keys for Gemini API (SHA-256 hashes)
    private let geminiPinnedKeys: Set<String> = [
        // Add actual Gemini API public key hashes here
        // These should be obtained from the actual certificates
        "REPLACE_WITH_ACTUAL_GEMINI_PUBLIC_KEY_HASH_1",
        "REPLACE_WITH_ACTUAL_GEMINI_PUBLIC_KEY_HASH_2"
    ]

    /// Pinned public keys for NPHIES (SHA-256 hashes)
    private let nphiesPinnedKeys: Set<String> = [
        // Add actual NPHIES public key hashes here
        "REPLACE_WITH_ACTUAL_NPHIES_PUBLIC_KEY_HASH_1",
        "REPLACE_WITH_ACTUAL_NPHIES_PUBLIC_KEY_HASH_2"
    ]

    /// Domains that require pinning
    private let pinnedDomains: Set<String> = [
        "generativelanguage.googleapis.com",
        "nphies.sa",
        "sandbox.nphies.sa"
    ]

    /// Enable/disable pinning (for development/testing)
    private var isPinningEnabled: Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "EnableCertificatePinning")
        #else
        return true // Always enabled in production
        #endif
    }

    private override init() {
        super.init()
        AppLogger.shared.log("CertificatePinningManager initialized", level: .info)
    }

    // MARK: - Public API

    /// Validates server trust for a given host
    /// - Parameters:
    ///   - serverTrust: The server trust to validate
    ///   - domain: The domain being accessed
    /// - Returns: True if the certificate is valid and pinned
    func validate(serverTrust: SecTrust, forDomain domain: String) -> Bool {
        // Check if pinning is required for this domain
        guard isPinningRequired(for: domain) else {
            // Domain not in pinned list, use default validation
            return evaluateDefaultTrust(serverTrust)
        }

        // Check if pinning is enabled
        guard isPinningEnabled else {
            AppLogger.shared.log(
                "⚠️ Certificate pinning disabled for \(domain) in DEBUG mode",
                level: .warning
            )
            return evaluateDefaultTrust(serverTrust)
        }

        // Perform certificate pinning validation
        return validatePinnedCertificate(serverTrust: serverTrust, domain: domain)
    }

    /// Creates a URLSession with certificate pinning
    func createSecureURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = AFHAMConstants.API.timeout
        configuration.timeoutIntervalForResource = AFHAMConstants.API.timeout * 2
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )

        return session
    }

    // MARK: - Certificate Validation

    private func validatePinnedCertificate(serverTrust: SecTrust, domain: String) -> Bool {
        // Get the certificate chain
        guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            AppLogger.shared.log(
                "❌ Failed to get certificate chain for \(domain)",
                level: .error
            )
            return false
        }

        // Get pinned keys for this domain
        let pinnedKeys = getPinnedKeys(for: domain)

        // Extract public keys from certificates and compare
        for certificate in certificates {
            if let publicKey = getPublicKey(from: certificate) {
                let publicKeyHash = hashPublicKey(publicKey)

                if pinnedKeys.contains(publicKeyHash) {
                    AppLogger.shared.log(
                        "✅ Certificate pinning validated for \(domain)",
                        level: .success
                    )
                    return true
                }
            }
        }

        AppLogger.shared.log(
            "❌ Certificate pinning failed for \(domain) - No matching pinned keys",
            level: .error
        )
        return false
    }

    private func evaluateDefaultTrust(_ serverTrust: SecTrust) -> Bool {
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(serverTrust, &error)

        if let error = error {
            AppLogger.shared.log(
                "❌ Default trust evaluation failed: \(error.localizedDescription)",
                level: .error
            )
        }

        return isValid
    }

    // MARK: - Helper Methods

    private func isPinningRequired(for domain: String) -> Bool {
        return pinnedDomains.contains { domain.contains($0) }
    }

    private func getPinnedKeys(for domain: String) -> Set<String> {
        if domain.contains("generativelanguage.googleapis.com") {
            return geminiPinnedKeys
        } else if domain.contains("nphies.sa") {
            return nphiesPinnedKeys
        }
        return []
    }

    private func getPublicKey(from certificate: SecCertificate) -> SecKey? {
        var trust: SecTrust?
        let policy = SecPolicyCreateBasicX509()

        let status = SecTrustCreateWithCertificates(
            certificate,
            policy,
            &trust
        )

        guard status == errSecSuccess, let trust = trust else {
            return nil
        }

        return SecTrustCopyKey(trust)
    }

    private func hashPublicKey(_ publicKey: SecKey) -> String {
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return ""
        }

        let hash = SHA256.hash(data: publicKeyData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Debug Helpers

    #if DEBUG
    /// Extracts and prints public key hash from a certificate (for pinning setup)
    func extractPublicKeyHash(from url: URL) async {
        guard let host = url.host else { return }

        let task = URLSession.shared.dataTask(with: url) { [weak self] _, response, error in
            if let error = error {
                AppLogger.shared.log("Error fetching certificate: \(error)", level: .error)
                return
            }

            // In a real implementation, we would extract the certificate from the response
            // and calculate its public key hash
            AppLogger.shared.log(
                """
                To extract public key hash:
                1. Run: openssl s_client -connect \(host):443 -showcerts
                2. Save certificate to file (cert.pem)
                3. Run: openssl x509 -in cert.pem -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
                """,
                level: .info
            )
        }
        task.resume()
    }
    #endif
}

// MARK: - URLSessionDelegate

extension CertificatePinningManager: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let domain = challenge.protectionSpace.host

        if validate(serverTrust: serverTrust, forDomain: domain) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            AppLogger.shared.log(
                "🔒 Certificate validation failed for \(domain)",
                level: .error
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - URLSession Extension

extension URLSession {
    /// Creates a secure URLSession with certificate pinning
    static var secure: URLSession {
        return CertificatePinningManager.shared.createSecureURLSession()
    }
}
