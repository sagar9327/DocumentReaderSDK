//
//  FaceCameraManager.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import AVFoundation
import Vision

final class FaceCameraManager: NSObject, @unchecked Sendable {
    
    // MARK: - Public
    
    let previewLayer: AVCaptureVideoPreviewLayer
    
    var captureRegion = CGRect(
        x: 0.15,
        y: 0.15,
        width: 0.70,
        height: 0.70
    )
    
    var onFaceDetected: ((Bool) -> Void)?
    
    var onCapture: ((UIImage?) -> Void)?
    
    // MARK: - Private
    
    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    
    private let faceDetector = FaceDetector()
    
    private var isConfigured = false
    private var isCapturing = false
    
    private var stableDetectionCount = 0
    
    // Number of consecutive frames required
    // before automatic capture.
    private let requiredStableFrames = 5
    
    // MARK: - Init
    
    override init() {
        
        previewLayer = AVCaptureVideoPreviewLayer(
            session: session
        )
        
        // Show complete camera image.
        previewLayer.videoGravity = .resizeAspect
        
        super.init()
        
        configureSession()
    }
    
    // MARK: - Session
    
    private func configureSession() {
        
        guard !isConfigured else {
            return
        }
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // MARK: Camera
        
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            
            print("❌ Front camera not available")
            
            session.commitConfiguration()
            
            return
        }
        
        do {
            
            let input = try AVCaptureDeviceInput(
                device: camera
            )
            
            guard session.canAddInput(input) else {
                
                print("❌ Cannot add camera input")
                
                session.commitConfiguration()
                
                return
            }
            
            session.addInput(input)
            
        } catch {
            
            print(
                "❌ Camera input error:",
                error
            )
            
            session.commitConfiguration()
            
            return
        }
        
