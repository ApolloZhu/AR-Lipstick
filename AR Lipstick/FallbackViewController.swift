/*
 AR Lipstick
 
 FallbackViewController.swift
 Created by Apollo Zhu on 2019/6/21.
 
 Copyright © 2019-2021 Apollo Zhu.

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import AVFoundation
import MLKit

class FallbackViewController: UIViewController, LipstickChooserDelegate {
    // MARK: - Lipsticks
    
    var lipstickColor: UIColor = .black {
        didSet {
            shapeLayer.fillColor = lipstickColor.cgColor
            shapeLayer.strokeColor = lipstickColor.cgColor
        }
    }
    
    func didChooseLipstick(_ lipstick: Lipstick) {
        lipstickColor = lipstick.color
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "segue",
            let nav = segue.destination as? UINavigationController,
            let vc = nav.viewControllers.first as? LipstickTableViewController
            else { return }
        vc.delegate = self
    }
    
    // MARK: - Layout
    
    var captureHeight: CGFloat!
    var captureWidth: CGFloat!
    
    func layerSize(forViewBounds size: CGSize) -> CGSize {
        let unit = min(size.width / captureWidth, size.height / captureHeight)
        return CGSize(width: unit * captureWidth, height: unit * captureHeight)
    }
    
    func updateLayerSizes(forViewBounds size: CGSize) {
        let newSize = layerSize(forViewBounds: size)
        self.shapeLayer.frame.size = newSize
        self.previewLayer.frame.size = newSize
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.updateLayerSizes(forViewBounds: size)
        })
    }
    
    // MARK: - Rendering
    
    var framesMissingLips = 0
    let maxFramesMissingLips = 5
    func updateForLips(_ allLips: [Lips]) {
        guard !allLips.isEmpty else {
            framesMissingLips += 1
            if framesMissingLips < maxFramesMissingLips { return }
            // Only remove mask after we confirm there's no lips,
            // not because Firebase only supplies data every other frame.
            return DispatchQueue.main.async { [weak self] in
                self?.shapeLayer.path = nil
            }
        }
        framesMissingLips = 0
        let layerWidth = shapeLayer.frame.width
        let layerHeight = shapeLayer.frame.height
        /// X and Y coordinates are flipped probably
        /// because CVBuffer is also flipped, but
        /// I haven't looked into why that is the case.
        func convert(_ point: VisionPoint) -> CGPoint {
            return CGPoint(
                x: point.y * layerHeight / captureHeight,
                y: point.x * layerWidth / captureWidth
            )
        }
        let path = UIBezierPath()
        for lips in allLips {
            let allPoints = [
                lips[0].points.map(convert) + lips[1].points.map(convert),
                lips[2].points.map(convert) + lips[3].points.map(convert)
            ]
            for points in allPoints {
                path.move(to: points.first!)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
                path.close()
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.shapeLayer.path = path.cgPath
        }
    }
    
    let shapeLayer = CAShapeLayer()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lipstickColor = .black
        shapeLayer.opacity = 0.5
        shapeLayer.fillRule = .evenOdd
        shapeLayer.lineJoin = .round
        shapeLayer.lineWidth = 5
        view.layer.insertSublayer(shapeLayer, at: 0)
        
        // MARK: - Camera
        previewLayer.session = session
        view.layer.insertSublayer(previewLayer, at: 0)
        
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        let input = try! AVCaptureDeviceInput(device: frontCamera)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        session.beginConfiguration()
        session.sessionPreset = .medium
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        
        session.startRunning()
    }
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
    
    // MARK: - Detection
    // https://developers.google.com/ml-kit/vision/face-detection/ios
    
    let faceDetectorOptions: FaceDetectorOptions = {
        $0.performanceMode = .accurate
        $0.contourMode = .all
        return $0
    }(FaceDetectorOptions())
    lazy var faceDetector = FaceDetector.faceDetector(options: faceDetectorOptions)
}

typealias Lips = [FaceContour]
let coutourTypes: [FaceContourType] = [.upperLipTop, .lowerLipBottom, .upperLipBottom, .lowerLipTop]

extension FallbackViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        if captureHeight == nil {
            guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            // For some reason width and height are flipped
            let side1 = CGFloat(CVPixelBufferGetHeight(cvBuffer))
            let side2 = CGFloat(CVPixelBufferGetWidth(cvBuffer))
            // so we have to choose the correct value ourselves
            captureHeight = max(side1, side2)
            captureWidth = min(side1, side2)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateLayerSizes(forViewBounds: self.view!.bounds.size)
            }
        }
        let image = VisionImage(buffer: sampleBuffer)
        image.orientation = imageOrientation(
            deviceOrientation: UIDevice.current.orientation,
            cameraPosition: .front
        )
        faceDetector.process(image, completion: processFaces)
    }
    
    func processFaces(_ faces: [Face]?, _ error: Error?) {
        var allLips = [Lips]()
        defer { updateForLips(allLips) }
        if let error = error { return print(error) }
        guard let faces = faces, !faces.isEmpty else { return }
        allLips = faces.lazy
            .map { face in coutourTypes.compactMap { face.contour(ofType: $0) } }
            .filter { $0.count == 4 }
    }
}

func imageOrientation(
    deviceOrientation: UIDeviceOrientation,
    cameraPosition: AVCaptureDevice.Position
) -> UIImage.Orientation {
    switch deviceOrientation {
    case .portrait:
        return cameraPosition == .front ? .leftMirrored : .right
    case .landscapeLeft:
        return cameraPosition == .front ? .downMirrored : .up
    case .portraitUpsideDown:
        return cameraPosition == .front ? .rightMirrored : .left
    case .landscapeRight:
        return cameraPosition == .front ? .upMirrored : .down
    case .faceDown, .faceUp, .unknown:
        return .up
    @unknown default:
        return .up
    }
}
