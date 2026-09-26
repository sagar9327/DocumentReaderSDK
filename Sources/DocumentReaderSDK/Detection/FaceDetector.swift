//
//  FaceDetector.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import Vision

enum FaceDetectionResult {
    case noFace
    case oneFace
    case multipleFaces
}

enum SelfieValidationError: Error {
    case noFaceDetected
    case multipleFacesDetected
}

final class FaceDetector {

    func validate(image: UIImage) throws {

        guard let cgImage = image.cgImage else {
            throw SelfieValidationError.noFaceDetected
        }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            options: [:]
        )
        try handler.perform([request])

        let faces = request.results ?? []

        switch faces.count {
        case 0:
            throw SelfieValidationError.noFaceDetected

        case 1:
            return

        default:
            throw SelfieValidationError.multipleFacesDetected
        }
    }
}
