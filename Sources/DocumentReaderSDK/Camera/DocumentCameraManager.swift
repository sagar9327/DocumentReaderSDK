//
//  DocumentCameraManager.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import AVFoundation
import Vision

final class DocumentCameraManager: NSObject, @unchecked Sendable {
    
    // MARK: - Camera
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // MARK: - Image Quality
    
    private let imageQualityAnalyzer =
    ImageQualityAnalyzer()
    
    // MARK: - Preview
    
    private(set) var previewLayer:
    AVCaptureVideoPreviewLayer?
    
    // MARK: - Callbacks
    
    var onDocumentDetected:
    ((CGRect) -> Void)?
    
    var onDocumentCaptured:
    ((CapturedDocument) -> Void)?
    
    // MARK: - State
    
    private var isCapturing = false
    
    private var stableDetectionCount = 0
    
    private var qualityGoodCount = 0
    
    private var lastDetectedObservation: VNRectangleObservation?
    
    private var frameCounter = 0
    
    // MARK: - Configuration
    
    private let requiredStableFrames = 10
    
    private let requiredGoodQualityFrames = 5
    
    private let minimumConfidence:
    Float = 0.6
    
    private let minimumDocumentSize:
    Float = 0.1
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        
        setupPreviewLayer()
        setupVideoOutput()
    }
    
    // MARK: - Preview Layer
    
    private func setupPreviewLayer() {
        
        let layer =
        AVCaptureVideoPreviewLayer(
            session: session
        )
        
        layer.videoGravity =
            .resizeAspectFill
        
        previewLayer = layer
    }
    
    // MARK: - Video Output
    
    private func setupVideoOutput() {
        
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(
                label: "document.camera.video",
                qos: .userInitiated
            )
        )
        
        videoOutput.alwaysDiscardsLateVideoFrames =
        true
    }
    
    // MARK: - Start Camera
    
    func start() {
        
        guard !session.isRunning else {
            return
        }
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // MARK: Camera
        
        guard let camera =
                AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                )
        else {
            
            print(
                "❌ Back camera not available"
            )
            
            session.commitConfiguration()
            
            return
        }
        
        do {
            
            let input =
            try AVCaptureDeviceInput(
                device: camera
            )
            
            if session.canAddInput(input) {
                
                session.addInput(input)
            }
            
            // MARK: Photo Output
            
            if session.canAddOutput(
                photoOutput
            ) {
                
                session.addOutput(
                    photoOutput
                )
            }
            
            // MARK: Video Output
            
            if session.canAddOutput(
                videoOutput
            ) {
                
                session.addOutput(
                    videoOutput
                )
            }
            
            session.commitConfiguration()
            
            DispatchQueue.global(
                qos: .userInitiated
            ).async { [weak self] in
                
                self?.session.startRunning()
            }
            
        } catch {
            
            session.commitConfiguration()
            
            print(
                "❌ Document camera setup failed:",
                error
            )
        }
    }
    
    // MARK: - Stop Camera
    
    func stop() {
        
        guard session.isRunning else {
            return
        }
        
        DispatchQueue.global(
            qos: .userInitiated
        ).async { [weak self] in
            
            self?.session.stopRunning()
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        
        stableDetectionCount = 0
        
        qualityGoodCount = 0
        
        lastDetectedObservation = nil
        
        frameCounter = 0
        
        isCapturing = false
    }
    
    // MARK: - Capture Photo
    
    private func capturePhoto() {
        
        guard !isCapturing else {
            return
        }
        
        guard let connection =
                photoOutput.connection(
                    with: .video
                )
        else {
            
            print(
                "❌ Photo output connection unavailable"
            )
            
            return
        }
        
        /*
         The scanner is portrait-oriented.
         Make sure the captured photo is also
         portrait-oriented.
         */
        
        if connection.isVideoOrientationSupported {
            
            connection.videoOrientation =
                .portrait
        }
        
        isCapturing = true
        
        let settings =
        AVCapturePhotoSettings()
        
        photoOutput.capturePhoto(
            with: settings,
            delegate: self
        )
    }
}


// MARK: - Video Frame Processing

extension DocumentCameraManager:
    AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
        guard !isCapturing else {
            return
        }
        
        guard let pixelBuffer =
                CMSampleBufferGetImageBuffer(
                    sampleBuffer
                )
        else {
            return
        }
        
        frameCounter += 1
        
        /*
         We don't need to run expensive
         quality analysis on every frame.
         
         Analyze every 5th frame.
         */
        
        let shouldCheckQuality =
        frameCounter % 5 == 0
        
        // MARK: Vision Rectangle Detection
        
        let request =
        VNDetectRectanglesRequest()
        
        request.minimumConfidence =
        minimumConfidence
        
        request.minimumAspectRatio =
        0.5
        
        request.maximumAspectRatio =
        2.0
        
        request.minimumSize =
        minimumDocumentSize
        
        /*
         Rear camera in portrait orientation.
         
         Vision needs the correct image
         orientation to calculate the
         bounding box correctly.
         */
        
        let handler =
        VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .right,
            options: [:]
        )
        
        do {
            
            try handler.perform(
                [request]
            )
            
        } catch {
            
            print(
                "❌ Document detection failed:",
                error
            )
            
            return
        }
        
        // MARK: No Document Detected
        
        guard let rectangle =
                request.results?.first
        else {
            
            stableDetectionCount = 0
            
            qualityGoodCount = 0
            
            lastDetectedObservation = nil
            
            DispatchQueue.main.async { [weak self] in
                
                self?.onDocumentDetected?(
                    .zero
                )
            }
            
            return
        }
        
        // MARK: Bounding Box
        
        let boundingBox =
        rectangle.boundingBox
        
        // MARK: Stability
        
        if let previousObservation =
            lastDetectedObservation {
            
            if isBoundingBoxStable(
                previousObservation.boundingBox,
                boundingBox
            ) {
                
                stableDetectionCount += 1
                
            } else {
                
                stableDetectionCount = 0
            }
            
        } else {
            
            stableDetectionCount = 1
        }
        
        lastDetectedObservation =
        rectangle
        
        // MARK: Update UI
        
        DispatchQueue.main.async { [weak self] in
            
            self?.onDocumentDetected?(
                boundingBox
            )
        }
        
        // MARK: Image Quality
        
        if shouldCheckQuality {
            
            guard let image =
                    imageFromSampleBuffer(
                        sampleBuffer
                    )
            else {
                return
            }
            
            let qualityIsGood =
            validateImageQuality(
                image
            )
            
            if qualityIsGood {
                
                qualityGoodCount += 1
                
            } else {
                
                qualityGoodCount = 0
            }
        }
        
        // MARK: Automatic Capture
        
        if stableDetectionCount >=
            requiredStableFrames &&
            qualityGoodCount >=
            requiredGoodQualityFrames {
            
            DispatchQueue.main.async { [weak self] in
                
                self?.capturePhoto()
            }
        }
    }
}


