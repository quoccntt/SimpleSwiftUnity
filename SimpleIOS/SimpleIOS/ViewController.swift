//
//  ViewController.swift
//  SimpleIOS
//
//  Created by QuocNP1.APL on 21/09/2022.
//

import UIKit
import UnityFramework

class ViewController: UIViewController {
    @IBOutlet private weak var unityView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func tapShowUnity(_ sender: UIButton) {
        showUnity()
    }
    
    private func showUnity() {
        UnityEmbeddedSwift.showUnity()
        if let view = UnityEmbeddedSwift.addUnityWindow() {
            view.frame = CGRect(x: self.unityView.frame.origin.x, y: self.unityView.frame.origin.y , width: self.unityView.frame.width, height: self.unityView.frame.height)
            self.unityView.superview?.addSubview(view)
        }
    }
}

