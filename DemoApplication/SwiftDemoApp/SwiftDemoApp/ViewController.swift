//
//  ViewController.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import OptimoveSDK

class ViewController: UIViewController, OptimoveDeepLinkCallback,OptimoveSuccessStateListener
{
    func didReceive(deepLink: OptimoveDeepLinkComponents?)
    {
        if let deepLink = deepLink {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: deepLink.screenName) {
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Optimove.sharedInstance.registerSuccessStateListener(self)
        Optimove.sharedInstance.register(deepLinkResponder: OptimoveDeepLinkResponder(self))
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
    }
    
    
    @IBAction func subscribrToTest(_ sender: UIButton)
    {
        Optimove.sharedInstance.startTestMode()
    }
    
    @IBAction func unsubsribeFromTest(_ sender: UIButton)
    {
        Optimove.sharedInstance.stopTestMode()
    }
    func optimove(_ optimove: Optimove, didBecomeActiveWithMissingPermissions missingPermissions: [OptimoveDeviceRequirement]) {
        Optimove.sharedInstance.reportScreenVisit(viewControllersIdentifiers: ["main screen"])
        Optimove.sharedInstance.unregisterSuccessStateListener(self)
    }
}


