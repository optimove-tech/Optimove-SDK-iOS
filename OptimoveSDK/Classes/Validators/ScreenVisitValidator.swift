//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

struct ScreenVisitValidator {

    enum Result {
        case valid
        case emptyTitle
    }

    static func validate(screenTitle: String) -> ScreenVisitValidator.Result {
        guard !screenTitle.isEmpty else {
            Logger.error("Failed to report screen visit. Reason: empty title")
            return .emptyTitle
        }
        return .valid
    }

}
