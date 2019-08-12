//  Copyright © 2019 Optimove. All rights reserved.

protocol Eventable: Component {
    func setUserId(_ userId: String)
    func report(event: OptimoveEvent, config: EventsConfig)
    func reportScreenEvent(customURL: String,
                           pageTitle: String,
                           category: String?) throws
    func dispatchNow()
}
