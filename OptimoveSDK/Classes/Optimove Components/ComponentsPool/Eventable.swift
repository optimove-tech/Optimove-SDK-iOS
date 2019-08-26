//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore

protocol Eventable: Component {
    func setUserId(_ userId: String)
    func report(event: OptimoveEvent) throws
    func reportScreenEvent(customURL: String,
                           pageTitle: String,
                           category: String?) throws
    func dispatchNow()
}