// MARK: - Document Stability

private extension DocumentCameraManager {
    
    func isBoundingBoxStable(
        _ previous: CGRect,
        _ current: CGRect
    ) -> Bool {
        
        let centerDifferenceX =
        abs(
            previous.midX -
            current.midX
        )
        
        let centerDifferenceY =
        abs(
            previous.midY -
            current.midY
        )
        
        let widthDifference =
        abs(
            previous.width -
            current.width
        )
        
        let heightDifference =
        abs(
            previous.height -
            current.height
        )
        
        /*
         Vision bounding boxes are normalized
         between 0 and 1.
         
         Small movement is acceptable.
         
         Large movement resets stability.
         */
        
        return centerDifferenceX < 0.03 &&
        centerDifferenceY < 0.03 &&
        widthDifference < 0.05 &&
        heightDifference < 0.05
    }
}


// MARK: - Image Quality

private extension DocumentCameraManager {
    
    func validateImageQuality(
        _ image: UIImage
    ) -> Bool {
        
        do {
            
            try imageQualityAnalyzer.validate(
                image: image
            )
            
            try imageQualityAnalyzer.validateBlur(
                image: image
            )
            
            print(
                "✅ Document image quality is good"
            )
            
            return true
            
        } catch ImageQualityError.tooDark {
            
            print(
                "⚠️ Document is too dark"
            )
            
            return false
            
        } catch ImageQualityError.tooBlurry {
            
            print(
                "⚠️ Document is too blurry"
            )
            
            return false
            
        } catch {
            
            print(
                "⚠️ Document quality validation failed:",
                error
            )
            
            return false
        }
    }
}


// MARK: - CMSampleBuffer → UIImage

private extension DocumentCameraManager {
    
    func imageFromSampleBuffer(
        _ sampleBuffer: CMSampleBuffer
    ) -> UIImage? {
        
        guard let pixelBuffer =
                CMSampleBufferGetImageBuffer(
                    sampleBuffer
                )
        else {
            return nil
        }
        
        let ciImage =
        CIImage(
            cvPixelBuffer: pixelBuffer
        )
        
        let context =
        CIContext()
        
        guard let cgImage =
                context.createCGImage(
                    ciImage,
                    from: ciImage.extent
                )
        else {
            return nil
        }
        
        return UIImage(
            cgImage: cgImage,
            scale: 1.0,
            orientation: .right
        )
    }
}


// MARK: - Photo Capture

extension DocumentCameraManager:
    AVCapturePhotoCaptureDelegate {
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo:
        AVCapturePhoto,
        error: Error?
    ) {
        
        guard error == nil else {
            
            print(
                "❌ Document photo capture failed:",
                error!
            )
            
            resetCaptureState()
            
            return
        }
        
        guard
            let data =
                photo.fileDataRepresentation(),
            
                let image =
                UIImage(
                    data: data
                ),
            
                let boundingBox =
                lastDetectedObservation
                
        else {
            
            print(
                "❌ Unable to create captured document"
            )
            
            resetCaptureState()
            
            return
        }
        
        /*
         Normalize the image orientation before
         passing it to the scanner screen.
         
         This is important because the raw
         AVCapturePhoto can contain orientation
         metadata rather than physically rotated
         pixel data.
         */
        
        let normalizedImage =
        image.normalized()
        
        let capturedDocument =
        CapturedDocument(
            image: normalizedImage,
            observation: boundingBox
        )
        
        DispatchQueue.main.async { [weak self] in
            
            self?.onDocumentCaptured?(
                capturedDocument
            )
        }
    }
}


// MARK: - Capture State

private extension DocumentCameraManager {
    
    func resetCaptureState() {
        
        isCapturing = false
        
        stableDetectionCount = 0
        
        qualityGoodCount = 0
        
        lastDetectedObservation = nil
    }
}


// MARK: - UIImage Normalization

private extension UIImage {
    
    func normalized() -> UIImage {
        
        guard imageOrientation != .up else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(
            size,
            false,
            scale
        )
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        draw(
            in: CGRect(
                origin: .zero,
                size: size
            )
        )
        return
        UIGraphicsGetImageFromCurrentImageContext()
        ?? self
    }
}
