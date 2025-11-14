//
//  MedicalTemplateEngine.swift
//  AFHAM - Medical Template Analysis Engine
//
//  Provides specialized analysis for different medical document types:
//  Lab reports, prescriptions, insurance claims, food labels, etc.
//

import Foundation
import SwiftUI

// MARK: - Medical Template Engine

/// Specialized analysis engine for medical and healthcare documents
class MedicalTemplateEngine {

    // MARK: - Template Analysis

    /// Analyze document using specialized template
    func analyzeWithTemplate(
        documentType: DocumentType,
        extractedText: String,
        tables: [TableStructure],
        entities: [ExtractedEntity]
    ) async throws -> TemplateAnalysisResult {

        switch documentType {
        case .labReport:
            return try await analyzeLabReport(text: extractedText, tables: tables, entities: entities)

        case .prescription:
            return try await analyzePrescription(text: extractedText, entities: entities)

        case .insuranceClaim:
            return try await analyzeInsuranceClaim(text: extractedText, tables: tables, entities: entities)

        case .medicalReport:
            return try await analyzeMedicalReport(text: extractedText, entities: entities)

        case .foodLabel:
            return try await analyzeFoodLabel(text: extractedText, tables: tables)

        case .pharmacyLabel:
            return try await analyzePharmacyLabel(text: extractedText, entities: entities)

        default:
            return try await analyzeGeneric(text: extractedText, documentType: documentType)
        }
    }

    // MARK: - Lab Report Analysis

    private func analyzeLabReport(
        text: String,
        tables: [TableStructure],
        entities: [ExtractedEntity]
    ) async throws -> TemplateAnalysisResult {

        var findings: [TemplateFinding] = []
        var interpretations: [Interpretation] = []
        var recommendations: [String] = []
        var visualizations: [VisualizationData] = []

        // Extract lab values from tables or text
        let labValues = extractLabValues(from: text, tables: tables)

        for labValue in labValues {
            let finding = TemplateFinding(
                category: labValue.category,
                key: labValue.testName,
                value: labValue.value,
                unit: labValue.unit,
                normalRange: labValue.normalRange,
                status: labValue.status,
                citations: []
            )
            findings.append(finding)

            // Add interpretation for abnormal values
            if labValue.status != .normal {
                let interpretation = Interpretation(
                    title: "\(labValue.testName) \(labValue.status.rawValue)",
                    description: generateLabInterpretation(labValue),
                    confidence: 0.85,
                    sources: ["Clinical lab reference ranges"]
                )
                interpretations.append(interpretation)
            }
        }

        // Generate recommendations
        let abnormalValues = labValues.filter { $0.status != .normal }
        if !abnormalValues.isEmpty {
            recommendations.append("Consult with your healthcare provider about the abnormal values")

            let criticalValues = abnormalValues.filter { $0.status == .critical }
            if !criticalValues.isEmpty {
                recommendations.insert("⚠️ URGENT: Critical values detected - seek immediate medical attention", at: 0)
            }
        } else {
            recommendations.append("All values are within normal range")
        }

        // Create visualization data
        if !labValues.isEmpty {
            let chartData = Dictionary(
                uniqueKeysWithValues: labValues.prefix(10).map { ($0.testName, $0.numericValue ?? 0) }
            )

            visualizations.append(VisualizationData(
                type: .barChart,
                title: "Lab Test Results",
                data: chartData
            ))
        }

        return TemplateAnalysisResult(
            templateType: .labReport,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: recommendations,
            visualizations: visualizations
        )
    }

    // MARK: - Prescription Analysis

