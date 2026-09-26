//
//  SelfieVC.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import AVFoundation

final class SelfieViewController: UIViewController {
    
    private let cameraManager = FaceCameraManager()
    
    private let faceGuideLayer = CAShapeLayer()
    
    private let statusLabel = UILabel()
    
    private let retakeButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    
    private let previewImageView = UIImageView()
    
    private var continuation:
    CheckedContinuation<UIImage?, Never>?
    
    private var isShowingPreview = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Selfie"
        view.backgroundColor = .black
        
        setupCamera()
        setupUI()
        setupButtons()
        
        cameraManager.onFaceDetected = {
            [weak self] isInsideBox in
            
            guard let self else {
                return
            }
            
            DispatchQueue.main.async {
                
                guard !self.isShowingPreview else {
                    return
                }
                
                self.updateFaceGuide(
                    isFaceInside: isInsideBox
                )
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cameraManager.previewLayer.frame = view.bounds
        updateFaceGuideFrame()
    }
    
    override func viewDidAppear(
        _ animated: Bool
    ) {
        super.viewDidAppear(animated)
        
        updateFaceGuideFrame()
    }
    
    override func viewWillAppear(
        _ animated: Bool
    ) {
        super.viewWillAppear(animated)
        
        guard !isShowingPreview else {
            return
        }
        
        cameraManager.start()
    }
    
    override func viewWillDisappear(
        _ animated: Bool
    ) {
        super.viewWillDisappear(animated)
        
        cameraManager.stop()
    }
    
    // MARK: - Camera
    
    private func setupCamera() {
        
        let previewLayer =
        cameraManager.previewLayer
        
        previewLayer.videoGravity =
            .resizeAspect
        
        view.layer.insertSublayer(
            previewLayer,
            at: 0
        )
    }
    
    // MARK: - UI
    
    private func setupUI() {
        
        setupFaceGuide()
        
        statusLabel.text =
        "Position your face inside the box"
        
        statusLabel.textColor = .white
        
        statusLabel.font =
            .systemFont(
                ofSize: 17,
                weight: .medium
            )
        
        statusLabel.textAlignment = .center
        
        view.addSubview(statusLabel)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            statusLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 20
            ),
            
            statusLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -20
            ),
            
