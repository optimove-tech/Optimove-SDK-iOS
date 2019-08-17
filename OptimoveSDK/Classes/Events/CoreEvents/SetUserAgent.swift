//  Copyright © 2019 Optimove. All rights reserved.

final class SetUserAgent: OptimoveCoreEvent {

    struct Constants {
        static let name = OptimoveKeys.Configuration.setUserAgent.rawValue
        static let userAgentSliceLenght: Int = 255
        static let userAgentHeaderBase = "user_agent_header"
    }

    var name: String = Constants.name
    var parameters: [String: Any]

    init(userAgent: String) {
        parameters = userAgent
            .split(by: Constants.userAgentSliceLenght)
            .enumerated()
            .reduce(into: [String: Any]()) { (result, userAgent) in
                let key = Constants.userAgentHeaderBase + String(userAgent.offset + 1)
                result[key] = userAgent.element
            }
    }
}
