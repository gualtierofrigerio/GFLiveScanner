//
//  GFLiveScannerUtils.swift
//  GFLiveScanner
//
//  Created by Gualtiero Frigerio on 21/11/2020.
//

import AVFoundation
import CoreGraphics
import UIKit

/// Class with static function needed by the live scanner
/// like getting the current screen orientation
/// converting the SampleBuffer to a CGImage or UIImage
/// and get the correct orientation for images or video
/// coming from AVCaptureSession based on the device orientation
class GFLiveScannerUtils {
    /// Get current device orientation
    /// - Returns: Current UIInterfaceOrientation
    class func getCurrentOrientation() -> UIInterfaceOrientation {
        var orientation:UIInterfaceOrientation
        if #available(iOS 13.0, *) {
            orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        return orientation
    }
    /// Returns if possible a CGImage from a CMSampleBuffer
    /// - Parameter sampleBuffer: The CMSampleBuffer to convert to an image
    /// - Returns: The optional CGImage
    class func getCGImageFromSampleBuffer(_ sampleBuffer:CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: baseAddress, width: width,
                                      height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                      space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        let cgImage = context.makeImage()
        
        return cgImage
    }
    /// Tries to get a UIImage from a CMSampleBuffer with an orientation
    /// - Parameters:
    ///   - sampleBuffer: The CMSampleBuffer containing the image
    ///   - orientation: The desired orientation
    /// - Returns: An optional UIImage
    class func getUIImageFromSampleBuffer(_ sampleBuffer:CMSampleBuffer, orientation:UIInterfaceOrientation) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return nil}
        var cImage = CIImage(cvImageBuffer: imageBuffer)
        cImage = getOrientedImage(cImage, forOrientation: orientation)
        return UIImage(ciImage: cImage)
    }
    
    /// Returnes a CIImage rotated based on the given orientation
    /// - Parameters:
    ///   - image: The image to rotate
    ///   - orientation: The desired orientation
    /// - Returns: The rotated image
    class func getOrientedImage(_ image:CIImage, forOrientation orientation:UIInterfaceOrientation) -> CIImage {
        var cImage = image
        switch orientation {
        case .portrait:
            cImage = cImage.oriented(forExifOrientation: 6)
            break
        case .portraitUpsideDown:
            cImage = cImage.oriented(forExifOrientation: 8)
            break
        case .landscapeLeft:
            cImage = cImage.oriented(forExifOrientation: 3)
            break
        case .landscapeRight:
            cImage = cImage.oriented(forExifOrientation: 1)
            break
        default:
            break
        }
        return cImage
    }
    
    /// Returns the image property orientation based on the current interface orientation
    /// this is necessary because the CGImage orientation has to be adjusted
    /// based on current interface orientation
    /// so we get a CGImage and we know the current orientation of the device
    /// and we have to use this adjusted orientation for the OCR
    /// - Returns: The CGImagePropertyOrientation to use for an image
    class func imageOrientationForCurrentOrientation() -> CGImagePropertyOrientation? {
        var returnOrientation:CGImagePropertyOrientation? = nil
        let orientation = GFLiveScannerUtils.getCurrentOrientation()
        switch orientation {
        case .portrait:
            returnOrientation = CGImagePropertyOrientation.right
        case .landscapeLeft:
            returnOrientation = CGImagePropertyOrientation.down
        case .landscapeRight:
            returnOrientation = CGImagePropertyOrientation.up
        case .portraitUpsideDown:
            returnOrientation = CGImagePropertyOrientation.left
        default:
            returnOrientation = nil
        }
        return returnOrientation
    }
    
    /// Returns the correct AVCaptureVideoOrientation based on current device orientation
    /// - Returns: The AVCaptureVideoOrientation value
    class func videoOrientationForCurrentOrientation() -> AVCaptureVideoOrientation {
        let orientation = GFLiveScannerUtils.getCurrentOrientation()
        var videoOrientation:AVCaptureVideoOrientation = .portrait
        switch orientation {
        case .portrait:
            videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
            break
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            videoOrientation = .landscapeRight
            break
        default:
            break
        }
        return videoOrientation
    }
}
