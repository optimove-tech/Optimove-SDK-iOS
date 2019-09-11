//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

struct ScreenVisitValidator {

    enum Result {
        case valid
        case emptyTitle
        case emptyPath
    }

    static func validate(screenPath: String, screenTitle: String) -> ScreenVisitValidator.Result {
        guard !screenTitle.isEmpty else {
            Logger.error("Failed to report screen visit. Reason: empty title")
            return .emptyTitle
        }
        guard !screenPath.isEmpty else {
            Logger.error("Failed to report screen visit. Reason: empty path")
            return .emptyPath
        }
        return .valid
    }

}
