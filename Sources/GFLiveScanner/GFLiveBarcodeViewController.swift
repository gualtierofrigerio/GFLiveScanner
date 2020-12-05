//
//  GFLiveBarcodeViewController.swift
//  GFLiveScanner
//
//  Created by Gualtiero Frigerio on 21/11/2020.
//

import AVFoundation
import UIKit

@available(iOS 10.0, *)
class GFLiveBarcodeViewController: UIViewController, GFLiveScanner {
    required init(withDelegate delegate:GFLiveScannerDelegate?, cameraView: UIView) {
        self.cameraView = cameraView
        self.delegate = delegate
        self.queue = DispatchQueue(label: "GFBarcodeScannerQueue")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - GFLiveScanner
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        previewLayer
    }
    
    func startScanning() {
        configureCaptureSession()
        guard let session = captureSession else {return}
        configurePreview()
        queue.async {
            session.startRunning()
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
    }
    
    // MARK: - Private
    private var cameraView:UIView
    private var captureSession:AVCaptureSession?
    private var delegate:GFLiveScannerDelegate?
    private var drawRectangles = false
    private var previewLayer:AVCaptureVideoPreviewLayer?
    private var queue:DispatchQueue
    private var rectanglesLayer:CAShapeLayer?
    
    /// Configures an AVCaptureSession
    /// setting its delegate and the objectTypes
    /// - Returns: an optional AVCaptureSession
    private func configureCaptureSession() {
        if captureSession != nil {
            return
        }
        /// These are the AVMetadataObject we are intested in
        /// I put here the most common barcodes and the QR code as well
        let objectTypes:[AVMetadataObject.ObjectType] =
            [AVMetadataObject.ObjectType.aztec,
             AVMetadataObject.ObjectType.code39,
             AVMetadataObject.ObjectType.code39Mod43,
             AVMetadataObject.ObjectType.code93,
             AVMetadataObject.ObjectType.code128,
             AVMetadataObject.ObjectType.dataMatrix,
             AVMetadataObject.ObjectType.ean8,
             AVMetadataObject.ObjectType.ean13,
             AVMetadataObject.ObjectType.interleaved2of5,
             AVMetadataObject.ObjectType.itf14,
             AVMetadataObject.ObjectType.pdf417,
             AVMetadataObject.ObjectType.qr,
             AVMetadataObject.ObjectType.upce
            ]
        
        let session = AVCaptureSession()
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInWideAngleCamera, .builtInTelephotoCamera],
                                                                      mediaType: AVMediaType.video,
                                                                      position: .unspecified)
        
        guard let captureDevice = deviceDiscoverySession.devices.first,
            let videoDeviceInput = try? AVCaptureDeviceInput(device: captureDevice),
            session.canAddInput(videoDeviceInput)
            else { return }
        session.addInput(videoDeviceInput)
        
        /// In addition to the AVCaptureVideoDataOutput we configure a
        /// AVCaptureMetadataOutput so the delegate function metadataOutput
        /// is called every time a barcode or QR code is detected
        let metadataOutput = AVCaptureMetadataOutput()
        session.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: queue)
        metadataOutput.metadataObjectTypes = objectTypes
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        
        session.addOutput(videoOutput)
        captureSession = session
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
    
    /// Draw rectangles on a layer to display the position of detected barcodes
    /// - Parameter rectangles: The rectangles to draw on the layer
    private func drawRectangles(_ rectangles:[CGRect]) {
        guard let previewLayer = previewLayer else {return}
        if let layer = rectanglesLayer {
            layer.removeFromSuperlayer()
        }
        rectanglesLayer = GFGeometryUtility.getLayer(withRectangles: rectangles, frameSize: previewLayer.frame, strokeColor: UIColor.green.cgColor)
        DispatchQueue.main.async {
            if let previewLayer = self.previewLayer,
               let rectanglesLayer = self.rectanglesLayer {
                previewLayer.addSublayer(rectanglesLayer)
                previewLayer.setNeedsDisplay()
            }
        }
    }
    
    /// Returns an array of barcoded from an array of AVMetadataObject
    /// - Parameter metadataObjects: The array of AVMetadataObject containing the codes
    /// - Returns: A String array of barcodes
    private func getBarcodeStringFromCapturedObjects(metadataObjects:[AVMetadataObject]) -> [String] {
        var rectangles = [CGRect]()
        var codes:[String] = []
        for metadata in metadataObjects {
            if let object = metadata as? AVMetadataMachineReadableCodeObject,
                let stringValue = object.stringValue {
                codes.append(stringValue)
                if drawRectangles {
                    rectangles.append(object.bounds)
                }
            }
        }
        if drawRectangles {
            drawRectangles(rectangles)
        }
        return codes
    }
}

// MARK: - AVCaptureMeta delegate

@available(iOS 10.0, *)
extension GFLiveBarcodeViewController:AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate  {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        let codes = getBarcodeStringFromCapturedObjects(metadataObjects: metadataObjects)
        delegate?.capturedStrings(strings: codes)
    }
}
