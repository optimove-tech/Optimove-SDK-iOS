//  Copyright © 2019 Optimove. All rights reserved.

final class SetUserEmailEvent: OptimoveCoreEvent {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setEmail.rawValue
        struct Key {
            static let email = OptimoveKeys.Configuration.email.rawValue
        }
    }

    let name: String = Constants.name
    let parameters: [String: Any]

    init(email: String) {
        self.parameters = [
            Constants.Key.email: email
        ]
    }
}
