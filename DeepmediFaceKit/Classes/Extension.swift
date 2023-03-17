//
//  Extension.swift
//  DeepmediFaceKit
//
//  Created by 딥메디 on 2023/03/17.
//

import Foundation

extension UIImage {
    enum type: String {
        case ciImage, uiImage
    }
    var ciImageToCVPixelBuffer: CVPixelBuffer? {
        if let ciImage = CIImage(image: self) {
            let attrs = [
                String(kCVPixelBufferCGImageCompatibilityKey): false,
                String(kCVPixelBufferCGBitmapContextCompatibilityKey): false,
            ] as CFDictionary
            var buffer: CVPixelBuffer?
            let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                             Int(ciImage.extent.width),
                                             Int(ciImage.extent.height),
                                             kCVPixelFormatType_32BGRA,
                                             attrs,
                                             &buffer)
            
            guard (status == kCVReturnSuccess) else {
                return nil
            }
            
            let context = CIContext()
            context.render(ciImage, to: buffer!)
            
            return buffer
        }
        return nil
    }
    
    var uiImageToCVPixelBuffer: CVPixelBuffer? {
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let attrs = [
            String(kCVPixelBufferCGImageCompatibilityKey): false,
            String(kCVPixelBufferCGBitmapContextCompatibilityKey): false,
        ] as CFDictionary
        var buffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32BGRA,
                                         attrs,
                                         &buffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(buffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(buffer!),
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)

        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(buffer!, CVPixelBufferLockFlags(rawValue: 0))

        return buffer
    }
       
    func createCMSampleBuffer() -> CMSampleBuffer? {
        guard let pixelBuffer = ciImageToCVPixelBuffer else { fatalError("pixel buffer return") }
        var timimgInfo = CMSampleTimingInfo()
        var videoInfo: CMVideoFormatDescription?
        var newSampleBuffer: CMSampleBuffer?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil,
                                                     imageBuffer: pixelBuffer,
                                                     formatDescriptionOut: &videoInfo)
        CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                           imageBuffer: pixelBuffer,
                                           dataReady: true,
                                           makeDataReadyCallback: nil,
                                           refcon: nil,
                                           formatDescription: videoInfo!,
                                           sampleTiming: &timimgInfo,
                                           sampleBufferOut: &newSampleBuffer)
        return newSampleBuffer!
    }
}

extension CGPath {
    func resized(to rect: CGRect) -> CGPath? {
        let boundingBox = self.boundingBox
        let boundingBoxAspectRatio = boundingBox.width / boundingBox.height
        let viewAspectRatio = rect.width / rect.height
        let scaleFactor = boundingBoxAspectRatio > viewAspectRatio ?
            rect.width / boundingBox.width :
            rect.height / boundingBox.height
        let useScale = scaleFactor * 0.8
        
        let scaledSize = boundingBox.size.applying(CGAffineTransform(scaleX: useScale, y: useScale))
        let centerOffset = CGSize(
            width: (rect.width - scaledSize.width) / (useScale * 2),
            height: (rect.height - scaledSize.height) / (useScale * 2)
        )

        var transform = CGAffineTransform.identity
            .scaledBy(x: useScale, y: useScale)
            .translatedBy(x: -boundingBox.minX + centerOffset.width, y: -boundingBox.minY + centerOffset.height)
        
        return copy(using: &transform)
    }
}
