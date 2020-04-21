//  Copyright © 2019 Optimove. All rights reserved.

final class SetUserAgent: Event {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setUserAgent.rawValue
        static let userAgentSliceLenght: Int = 255
        static let userAgentHeaderBase = "user_agent_header"
    }

    init(userAgent: String) {
        super.init(
            name: Constants.name,
            context: userAgent
                .split(by: Constants.userAgentSliceLenght)
                .enumerated()
                .reduce(into: [String: Any]()) { (result, userAgent) in
                    let key = Constants.userAgentHeaderBase + String(userAgent.offset + 1)
                    result[key] = userAgent.element
            }
        )
    }
}
