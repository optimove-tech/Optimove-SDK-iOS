//
//  ViewController.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import UIKit
import Firebase
import OptimovePiwikTracker
import OptimoveSDK
import MessageUI

class ViewController: UIViewController,OptimoveDeepLinkCallback
{
    func didReceive(deepLink: OptimoveDeepLinkComponents?)
    {
        DispatchQueue.main.asyncAfter(deadline: .now()+2.0)
        {
            let vc = self.storyboard!.instantiateViewController(withIdentifier: deepLink!.screenName)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Optimove.sharedInstance.register(stateDelegate: self)
        Optimove.sharedInstance.register(deepLinkResponder: OptimoveDeepLinkResponder(self))
    }
    
    @IBAction func dispatch(_ sender: UIButton)
    {
        PiwikTracker.shared?.dispatch()
    }
    
    @IBAction func subscribrToTest(_ sender: UIButton)
    {
        Optimove.sharedInstance.subscribeToTestMode()
    }
    
    @IBAction func unsubsribeFromTest(_ sender: UIButton)
    {
        Optimove.sharedInstance.unSubscribeFromTestMode()
    }
    @IBAction func resetToken(_ sender: UIButton)
    {
        InstanceID.instanceID().deleteID
        { (error) in
            print(error?.localizedDescription ?? "reset FCM Token")
        }
    }
    @IBAction func sendLogs(_ sender: UIButton)
    {
        if( MFMailComposeViewController.canSendMail() )
        {
            let url  = OptimoveFileManager.shared.optimoveSDKDirectory.appendingPathComponent("Logs")
            guard let logsUrls = try? FileManager.default.contentsOfDirectory(at: url,
                                                    includingPropertiesForKeys: nil,
                                                    options: .skipsHiddenFiles)
                else {return}
            var logs = [Data]()
            for logUrl in logsUrls
            {
                guard let log = try? Data.init(contentsOf: logUrl) else { continue }
                logs.append(log)
            }
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            //Set the subject and message of the email
            mailComposer.setSubject("Here are my logs")
            mailComposer.setMessageBody("This is what they sound like.", isHTML: false)
            mailComposer.setToRecipients(["elkana_o@optimove.com"])
            
            for i in 0..<logs.count
            {
                mailComposer.addAttachmentData(logs[i], mimeType: "text/plain", fileName: "loggingFile_\(i).txt")
            }
            self.present(mailComposer, animated: true, completion: nil)
        }
    }
}
extension ViewController: MFMailComposeViewControllerDelegate
{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        Optimove.sharedInstance.logger.debug ("send mail to developer")
            
        self.dismiss(animated: true, completion: nil)
    }
}
extension ViewController: OptimoveStateDelegate
{
    func didStartLoading() {
        
    }
    
    func didBecomeActive() {
        Optimove.sharedInstance.setScreenEvent(viewControllersIdetifiers: ["main screen"], url: nil)
    }
    
    func didBecomeInvalid(withErrors errors: [Int]) {
        
    }
    
    var optimoveStateDelegateID: Int {
        return 3
    }
}