    private func analyzePrescription(
        text: String,
        entities: [ExtractedEntity]
    ) async throws -> TemplateAnalysisResult {

        var findings: [TemplateFinding] = []
        var interpretations: [Interpretation] = []
        var recommendations: [String] = []

        // Extract medications
        let medications = extractMedications(from: text, entities: entities)

        for medication in medications {
            let finding = TemplateFinding(
                category: "Medication",
                key: medication.name,
                value: medication.dosage,
                unit: medication.frequency,
                normalRange: nil,
                status: .normal,
                citations: []
            )
            findings.append(finding)

            // Add usage instructions
            let interpretation = Interpretation(
                title: medication.name,
                description: "Dosage: \(medication.dosage)\nFrequency: \(medication.frequency)\nDuration: \(medication.duration ?? "As prescribed")",
                confidence: 0.9,
                sources: []
            )
            interpretations.append(interpretation)
        }

        // Generate recommendations
        recommendations.append("Take medications exactly as prescribed")
        recommendations.append("Set reminders for medication times")
        recommendations.append("Contact pharmacist for any questions")

        if medications.count > 3 {
            recommendations.append("Consider using a pill organizer for multiple medications")
        }

        return TemplateAnalysisResult(
            templateType: .prescription,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: recommendations,
            visualizations: nil
        )
    }

    // MARK: - Insurance Claim Analysis

    private func analyzeInsuranceClaim(
        text: String,
        tables: [TableStructure],
        entities: [ExtractedEntity]
    ) async throws -> TemplateAnalysisResult {

        var findings: [TemplateFinding] = []
        var interpretations: [Interpretation] = []
        var recommendations: [String] = []

        // Extract claim details
        let claimDetails = extractClaimDetails(from: text, tables: tables)

        // Policy information
        if let policyNumber = claimDetails["policy_number"] {
            findings.append(TemplateFinding(
                category: "Policy",
                key: "Policy Number",
                value: policyNumber,
                status: .normal
            ))
        }

        // Claim amount
        if let claimAmount = claimDetails["claim_amount"] {
            findings.append(TemplateFinding(
                category: "Financial",
                key: "Claim Amount",
                value: claimAmount,
                unit: "SAR",
                status: .normal
            ))
        }

        // Coverage amount
        if let coverageAmount = claimDetails["coverage_amount"] {
            findings.append(TemplateFinding(
                category: "Financial",
                key: "Coverage Amount",
                value: coverageAmount,
                unit: "SAR",
                status: .normal
            ))
        }

        // Detect denial or issues
        if text.lowercased().contains("denied") || text.lowercased().contains("rejected") {
            let interpretation = Interpretation(
                title: "Claim Status: Denied",
                description: "This claim has been denied. Review the reason codes and consider appealing if appropriate.",
                confidence: 0.9,
                sources: []
            )
            interpretations.append(interpretation)

            recommendations.append("⚠️ Review the denial reason carefully")
            recommendations.append("Contact insurance provider for clarification")
            recommendations.append("Consider filing an appeal if you believe the denial is incorrect")
        } else {
            recommendations.append("Review claim details for accuracy")
            recommendations.append("Keep this document for your records")
        }

        return TemplateAnalysisResult(
            templateType: .insuranceClaim,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: recommendations,
            visualizations: nil
        )
    }

    // MARK: - Medical Report Analysis

    private func analyzeMedicalReport(
        text: String,
        entities: [ExtractedEntity]
    ) async throws -> TemplateAnalysisResult {

        var findings: [TemplateFinding] = []
        var interpretations: [Interpretation] = []
        var recommendations: [String] = []

        // Extract diagnoses
        let diagnoses = entities.filter { $0.type == .diagnosis }
        for diagnosis in diagnoses {
            findings.append(TemplateFinding(
                category: "Diagnosis",
                key: "Diagnosed Condition",
                value: diagnosis.value,
                status: .normal
            ))
        }

        // Extract procedures
        let procedures = entities.filter { $0.type == .procedure }
        for procedure in procedures {
            findings.append(TemplateFinding(
                category: "Procedure",
                key: "Performed Procedure",
                value: procedure.value,
                status: .normal
            ))
        }

        // General recommendations
        recommendations.append("Discuss this report with your healthcare provider")
        recommendations.append("Keep for your medical records")
        recommendations.append("Share with specialists as needed")

        return TemplateAnalysisResult(
            templateType: .medicalReport,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: recommendations,
            visualizations: nil
        )
    }

