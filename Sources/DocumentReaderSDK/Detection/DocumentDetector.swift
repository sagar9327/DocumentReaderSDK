//
//  DocumentDetector.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import Vision

public enum DocumentDetectionError: Error {
    case invalidImage
    case noDocumentDetected
}

public struct DocumentDetectionResult {
    public let boundingBox: CGRect
    public init(boundingBox: CGRect) {
        self.boundingBox = boundingBox
    }
}

public final class DocumentDetector {
    public init(){}
    
    public func detectDocument(in image: UIImage) throws -> DocumentDetectionResult {

        guard let cgImage = image.cgImage else {
            throw DocumentDetectionError.invalidImage
        }

        let request = VNDetectRectanglesRequest()

        request.minimumConfidence = 0.7
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 2.0
        request.minimumSize = 0.2

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            options: [:]
        )

        try handler.perform([request])

        guard let rectangle = request.results?.first else {
            throw DocumentDetectionError.noDocumentDetected
        }

        return DocumentDetectionResult(
            boundingBox: rectangle.boundingBox
        )
    }
}
