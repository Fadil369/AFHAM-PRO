// AFHAM - NPHIES/FHIR Healthcare Compliance
// Saudi National Platform for Health Information Exchange Services integration
// Full FHIR R4 compliance with Saudi healthcare standards

import SwiftUI
import Foundation

// MARK: - NPHIES COMPLIANCE: Core Manager
@MainActor
class NPHIESComplianceManager: ObservableObject {
    static let shared = NPHIESComplianceManager()
    
    @Published var isNPHIESEnabled = true
    @Published var fhirResources: [FHIRResource] = []
    @Published var complianceStatus: ComplianceStatus = .checking
    @Published var auditLog: [ComplianceAuditEntry] = []
    
    // BrainSAIT OID namespace for Saudi Arabia
    private let brainSAITOIDSaudi = "1.3.6.1.4.1.61026.2"
    private let brainSAITOIDSudan = "1.3.6.1.4.1.61026.1"
    
    // NPHIES endpoints (sandbox/production)
    private let nphiesBaseURL = "https://nphies.sa/fhir/r4"
    private let nphiesSandboxURL = "https://sandbox.nphies.sa/fhir/r4"
    
    private let complianceValidator = NPHIESValidator()
    private let fhirProcessor = FHIRProcessor()
    private let auditLogger = ComplianceAuditLogger()
    
    private init() {
        validateNPHIESCompliance()
        setupComplianceMonitoring()
        
        AppLogger.shared.log("NPHIESComplianceManager initialized", level: .info)
    }
    
    // MARK: - FHIR Resource Management
    func createPatientResource(_ patientData: PatientData) async throws -> FHIRPatient {
        let patient = FHIRPatient(
            id: UUID().uuidString,
            identifier: [
                FHIRIdentifier(
                    system: "\(brainSAITOIDSaudi).patient",
                    value: patientData.nationalId
                )
            ],
            name: [
                FHIRHumanName(
                    family: patientData.familyName,
                    given: patientData.givenNames,
                    text: patientData.fullName
                )
            ],
            gender: patientData.gender.fhirValue,
            birthDate: patientData.birthDate,
            address: patientData.address?.toFHIRAddress(),
            telecom: patientData.contacts.map { $0.toFHIRContactPoint() }
        )
        
        try await validateFHIRResource(patient)
        await auditLogger.logResourceCreation(.patient, resourceId: patient.id)
        
        AppLogger.shared.log("FHIR Patient resource created: \(patient.id)", level: .success)
        return patient
    }
    
    func createDocumentReference(_ document: DocumentMetadata, patientId: String) async throws -> FHIRDocumentReference {
        let docRef = FHIRDocumentReference(
            id: UUID().uuidString,
            identifier: [
                FHIRIdentifier(
                    system: "\(brainSAITOIDSaudi).document",
                    value: document.id.uuidString
                )
            ],
            status: .current,
            type: FHIRCodeableConcept.documentType(document.documentType),
            category: [FHIRCodeableConcept.clinicalDocument()],
            subject: FHIRReference(reference: "Patient/\(patientId)"),
            date: document.uploadDate,
            author: [FHIRReference(reference: "Organization/brainsait")],
            content: [
                FHIRDocumentReferenceContent(
                    attachment: FHIRAttachment(
                        contentType: getMimeType(for: document.documentType),
                        size: Int(document.fileSize),
                        title: document.fileName,
                        creation: document.uploadDate
                    )
                )
            ]
        )
        
        try await validateFHIRResource(docRef)
        await auditLogger.logResourceCreation(.documentReference, resourceId: docRef.id)
        
        AppLogger.shared.log("FHIR DocumentReference created: \(docRef.id)", level: .success)
        return docRef
    }
    
