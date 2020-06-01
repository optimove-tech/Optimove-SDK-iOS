import UIKit
import OptimoveSDK

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Report screen visit like this
        Optimove.shared.reportScreenVisit(screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
        // OR
        Optimove.shared.reportScreenVisit(screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")

        // Optipush Only
        Optimove.shared.register(deepLinkResponder: OptimoveDeepLinkResponder(self))
    }

}

// Mark - Optimove SDK Indentification

extension ViewController {

    func login(email: String) {
        // Some login logic through which the SDK ID is retrieved
        let sdkId = "aGVsbG93b3JsZA=="

        /**
         Option 1:
         If there are both valid the email and the sdkId, you can call the registerUser
         */
        Optimove.shared.registerUser(sdkId: sdkId, email: email)

        /**
         Option 2: If there is only the email is valid, you can call the
         ```
         Optimove.shared.setUserEmail(email: email)
         ```

         Option 3: No need to wait for the SDK to be initialized when calling setUserId
         ```
         Optimove.shared.setUserId(sdkId)
         ```
         */
    }
}

// Mark - Optimove SDK Events

extension ViewController {

    func reportSimpleEvent() {
        Optimove.shared.reportEvent(
            name: "signup",
            parameters: [
                "first_name": "John",
                "last_name": "Doe",
                "email": "john@doe.com",
                "age": 42,
                "opt_in": false
            ]
        )
    }

    func reportComplexEvent() {
        Optimove.shared.reportEvent(PlacedOrderEvent([CartItem]()))
    }
}

// Mark - Optimove SDK Optipush

extension ViewController: OptimoveDeepLinkCallback {

    func didReceive(deepLink: OptimoveDeepLinkComponents?) {
        guard let deepLink = deepLink else { return }
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "deepLinkVc") as? DeepLinkViewController else { return }
        vc.deepLinkComp = deepLink
        present(vc, animated: true)
    }

}
