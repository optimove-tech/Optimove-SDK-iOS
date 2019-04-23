
import UIKit
import OptimoveSDK

class SetUserIDViewController: UIViewController
{
    @IBOutlet weak var userIDTextField: UITextField!
    
    @IBAction func pressSetUserID(_ sender: UIButton)
    {
        if let text = userIDTextField.text
        {
            Optimove.shared.setUserId(text)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Optimove.shared.setScreenVisit(screenPathArray: ["main_screen","login"], screenTitle: "login")
    }
}
