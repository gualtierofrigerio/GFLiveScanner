//
//  GFLiveScanViewController.swift
//  GFLiveScanner
//
//  Created by Gualtiero Frigerio on 21/11/2020.
//

import AVFoundation
import UIKit

/// GFBarcodeScannerViewcontroller
/// A view controller responsible for showing the camera and detect barcodes
/// or perform live OCR on the camera feed
/// The VC can be configure via a GFLiveScannerOptions struct
/// if nothing is provided a default one is used
public class GFLiveScannerViewController : UIViewController {
    var isFullScreen = false
    var getImageCallback:((UIImage?) -> Void)?
    var torchStatus:GFTorchStatus = .off
    
    init(withDelegate delegate:GFLiveScannerDelegate, options:GFLiveScannerOptions?) {
        self.delegate = delegate
        self.cameraView = UIView(frame: CGRect.zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if let mode = self.mode {
            startScanning(mode: mode)
        }
    }
    
    public override func viewWillLayoutSubviews() {
        cameraView.frame = getCameraViewFrame()
        previewLayer?.frame = cameraView.layer.bounds
        previewLayer?.connection?.videoOrientation = GFLiveScannerUtils.videoOrientationForCurrentOrientation()
    }
    
    
    /// Starts a live scanner for the configured mode
    /// - Parameter mode: The scanning mode
    public func startScanning(mode:GFLiveScannerMode) {
        // if we're not part of the view hierarchy we save the mode
        // and we'll start scanning after viewDidAppear
        if view.superview == nil {
            self.mode = mode
            return
        }
        configureView()
        if mode == .barcode {
            if #available(iOS 10.0, *) {
                scanner = GFLiveBarcodeViewController(withDelegate:delegate, cameraView: cameraView)
            } else {
                fatalError("barcode mode only available in 10.0")
            }
        }
        else {
            if #available(iOS 13.0, *) {
                scanner = GFLiveOcrViewController(withDelegate: delegate, cameraView: cameraView)
            } else {
                fatalError("ocr mode only available in 13.0")
            }
        }
        addChild(scanner!)
        scanner!.startScanning()
        addPreviewLayer()
    }
    /// Stop the scaning process
    public func stopScanning() {
        scanner?.stopScanning()
        removePreviewLayer()
    }
    
    public func getImage(callback: @escaping((UIImage?) ->Void)) {
        self.getImageCallback = callback
    }
    
    public func isTorchAvailable() -> Bool {
        return checkTorchAvailability()
    }
    
    @discardableResult public func toggleTorch() -> GFTorchStatus {
        let on = torchStatus != .on ? true : false
        torchStatus = changeTorchStatus(on:on)
        return torchStatus
    }
    
    // MARK: - Private
    private var cameraView:UIView
    private var delegate:GFLiveScannerDelegate
    private var mode:GFLiveScannerMode?
    private var options:GFLiveScannerOptions = GFLiveScannerOptions()
    private var previewLayer:AVCaptureVideoPreviewLayer?
    private var scanner:GFLiveScanner?
    
    private func addPreviewLayer() {
        if let layer = scanner?.getPreviewLayer() {
            cameraView.layer.addSublayer(layer)
            previewLayer = layer
        }
    }
    
    private func checkTorchAvailability() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video) else { return false }
        if device.hasTorch {
            return true
        }
        return false
    }
    
    private func changeTorchStatus(on:Bool) -> GFTorchStatus {
        if checkTorchAvailability() == false {
            return .unavailable
        }
        guard let device = AVCaptureDevice.default(for: .video) else { return .unavailable }
        var status = GFTorchStatus.unavailable
        do {
            try device.lockForConfiguration()
            if on == true {
                device.torchMode = .on
                status = .on
            } else {
                device.torchMode = .off
                status = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Error while trying to access the torch")
        }
        return status
    }
    
    @objc private func closeButtonTap(_ sender:Any) {
        self.scanner?.stopScanning()
        delegate.liveCaptureEnded(withError: createError(withMessage: "User closed the capture view",
                                                         code: 0))
        self.dismiss(animated: true, completion: nil)
    }
    
    private func configureView() {
        if cameraView.superview != nil {
            return // only perform setup if the view is not yet created
        }
        self.isFullScreen = options.fullScreen
        
        var frame = self.view.frame
        
        if options.toolbarHeight > 0 {
            frame.size.height = options.toolbarHeight
            let toolbarView = UIView.init(frame: frame)
            toolbarView.backgroundColor = options.backgroundColor
            frame.origin = CGPoint(x: 20.0, y: 20.0)
            let closeButton = UIButton.init(frame: frame)
            closeButton.addTarget(self, action: #selector(self.closeButtonTap(_:)), for: .touchUpInside)
            closeButton.setTitle(options.closeButtonText, for: .normal)
            closeButton.contentHorizontalAlignment = .left
            closeButton.setTitleColor(options.closeButtonTextColor, for: .normal)
            
            toolbarView.addSubview(closeButton)
            self.view.addSubview(toolbarView)
        }
        
        cameraView.frame = getCameraViewFrame()
        self.view.addSubview(cameraView)
    }
    
    /// Creates an NSError with a string and a code
    /// - Parameters:
    ///   - withMessage: the String with the error message
    ///   - code: the error code
    /// - Returns: An NSError
    private func createError(withMessage:String, code:Int) -> NSError {
        let error = NSError(domain: "GFLiveScanner", code: code, userInfo: ["Message" : withMessage])
        return error
    }
    
    private func getCameraViewFrame() -> CGRect {
        var frame = self.view.frame
        if isFullScreen == false {
            if let superView = self.view.superview {
                frame.origin = CGPoint(x: 0, y: 0)
                frame.size = superView.frame.size
            }
        }
        else  {
            frame.origin.y = options.toolbarHeight
            frame.size.height = frame.size.height - options.toolbarHeight
        }
        return frame
    }
    
    private func removePreviewLayer() {
        if let layer = previewLayer {
            layer.removeFromSuperlayer()
            previewLayer = nil
        }
    }
}