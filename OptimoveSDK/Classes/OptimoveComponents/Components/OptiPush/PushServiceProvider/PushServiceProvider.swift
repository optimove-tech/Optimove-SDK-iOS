//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

protocol PushServiceProviderDelegate: class {
    func onRefreshToken()
}

protocol PushServiceProvider {

    var delegate: PushServiceProviderDelegate? { get set }
    func handleRegistration(apnsToken: Data)

    func subscribeToTopics()
    func subscribeToTopic(topic: String)

    func unsubscribeFromTopics()
    func unsubscribeFromTopic(topic: String)
}
