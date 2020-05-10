//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum Operation {
    case report(events: [Event])
    case dispatchNow
    case setInstallation
    case togglePushCampaigns(areDisabled: Bool)
    case deviceToken(token: Data)
    case optIn
    case optOut
}

enum OptistreamOperation {
    case report(events: [OptistreamEvent])
    case dispatchNow
}
