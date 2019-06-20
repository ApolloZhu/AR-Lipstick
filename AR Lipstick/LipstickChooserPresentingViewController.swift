//
//  LipstickChooserPresentingViewController.swift
//  AR Lipstick
//
//  Created by Apollo Zhu on 2019/6/20.
//  Copyright © 2019 Apollo Zhu. All rights reserved.
//

import UIKit
import FloatingPanel

class LipstickChooserPresentingViewController: UIViewController, LipstickChooserDelegate, FloatingPanelControllerDelegate {
    func didChooseLipstick(_ lipstick: Lipstick) {
        fatalError("Required method `didChooseLipstick` not implemented")
    }
    
    let fpc = FloatingPanelController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fpc.delegate = self
        let lipstickChooser = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "lipstickChooser")
            as! LipstickCollectionViewController
        lipstickChooser.delegate = self
        fpc.set(contentViewController: lipstickChooser)
        fpc.track(scrollView: lipstickChooser.collectionView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fpc.addPanel(toParent: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        fpc.removePanelFromParent(animated: animated)
    }
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        return traitCollection.verticalSizeClass == .compact ? FloatingPanelDefaultLandscapeLayout() : nil
    }
}
