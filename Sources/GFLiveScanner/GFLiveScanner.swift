//
//  GFLiveScanner.swift
//  GFLiveScanner
//
//  Created by Gualtiero Frigerio on 21/11/2020.
//

import AVFoundation
import UIKit

/// Enum describing the status of the iPhone torch
public enum GFTorchStatus {
    case on
    case off
    case unavailable
}

public enum GFLiveScannerMode {
    case barcode
    case ocr
}

/// Struct containing options for the GFBarcodeScannerViewController
/// There is a initializer with a fullscreen parameter
/// If fullscren is true there is a default Close button
/// otherwise we assume the BarcodeViewController will be embedded
/// into a containing VC providing the close button and the toolbar
public struct GFLiveScannerOptions {
    var closeButtonText:String = "" // Text for the close button
    var closeButtonTextColor:UIColor = UIColor.black // Text color for close button
    var backgroundColor:UIColor = UIColor.white // Toolbar background color
    var toolbarHeight:CGFloat = 60.0 // Height of the toolbar
    var fullScreen:Bool = false // fullscreen mode
    var drawRectangles:Bool = false // draw a rectangle when a barcode is detected
    
    init() {
        self.init(fullScreen: false)
    }
    
    public init(fullScreen:Bool) {
        if fullScreen {
            closeButtonText = "Close"
            closeButtonTextColor = UIColor.black
            backgroundColor = UIColor.white
            toolbarHeight = 60.0
            drawRectangles = false
        }
        else {
            toolbarHeight = 0
            backgroundColor = UIColor.white
            closeButtonText = ""
            closeButtonTextColor = UIColor.white
            drawRectangles = true
        }
        self.fullScreen = fullScreen
    }
}

public protocol GFLiveScannerDelegate {
    func capturedStrings(strings:[String])
    func liveCaptureEnded(withError:Error?)
}

protocol GFLiveScanner:UIViewController {
    /// The init function specifies a delegate and the cameraView used
    /// for the preview.
    /// - Parameters:
    ///   - withDelegate: GFLivescannerDelegate that received the strings
    ///   - cameraView: The view showing the camera feed
    init(withDelegate:GFLiveScannerDelegate, cameraView:UIView)

    /// Creates a preview layer to add to the camera view
    /// in order to show the user the camera feed
    /// Returns: - An optional AVCaptureVideoPreviewLayer
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer?
    /// Begins a scanning session
    /// And asks for the camera permission if it wasn't already granted
    func startScanning()
    /// Ends the scanning session
    func stopScanning()
}
