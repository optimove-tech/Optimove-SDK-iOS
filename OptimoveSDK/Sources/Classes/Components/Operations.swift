//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

enum CommonOperation {
    case report(events: [Event])
    case dispatchNow
    case setInstallation
    case optIn
    case optOut
    case none
}

enum OptistreamOperation {
    case report(events: [OptistreamEvent])
    case dispatchNow
}