    // MARK: - Food Label Analysis

    private func analyzeFoodLabel(
        text: String,
        tables: [TableStructure]
    ) async throws -> TemplateAnalysisResult {

        var findings: [TemplateFinding] = []
        var interpretations: [Interpretation] = []
        var recommendations: [String] = []
        var visualizations: [VisualizationData] = []

        // Extract nutrition facts
        let nutritionFacts = extractNutritionFacts(from: text, tables: tables)

        for (nutrient, value) in nutritionFacts {
            let status = assessNutrientLevel(nutrient: nutrient, value: value)

            findings.append(TemplateFinding(
                category: "Nutrition",
                key: nutrient,
                value: "\(value)",
                unit: getNutrientUnit(nutrient),
                normalRange: getNutrientDailyValue(nutrient),
                status: status
            ))
        }

        // Generate dietary insights
        if let calories = nutritionFacts["Calories"], calories > 400 {
            interpretations.append(Interpretation(
                title: "High Calorie Content",
                description: "This product contains \(calories) calories per serving, which is relatively high.",
                confidence: 0.95,
                sources: ["FDA nutrition guidelines"]
            ))
        }

        if let sodium = nutritionFacts["Sodium"], sodium > 20 {
            interpretations.append(Interpretation(
                title: "High Sodium",
                description: "This product contains high levels of sodium. Consider limiting intake if you're watching sodium consumption.",
                confidence: 0.9,
                sources: ["WHO sodium intake guidelines"]
            ))
        }

        // Recommendations
        recommendations.append("Consider serving size when planning meals")
        recommendations.append("Balance with low-calorie, nutrient-dense foods")

        if !nutritionFacts.isEmpty {
            visualizations.append(VisualizationData(
                type: .pieChart,
                title: "Macronutrient Distribution",
                data: nutritionFacts
            ))
        }

        return TemplateAnalysisResult(
            templateType: .foodLabel,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: recommendations,
            visualizations: visualizations
        )
    }

    // MARK: - Pharmacy Label Analysis

    private func analyzePharmacyLabel(
        text: String,
        entities: [ExtractedEntity]
    ) async throws -> TemplateAnalysisResult {

        var findings: [TemplateFinding] = []
        var interpretations: [Interpretation] = []
        var recommendations: [String] = []

        // Extract medication info
        let medicationInfo = extractPharmacyInfo(from: text)

        if let drugName = medicationInfo["drug_name"] {
            findings.append(TemplateFinding(
                category: "Medication",
                key: "Drug Name",
                value: drugName,
                status: .normal
            ))
        }

        if let dosage = medicationInfo["dosage"] {
            findings.append(TemplateFinding(
                category: "Dosage",
                key: "Strength",
                value: dosage,
                status: .normal
            ))
        }

        if let directions = medicationInfo["directions"] {
            interpretations.append(Interpretation(
                title: "Usage Instructions",
                description: directions,
                confidence: 0.9,
                sources: []
            ))
        }

        recommendations.append("Follow dosage instructions carefully")
        recommendations.append("Store as directed on the label")
        recommendations.append("Check expiration date before use")

        return TemplateAnalysisResult(
            templateType: .pharmacyLabel,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: recommendations,
            visualizations: nil
        )
    }

    // MARK: - Generic Analysis

    private func analyzeGeneric(
        text: String,
        documentType: DocumentType
    ) async throws -> TemplateAnalysisResult {

        let wordCount = text.split(separator: " ").count

        let findings = [
            TemplateFinding(
                category: "General",
                key: "Word Count",
                value: "\(wordCount)",
                status: .normal
            )
        ]

        let interpretations = [
            Interpretation(
                title: "Document Captured",
                description: "Document successfully processed with \(wordCount) words extracted.",
                confidence: 0.8,
                sources: []
            )
        ]

        return TemplateAnalysisResult(
            templateType: documentType,
            specificFindings: findings,
            interpretations: interpretations,
            recommendations: [],
            visualizations: nil
        )
    }

    // MARK: - Helper Methods