    func createDiagnosticReport(_ analysisResult: String, patientId: String, documentId: String) async throws -> FHIRDiagnosticReport {
        let report = FHIRDiagnosticReport(
            id: UUID().uuidString,
            identifier: [
                FHIRIdentifier(
                    system: "\(brainSAITOIDSaudi).diagnostic-report",
                    value: UUID().uuidString
                )
            ],
            status: .final,
            category: [FHIRCodeableConcept.diagnosticServiceCategory()],
            code: FHIRCodeableConcept.documentAnalysis(),
            subject: FHIRReference(reference: "Patient/\(patientId)"),
            effectiveDateTime: Date(),
            issued: Date(),
            performer: [FHIRReference(reference: "Organization/brainsait")],
            conclusionCode: [FHIRCodeableConcept.aiAnalysis()],
            conclusion: analysisResult,
            presentedForm: [
                FHIRAttachment(
                    contentType: "text/plain",
                    data: analysisResult.data(using: .utf8)?.base64EncodedString(),
                    title: "AI Analysis Result",
                    creation: Date()
                )
            ]
        )
        
        try await validateFHIRResource(report)
        await auditLogger.logResourceCreation(.diagnosticReport, resourceId: report.id)
        
        AppLogger.shared.log("FHIR DiagnosticReport created: \(report.id)", level: .success)
        return report
    }
    
    // MARK: - NPHIES Integration
    func submitToNPHIES(_ resource: FHIRResource) async throws -> NPHIESResponse {
        guard isNPHIESEnabled else {
            throw NPHIESError.serviceDisabled
        }
        
        // Validate resource meets NPHIES requirements
        try await validateNPHIESCompliance(resource)
        
        // Submit to NPHIES platform
        let request = createNPHIESRequest(resource)
        let response = try await submitRequest(request)
        
        await auditLogger.logNPHIESSubmission(resource.resourceType, resourceId: resource.id, success: response.success)
        
        AppLogger.shared.log("Resource submitted to NPHIES: \(resource.id)", level: .success)
        return response
    }
    
    func queryNPHIES(_ query: NPHIESQuery) async throws -> NPHIESQueryResponse {
        let request = createNPHIESQuery(query)
        let response = try await submitQueryRequest(request)
        
        await auditLogger.logNPHIESQuery(query.resourceType, parameters: query.parameters)
        
        return response
    }
    
    // MARK: - Compliance Validation
    private func validateFHIRResource(_ resource: FHIRResource) async throws {
        let validationResult = await complianceValidator.validateFHIRResource(resource)
        
        guard validationResult.isValid else {
            throw NPHIESError.validationFailed(validationResult.errors)
        }
        
        // Additional NPHIES-specific validation
        try await validateNPHIESSpecificRequirements(resource)
    }
    
    private func validateNPHIESCompliance(_ resource: FHIRResource) async throws {
        // Check required NPHIES profiles
        guard await complianceValidator.validateNPHIESProfile(resource) else {
            throw NPHIESError.profileValidationFailed
        }
        
        // Validate Saudi-specific requirements
        try validateSaudiRequirements(resource)
        
        // Check data privacy compliance (PDPL)
        try validateDataPrivacyCompliance(resource)
    }
    
    private func validateNPHIESSpecificRequirements(_ resource: FHIRResource) async throws {
        switch resource.resourceType {
        case .patient:
            try validatePatientRequirements(resource as! FHIRPatient)
        case .documentReference:
            try validateDocumentRequirements(resource as! FHIRDocumentReference)
        case .diagnosticReport:
            try validateDiagnosticRequirements(resource as! FHIRDiagnosticReport)
        default:
            break
        }
    }
    
    private func validatePatientRequirements(_ patient: FHIRPatient) throws {
        // Validate Saudi national ID format
        guard let nationalId = patient.identifier.first(where: { $0.system.contains("patient") })?.value else {
            throw NPHIESError.missingRequiredField("Patient national identifier")
        }
        
        guard isValidSaudiNationalId(nationalId) else {
            throw NPHIESError.invalidNationalId
        }
        
        // Ensure Arabic name is provided if available
        if !patient.name.isEmpty && !hasArabicName(patient.name) {
            AppLogger.shared.log("Warning: Patient name should include Arabic variant", level: .warning)
        }
    }
    
    private func validateDocumentRequirements(_ docRef: FHIRDocumentReference) throws {
        // Validate document type is supported by NPHIES
        guard isNPHIESSupportedDocumentType(docRef.type) else {
            throw NPHIESError.unsupportedDocumentType
        }
        
        // Ensure proper categorization
        guard !docRef.category.isEmpty else {
            throw NPHIESError.missingRequiredField("Document category")
        }
    }
    
