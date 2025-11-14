//
//  ExportManager.swift
//  AFHAM - Export Manager
//
//  Handles exporting captured insights to various formats:
//  FHIR Observation, PDF, CSV, JSON, WhatsApp, Plain Text
//

import Foundation
import SwiftUI
import PDFKit

// MARK: - Export Manager

class ExportManager {

    // MARK: - Main Export Method

    func export(insight: CapturedInsight, format: ExportFormat) async throws {
        switch format {
        case .fhir:
            try await exportAsFHIR(insight)
        case .pdf:
            try await exportAsPDF(insight)
        case .csv:
            try await exportAsCSV(insight)
        case .json:
            try await exportAsJSON(insight)
        case .whatsapp:
            try await exportAsWhatsAppSummary(insight)
        case .text:
            try await exportAsText(insight)
        }
    }

    // MARK: - FHIR Export

    private func exportAsFHIR(_ insight: CapturedInsight) async throws {
        let fhirObservation = createFHIRObservation(from: insight)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(fhirObservation)

        let filename = "FHIR_Observation_\(insight.documentId.uuidString).json"
        try await saveAndShare(data: jsonData, filename: filename, mimeType: "application/fhir+json")
    }

    private func createFHIRObservation(from insight: CapturedInsight) -> FHIRObservation {
        var observations: [FHIRObservationComponent] = []

        // Add findings from template analysis
        if let templateAnalysis = insight.templateAnalysis {
            for finding in templateAnalysis.specificFindings {
                let component = FHIRObservationComponent(
                    code: FHIRCodeableConcept(
                        coding: [FHIRCoding(
                            system: "http://afham.health/observation",
                            code: finding.key.replacingOccurrences(of: " ", with: "_").lowercased(),
                            display: finding.key
                        )],
                        text: finding.key
                    ),
                    valueString: "\(finding.value) \(finding.unit ?? "")"
                )
                observations.append(component)
            }
        }

        return FHIRObservation(
            resourceType: "Observation",
            id: insight.id.uuidString,
            status: "final",
            category: [
                FHIRCodeableConcept(
                    coding: [FHIRCoding(
                        system: "http://terminology.hl7.org/CodeSystem/observation-category",
                        code: "procedure",
                        display: "Procedure"
                    )],
                    text: nil
                )
            ],
            code: FHIRCodeableConcept(
                coding: [FHIRCoding(
                    system: "http://afham.health/document-type",
                    code: insight.capturedDocument.documentType.rawValue,
                    display: insight.capturedDocument.documentType.displayName
                )],
                text: insight.capturedDocument.documentType.displayName
            ),
            effectiveDateTime: ISO8601DateFormatter().string(from: insight.timestamp),
            issued: ISO8601DateFormatter().string(from: insight.timestamp),
            valueString: insight.unifiedSummary,
            component: observations.isEmpty ? nil : observations
        )
    }

    // MARK: - PDF Export

    private func exportAsPDF(_ insight: CapturedInsight) async throws {
        let pdfData = try createPDFDocument(from: insight)

        let filename = "Document_Analysis_\(dateFormatter.string(from: insight.timestamp)).pdf"
        try await saveAndShare(data: pdfData, filename: filename, mimeType: "application/pdf")
    }

