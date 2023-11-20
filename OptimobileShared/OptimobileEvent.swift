//  Copyright © 2023 Optimove. All rights reserved.

enum OptimobileEvent : String {
    case DEEP_LINK_MATCHED = "k.deepLink.matched"
    case DEVICE_UNSUBSCRIBED = "k.push.deviceUnsubscribed"
    case ENGAGE_BEACON_ENTERED_PROXIMITY = "k.engage.beaconEnteredProximity"
    case ENGAGE_LOCATION_UPDATED = "k.engage.locationUpdated"
    case IN_APP_CONSENT_CHANGED = "k.inApp.statusUpdated"
    case MESSAGE_DELETED_FROM_INBOX = "k.message.inbox.deleted"
    case MESSAGE_DELIVERED = "k.message.delivered"
    case MESSAGE_DISMISSED = "k.message.dismissed"
    case MESSAGE_OPENED = "k.message.opened"
    case MESSAGE_READ = "k.message.read"
    case PUSH_DEVICE_REGISTER = "k.push.deviceRegistered"
    case STATS_ASSOCIATE_USER = "k.stats.userAssociated"
    case STATS_BACKGROUND = "k.bg"
    case STATS_CALL_HOME = "k.stats.installTracked"
    case STATS_FOREGROUND = "k.fg"
    case STATS_USER_ASSOCIATION_CLEARED = "k.stats.userAssociationCleared"
}
