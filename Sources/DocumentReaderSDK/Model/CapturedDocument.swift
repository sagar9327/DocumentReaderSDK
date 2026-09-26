//
//  CapturedDocument.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//

import UIKit
import Vision

struct CapturedDocument {
    let image: UIImage
    let observation: VNRectangleObservation
}
