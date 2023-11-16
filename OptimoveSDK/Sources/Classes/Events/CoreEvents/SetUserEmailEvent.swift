//  Copyright © 2019 Optimove. All rights reserved.

final class SetUserEmailEvent: Event {
    enum Constants {
        static let name = OptimoveKeys.Configuration.setEmail.rawValue
        enum Key {
            static let email = OptimoveKeys.Configuration.email.rawValue
        }
    }

    init(email: String) {
        super.init(name: Constants.name, context: [Constants.Key.email: email])
    }
}