            statusLabel.bottomAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -30
            )
        ])
        
        setupPreviewImageView()
    }
    
    private func setupFaceGuide() {
        
        faceGuideLayer.fillColor =
        UIColor.clear.cgColor
        
        faceGuideLayer.strokeColor =
        UIColor.white.cgColor
        
        faceGuideLayer.lineWidth = 4
        
        faceGuideLayer.lineJoin =
            .round
        
        view.layer.addSublayer(
            faceGuideLayer
        )
    }
    
    private func setupPreviewImageView() {
        
        previewImageView.contentMode =
            .scaleAspectFit
        
        previewImageView.backgroundColor =
            .black
        
        previewImageView.isHidden = true
        
        view.addSubview(
            previewImageView
        )
        
        previewImageView.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            previewImageView.topAnchor.constraint(
                equalTo: view.topAnchor
            ),
            
            previewImageView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor
            ),
            
            previewImageView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor
            ),
            
            previewImageView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor
            )
        ])
    }
    
    // MARK: - Buttons
    
    private func setupButtons() {
        
        // Retake
        
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
                ofSize: 34,
                weight: .bold
            )
        
        retakeButton.backgroundColor =
        UIColor.systemRed.withAlphaComponent(
            0.85
        )
        
        retakeButton.layer.cornerRadius =
        35
        
        retakeButton.addTarget(
            self,
            action: #selector(retakeTapped),
            for: .touchUpInside
        )
        
        // Confirm
        
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
                ofSize: 34,
                weight: .bold
            )
        
        confirmButton.backgroundColor =
        UIColor.systemGreen.withAlphaComponent(
            0.85
        )
        
        confirmButton.layer.cornerRadius =
        35
        
        confirmButton.addTarget(
            self,
            action: #selector(confirmTapped),
            for: .touchUpInside
        )
        
        view.addSubview(
            retakeButton
        )
        
        view.addSubview(
            confirmButton
        )
        
        retakeButton.translatesAutoresizingMaskIntoConstraints =
        false
        
        confirmButton.translatesAutoresizingMaskIntoConstraints =
        false
        
        NSLayoutConstraint.activate([
            
            retakeButton.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 40
            ),
            
            retakeButton.bottomAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -30
            ),
            
            retakeButton.widthAnchor.constraint(
                equalToConstant: 70
            ),
            
            retakeButton.heightAnchor.constraint(
                equalToConstant: 70
            ),
            
            confirmButton.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -40
            ),
            
            confirmButton.bottomAnchor.constraint(
                equalTo:
                    view.safeAreaLayoutGuide.bottomAnchor,
                constant: -30
            ),
            
            confirmButton.widthAnchor.constraint(
                equalToConstant: 70
            ),
            
            confirmButton.heightAnchor.constraint(
                equalToConstant: 70
            )
        ])
        
        retakeButton.isHidden = true
        confirmButton.isHidden = true
    }
    
    // MARK: - Face Guide
    
    private func updateFaceGuideFrame() {
        
        let previewLayer = cameraManager.previewLayer
        
        guard view.bounds.width > 0,
              view.bounds.height > 0 else {
            return
        }
        
        // Make the box 55% of the screen width.
        let side = view.bounds.width * 0.55
        
        let x =
        (view.bounds.width - side) / 2
        
        let y =
        (view.bounds.height - side) / 2
        
        let squareFrame = CGRect(
            x: x,
            y: y,
            width: side,
            height: side
        )
        
        // Draw the square.
        faceGuideLayer.frame = squareFrame
        
        faceGuideLayer.path =
        UIBezierPath(
            roundedRect: faceGuideLayer.bounds,
            cornerRadius: 20
        ).cgPath
        
        // Make sure preview layer has the same frame.
        previewLayer.frame = view.bounds
        
        // Convert screen square -> camera coordinates.
        let region =
        previewLayer.metadataOutputRectConverted(
            fromLayerRect: squareFrame
        )
        
        cameraManager.captureRegion = region
        
        print("🟩 BOX FRAME:", squareFrame)
        print("🎯 CAPTURE REGION:", region)
    }
    
    private func updateFaceGuide(
        isFaceInside: Bool
    ) {
        
        if isFaceInside {
            
            faceGuideLayer.strokeColor =
            UIColor.systemGreen.cgColor
            
            statusLabel.text =
            "Hold steady..."
            
        } else {
            
            faceGuideLayer.strokeColor =
            UIColor.white.cgColor
            
            statusLabel.text =
            "Position your face inside the box"
        }
    }
    
    // MARK: - Capture
    
    func captureSelfie() async -> UIImage? {
        
        await withCheckedContinuation {
            (
                continuation:
                    CheckedContinuation<UIImage?, Never>
            ) in
            
            self.continuation =
            continuation
            
            cameraManager.onCapture = {
                [weak self] image in
                
                guard let self else {
                    return
                }
                
                DispatchQueue.main.async {
                    
                    guard let image else {
                        return
                    }
                    
                    self.showCapturedImage(
                        image
                    )
                }
            }
        }
    }
    
    // MARK: - Preview
    
    private func showCapturedImage(
        _ image: UIImage
    ) {
        
        isShowingPreview = true
        
        cameraManager.stop()
        
        previewImageView.image =
        image
        
        previewImageView.isHidden =
        false
        
        faceGuideLayer.isHidden =
        true
        
        statusLabel.isHidden =
        true
        
        retakeButton.isHidden =
        false
        
        confirmButton.isHidden =
        false
    }
    
    // MARK: - Retake
    
    @objc
    private func retakeTapped() {
        
        isShowingPreview = false
        
        previewImageView.image =
        nil
        
        previewImageView.isHidden =
        true
        
        faceGuideLayer.isHidden =
        false
        
        statusLabel.isHidden =
        false
        
        retakeButton.isHidden =
        true
        
        confirmButton.isHidden =
        true
        
        cameraManager.reset()
        
        cameraManager.start()
    }
    
    // MARK: - Confirm
    
    @objc
    private func confirmTapped() {
        guard let image =
                previewImageView.image else {
            return
        }
        continuation?.resume(
            returning: image
        )
        continuation = nil
    }
}
