//
//  GFLiveOCRViewController.swift
//  GFLiveScanner
//
//  Created by Gualtiero Frigerio on 21/11/2020.
//

import AVFoundation
import Combine
import UIKit

/// ViewController responsible for capturing video via AVCaptureSession
/// The view controller has a preview layer to show the camera output
@available(iOS 13.0, *)
class GFLiveOcrViewController: UIViewController, GFLiveScanner {
    required init(withDelegate delegate:GFLiveScannerDelegate?, cameraView:UIView) {
        self.delegate = delegate
        self.cameraView = cameraView
        self.ocrHelper = GFOcrHelper(fastRecognition:true)
        super.init(nibName: nil, bundle: nil)
        configureCaptureSession()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getCapturedStringsPublisher() -> AnyPublisher<[String], Never> {
        $capturedStrings.eraseToAnyPublisher()
    }
    
    // MARK: - GFLiveScanner
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        configurePreview()
        return previewLayer
    }
    
    func startScanning() {
        configurePreview()
        captureSession?.startRunning()
    }
    
    func stopScanning() {
       captureSession?.stopRunning()
    }
    
    // MARK: - Private
    
    private var cameraView:UIView
    private var captureSession:AVCaptureSession?
    private var delegate:GFLiveScannerDelegate?
    private var ocrHelper:GFOcrHelper
    private var previewLayer:AVCaptureVideoPreviewLayer?
    @Published private var capturedStrings:[String] = []
    
    /// Perform the initial configuration instantiating the AVCaptureDevice
    /// and reating the AVCaptureSession
    private func configureCaptureSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            if let delegate = delegate {
                let error = GFLiveScannerUtils.createError(withMessage: "Couldn't create AVCaptureDeviceInput",code: 0)
                delegate.liveCaptureEnded(withError: error)
            }
            return
        }
        let session = AVCaptureSession()
        session.addInput(input)
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA)]
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        session.addOutput(output)
        self.captureSession = session
    }
    
    /// Configure the preview layer
    /// the layer is added to the cameraView
    private func configurePreview() {
        guard let session = captureSession else {return}
        if self.previewLayer == nil {
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.frame = cameraView.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            cameraView.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        }
    }
}

// MARK: - AVCapture delegate

@available(iOS 13.0, *)
extension GFLiveOcrViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let image = GFLiveScannerUtils.getCGImageFromSampleBuffer(sampleBuffer) else {
            return
        }
        let orientation = GFLiveScannerUtils.imageOrientationForCurrentOrientation()
        ocrHelper.getTextFromImage(image, orientation:orientation) { success, strings in
            if let strings = strings {
                self.delegate?.capturedStrings(strings:strings)
                self.capturedStrings = strings
            }
        }
    }
    
    
}