    private func extractLabValues(from text: String, tables: [TableStructure]) -> [LabValue] {
        var values: [LabValue] = []

        // Common lab test patterns
        let labPatterns = [
            "Hemoglobin": (normal: "12.0-16.0", unit: "g/dL", category: "Hematology"),
            "WBC": (normal: "4.0-11.0", unit: "×10³/µL", category: "Hematology"),
            "Platelets": (normal: "150-400", unit: "×10³/µL", category: "Hematology"),
            "Glucose": (normal: "70-100", unit: "mg/dL", category: "Chemistry"),
            "Creatinine": (normal: "0.6-1.2", unit: "mg/dL", category: "Chemistry"),
            "ALT": (normal: "7-56", unit: "U/L", category: "Liver"),
            "AST": (normal: "10-40", unit: "U/L", category: "Liver")
        ]

        for (testName, info) in labPatterns {
            if let value = extractValueForTest(testName, from: text) {
                let numericValue = Double(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0

                let status = assessLabStatus(
                    value: numericValue,
                    normalRange: info.normal,
                    testName: testName
                )

                values.append(LabValue(
                    testName: testName,
                    value: value,
                    unit: info.unit,
                    normalRange: info.normal,
                    category: info.category,
                    status: status,
                    numericValue: numericValue
                ))
            }
        }

        // Also extract from tables
        for table in tables {
            if let headers = table.headers,
               headers.contains(where: { $0.lowercased().contains("test") || $0.lowercased().contains("result") }) {

                for row in table.rows {
                    if row.count >= 2 {
                        let testName = row[0]
                        let value = row[1]

                        values.append(LabValue(
                            testName: testName,
                            value: value,
                            unit: row.count > 2 ? row[2] : "",
                            normalRange: row.count > 3 ? row[3] : nil,
                            category: "Lab",
                            status: .normal,
                            numericValue: Double(value)
                        ))
                    }
                }
            }
        }

        return values
    }

    private func extractValueForTest(_ testName: String, from text: String) -> String? {
        let pattern = "\(testName)[:\\s]+([0-9.]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               match.numberOfRanges > 1,
               let valueRange = Range(match.range(at: 1), in: text) {
                return String(text[valueRange])
            }
        }
        return nil
    }

    private func assessLabStatus(value: Double, normalRange: String, testName: String) -> FindingStatus {
        // Parse normal range
        let components = normalRange.components(separatedBy: "-")
        guard components.count == 2,
              let min = Double(components[0]),
              let max = Double(components[1]) else {
            return .unknown
        }

        if value < min {
            return value < min * 0.7 ? .critical : .abnormalLow
        } else if value > max {
            return value > max * 1.5 ? .critical : .abnormalHigh
        }

        return .normal
    }

    private func generateLabInterpretation(_ labValue: LabValue) -> String {
        switch labValue.status {
        case .abnormalLow:
            return "\(labValue.testName) is below the normal range (\(labValue.normalRange ?? "N/A")). This may indicate various conditions and should be discussed with your healthcare provider."
        case .abnormalHigh:
            return "\(labValue.testName) is above the normal range (\(labValue.normalRange ?? "N/A")). This may indicate various conditions and should be discussed with your healthcare provider."
        case .critical:
            return "⚠️ CRITICAL: \(labValue.testName) is significantly outside the normal range. Seek immediate medical attention."
        default:
            return "\(labValue.testName) is within normal range."
        }
    }

    private func extractMedications(from text: String, entities: [ExtractedEntity]) -> [Medication] {
        var medications: [Medication] = []

        // Use entities to find medication names
        let medicationEntities = entities.filter { $0.type == .medication }

        for entity in medicationEntities {
            let medication = Medication(
                name: entity.value,
                dosage: extractDosage(for: entity.value, from: text) ?? "As prescribed",
                frequency: extractFrequency(for: entity.value, from: text) ?? "As directed",
                duration: extractDuration(for: entity.value, from: text)
            )
            medications.append(medication)
        }

        return medications
    }

