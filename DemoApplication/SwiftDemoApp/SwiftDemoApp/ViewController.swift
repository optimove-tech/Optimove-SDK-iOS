
import UIKit
import OptimoveSDK

class ViewController: UIViewController, OptimoveDeepLinkCallback {
    func didReceive(deepLink: OptimoveDeepLinkComponents?)
    {
        guard let deepLink = deepLink else {return}
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "deepLinkVc") as? DeepLinkViewController else { return }

        vc.deepLinkComp = deepLink
       
        present(vc, animated: true)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        Optimove.shared.register(deepLinkResponder: OptimoveDeepLinkResponder(self))
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        Optimove.shared.setScreenVisit(screenPathArray: ["main screen"], screenTitle: "main screen")
    }
    
    
    @IBAction func subscribrToTest(_ sender: UIButton)
    {
        Optimove.shared.startTestMode()
    }
    
    @IBAction func unsubsribeFromTest(_ sender: UIButton)
    {
        Optimove.shared.stopTestMode()
    }
    
}


