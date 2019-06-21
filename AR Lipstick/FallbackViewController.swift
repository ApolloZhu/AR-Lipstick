//
//  FallbackViewController.swift
//  AR Lipstick
//
//  Created by Apollo Zhu on 2019/6/21.
//  Copyright © 2019 Apollo Zhu. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

typealias Lips = (innerLips: VNFaceLandmarkRegion2D, outerLips: VNFaceLandmarkRegion2D)

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
    
    // MARK: - Rendering
    
    func layerSize(forViewBounds size: CGSize) -> CGSize {
        let larger = max(size.width, size.height)
        let smaller = min(size.width, size.height)
        let unit = min(larger / 16, smaller / 9)
        if size.width > size.height {
            return CGSize.init(width: unit * 16, height: unit * 9)
        } else {
            return CGSize(width: unit * 9, height: unit * 16)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            let newSize = self.layerSize(forViewBounds: size)
            self.shapeLayer.frame.size = newSize
            self.previewLayer.frame.size = newSize
        })
    }
    
    func updateForLips(_ allLips: [Lips]) {
        let path = UIBezierPath()
        for lips in allLips {
            let allPoints = [
                lips.innerLips.pointsInImage(imageSize: shapeLayer.frame.size),
                lips.outerLips.pointsInImage(imageSize: shapeLayer.frame.size)
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
        let size = layerSize(forViewBounds: view.bounds.size)
        
        lipstickColor = .black
        shapeLayer.fillRule = .evenOdd
        shapeLayer.frame.size = size
        shapeLayer.opacity = 0.82
        view.layer.insertSublayer(shapeLayer, at: 0)
        
        // MARK: - Camera
        previewLayer.session = session
        previewLayer.frame.size = size
        view.layer.insertSublayer(previewLayer, at: 0)
        
        let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
        let input = try! AVCaptureDeviceInput(device: frontCamera)
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        
        session.beginConfiguration()
        // session.sessionPreset = .high
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        
        session.startRunning()
    }
    
    let previewLayer = AVCaptureVideoPreviewLayer()
    let session = AVCaptureSession()
}

// MARK: - Detection

extension FallbackViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handler = VNImageRequestHandler(
            cvPixelBuffer: cvBuffer,
            orientation: CGImagePropertyOrientation(connection.videoOrientation)
        )
        let request = VNDetectFaceLandmarksRequest(completionHandler: processLandmarks)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func processLandmarks(_ request: VNRequest, _ error: Error?) {
        if let error = error {
            print(error)
        }
        guard let results = request.results as? [VNFaceObservation] else { return }
        let allLips: [Lips] = results.lazy.compactMap {
            guard let landmarks = $0.landmarks
                , let innerLips = landmarks.innerLips
                , let outerLips = landmarks.outerLips
                else { return nil }
            return (innerLips, outerLips)
        }
        updateForLips(allLips)
    }
}

extension CGImagePropertyOrientation {
    init!(_ videoOrientation: AVCaptureVideoOrientation) {
        switch videoOrientation {
        case .portrait:
            self = .up
        case .portraitUpsideDown:
            self = .down
        case .landscapeRight:
            self = .right
        case .landscapeLeft:
            self = .left
        @unknown default:
            return nil
        }
    }
}