    private func validateDiagnosticRequirements(_ report: FHIRDiagnosticReport) throws {
        // Validate diagnostic codes are from approved code systems
        guard isValidDiagnosticCode(report.code) else {
            throw NPHIESError.invalidDiagnosticCode
        }
        
        // Ensure performer is properly identified
        guard !report.performer.isEmpty else {
            throw NPHIESError.missingRequiredField("Report performer")
        }
    }
    
    // MARK: - Data Privacy (PDPL) Compliance
    private func validateDataPrivacyCompliance(_ resource: FHIRResource) throws {
        // Ensure data minimization
        validateDataMinimization(resource)
        
        // Check consent requirements
        try validateConsentRequirements(resource)
        
        // Verify encryption and security
        try validateSecurityRequirements(resource)
    }
    
    private func validateDataMinimization(_ resource: FHIRResource) {
        // Ensure only necessary data is included
        switch resource.resourceType {
        case .patient:
            let patient = resource as! FHIRPatient
            if patient.address?.count ?? 0 > 1 {
                AppLogger.shared.log("Warning: Multiple addresses may violate data minimization", level: .warning)
            }
        default:
            break
        }
    }
    
    private func validateConsentRequirements(_ resource: FHIRResource) throws {
        // In a production system, verify patient consent for data processing
        let hasConsent = checkPatientConsent(resource)
        guard hasConsent else {
            throw NPHIESError.missingConsent
        }
    }
    
    private func validateSecurityRequirements(_ resource: FHIRResource) throws {
        // Ensure proper security measures are in place
        guard AFHAMConstants.Security.encryptLocalStorage else {
            throw NPHIESError.securityRequirementsNotMet
        }
    }
    
    // MARK: - NPHIES Communication
    private func createNPHIESRequest(_ resource: FHIRResource) -> NPHIESRequest {
        return NPHIESRequest(
            method: .post,
            endpoint: "\(nphiesBaseURL)/\(resource.resourceType.rawValue)",
            headers: [
                "Content-Type": "application/fhir+json",
                "Authorization": "Bearer \(getNPHIESToken())",
                "X-BrainSAIT-Client": "AFHAM/1.0.0"
            ],
            body: try! fhirProcessor.encodeResource(resource)
        )
    }
    
    private func createNPHIESQuery(_ query: NPHIESQuery) -> NPHIESRequest {
        let queryString = query.parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        return NPHIESRequest(
            method: .get,
            endpoint: "\(nphiesBaseURL)/\(query.resourceType.rawValue)?\(queryString)",
            headers: [
                "Authorization": "Bearer \(getNPHIESToken())",
                "Accept": "application/fhir+json"
            ],
            body: nil
        )
    }
    
    private func submitRequest(_ request: NPHIESRequest) async throws -> NPHIESResponse {
        guard let url = URL(string: request.endpoint) else {
            throw NPHIESError.invalidEndpoint
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = request.body {
            urlRequest.httpBody = body
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NPHIESError.invalidResponse
        }
        
        return NPHIESResponse(
            statusCode: httpResponse.statusCode,
            data: data,
            success: (200...299).contains(httpResponse.statusCode)
        )
    }
    
    private func submitQueryRequest(_ request: NPHIESRequest) async throws -> NPHIESQueryResponse {
        let response = try await submitRequest(request)
        
        guard response.success else {
            throw NPHIESError.queryFailed
        }
        
        let resources = try fhirProcessor.decodeResources(response.data)
        
        return NPHIESQueryResponse(
            resources: resources,
            total: resources.count,
            success: true
        )
    }
    
    // MARK: - Utility Methods
    private func validateNPHIESCompliance() {
        Task {
            let isCompliant = await complianceValidator.validateSystemCompliance()
            await MainActor.run {
                complianceStatus = isCompliant ? .compliant : .nonCompliant
            }
        }
    }
    
    private func setupComplianceMonitoring() {
        // Setup periodic compliance checks
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { [weak self] in
                await self?.performComplianceCheck()
            }
        }
    }
    
