//
//  GFGeometryUtility.swift
//  GFLiveScanner
//
//  Created by Gualtiero Frigerio on 21/11/2020.
//

import Foundation
import CoreGraphics
import UIKit


/// This class contains an utility function to get a layer with an array of rectangles
/// Is used by GFBarcodeScanner to draw a rectangle over an area where a
/// barcode is detected
class GFGeometryUtility {
    /// Creates a CAShapeLayer with an array of rectangles
    /// - Parameters:
    ///   - rectangles: The array of rectangles to draw in the layer
    ///   - frameSize: the size of the layer
    ///   - strokeColor: stroke color for the rectangles
    /// - Returns: A CAShapeLayer with the rectangles
    public static func getLayer(withRectangles rectangles:[CGRect],
                                frameSize:CGRect,
                                strokeColor:CGColor) -> CAShapeLayer {
        let layer = CAShapeLayer()
        layer.frame = frameSize
        
        var path = UIBezierPath()
        for rect in rectangles {
            let transformedRect = transformRect(rect, forFrame: frameSize)
            path = updatePath(path, withRect: transformedRect)
        }
        drawPath(path, onLayer: layer, strokeColor:strokeColor)
        
        return layer
    }
    
    // MARK: - Private
    
    /// Draws a UIBezierPath on a layer
    /// - Parameters:
    ///   - path: The UIBezierPath to draw
    ///   - layer: The layer where the path has to be drawn
    ///   - strokeColor: The stroke color of the path
    static private func drawPath(_ path:UIBezierPath, onLayer layer:CAShapeLayer, strokeColor:CGColor) {
        path.close()
        layer.path = path.cgPath
        layer.strokeColor = strokeColor
        layer.fillColor = UIColor.clear.cgColor
    }
    
    /// The CGRect coming from AV doesn't have the real size but is scaled between 0 and 1
    /// so we need to convert it to real sizes based on the given frame
    /// AV rect is landscape so if we're portrait we invert width and height
    /// - Parameters:
    ///   - bounds: the rect bounds
    ///   - frame: the containing frame
    /// - Returns: the rect transformed
    static private func transformRect(_ bounds:CGRect,  forFrame frame:CGRect) -> CGRect {
        var returnFrame = CGRect(x: 0, y: 0, width:0, height: 0)
        var size = frame.size
        let orientation = UIApplication.shared.statusBarOrientation
        if  orientation == .portrait || orientation == .portraitUpsideDown {
            let tmp = size.width
            size.width = size.height
            size.height = tmp
        }
        returnFrame.origin.y = bounds.origin.x * size.width
        returnFrame.origin.x = bounds.origin.y * size.height
        returnFrame.size.width = bounds.size.width * size.width
        returnFrame.size.height = bounds.size.height * size.height
        return returnFrame
    }
    
    /// Update a UIBezierPath with a CGRect
    /// If no path is specified a new one is created
    /// Called by getLayer to draw rectangles on a layer
    /// - Parameters:
    ///   - path: The optional path to update
    ///   - rect: The rectangle to draw
    /// - Returns: The UIBezierPath with the rectangle
    static private func updatePath(_ path:UIBezierPath?, withRect rect:CGRect) -> UIBezierPath {
        let updatedPath = path ?? UIBezierPath()
        updatedPath.move(to: rect.origin)
        updatedPath.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y))
        updatedPath.addLine(to: CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height))
        updatedPath.addLine(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.size.height))
        return updatedPath
    }
    
}
