//
//  CameraManager.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import AVFoundation
protocol CameraManager {
    func start()
    func stop()
    func capture(completion: @escaping (UIImage?) -> Void)
    var previewLayer: AVCaptureVideoPreviewLayer? { get }
}