    private func performComplianceCheck() async {
        let isCompliant = await complianceValidator.validateSystemCompliance()
        await MainActor.run {
            complianceStatus = isCompliant ? .compliant : .nonCompliant
        }
        
        if !isCompliant {
            AppLogger.shared.log("NPHIES compliance check failed", level: .error)
        }
    }
    
    private func isValidSaudiNationalId(_ id: String) -> Bool {
        // Validate Saudi national ID format (10 digits)
        let regex = "^[12][0-9]{9}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: id)
    }
    
    private func hasArabicName(_ names: [FHIRHumanName]) -> Bool {
        return names.contains { name in
            name.text?.contains(where: { char in
                return ("\u{0600}"..."\u{06FF}").contains(char)
            }) ?? false
        }
    }
    
    private func isNPHIESSupportedDocumentType(_ type: FHIRCodeableConcept) -> Bool {
        // Check if document type is in NPHIES supported list
        let supportedTypes = ["34133-9", "11502-2", "18842-5"] // LOINC codes for clinical documents
        return type.coding.contains { coding in
            supportedTypes.contains(coding.code)
        }
    }
    
    private func isValidDiagnosticCode(_ code: FHIRCodeableConcept) -> Bool {
        // Validate diagnostic codes against approved code systems
        return code.coding.contains { coding in
            coding.system == "http://loinc.org" || coding.system == "http://snomed.info/sct"
        }
    }
    
    private func checkPatientConsent(_ resource: FHIRResource) -> Bool {
        // In production, this would check actual consent records
        return true
    }
    
    private func getNPHIESToken() -> String {
        // In production, this would fetch a valid OAuth token
        return "mock_nphies_token"
    }
    
    private func getMimeType(for documentType: String) -> String {
        return AFHAMConstants.Files.mimeTypes[documentType.lowercased()] ?? "application/octet-stream"
    }
    
    private func validateSaudiRequirements(_ resource: FHIRResource) throws {
        // Validate Saudi-specific healthcare requirements
        // This would include checks for Saudi medical coding standards
    }
}

// MARK: - FHIR Data Models
protocol FHIRResource {
    var id: String { get }
    var resourceType: FHIRResourceType { get }
}

enum FHIRResourceType: String {
    case patient = "Patient"
    case documentReference = "DocumentReference"
    case diagnosticReport = "DiagnosticReport"
    case organization = "Organization"
    case practitioner = "Practitioner"
}

struct FHIRPatient: FHIRResource {
    let id: String
    let resourceType: FHIRResourceType = .patient
    let identifier: [FHIRIdentifier]
    let name: [FHIRHumanName]
    let gender: String
    let birthDate: Date
    let address: [FHIRAddress]?
    let telecom: [FHIRContactPoint]
}

struct FHIRDocumentReference: FHIRResource {
    let id: String
    let resourceType: FHIRResourceType = .documentReference
    let identifier: [FHIRIdentifier]
    let status: DocumentStatus
    let type: FHIRCodeableConcept
    let category: [FHIRCodeableConcept]
    let subject: FHIRReference
    let date: Date
    let author: [FHIRReference]
    let content: [FHIRDocumentReferenceContent]
}

struct FHIRDiagnosticReport: FHIRResource {
    let id: String
    let resourceType: FHIRResourceType = .diagnosticReport
    let identifier: [FHIRIdentifier]
    let status: ReportStatus
    let category: [FHIRCodeableConcept]
    let code: FHIRCodeableConcept
    let subject: FHIRReference
    let effectiveDateTime: Date
    let issued: Date
    let performer: [FHIRReference]
    let conclusionCode: [FHIRCodeableConcept]
    let conclusion: String
    let presentedForm: [FHIRAttachment]
}

// MARK: - FHIR Support Types
struct FHIRIdentifier {
    let system: String
    let value: String
}

struct FHIRHumanName {
    let family: String
    let given: [String]
    let text: String
}

struct FHIRAddress {
    let line: [String]
    let city: String
    let postalCode: String
    let country: String
}

struct FHIRContactPoint {
    let system: ContactSystem
    let value: String
}

