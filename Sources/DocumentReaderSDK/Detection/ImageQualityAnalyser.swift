//
//  ImageQualityAnalyser.swift
//  DocumentReaderSDK
//
//  Created by Sagar Kalathil on 26/09/26.
//
import UIKit
import CoreImage

enum ImageQualityError: Error {
    case tooDark
    case tooBlurry
}

final class ImageQualityAnalyzer {
    
    private let context = CIContext()
    
    func validate(image: UIImage) throws {
        
        guard let ciImage = CIImage(image: image) else {
            return
        }
        
        let extent = ciImage.extent
        
        guard let averageColor = context.createCGImage(
            ciImage,
            from: extent
        ) else {
            return
        }
        
        let imageWidth = averageColor.width
        let imageHeight = averageColor.height
        
        guard imageWidth > 0, imageHeight > 0 else {
            return
        }
        
        // Simple brightness estimation.
        // We'll improve this later.
        let brightness = calculateBrightness(
            cgImage: averageColor
        )
        
        print("Image brightness:", brightness)
        
        if brightness < 40 {
            throw ImageQualityError.tooDark
        }
    }
    
    private func calculateBrightness(cgImage: CGImage) -> Double {
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let pointer = CFDataGetBytePtr(data) else {
            return 255
        }
        
        let bytesPerPixel = 4
        let pixelCount = cgImage.width * cgImage.height
        
        var totalBrightness = 0.0
        
        for index in 0..<pixelCount {
            
            let offset = index * bytesPerPixel
            
            let red = Double(pointer[offset])
            let green = Double(pointer[offset + 1])
            let blue = Double(pointer[offset + 2])
            
            let brightness =
            (0.299 * red) +
            (0.587 * green) +
            (0.114 * blue)
            
            totalBrightness += brightness
        }
        
        return totalBrightness / Double(pixelCount)
    }
    
    private func calculateSharpness(cgImage: CGImage) -> Double {
        
        let width = 200
        let height = 200
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return 0
        }
        
        context.interpolationQuality = .low
        
        context.draw(
            cgImage,
            in: CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )
        
        guard let data = context.data else {
            return 0
        }
        
        let pixels = data.assumingMemoryBound(to: UInt8.self)
        
        var total = 0.0
        var totalSquared = 0.0
        
        let count = width * height
        
        for index in 0..<count {
            
            let pixel = Double(pixels[index])
            
            total += pixel
            totalSquared += pixel * pixel
        }
        
        let mean = total / Double(count)
        
        return (totalSquared / Double(count)) - (mean * mean)
    }
    
    func validateBlur(image: UIImage) throws {
        guard let cgImage = image.cgImage else { return }
        let score = calculateSharpness(cgImage: cgImage)
        print("Image Sharpness: ", score)
        if score < 100 {
            throw ImageQualityError.tooBlurry
        }
    }
}
