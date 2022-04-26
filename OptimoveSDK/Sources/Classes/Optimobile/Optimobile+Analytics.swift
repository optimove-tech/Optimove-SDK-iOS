//  Copyright © 2022 Optimove. All rights reserved.

import Foundation

extension Optimobile {
    static func trackEvent(eventType: OptimobileEvent, properties: [String:Any]?, immediateFlush: Bool = false) {
        getInstance().analyticsHelper.trackEvent(eventType: eventType.rawValue, properties: properties, immediateFlush: immediateFlush)
    }
    
    static func trackEvent(eventType: KumulosSharedEvent, properties: [String:Any]?, immediateFlush: Bool = false) {
        getInstance().analyticsHelper.trackEvent(eventType: eventType.rawValue, properties: properties, immediateFlush: immediateFlush)
    }
    
    static func trackEvent(eventType: String, atTime: Date, properties: [String:Any]?, immediateFlush: Bool = false, onSyncComplete:SyncCompletedBlock? = nil) {
        getInstance().analyticsHelper.trackEvent(eventType: eventType, atTime: atTime, properties: properties, immediateFlush: immediateFlush, onSyncComplete: onSyncComplete)
    }
    
    /**
     Logs an analytics event to the local database

     Parameters:
     - eventType: Unique identifier for the type of event
     - properties: Optional meta-data about the event
     */
    static func trackEvent(eventType: String, properties: [String:Any]?) {
        getInstance().analyticsHelper.trackEvent(eventType: eventType, properties: properties, immediateFlush: false)
    }

    /**
     Logs an analytics event to the local database then flushes all locally stored events to the server

     Parameters:
     - eventType: Unique identifier for the type of event
     - properties: Optional meta-data about the event
     */
    static func trackEventImmediately(eventType: String, properties: [String:Any]?) {
        getInstance().analyticsHelper.trackEvent(eventType: eventType, properties: properties, immediateFlush: true)
    }

    /**
     Associates a user identifier with the current Kumulos installation record

     Parameters:
     - userIdentifier: Unique identifier for the current user
     */
    static func associateUserWithInstall(userIdentifier: String) {
        associateUserWithInstallImpl(userIdentifier: userIdentifier, attributes: nil)
    }

    /**
     Associates a user identifier with the current Kumulos installation record, additionally setting the attributes for the user

     Parameters:
     - userIdentifier: Unique identifier for the current user
     - attributes: JSON encodable dictionary of attributes to store for the user
     */
    static func associateUserWithInstall(userIdentifier: String, attributes: [String:AnyObject]) {
        associateUserWithInstallImpl(userIdentifier: userIdentifier, attributes: attributes)
    }
    
    /**
     Returns the identifier for the user currently associated with the Kumulos installation record
     If no user is associated, it returns the Kumulos installation ID
    */
    static var currentUserIdentifier : String {
        get {
            return OptimobileHelper.currentUserIdentifier
        }
    }

    /**
     Clears any existing association between this install record and a user identifier.

     See associateUserWithInstall and currentUserIdentifier for further information.
     */
    static func clearUserAssociation() {
        OptimobileHelper.userIdLock.wait()
        let currentUserId = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue) as! String?
        OptimobileHelper.userIdLock.signal()

        Optimobile.trackEvent(eventType: OptimobileEvent.STATS_USER_ASSOCIATION_CLEARED, properties: ["oldUserIdentifier": currentUserId ?? NSNull()])

        OptimobileHelper.userIdLock.wait()
        KeyValPersistenceHelper.removeObject(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)
        OptimobileHelper.userIdLock.signal()

        if (currentUserId != nil && currentUserId != Optimobile.installId) {
            getInstance().inAppHelper.handleAssociatedUserChange();
        }
    }

    fileprivate static func associateUserWithInstallImpl(userIdentifier: String, attributes: [String:AnyObject]?) {
        if userIdentifier == "" {
            print("User identifier cannot be empty, aborting!")
            return
        }

        var params : [String:Any]
        if let attrs = attributes {
            params = ["id": userIdentifier, "attributes": attrs]
        }
        else {
            params = ["id": userIdentifier]
        }

        OptimobileHelper.userIdLock.wait()
        let currentUserId = KeyValPersistenceHelper.object(forKey: OptimobileUserDefaultsKey.USER_ID.rawValue) as! String?
        KeyValPersistenceHelper.set(userIdentifier, forKey: OptimobileUserDefaultsKey.USER_ID.rawValue)
        OptimobileHelper.userIdLock.signal()

        Optimobile.trackEvent(eventType: OptimobileEvent.STATS_ASSOCIATE_USER, properties: params, immediateFlush: true)

        if (currentUserId == nil || currentUserId != userIdentifier) {
            getInstance().inAppHelper.handleAssociatedUserChange();
        }
    }

}
