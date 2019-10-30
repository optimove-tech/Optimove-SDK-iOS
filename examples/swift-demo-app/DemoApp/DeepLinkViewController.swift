
import UIKit
import OptimoveSDK
class DeepLinkViewController: UIViewController {
    @IBOutlet weak var deepLinkLabel: UILabel!

    var deepLinkComp: OptimoveDeepLinkComponents?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let deepLinkComp = self.deepLinkComp else {
            self.deepLinkLabel.text = "No Deep Link"
            return
        }
        var params = "No Params"
        if let query = deepLinkComp.parameters {
            params = query.reduce("", { (result, arg1) in
                let (key, value) = arg1
                return "\(result)\(key)=\(value)\n"
            }).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        self.deepLinkLabel.text = "\(deepLinkComp.screenName):\n\(params)"
    }

    @IBAction func dismissMe(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
