/*
 AR Lipstick
 
 ViewController.swift
 Created by Apollo Zhu on 2019/6/19.
 
 Copyright © 2019 Apollo Zhu.
 Copyright © 2019 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, LipstickChooserDelegate {
    // MARK: - Lipstick
    var lipstickColor: UIColor = .black {
        didSet {
            for mask in masks where mask.geometry is ARSCNFaceGeometry {
                mask.geometry?.firstMaterial?.multiply.contents = lipstickColor
            }
        }
    }
    
    func didChooseLipstick(_ lipstick: Lipstick) {
        lipstickColor = lipstick.color
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "segue",
            let vc = segue.destination as? LipstickTableViewController
            else { return }
        vc.delegate = self
    }
    
    // MARK: - Rendering
    
    var faceAnchors: Set<ARFaceAnchor> = []
    var masks: Set<SCNNode> = []
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return nil }
        faceAnchors.insert(faceAnchor)
        
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        
        let material = faceGeometry.firstMaterial!
        material.diffuse.contents = #imageLiteral(resourceName: "wireframeTexture")
        material.multiply.contents = lipstickColor
        material.lightingModel = .physicallyBased
        
        let mask = SCNNode(geometry: faceGeometry)
        masks.insert(mask)
        return mask
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        guard faceAnchors.contains(faceAnchor),
            masks.contains(node),
            let faceGeometry = node.geometry as? ARSCNFaceGeometry
            else { fatalError() }
        
        faceGeometry.update(from: faceAnchor.geometry)
        if #available(iOS 12.0, *), faceAnchor.isTongueOut {
            print("No tongue, please")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        faceAnchors.remove(faceAnchor)
        masks.remove(node)
    }
    
    // MARK: - Setup
    
    @IBOutlet var sceneView: ARSCNView!
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        // Create a session configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lipstickColor = .red
        sceneView.delegate = self
        sceneView.automaticallyUpdatesLighting = true
    }
    
    // MARK: - State Changes
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        sceneView.session.pause()
    }
    
    // MARK: - Error Handling
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async { [weak self] in
            self?.displayError(errorMessage, withTitle: NSLocalizedString("The AR session failed.", comment: "Alert title"))
        }
    }
    
    /// Present an alert informing about the error that has occurred.
    private func displayError(_ message: String, withTitle title: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionTitle = NSLocalizedString("Restart Session", comment: "Alert action title")
        let restartAction = UIAlertAction(title: actionTitle, style: .default) { [weak self] _ in
            alertController.dismiss(animated: true, completion: nil)
            self?.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Extensions

extension UIImage {
    func withTintColor(_ color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let rect = CGRect(origin: .zero, size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(rect)
            draw(in: rect, blendMode: .destinationIn, alpha: 1)
        }
    }
}

extension ARFaceAnchor {
    @available(iOS 12.0, *)
    var isTongueOut: Bool {
        return blendShapes[ARFaceAnchor.BlendShapeLocation.tongueOut]!.floatValue > 0.05
    }
}
