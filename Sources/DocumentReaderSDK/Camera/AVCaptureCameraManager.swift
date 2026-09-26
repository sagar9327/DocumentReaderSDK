//
//  AVCaptureCameraManager.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import AVFoundation

class AVCaptureCameraManager: NSObject, CameraManager {
    var previewLayer: AVCaptureVideoPreviewLayer?
    

    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()

    private var captureCompletion: ((UIImage?) -> Void)?

    override init() {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        super.init()
    }

    func start() {
        guard !session.isRunning else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) else {
            session.commitConfiguration()
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }

            session.commitConfiguration()

            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }

        } catch {
            session.commitConfiguration()
            print("Camera setup failed:", error)
        }
    }

    func stop() {

        guard session.isRunning else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    func capture(completion: @escaping (UIImage?) -> Void) {

        captureCompletion = completion

        let settings = AVCapturePhotoSettings()

        photoOutput.capturePhoto(
            with: settings,
            delegate: self
        )
    }
}
extension AVCaptureCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {

        guard
            error == nil,
            let data = photo.fileDataRepresentation(),
            let image = UIImage(data: data)
        else {
            captureCompletion?(nil)
            captureCompletion = nil
            return
        }

        captureCompletion?(image)
        captureCompletion = nil
    }
}
