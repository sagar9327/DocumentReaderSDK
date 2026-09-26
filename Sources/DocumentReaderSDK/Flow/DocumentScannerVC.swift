//
//  DocumentScannerVC.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import Vision
import CoreImage

public final class DocumentScannerViewController: UIViewController {
    
    // MARK: - Properties
    
    private let cameraManager = DocumentCameraManager()
    
    private let scannerFrameView = UIView()
    
    private let instructionLabel = UILabel()
    
    private var continuation:
    CheckedContinuation<UIImage, Never>?
    
    private var capturedDocumentImage: UIImage?
    
    private var capturedDocumentPreview: UIView?
    
    // MARK: - Lifecycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Scan Document"
        
        view.backgroundColor = .black
        
        setupCamera()
        
        setupScannerFrame()
        
        setupInstruction()
    }
    
    public override func viewDidAppear(
        _ animated: Bool
    ) {
        super.viewDidAppear(animated)
        
        cameraManager.start()
    }
    
    public override func viewDidDisappear(
        _ animated: Bool
    ) {
        super.viewDidDisappear(animated)
        
        cameraManager.stop()
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cameraManager.previewLayer?.frame = view.bounds
    }
    
    // MARK: - Public API
    
    public func scanDocument() async -> UIImage {
        
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() {
        
        guard let previewLayer =
                cameraManager.previewLayer
        else {
            
            print("Preview layer unavailable")
            
            return
        }
        
        view.layer.insertSublayer(
            previewLayer,
            at: 0
        )
        
        cameraManager.onDocumentDetected = {
            [weak self] boundingBox in
            
            guard let self else {
                return
            }
            
            self.updateDocumentFrame(
                boundingBox: boundingBox
            )
        }
        
        cameraManager.onDocumentCaptured = {
            [weak self] capturedDocument in
            
            guard let self else {
                return
            }
            
            let correctedImage =
            self.perspectiveCorrectedImage(
                image: capturedDocument.image,
                observation: capturedDocument.observation
            )
            
            self.showCapturedDocument(
                correctedImage
            )
        }
    }
    
    // MARK: - Scanner Frame
    
    private func setupScannerFrame() {
        
        scannerFrameView.backgroundColor =
            .clear
        
        scannerFrameView.layer.borderWidth =
        3
        
        scannerFrameView.layer.borderColor =
        UIColor.white.cgColor
        
        scannerFrameView.layer.cornerRadius =
        12
        
        view.addSubview(
            scannerFrameView
        )
        
        scannerFrameView.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            scannerFrameView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            
            scannerFrameView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            
            scannerFrameView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            ),
            
            scannerFrameView.heightAnchor.constraint(
                equalTo: scannerFrameView.widthAnchor,
                multiplier: 0.70
            )
        ])
    }
    
    // MARK: - Detection UI
    
    private func updateDocumentFrame(
        boundingBox: CGRect
    ) {
        
        guard boundingBox != .zero else {
            
            scannerFrameView.layer.borderColor =
            UIColor.white.cgColor
            
            instructionLabel.text =
            "Position your document inside the frame"
            
            return
        }
        
        let convertedRect = CGRect(
            x: boundingBox.origin.x,
            
            y:
                1
            - boundingBox.origin.y
            - boundingBox.height,
            
            width: boundingBox.width,
            
            height: boundingBox.height
        )
        
        let detectedFrame = CGRect(
            x:
                convertedRect.origin.x
            * view.bounds.width,
            
            y:
                convertedRect.origin.y
            * view.bounds.height,
            
            width:
                convertedRect.width
            * view.bounds.width,
            
            height:
                convertedRect.height
            * view.bounds.height
        )
        
        scannerFrameView.frame =
        detectedFrame
        
        scannerFrameView.layer.borderColor =
        UIColor.systemGreen.cgColor
        
        instructionLabel.text =
        "Hold steady..."
    }
    
    // MARK: - Instruction
    
    private func setupInstruction() {
        
        instructionLabel.text =
        "Position your document inside the frame"
        
        instructionLabel.textColor =
            .white
        
        instructionLabel.textAlignment =
            .center
        
        instructionLabel.numberOfLines =
        2
        
        instructionLabel.font =
            .systemFont(
                ofSize: 17,
                weight: .medium
            )
        
        view.addSubview(
            instructionLabel
        )
        
        instructionLabel.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            instructionLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 30
            ),
            
            instructionLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -30
            ),
            
            instructionLabel.bottomAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -40
            )
        ])
    }
    
    // MARK: - Perspective Correction
    
    private func perspectiveCorrectedImage(
        image: UIImage,
        observation: VNRectangleObservation
    ) -> UIImage {
        
        guard let inputImage =
                CIImage(image: image)
        else {
            return image
        }
        
        let extent =
        inputImage.extent
        
        let topLeft =
        convertPoint(
            observation.topLeft,
            to: extent
        )
        
        let topRight =
        convertPoint(
            observation.topRight,
            to: extent
        )
        
        let bottomLeft =
        convertPoint(
            observation.bottomLeft,
            to: extent
        )
        
        let bottomRight =
        convertPoint(
            observation.bottomRight,
            to: extent
        )
        
        guard let filter =
                CIFilter(
                    name: "CIPerspectiveCorrection"
                )
        else {
            return image
        }
        
        filter.setValue(
            inputImage,
            forKey: kCIInputImageKey
        )
        
        filter.setValue(
            CIVector(cgPoint: topLeft),
            forKey: "inputTopLeft"
        )
        
        filter.setValue(
            CIVector(cgPoint: topRight),
            forKey: "inputTopRight"
        )
        
        filter.setValue(
            CIVector(cgPoint: bottomLeft),
            forKey: "inputBottomLeft"
        )
        
        filter.setValue(
            CIVector(cgPoint: bottomRight),
            forKey: "inputBottomRight"
        )
        
        guard let outputImage =
                filter.outputImage
        else {
            return image
        }
        
        let context =
        CIContext()
        
        guard let cgImage =
                context.createCGImage(
                    outputImage,
                    from: outputImage.extent
                )
        else {
            return image
        }
        
        return UIImage(
            cgImage: cgImage,
            scale: image.scale,
            orientation: .up
        )
    }
    
    // MARK: - Coordinate Conversion
    
    private func convertPoint(
        _ point: CGPoint,
        to extent: CGRect
    ) -> CGPoint {
        
        return CGPoint(
            x:
                extent.origin.x
            + point.x * extent.width,
            
            y:
                extent.origin.y
            + point.y * extent.height
        )
    }
    
    // MARK: - Captured Document Preview
    
    private func showCapturedDocument(
        _ image: UIImage
    ) {
        
        cameraManager.stop()
        
        capturedDocumentImage =
        image
        
        let previewView =
        UIView()
        
        previewView.backgroundColor =
            .black
        
        view.addSubview(
            previewView
        )
        
        previewView.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            previewView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            
            previewView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            
            previewView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            ),
            
            previewView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            )
        ])
        
        capturedDocumentPreview =
        previewView
        
        // MARK: Document Image
        
        let imageView =
        UIImageView(
            image: image
        )
        
        imageView.contentMode =
            .scaleAspectFit
        
        imageView.backgroundColor =
            .black
        
        previewView.addSubview(
            imageView
        )
        
        imageView.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            imageView.topAnchor.constraint(
                equalTo:
                    previewView.safeAreaLayoutGuide.topAnchor,
                constant: 20
            ),
            
            imageView.leadingAnchor.constraint(
                equalTo:
                    previewView.leadingAnchor,
                constant: 20
            ),
            
            imageView.trailingAnchor.constraint(
                equalTo:
                    previewView.trailingAnchor,
                constant: -20
            ),
            
            imageView.bottomAnchor.constraint(
                equalTo:
                    previewView.safeAreaLayoutGuide.bottomAnchor,
                constant: -100
            )
        ])
        
        // MARK: Retake Button
        
        let retakeButton =
        UIButton(type: .system)
        
        retakeButton.setTitle(
            "✕",
            for: .normal
        )
        
        retakeButton.setTitleColor(
            .white,
            for: .normal
        )
        
        retakeButton.titleLabel?.font =
            .systemFont(
                ofSize: 30,
                weight: .bold
            )
        
        retakeButton.backgroundColor =
            .systemRed
        
        retakeButton.layer.cornerRadius =
        30
        
        retakeButton.addTarget(
            self,
            action: #selector(
                retakeDocument
            ),
            for: .touchUpInside
        )
        
        previewView.addSubview(
            retakeButton
        )
        
        retakeButton.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            retakeButton.leadingAnchor.constraint(
                equalTo:
                    previewView.leadingAnchor,
                constant: 30
            ),
            
            retakeButton.bottomAnchor.constraint(
                equalTo:
                    previewView.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            ),
            
            retakeButton.widthAnchor.constraint(
                equalToConstant: 60
            ),
            
            retakeButton.heightAnchor.constraint(
                equalToConstant: 60
            )
        ])
        
        // MARK: Confirm Button
        
        let confirmButton =
        UIButton(type: .system)
        
        confirmButton.setTitle(
            "✓",
            for: .normal
        )
        
        confirmButton.setTitleColor(
            .white,
            for: .normal
        )
        
        confirmButton.titleLabel?.font =
            .systemFont(
                ofSize: 30,
                weight: .bold
            )
        
        confirmButton.backgroundColor =
            .systemGreen
        
        confirmButton.layer.cornerRadius =
        30
        
        confirmButton.addTarget(
            self,
            action: #selector(
                confirmDocument
            ),
            for: .touchUpInside
        )
        
        previewView.addSubview(
            confirmButton
        )
        
        confirmButton.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            confirmButton.trailingAnchor.constraint(
                equalTo:
                    previewView.trailingAnchor,
                constant: -30
            ),
            
            confirmButton.bottomAnchor.constraint(
                equalTo:
                    previewView.safeAreaLayoutGuide.bottomAnchor,
                constant: -20
            ),
            
            confirmButton.widthAnchor.constraint(
                equalToConstant: 60
            ),
            
            confirmButton.heightAnchor.constraint(
                equalToConstant: 60
            )
        ])
    }
    
    // MARK: - Confirm
    
    @objc private func confirmDocument() {
        
        guard let image =
                capturedDocumentImage
        else {
            return
        }
        
        print(
            "Document confirmed"
        )
        
        continuation?.resume(
            returning: image
        )
        
        continuation = nil
        
        dismiss(
            animated: true
        )
    }
    
    // MARK: - Retake
    
    @objc private func retakeDocument() {
        
        print(
            "Retaking document"
        )
        
        capturedDocumentImage =
        nil
        
        capturedDocumentPreview?
            .removeFromSuperview()
        
        capturedDocumentPreview =
        nil
        
        cameraManager.reset()
        
        cameraManager.start()
    }
}