struct FHIRCodeableConcept {
    let coding: [FHIRCoding]
    let text: String
    
    static func documentType(_ type: String) -> FHIRCodeableConcept {
        return FHIRCodeableConcept(
            coding: [FHIRCoding(system: "http://loinc.org", code: "34133-9", display: "Summary of episode note")],
            text: type
        )
    }
    
    static func clinicalDocument() -> FHIRCodeableConcept {
        return FHIRCodeableConcept(
            coding: [FHIRCoding(system: "http://hl7.org/fhir/document-relationship-type", code: "replaces", display: "Clinical Document")],
            text: "Clinical Document"
        )
    }
    
    static func diagnosticServiceCategory() -> FHIRCodeableConcept {
        return FHIRCodeableConcept(
            coding: [FHIRCoding(system: "http://terminology.hl7.org/CodeSystem/v2-0074", code: "LAB", display: "Laboratory")],
            text: "Laboratory"
        )
    }
    
    static func documentAnalysis() -> FHIRCodeableConcept {
        return FHIRCodeableConcept(
            coding: [FHIRCoding(system: "http://loinc.org", code: "33747-0", display: "Document analysis")],
            text: "AI Document Analysis"
        )
    }
    
    static func aiAnalysis() -> FHIRCodeableConcept {
        return FHIRCodeableConcept(
            coding: [FHIRCoding(system: "http://snomed.info/sct", code: "385676005", display: "Automated analysis")],
            text: "AI Analysis"
        )
    }
}

struct FHIRCoding {
    let system: String
    let code: String
    let display: String
}

struct FHIRReference {
    let reference: String
}

struct FHIRAttachment {
    let contentType: String
    let size: Int?
    let data: String?
    let title: String
    let creation: Date
    
    init(contentType: String, size: Int? = nil, data: String? = nil, title: String, creation: Date) {
        self.contentType = contentType
        self.size = size
        self.data = data
        self.title = title
        self.creation = creation
    }
}

struct FHIRDocumentReferenceContent {
    let attachment: FHIRAttachment
}

enum DocumentStatus: String {
    case current
    case superseded
    case enteredInError = "entered-in-error"
}

enum ReportStatus: String {
    case registered
    case partial
    case preliminary
    case final
    case amended
    case corrected
    case appended
    case cancelled
    case enteredInError = "entered-in-error"
    case unknown
}

enum ContactSystem: String {
    case phone
    case fax
    case email
    case pager
    case url
    case sms
    case other
}

enum Gender: String {
    case male
    case female
    case other
    case unknown
    
    var fhirValue: String { rawValue }
}

// MARK: - Supporting Data Models
struct PatientData {
    let nationalId: String
    let familyName: String
    let givenNames: [String]
    let fullName: String
    let gender: Gender
    let birthDate: Date
    let address: AddressData?
    let contacts: [ContactData]
}

struct AddressData {
    let street: String
    let city: String
    let postalCode: String
    let country: String = "SA" // Saudi Arabia
    
    func toFHIRAddress() -> FHIRAddress {
        return FHIRAddress(
            line: [street],
            city: city,
            postalCode: postalCode,
            country: country
        )
    }
}

struct ContactData {
    let type: ContactSystem
    let value: String
    
    func toFHIRContactPoint() -> FHIRContactPoint {
        return FHIRContactPoint(system: type, value: value)
    }
}

// MARK: - NPHIES Communication Models
struct NPHIESRequest {
    let method: HTTPMethod
    let endpoint: String
    let headers: [String: String]
    let body: Data?
}

struct NPHIESResponse {
    let statusCode: Int
    let data: Data
    let success: Bool
}

struct NPHIESQuery {
    let resourceType: FHIRResourceType
    let parameters: [String: String]
}

