//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol Pushable: Component {
    func application(didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    func performRegistration()
    func unsubscribeFromTopic(topic: String)
    func subscribeToTopic(topic: String)
}
