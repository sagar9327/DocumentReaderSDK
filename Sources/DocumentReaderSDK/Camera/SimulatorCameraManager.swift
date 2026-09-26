//
//  SimulatorCameraManager.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import AVFoundation
final class SimulatorCameraManager: CameraManager {
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        nil
    }
    func start() {
        print("Start")
    }
    
    func stop() {
        print("stop")
    }

    
    func capture(completion: @escaping (UIImage?) -> Void) {
        let image = UIImage(named: "Sachin")
        completion(image)
    }
}
