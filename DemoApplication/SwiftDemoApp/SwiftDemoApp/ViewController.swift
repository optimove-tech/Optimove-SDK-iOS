
import UIKit
import OptimoveSDK

class ViewController: UIViewController, OptimoveSuccessStateListener, OptimoveDeepLinkCallback {
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Optimove.shared.register(deepLinkResponder: OptimoveDeepLinkResponder(self))
        Optimove.shared.registerSuccessStateListener(self)
    }
    
    func optimove(_ optimove: Optimove, didBecomeActiveWithMissingPermissions missingPermissions: [OptimoveDeviceRequirement]) {
        // Report this
        Optimove.shared.setScreenVisit(
            screenPath: "Home/Store/Footware/Boots",
            screenTitle: "<YOUR_TITLE>",
            screenCategory: "<OPTIONAL: YOUR_CATEGORY>"
        )
        // OR that
        Optimove.shared.setScreenVisit(
            screenPathArray: ["Home", "Store", "Footware", "Boots"],
            screenTitle: "<YOUR_TITLE>",
            screenCategory: "<OPTIONAL: YOUR_CATEGORY>"
        )
    }
    
    @IBAction func subscribrToTest(_ sender: UIButton)
    {
        Optimove.shared.startTestMode()
    }
    
    @IBAction func unsubsribeFromTest(_ sender: UIButton)
    {
        Optimove.shared.stopTestMode()
    }

    func didReceive(deepLink: OptimoveDeepLinkComponents?)
    {
        guard let deepLink = deepLink else {return}
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "deepLinkVc") as? DeepLinkViewController else { return }
        
        vc.deepLinkComp = deepLink
        
        present(vc, animated: true)
    }
}
