//  Copyright © 2019 Optimove. All rights reserved.

final class SetUserAgent: Event {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setUserAgent.rawValue
        static let userAgentHeaderBase = "user_agent_header"
    }

    init(userAgent: String) {
        super.init(
            name: Constants.name,
            context: [
                Constants.userAgentHeaderBase: userAgent
            ]
        )
    }
}
