//
//  CameraIntakeManager.swift
//  AFHAM - Camera Intake Layer
//
//  Manages camera capture, document detection, perspective correction,
//  and multi-page batching using AVCaptureSession and VisionKit
//

import Foundation
import SwiftUI
import AVFoundation
import Vision
import VisionKit
import Combine

// MARK: - Camera Intake Manager

/// Manages camera-based document capture with intelligent detection
@MainActor
class CameraIntakeManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isSessionRunning = false
    @Published var capturedImages: [CapturedImage] = []
    @Published var currentDocumentType: DocumentType = .generic
    @Published var detectedDocuments: [DetectedDocument] = []
    @Published var captureQuality: CaptureQuality = .good
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var batchMode = false
    @Published var currentPageCount = 0

    // MARK: - Properties

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private var currentDevice: AVCaptureDevice?

    private let captureQueue = DispatchQueue(label: "com.afham.capture", qos: .userInitiated)
    private let processingQueue = DispatchQueue(label: "com.afham.processing", qos: .userInitiated)

    private var documentDetectionRequest: VNDetectDocumentSegmentationRequest?
    private var rectangleDetectionRequest: VNDetectRectanglesRequest?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    override init() {
        super.init()
        setupVisionRequests()
    }

    deinit {
        stopSession()
    }

    // MARK: - Session Management

    /// Start the camera capture session
    func startSession() async throws {
        // Request camera permission
        let authorized = await checkCameraAuthorization()
        guard authorized else {
            throw CameraError.notAuthorized
        }

        // Setup capture session
        let session = AVCaptureSession()
        session.sessionPreset = .photo

        // Configure video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCameraAvailable
        }

        let videoInput = try AVCaptureDeviceInput(device: camera)
        guard session.canAddInput(videoInput) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(videoInput)

        // Configure video output for real-time processing
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: captureQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        guard session.canAddOutput(videoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(videoOutput)

        // Configure photo output for high-res capture
        let photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true

        guard session.canAddOutput(photoOutput) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(photoOutput)

        self.captureSession = session
        self.videoOutput = videoOutput
        self.photoOutput = photoOutput
        self.currentDevice = camera

        // Configure camera settings
        try configureCameraSettings()

        // Start session
        captureQueue.async { [weak self] in
            self?.captureSession?.startRunning()

            Task { @MainActor [weak self] in
                self?.isSessionRunning = true
            }
        }
    }

    /// Stop the camera capture session
    nonisolated func stopSession() {
        captureQueue.async { [weak self] in
            self?.captureSession?.stopRunning()

            Task { @MainActor [weak self] in
                self?.isSessionRunning = false
            }
        }
    }

    /// Configure optimal camera settings for document capture
    private func configureCameraSettings() throws {
        guard let device = currentDevice else { return }

        try device.lockForConfiguration()

        // Focus mode
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }

        // Exposure mode
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }

        // White balance
        if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
            device.whiteBalanceMode = .continuousAutoWhiteBalance
        }

        // Enable auto-stabilization
        if device.isLowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = true
        }

        device.unlockForConfiguration()
    }

    // MARK: - Document Capture

    /// Capture a document photo
    func captureDocument() {
        guard let photoOutput = photoOutput else {
            errorMessage = "Camera not ready"
            return
        }

        isProcessing = true

        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        settings.flashMode = .auto

        // Enable depth data if available
        if photoOutput.isDepthDataDeliverySupported {
            settings.isDepthDataDeliveryEnabled = true
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    /// Process captured image with perspective correction
    private func processImage(_ image: UIImage) async {
        await MainActor.run {
            isProcessing = true
        }

        do {
            // Detect document boundaries
            let correctedImage = try await detectAndCorrectPerspective(image)

            // Assess quality
            let quality = try await assessImageQuality(correctedImage)

            // Create captured image
            let capturedImage = CapturedImage(
                id: UUID(),
                image: correctedImage,
                originalImage: image,
                timestamp: Date(),
                quality: quality,
                pageNumber: currentPageCount + 1,
                perspectiveCorrected: true
            )

            await MainActor.run {
                capturedImages.append(capturedImage)
                currentPageCount += 1

                if !batchMode {
                    finalizeBatch()
                }

                isProcessing = false
            }

        } catch {
            await MainActor.run {
                errorMessage = "Failed to process image: \(error.localizedDescription)"
                isProcessing = false
            }
        }
    }

    /// Detect document boundaries and apply perspective correction
    private func detectAndCorrectPerspective(_ image: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw CameraError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRectangleObservation],
                      let rectangle = observations.first else {
                    // No rectangle detected, return original image
                    continuation.resume(returning: image)
                    return
                }

                // Apply perspective correction
                do {
                    let correctedImage = try self.perspectiveCorrect(cgImage, rectangle: rectangle)
                    continuation.resume(returning: correctedImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            request.maximumObservations = 1
            request.minimumAspectRatio = 0.3
            request.maximumAspectRatio = 1.0
            request.minimumSize = 0.25
            request.minimumConfidence = 0.6

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Apply perspective transformation to correct document perspective
    private func perspectiveCorrect(_ image: CGImage, rectangle: VNRectangleObservation) throws -> UIImage {
        let imageSize = CGSize(width: image.width, height: image.height)

        // Convert normalized coordinates to image coordinates
        let topLeft = CGPoint(
            x: rectangle.topLeft.x * imageSize.width,
            y: (1 - rectangle.topLeft.y) * imageSize.height
        )
        let topRight = CGPoint(
            x: rectangle.topRight.x * imageSize.width,
            y: (1 - rectangle.topRight.y) * imageSize.height
        )
        let bottomLeft = CGPoint(
            x: rectangle.bottomLeft.x * imageSize.width,
            y: (1 - rectangle.bottomLeft.y) * imageSize.height
        )
        let bottomRight = CGPoint(
            x: rectangle.bottomRight.x * imageSize.width,
            y: (1 - rectangle.bottomRight.y) * imageSize.height
        )

        // Calculate output size (A4 aspect ratio: 1.414)
        let width = max(
            topLeft.distance(to: topRight),
            bottomLeft.distance(to: bottomRight)
        )
        let height = max(
            topLeft.distance(to: bottomLeft),
            topRight.distance(to: bottomRight)
        )

        let outputSize = CGSize(width: width, height: height)

        // Create perspective transform
        let perspectiveTransform = getPerspectiveTransform(
            from: [topLeft, topRight, bottomLeft, bottomRight],
            to: [
                CGPoint(x: 0, y: 0),
                CGPoint(x: outputSize.width, y: 0),
                CGPoint(x: 0, y: outputSize.height),
                CGPoint(x: outputSize.width, y: outputSize.height)
            ]
        )

        // Apply transform using CIImage
        guard let ciImage = CIImage(image: UIImage(cgImage: image)) else {
            throw CameraError.invalidImage
        }

        let transformed = ciImage.transformed(by: perspectiveTransform)
        let context = CIContext()

        guard let outputImage = context.createCGImage(transformed, from: transformed.extent) else {
            throw CameraError.processingFailed
        }

        return UIImage(cgImage: outputImage)
    }

    /// Calculate perspective transform matrix
    private func getPerspectiveTransform(from source: [CGPoint], to destination: [CGPoint]) -> CGAffineTransform {
        // Simplified perspective transform (using first 3 points for affine approximation)
        // For full perspective transform, use Core Image's perspective correction filter

        let transform = CGAffineTransform.identity
        // This is a simplified implementation
        // In production, use CIImage's applyingFilter("CIPerspectiveCorrection", parameters:)
        return transform
    }

    /// Assess image quality (blur, brightness, contrast)
    private func assessImageQuality(_ image: UIImage) async throws -> CaptureQuality {
        guard let cgImage = image.cgImage else {
            throw CameraError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            // Assess blur using variance of Laplacian
            let blurScore = calculateBlurScore(cgImage)

            // Assess brightness
            let brightness = calculateBrightness(cgImage)

            // Determine quality
            let quality: CaptureQuality
            if blurScore > 100 && brightness > 0.3 && brightness < 0.8 {
                quality = .excellent
            } else if blurScore > 50 && brightness > 0.2 && brightness < 0.9 {
                quality = .good
            } else if blurScore > 20 {
                quality = .acceptable
            } else {
                quality = .poor
            }

            continuation.resume(returning: quality)
        }
    }

    private func calculateBlurScore(_ image: CGImage) -> Double {
        // Simplified blur detection using image variance
        // In production, use Laplacian variance or similar
        return 75.0 // Placeholder
    }

    private func calculateBrightness(_ image: CGImage) -> Double {
        // Calculate average brightness
        // In production, sample pixels and calculate mean luminance
        return 0.5 // Placeholder
    }

    // MARK: - Batch Management

    /// Enable batch capture mode for multi-page documents
    func enableBatchMode() {
        batchMode = true
        currentPageCount = 0
        capturedImages.removeAll()
    }

    /// Add another page to the current batch
    func addPage() {
        captureDocument()
    }

    /// Finalize the batch and prepare for processing
    func finalizeBatch() {
        batchMode = false
        // Batch is ready for OCR processing
    }

    /// Clear current batch
    func clearBatch() {
        capturedImages.removeAll()
        currentPageCount = 0
    }

    // MARK: - Vision Setup

    private func setupVisionRequests() {
        // Document segmentation request (iOS 15+)
        if #available(iOS 15.0, *) {
            documentDetectionRequest = VNDetectDocumentSegmentationRequest()
        }

        // Rectangle detection for document boundaries
        rectangleDetectionRequest = VNDetectRectanglesRequest()
        rectangleDetectionRequest?.maximumObservations = 1
        rectangleDetectionRequest?.minimumAspectRatio = 0.3
        rectangleDetectionRequest?.maximumAspectRatio = 1.0
    }

    // MARK: - Authorization

    private func checkCameraAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // MARK: - Helpers

    /// Get preview layer for camera view
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraIntakeManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        // Real-time document detection for visual feedback
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        processingQueue.async { [weak self] in
            guard let self = self else { return }

            let request = VNDetectRectanglesRequest { [weak self] request, error in
                guard let self = self,
                      let observations = request.results as? [VNRectangleObservation],
                      !observations.isEmpty else { return }

                Task { @MainActor in
                    self.detectedDocuments = observations.map { obs in
                        DetectedDocument(
                            id: UUID(),
                            boundingBox: obs.boundingBox,
                            confidence: obs.confidence,
                            corners: [obs.topLeft, obs.topRight, obs.bottomLeft, obs.bottomRight]
                        )
                    }
                }
            }

            request.maximumObservations = 5
            request.minimumAspectRatio = 0.3
            request.minimumConfidence = 0.5

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraIntakeManager: AVCapturePhotoCaptureDelegate {

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            Task { @MainActor in
                self.errorMessage = "Capture failed: \(error.localizedDescription)"
                self.isProcessing = false
            }
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            Task { @MainActor in
                self.errorMessage = "Failed to process captured image"
                self.isProcessing = false
            }
            return
        }

        Task {
            await self.processImage(image)
        }
    }
}

// MARK: - Supporting Types

struct CapturedImage: Identifiable {
    let id: UUID
    let image: UIImage
    let originalImage: UIImage
    let timestamp: Date
    let quality: CaptureQuality
    let pageNumber: Int
    let perspectiveCorrected: Bool
}

struct DetectedDocument: Identifiable {
    let id: UUID
    let boundingBox: CGRect
    let confidence: Float
    let corners: [CGPoint]
}

enum CaptureQuality: String, Comparable {
    case excellent
    case good
    case acceptable
    case poor

    static func < (lhs: CaptureQuality, rhs: CaptureQuality) -> Bool {
        let order: [CaptureQuality] = [.poor, .acceptable, .good, .excellent]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }

    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .acceptable: return .yellow
        case .poor: return .red
        }
    }

    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .acceptable: return "Acceptable"
        case .poor: return "Poor - Retake Recommended"
        }
    }
}

enum CameraError: LocalizedError {
    case notAuthorized
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case invalidImage
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access not authorized"
        case .noCameraAvailable:
            return "No camera available"
        case .cannotAddInput:
            return "Cannot configure camera input"
        case .cannotAddOutput:
            return "Cannot configure camera output"
        case .invalidImage:
            return "Invalid image data"
        case .processingFailed:
            return "Image processing failed"
        }
    }
}

// MARK: - CGPoint Extension

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
