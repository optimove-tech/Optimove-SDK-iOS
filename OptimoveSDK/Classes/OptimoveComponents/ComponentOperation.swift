//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol ComponentOperation: Equatable { }

enum EventableOperation: ComponentOperation {
    case setUserId(userId: String)
    case report(event: OptimoveEvent)
    case reportScreenEvent(customURL: String, pageTitle: String, category: String?)
    case dispatchNow

    static func == (lhs: EventableOperation, rhs: EventableOperation) -> Bool {
        switch (lhs, rhs) {
        case (.setUserId, .setUserId):
            return true
        case (.report, .report):
            return true
        case (.reportScreenEvent, .reportScreenEvent):
            return true
        case (.dispatchNow, .dispatchNow):
            return true
        default:
            return false
        }
    }
}

enum PushableOperation: ComponentOperation {
    case deviceToken(token: Data)
    case performRegistration
    case unsubscribeFromTopic(topic: String)
    case subscribeToTopic(topic: String)

    static func == (lhs: PushableOperation, rhs: PushableOperation) -> Bool {
        switch (lhs, rhs) {
        case (.deviceToken, .deviceToken):
            return true
        case (.performRegistration, .performRegistration):
            return true
        case (.unsubscribeFromTopic, .unsubscribeFromTopic):
            return true
        case (.subscribeToTopic, .subscribeToTopic):
            return true
        default:
            return false
        }
    }
}
