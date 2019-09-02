//  Copyright © 2019 Optimove. All rights reserved.

import OptimoveCore
import Foundation

protocol Component {

}

protocol Pushable: Component {
    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    // TODO: Move `performRegistration` to OptiPush component.
    func performRegistration()
    func unsubscribeFromTopic(topic: String)
    func subscribeToTopic(topic: String)
}

protocol Eventable: Component {
    // TODO: Use
    func setUserId(_ userId: String)
    func report(event: OptimoveEvent) throws
    func reportScreenEvent(customURL: String,
                           pageTitle: String,
                           category: String?) throws
    func dispatchNow()
}