        // MARK: Video Output
        
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(
                label: "face.camera.video.queue"
            )
        )
        
        guard session.canAddOutput(
            videoOutput
        ) else {
            
            print("❌ Cannot add video output")
            
            session.commitConfiguration()
            
            return
        }
        
        session.addOutput(videoOutput)
        
        // MARK: Photo Output
        
        guard session.canAddOutput(
            photoOutput
        ) else {
            
            print("❌ Cannot add photo output")
            
            session.commitConfiguration()
            
            return
        }
        
        session.addOutput(photoOutput)
        
        session.commitConfiguration()
        
        configureConnections()
        
        isConfigured = true
    }
    
    // MARK: - Connections
    
    private func configureConnections() {
        
        if let connection =
            videoOutput.connection(
                with: .video
            ) {
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            if connection.isVideoMirroringSupported {
                
                connection.automaticallyAdjustsVideoMirroring = false
                
                connection.isVideoMirrored = true
            }
        }
        
        if let connection =
            photoOutput.connection(
                with: .video
            ) {
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            if connection.isVideoMirroringSupported {
                
                connection.automaticallyAdjustsVideoMirroring = false
                
                connection.isVideoMirrored = true
            }
        }
    }
    
    // MARK: - Start
    
    func start() {
        
        guard !session.isRunning else {
            return
        }
        
        print("📷 Starting face camera")
        
        DispatchQueue.global(
            qos: .userInitiated
        ).async { [weak self] in
            
            self?.session.startRunning()
            
            print("📷 Camera running")
        }
    }
    
    // MARK: - Stop
    
    func stop() {
        
        guard session.isRunning else {
            return
        }
        
        print("📷 Stopping face camera")
        
        DispatchQueue.global(
            qos: .userInitiated
        ).async { [weak self] in
            
            self?.session.stopRunning()
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        
        stableDetectionCount = 0
        
        isCapturing = false
        
        let callback = onFaceDetected
        
        DispatchQueue.main.async {
            
            callback?(false)
        }
    }
    
    // MARK: - Face Detection
    
    private func detectFace(
        in sampleBuffer: CMSampleBuffer
    ) {
        
        guard !isCapturing else {
            return
        }
        
        guard let pixelBuffer =
                CMSampleBufferGetImageBuffer(
                    sampleBuffer
                ) else {
            
            return
        }
        
        let request =
        VNDetectFaceRectanglesRequest()
        
        let handler =
        VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .leftMirrored,
            options: [:]
        )
        
        do {
            
            try handler.perform([
                request
            ])
            
        } catch {
            
            print(
                "❌ Vision error:",
                error
            )
            
            return
        }
        
        guard let faces = request.results else {
            
            stableDetectionCount = 0
            
            notifyFaceDetected(false)
            
            return
        }
        
        // We only accept exactly one face.
        
        guard faces.count == 1,
              let face = faces.first else {
            
            stableDetectionCount = 0
            
            notifyFaceDetected(false)
            
            return
        }
        
        let faceBox = face.boundingBox
        
        print(
            "Face:",
            faceBox,
            "Region:",
            captureRegion
        )
        
        let isInside =
        isFaceInsideCaptureRegion(
            faceBox
        )
        
        if !isInside {
            
            stableDetectionCount = 0
            
            notifyFaceDetected(false)
            
            return
        }
        
        // Face is inside green box.
        
        notifyFaceDetected(true)
        
        stableDetectionCount += 1
        
        print(
            "✅ Face inside box - stable frame:",
            stableDetectionCount,
            "/",
            requiredStableFrames
        )
        
        // IMPORTANT:
        // We intentionally do NOT block capture
        // using brightness / blur checks here.
        //
        // The requirement is:
        //
        // Face inside box
        // +
        // stable for a few frames
        // =
        // auto capture.
        
        if stableDetectionCount >=
            requiredStableFrames {
            
            print("📸 AUTO CAPTURE")
            
            capturePhoto()
        }
    }
    
    // MARK: - Face Region
    
    private func isFaceInsideCaptureRegion(
        _ face: CGRect
    ) -> Bool {
        
        let faceCenter = CGPoint(
            x: face.midX,
            y: face.midY
        )
        
        return captureRegion.contains(
            faceCenter
        )
    }
    
    // Vision uses bottom-left coordinates.
    // Convert to top-left coordinates.
    
    private func convertVisionRectToTopLeft(
        _ rect: CGRect
    ) -> CGRect {
        
        return CGRect(
            x: rect.origin.x,
            y: 1.0 - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
    
    // MARK: - Notification
    
    private func notifyFaceDetected(
        _ value: Bool
    ) {
        
        let callback = onFaceDetected
        
        DispatchQueue.main.async {
            
            callback?(value)
        }
    }
    
    // MARK: - Capture
    
    private func capturePhoto() {
        
        guard !isCapturing else {
            return
        }
        
        isCapturing = true
        
        stableDetectionCount = 0
        
        print("📸 Capturing selfie...")
        
        let settings =
        AVCapturePhotoSettings()
        
        if let connection =
            photoOutput.connection(
                with: .video
            ) {
            
            if connection.isVideoOrientationSupported {
                
                connection.videoOrientation =
                    .portrait
            }
            
            if connection.isVideoMirroringSupported {
                
                connection.automaticallyAdjustsVideoMirroring =
                false
                
                connection.isVideoMirrored =
                true
            }
        }
        
        photoOutput.capturePhoto(
            with: settings,
            delegate: self
        )
    }
    
    // MARK: - Crop
    
    private func cropToCaptureRegion(
        image: UIImage
    ) -> UIImage {
        
        let size = image.size
        
        let cropRect = CGRect(
            x: captureRegion.origin.x *
            size.width,
            
            y: captureRegion.origin.y *
            size.height,
            
            width: captureRegion.width *
            size.width,
            
            height: captureRegion.height *
            size.height
        ).integral
        
        let format =
        UIGraphicsImageRendererFormat()
        
        format.scale = image.scale
        
        format.opaque = true
        
        let renderer =
        UIGraphicsImageRenderer(
            size: cropRect.size,
            format: format
        )
        
        return renderer.image { _ in
            
            image.draw(
                in: CGRect(
                    x: -cropRect.origin.x,
                    y: -cropRect.origin.y,
                    width: size.width,
                    height: size.height
                )
            )
        }
    }
}

// MARK: - Video Delegate

extension FaceCameraManager:
    AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
        detectFace(
            in: sampleBuffer
        )
    }
}

// MARK: - Photo Delegate

extension FaceCameraManager:
    AVCapturePhotoCaptureDelegate {
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        
        if let error {
            
            print(
                "❌ Photo capture error:",
                error
            )
            
            isCapturing = false
            
            let callback = onCapture
            
            DispatchQueue.main.async {
                
                callback?(nil)
            }
            
            return
        }
        
        guard let data =
                photo.fileDataRepresentation(),
              let image =
                UIImage(data: data) else {
            
            print(
                "❌ Could not create UIImage"
            )
            
            isCapturing = false
            
            let callback = onCapture
            
            DispatchQueue.main.async {
                
                callback?(nil)
            }
            
            return
        }
        
        print(
            "📸 Original image:",
            image.size
        )
        
        let croppedImage =
        cropToCaptureRegion(
            image: image
        )
        
        print(
            "✂️ Cropped image:",
            croppedImage.size
        )
        
        let callback = onCapture
        
        DispatchQueue.main.async {
            
            callback?(croppedImage)
        }
    }
}