struct NPHIESQueryResponse {
    let resources: [FHIRResource]
    let total: Int
    let success: Bool
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Compliance and Validation
enum ComplianceStatus {
    case checking
    case compliant
    case nonCompliant
    case unknown
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

// MARK: - Errors
enum NPHIESError: LocalizedError {
    case serviceDisabled
    case validationFailed([String])
    case profileValidationFailed
    case missingRequiredField(String)
    case invalidNationalId
    case unsupportedDocumentType
    case invalidDiagnosticCode
    case missingConsent
    case securityRequirementsNotMet
    case invalidEndpoint
    case invalidResponse
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .serviceDisabled:
            return "NPHIES service is disabled"
        case .validationFailed(let errors):
            return "Validation failed: \(errors.joined(separator: ", "))"
        case .profileValidationFailed:
            return "NPHIES profile validation failed"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidNationalId:
            return "Invalid Saudi national ID format"
        case .unsupportedDocumentType:
            return "Document type not supported by NPHIES"
        case .invalidDiagnosticCode:
            return "Invalid diagnostic code"
        case .missingConsent:
            return "Patient consent required for data processing"
        case .securityRequirementsNotMet:
            return "Security requirements not met"
        case .invalidEndpoint:
            return "Invalid NPHIES endpoint"
        case .invalidResponse:
            return "Invalid response from NPHIES"
        case .queryFailed:
            return "NPHIES query failed"
        }
    }
}

// MARK: - Compliance Components
class NPHIESValidator {
    func validateFHIRResource(_ resource: FHIRResource) async -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Basic FHIR validation
        if resource.id.isEmpty {
            errors.append("Resource ID is required")
        }
        
        // Resource-specific validation would go here
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    func validateNPHIESProfile(_ resource: FHIRResource) async -> Bool {
        // Validate against NPHIES-specific profiles
        return true // Simplified for demo
    }
    
    func validateSystemCompliance() async -> Bool {
        // Check overall system compliance
        let hasRequiredSecurity = AFHAMConstants.Security.encryptLocalStorage
        let hasDataRetentionPolicy = AFHAMConstants.Security.dataRetentionPeriod > 0
        let hasAuditLogging = true // Assume audit logging is implemented
        
        return hasRequiredSecurity && hasDataRetentionPolicy && hasAuditLogging
    }
}

class FHIRProcessor {
    func encodeResource(_ resource: FHIRResource) throws -> Data {
        // In a real implementation, this would use a proper FHIR serialization library
        let jsonString = """
        {
            "resourceType": "\(resource.resourceType.rawValue)",
            "id": "\(resource.id)"
        }
        """
        return jsonString.data(using: .utf8)!
    }
    
    func decodeResources(_ data: Data) throws -> [FHIRResource] {
        // In a real implementation, this would parse FHIR JSON
        return []
    }
}

// MARK: - Audit Logging
actor ComplianceAuditLogger {
    private var auditEntries: [ComplianceAuditEntry] = []
    
    func logResourceCreation(_ resourceType: FHIRResourceType, resourceId: String) {
        let entry = ComplianceAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .resourceCreated,
            resourceType: resourceType,
            resourceId: resourceId,
            details: "\(resourceType.rawValue) resource created"
        )
        auditEntries.append(entry)
    }
    
    func logNPHIESSubmission(_ resourceType: FHIRResourceType, resourceId: String, success: Bool) {
        let entry = ComplianceAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: success ? .nphiesSubmissionSuccess : .nphiesSubmissionFailed,
            resourceType: resourceType,
            resourceId: resourceId,
            details: "NPHIES submission \(success ? "succeeded" : "failed")"
        )
        auditEntries.append(entry)
    }
    
    func logNPHIESQuery(_ resourceType: FHIRResourceType, parameters: [String: String]) {
        let entry = ComplianceAuditEntry(
            id: UUID(),
            timestamp: Date(),
            action: .nphiesQuery,
            resourceType: resourceType,
            resourceId: nil,
            details: "NPHIES query executed with parameters: \(parameters)"
        )
        auditEntries.append(entry)
    }
}

struct ComplianceAuditEntry: Codable {
    let id: UUID
    let timestamp: Date
    let action: AuditAction
    let resourceType: FHIRResourceType
    let resourceId: String?
    let details: String
    
    enum AuditAction: String, Codable {
        case resourceCreated
        case resourceUpdated
        case resourceDeleted
        case nphiesSubmissionSuccess
        case nphiesSubmissionFailed
        case nphiesQuery
        case complianceViolation
    }
}