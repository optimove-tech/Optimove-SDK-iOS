//
//  ViewController.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit

class ViewController: UIViewController, OptimoveDeepLinkCallback {
    func didReceive(deepLink: OptimoveDeepLinkComponents?)
    {
        if let deepLink = deepLink {
            DispatchQueue.main.asyncAfter(deadline: .now()+2.0)
            {
                if let vc = self.storyboard?.instantiateViewController(withIdentifier: deepLink.screenName) {
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Optimove.sharedInstance.register(deepLinkResponder: OptimoveDeepLinkResponder(self))
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        Optimove.sharedInstance.setScreenEvent(viewControllersIdetifiers: ["main screen"], url: nil)
    }
    
    
    @IBAction func subscribrToTest(_ sender: UIButton)
    {
        Optimove.sharedInstance.subscribeToTestMode()
    }
    
    @IBAction func unsubsribeFromTest(_ sender: UIButton)
    {
        Optimove.sharedInstance.unSubscribeFromTestMode()
    }
    
}