    private func createPDFDocument(from insight: CapturedInsight) throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "AFHAM - AI Health Assistant",
            kCGPDFContextAuthor: "AFHAM System",
            kCGPDFContextTitle: "Document Analysis Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.black
            ]
            let title = "Document Analysis Report"
            title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40

            // Document type
            let typeAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ]
            let type = "Type: \(insight.capturedDocument.documentType.displayName)"
            type.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: typeAttributes)
            yPosition += 30

            // Date
            let date = "Date: \(dateFormatter.string(from: insight.timestamp))"
            date.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: typeAttributes)
            yPosition += 40

            // Image
            if let image = UIImage(data: insight.capturedDocument.imageData) {
                let maxImageHeight: CGFloat = 200
                let imageWidth: CGFloat = 495
                let aspectRatio = image.size.height / image.size.width
                let imageHeight = min(imageWidth * aspectRatio, maxImageHeight)

                image.draw(in: CGRect(x: 50, y: yPosition, width: imageWidth, height: imageHeight))
                yPosition += imageHeight + 30
            }

            // Summary section
            if yPosition > 700 {
                context.beginPage()
                yPosition = 50
            }

            let sectionAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            "Summary".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
            yPosition += 30

            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]

            let summaryRect = CGRect(x: 50, y: yPosition, width: 495, height: 100)
            insight.unifiedSummary.draw(in: summaryRect, withAttributes: bodyAttributes)
            yPosition += 120

            // Findings
            if let templateAnalysis = insight.templateAnalysis, !templateAnalysis.specificFindings.isEmpty {
                if yPosition > 700 {
                    context.beginPage()
                    yPosition = 50
                }

                "Findings".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionAttributes)
                yPosition += 30

                for finding in templateAnalysis.specificFindings.prefix(10) {
                    let findingText = "\(finding.key): \(finding.value) \(finding.unit ?? "")"
                    findingText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
                    yPosition += 20

                    if yPosition > 800 {
                        context.beginPage()
                        yPosition = 50
                    }
                }
            }

            // Footer
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ]
            "Generated by AFHAM - AI Health Assistant".draw(
                at: CGPoint(x: 50, y: 800),
                withAttributes: footerAttributes
            )
        }

        return data
    }

    // MARK: - CSV Export

    private func exportAsCSV(_ insight: CapturedInsight) async throws {
        var csv = "Category,Key,Value,Unit,Status\n"

        if let templateAnalysis = insight.templateAnalysis {
            for finding in templateAnalysis.specificFindings {
                let row = [
                    finding.category,
                    finding.key,
                    finding.value,
                    finding.unit ?? "",
                    finding.status.rawValue
                ].map { "\"\($0)\"" }.joined(separator: ",")

                csv += row + "\n"
            }
        }

        let filename = "Analysis_\(dateFormatter.string(from: insight.timestamp)).csv"
        let data = csv.data(using: .utf8)!
        try await saveAndShare(data: data, filename: filename, mimeType: "text/csv")
    }

    // MARK: - JSON Export

    private func exportAsJSON(_ insight: CapturedInsight) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(insight)

        let filename = "Insight_\(insight.id.uuidString).json"
        try await saveAndShare(data: jsonData, filename: filename, mimeType: "application/json")
    }

    // MARK: - WhatsApp Summary Export

    private func exportAsWhatsAppSummary(_ insight: CapturedInsight) async throws {
        var message = "📋 *\(insight.capturedDocument.documentType.displayName)*\n\n"
        message += "*Date:* \(dateFormatter.string(from: insight.timestamp))\n\n"
        message += "*Summary:*\n\(insight.unifiedSummary)\n\n"

        if !insight.allActionItems.isEmpty {
            message += "*Action Items:*\n"
            for (index, action) in insight.allActionItems.prefix(5).enumerated() {
                message += "\(index + 1). \(action.title)\n"
            }
            message += "\n"
        }

        if let templateAnalysis = insight.templateAnalysis, !templateAnalysis.specificFindings.isEmpty {
            message += "*Key Findings:*\n"
            for finding in templateAnalysis.specificFindings.prefix(5) {
                let statusEmoji = finding.status == .normal ? "✅" : "⚠️"
                message += "\(statusEmoji) \(finding.key): \(finding.value) \(finding.unit ?? "")\n"
            }
        }

        message += "\n_Generated by AFHAM AI Health Assistant_"

        // Create shareable text
        let data = message.data(using: .utf8)!
        let filename = "WhatsApp_Summary.txt"
        try await saveAndShare(data: data, filename: filename, mimeType: "text/plain")
    }

    // MARK: - Plain Text Export

    private func exportAsText(_ insight: CapturedInsight) async throws {
        var text = "AFHAM Document Analysis Report\n"
        text += "================================\n\n"
        text += "Document Type: \(insight.capturedDocument.documentType.displayName)\n"
        text += "Date: \(dateFormatter.string(from: insight.timestamp))\n"
        text += "Confidence: \(Int(insight.overallConfidence * 100))%\n\n"
        text += "SUMMARY\n"
        text += "-------\n"
        text += "\(insight.unifiedSummary)\n\n"
        text += "EXTRACTED TEXT\n"
        text += "--------------\n"
        text += "\(insight.unifiedText)\n"

        let data = text.data(using: .utf8)!
        let filename = "Document_\(dateFormatter.string(from: insight.timestamp)).txt"
        try await saveAndShare(data: data, filename: filename, mimeType: "text/plain")
    }

    // MARK: - Save and Share

    private func saveAndShare(data: Data, filename: String, mimeType: String) async throws {
        // Save to temporary directory
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: tempURL)

        // Present share sheet on main thread
        await MainActor.run {
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
        }
    }

    // MARK: - Helpers

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - FHIR Models for Export

struct FHIRObservation: Codable {
    let resourceType: String
    let id: String
    let status: String
    let category: [FHIRCodeableConcept]?
    let code: FHIRCodeableConcept
    let effectiveDateTime: String?
    let issued: String?
    let valueString: String?
    let component: [FHIRObservationComponent]?
}

struct FHIRObservationComponent: Codable {
    let code: FHIRCodeableConcept
    let valueString: String?
}

struct FHIRCodeableConcept: Codable {
    let coding: [FHIRCoding]?
    let text: String?
}

struct FHIRCoding: Codable {
    let system: String?
    let code: String?
    let display: String?
}