    private func extractDosage(for medication: String, from text: String) -> String? {
        let pattern = "\(medication)[^.]*?(\\d+\\s*mg|\\d+\\s*ml|\\d+\\s*tablets?)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func extractFrequency(for medication: String, from text: String) -> String? {
        let frequencies = ["once daily", "twice daily", "three times daily", "every 12 hours", "as needed"]
        for frequency in frequencies {
            if text.lowercased().contains(frequency) {
                return frequency.capitalized
            }
        }
        return nil
    }

    private func extractDuration(for medication: String, from text: String) -> String? {
        let pattern = "for\\s+(\\d+\\s+days?|\\d+\\s+weeks?|\\d+\\s+months?)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func extractClaimDetails(from text: String, tables: [TableStructure]) -> [String: String] {
        var details: [String: String] = [:]

        // Policy number pattern
        if let policyMatch = extractPattern("Policy\\s*(?:Number|#)?[:\\s]*(\\w+)", from: text) {
            details["policy_number"] = policyMatch
        }

        // Claim amount
        if let amountMatch = extractPattern("Claim\\s*Amount[:\\s]*(\\d+[,.]?\\d*)", from: text) {
            details["claim_amount"] = amountMatch
        }

        // Coverage amount
        if let coverageMatch = extractPattern("Coverage\\s*Amount[:\\s]*(\\d+[,.]?\\d*)", from: text) {
            details["coverage_amount"] = coverageMatch
        }

        return details
    }

    private func extractNutritionFacts(from text: String, tables: [TableStructure]) -> [String: Double] {
        var facts: [String: Double] = [:]

        let nutrients = ["Calories", "Total Fat", "Saturated Fat", "Cholesterol", "Sodium",
                        "Carbohydrates", "Fiber", "Sugars", "Protein"]

        for nutrient in nutrients {
            if let value = extractPattern("\(nutrient)[:\\s]*(\\d+)", from: text),
               let numericValue = Double(value) {
                facts[nutrient] = numericValue
            }
        }

        return facts
    }

    private func extractPharmacyInfo(from text: String) -> [String: String] {
        var info: [String: String] = [:]

        if let drugName = extractPattern("(?:Drug|Medication)[:\\s]*([A-Za-z]+)", from: text) {
            info["drug_name"] = drugName
        }

        if let dosage = extractPattern("(\\d+\\s*mg|\\d+\\s*ml)", from: text) {
            info["dosage"] = dosage
        }

        if let directions = extractPattern("Directions[:\\s]*([^.]+)", from: text) {
            info["directions"] = directions
        }

        return info
    }

    private func extractPattern(_ pattern: String, from text: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return nil
    }

    private func assessNutrientLevel(nutrient: String, value: Double) -> FindingStatus {
        // Simplified assessment based on daily values
        switch nutrient {
        case "Sodium":
            return value > 20 ? .abnormalHigh : .normal
        case "Saturated Fat":
            return value > 13 ? .abnormalHigh : .normal
        case "Sugars":
            return value > 25 ? .abnormalHigh : .normal
        default:
            return .normal
        }
    }

    private func getNutrientUnit(_ nutrient: String) -> String {
        switch nutrient {
        case "Calories": return "kcal"
        case "Sodium": return "mg"
        case "Protein", "Total Fat", "Carbohydrates", "Fiber", "Sugars": return "g"
        default: return ""
        }
    }

    private func getNutrientDailyValue(_ nutrient: String) -> String? {
        switch nutrient {
        case "Sodium": return "< 2300 mg/day"
        case "Total Fat": return "< 78 g/day"
        case "Saturated Fat": return "< 20 g/day"
        case "Carbohydrates": return "275 g/day"
        case "Protein": return "50 g/day"
        default: return nil
        }
    }
}

// MARK: - Supporting Types

struct LabValue {
    let testName: String
    let value: String
    let unit: String
    let normalRange: String?
    let category: String
    let status: FindingStatus
    let numericValue: Double?
}

struct Medication {
    let name: String
    let dosage: String
    let frequency: String
    let duration: String?
}
