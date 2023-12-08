//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore
import UIKit

public enum InAppMessagePresentationResult: String {
    case PRESENTED = "presented"
    case EXPIRED = "expired"
    case FAILED = "failed"
    case PAUSED = "paused"
}

typealias kumulos_applicationPerformFetchWithCompletionHandler = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
typealias fetchBlock = @convention(block) (_ obj: Any, _ application: UIApplication, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
private var ks_existingBackgroundFetchDelegate: IMP?

typealias InAppSyncCompletionHandler = (_ result: Int) -> Void

class InAppManager {
    let httpClient: KSHttpClient
    let storage: OptimoveStorage
    let pendingNoticationHelper: PendingNotificationHelper
    let optimobileHelper: OptimobileHelper
    private(set) var presenter: InAppPresenter
    private var pendingTickleIds = NSMutableOrderedSet(capacity: 1)

    var messagesContext: NSManagedObjectContext?

    let MESSAGE_TYPE_IN_APP = 2

    private var syncQueue: DispatchQueue
    private let STORED_IN_APP_LIMIT = 50
    private let SYNC_DEBOUNCE_SECONDS = 3600 as TimeInterval

    var finishedInitializationToken: NSObjectProtocol?

    // MARK: Initialization

    init(
        _ config: OptimobileConfig,
        httpClient: KSHttpClient,
        urlBuilder: UrlBuilder,
        storage: OptimoveStorage,
        pendingNoticationHelper: PendingNotificationHelper,
        optimobileHelper: OptimobileHelper
    ) {
        self.httpClient = httpClient
        self.storage = storage
        self.pendingNoticationHelper = pendingNoticationHelper
        self.optimobileHelper = optimobileHelper
        presenter = InAppPresenter(
            displayMode: config.inAppDefaultDisplayMode,
            urlBuilder: urlBuilder,
            pendingNoticationHelper: pendingNoticationHelper
        )
        syncQueue = DispatchQueue(label: "com.optimove.inapp.sync")

        finishedInitializationToken = NotificationCenter.default
            .addObserver(forName: .optimobileInializationFinished, object: nil, queue: nil) { [weak self] notification in
                guard let self = self else { return }
                handleEnrollmentAndSyncSetup()
                Logger.debug("Notification \(notification.name.rawValue) was processed")
            }
    }

    func initialize() {
        initContext()
    }

    func initContext() {
        let objectModel: NSManagedObjectModel? = getDataModel()

        if objectModel == nil {
            print("Failed to create object model")
            return
        }

        var storeCoordinator: NSPersistentStoreCoordinator?
        if let objectModel = objectModel {
            storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        }

        let docsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let storeUrl = URL(string: "KSMessagesDb.sqlite", relativeTo: docsUrl)

        let options = [
            NSMigratePersistentStoresAutomaticallyOption: NSNumber(value: true),
            NSInferMappingModelAutomaticallyOption: NSNumber(value: true),
        ]

        do {
            try storeCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: options)
        } catch {
            print("Failed to set up persistent store: \(error)")
            return
        }

        messagesContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in initialization")
            return
        }

        context.performAndWait {
            context.persistentStoreCoordinator = storeCoordinator
        }
    }

    @objc func appBecameActive() {
        presentImmediateAndNextOpenContent()

        let onComplete: InAppSyncCompletionHandler = { result in
            if result > 0 {
                self.presentImmediateAndNextOpenContent()
            }
        }

        #if DEBUG
            sync(onComplete)
        #else
            syncDebounced(onComplete)
        #endif
    }

    let setupSyncTask: Void = {
        let klass: AnyClass = type(of: UIApplication.shared.delegate!)

        // Perform background fetch
        let performFetchSelector = #selector(UIApplicationDelegate.application(_:performFetchWithCompletionHandler:))
        let fetchType = NSString(string: "v@:@@?").utf8String
        let block: fetchBlock = { (obj: Any, application: UIApplication, completionHandler: @escaping (UIBackgroundFetchResult) -> Void) in
            var fetchResult: UIBackgroundFetchResult = .noData
            let fetchBarrier = DispatchSemaphore(value: 0)

            if let _ = ks_existingBackgroundFetchDelegate {
                unsafeBitCast(ks_existingBackgroundFetchDelegate, to: kumulos_applicationPerformFetchWithCompletionHandler.self)(obj, performFetchSelector, application, { (result: UIBackgroundFetchResult) in
                    fetchResult = result
                    fetchBarrier.signal()
                })
            } else {
                fetchBarrier.signal()
            }

            if Optimobile.sharedInstance.inAppManager.inAppEnabled() {
                Optimobile.sharedInstance.inAppManager.sync { (result: Int) in
                    _ = fetchBarrier.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(20))

                    if result < 0 {
                        fetchResult = .failed
                    } else if result > 0 {
                        fetchResult = .newData
                    }
                    // No data case is default, allow override from other handler
                    completionHandler(fetchResult)
                }
            } else {
                completionHandler(fetchResult)
            }
        }
        let kumulosPerformFetch = imp_implementationWithBlock(unsafeBitCast(block, to: AnyObject.self))

        ks_existingBackgroundFetchDelegate = class_replaceMethod(klass, performFetchSelector, kumulosPerformFetch, fetchType)
    }()

    // MARK: State helpers

    func inAppEnabled() -> Bool {
        return Optimobile.sharedInstance.inAppConsentStrategy != InAppConsentStrategy.notEnabled && userConsented()
    }

    func userConsented() -> Bool {
        // Note if this implementation is changed there is a usage in the main Optimobile initialisation path
        // that should be considered.
        return storage[.inAppConsented] ?? false
    }

    func updateUserConsent(consentGiven: Bool) {
        let props: [String: Any] = ["consented": consentGiven]

        Optimobile.trackEventImmediately(eventType: OptimobileEvent.IN_APP_CONSENT_CHANGED.rawValue, properties: props)

        if consentGiven {
            storage.set(value: consentGiven, key: .inAppConsented)
            handleEnrollmentAndSyncSetup()
        } else {
            DispatchQueue.global(qos: .default).async {
                self.resetMessagingState()
            }
        }
    }

    func handleAssociatedUserChange() {
        if Optimobile.sharedInstance.inAppConsentStrategy == InAppConsentStrategy.notEnabled {
            DispatchQueue.global(qos: .default).async {
                self.updateUserConsent(consentGiven: false)
            }
            return
        }

        DispatchQueue.global(qos: .default).async {
            self.resetMessagingState()
            self.handleEnrollmentAndSyncSetup()
        }
    }

    private func handleEnrollmentAndSyncSetup() {
        if Optimobile.sharedInstance.inAppConsentStrategy == InAppConsentStrategy.autoEnroll, userConsented() == false {
            updateUserConsent(consentGiven: true)
            return
        } else if Optimobile.sharedInstance.inAppConsentStrategy == InAppConsentStrategy.notEnabled, userConsented() == true {
            updateUserConsent(consentGiven: false)
            return
        }

        if !inAppEnabled() {
            return
        }

        _ = setupSyncTask
        NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        let onComplete: InAppSyncCompletionHandler = { result in
            if result > 0 {
                self.presentImmediateAndNextOpenContent()
            }
        }

        sync(onComplete)
    }

    private func resetMessagingState() {
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in resetMessagingState")
            return
        }

        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        storage.set(value: nil, key: .inAppConsented)
        storage.set(value: nil, key: .inAppLastSyncedAt)
        storage.set(value: nil, key: .inAppMostRecentUpdateAt)

        context.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.includesPendingChanges = true

            var messages: [InAppMessageEntity]
            do {
                messages = try context.fetch(fetchRequest) as! [InAppMessageEntity]
            } catch {
                return
            }

            for message in messages {
                context.delete(message)
            }

            do {
                try context.save()
            } catch {
                print("Failed to clean up messages: \(error)")
            }
        }
    }

    // MARK: Message management

    func syncDebounced(_ onComplete: InAppSyncCompletionHandler? = nil) {
        syncQueue.async {
            let lastSyncedAt: Date = self.storage[.inAppLastSyncedAt] ?? Date(timeIntervalSince1970: 0)

            if lastSyncedAt.timeIntervalSinceNow < self.SYNC_DEBOUNCE_SECONDS {
                return
            }

            self.sync(onComplete)
        }
    }

    func sync(_ onComplete: InAppSyncCompletionHandler? = nil) {
        let currentUserIdentifier = optimobileHelper.currentUserIdentifier()
        syncQueue.async {
            let syncBarrier = DispatchSemaphore(value: 0)

            let mostRecentUpdate: Date = storage[.inAppMostRecentUpdateAt]
            var after = ""

            if let mostRecentUpdate = mostRecentUpdate {
                let formatter = DateFormatter()
                formatter.timeStyle = .full
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
                formatter.locale = Locale(identifier: "en_US_POSIX")
                after = "?after=\(KSHttpUtil.urlEncode(formatter.string(from: mostRecentUpdate as Date))!)"
            }

            let encodedIdentifier = KSHttpUtil.urlEncode(currentUserIdentifier)
            let path = "/v1/users/\(encodedIdentifier!)/messages\(after)"

            self.httpClient.sendRequest(.GET, toPath: path, data: nil, onSuccess: { _, decodedBody in
                defer {
                    storage.set(value: Date(), key: .inAppMostRecentUpdateAt)
                    syncBarrier.signal()
                }

                let messagesToPersist = decodedBody as? [[AnyHashable: Any]]
                if messagesToPersist == nil || messagesToPersist!.count == 0 {
                    onComplete?(0)
                    return
                }

                self.persistInAppMessages(messages: messagesToPersist!)
                onComplete?(1)

                DispatchQueue.main.async {
                    if UIApplication.shared.applicationState != .active {
                        return
                    }

                    DispatchQueue.global(qos: .default).async {
                        let messagesToPresent = self.getMessagesToPresent([InAppPresented.IMMEDIATELY.rawValue])
                        self.presenter.queueMessagesForPresentation(messages: messagesToPresent, tickleIds: self.pendingTickleIds)
                    }
                }
            }, onFailure: { _, _, _ in
                onComplete?(-1)
                syncBarrier.signal()
            })

            syncBarrier.wait()
        }
    }

    private func persistInAppMessages(messages: [[AnyHashable: Any]]) {
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in persistInAppMessages")
            return
        }

        context.performAndWait {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: context)

            if entity == nil {
                print("Failed to get entity description for Message, aborting!")
                return
            }

            var mostRecentUpdate = NSDate(timeIntervalSince1970: 0)
            let dateParser = DateFormatter()
            dateParser.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
            dateParser.locale = Locale(identifier: "en_US_POSIX")
            dateParser.timeZone = TimeZone(secondsFromGMT: 0)

            var fetchedWithInbox = false
            for message in messages {
                let partId = message["id"] as! Int64

                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
                fetchRequest.entity = entity
                let predicate = NSPredicate(format: "id = %i", partId)
                fetchRequest.predicate = predicate

                var fetchedObjects: [InAppMessageEntity]
                do {
                    fetchedObjects = try context.fetch(fetchRequest) as! [InAppMessageEntity]
                } catch {
                    continue
                }

                // Upsert
                let model: InAppMessageEntity = fetchedObjects.count == 1 ? fetchedObjects[0] : InAppMessageEntity(entity: entity!, insertInto: context)

                model.id = partId
                model.updatedAt = dateParser.date(from: message["updatedAt"] as! String)! as NSDate
                if model.dismissedAt == nil {
                    model.dismissedAt = dateParser.date(from: message["openedAt"] as? String ?? "") as NSDate?
                }
                model.presentedWhen = message["presentedWhen"] as! String

                if model.readAt == nil {
                    model.readAt = dateParser.date(from: message["readAt"] as? String ?? "") as NSDate?
                }

                if model.sentAt == nil {
                    model.sentAt = dateParser.date(from: message["sentAt"] as? String ?? "") as NSDate?
                }

                model.content = message["content"] as! NSDictionary
                model.data = message["data"] as? NSDictionary
                model.badgeConfig = message["badge"] as? NSDictionary
                model.inboxConfig = message["inbox"] as? NSDictionary

                if model.inboxConfig != nil {
                    // crude way to refresh when new inbox, updated readAt, updated inbox title/subtite
                    // may cause redundant refreshes (if message with inbox updated, but not inbox itself).
                    fetchedWithInbox = true

                    let inbox = model.inboxConfig!

                    model.inboxFrom = dateParser.date(from: inbox["from"] as? String ?? "") as NSDate?
                    model.inboxTo = dateParser.date(from: inbox["to"] as? String ?? "") as NSDate?
                }

                let inboxDeletedAt = message["inboxDeletedAt"] as? String
                if inboxDeletedAt != nil {
                    model.inboxConfig = nil
                    model.inboxFrom = nil
                    model.inboxTo = nil
                    if model.dismissedAt == nil {
                        model.dismissedAt = dateParser.date(from: inboxDeletedAt!) as NSDate?
                    }
                }

                model.expiresAt = dateParser.date(from: message["expiresAt"] as? String ?? "") as NSDate?

                if model.updatedAt.timeIntervalSince1970 > mostRecentUpdate.timeIntervalSince1970 {
                    mostRecentUpdate = model.updatedAt
                }
            }

            // Evict
            var (idsEvicted, evictedWithInbox) = evictMessages(context: context)

            do {
                try context.save()
            } catch {
                print("Failed to persist messages: \(error)")
                return
            }

            // exceeders evicted after saving because fetchOffset is ignored when have unsaved changes
            // https://stackoverflow.com/questions/10725252/possible-issue-with-fetchlimit-and-fetchoffset-in-a-core-data-query
            let (exceederIdsEvicted, evictedExceedersWithInbox) = evictMessagesExceedingLimit(context: context)
            if exceederIdsEvicted.count > 0 {
                idsEvicted += exceederIdsEvicted

                do {
                    try context.save()
                } catch {
                    print("Failed to evict exceeding messages: \(error)")
                    return
                }
            }

            for idEvicted in idsEvicted {
                removeNotificationTickle(id: idEvicted)
            }

            storage.set(value: mostRecentUpdate, key: .inAppMostRecentUpdateAt)

            trackMessageDelivery(messages: messages)

            let inboxUpdated = fetchedWithInbox || evictedWithInbox || evictedExceedersWithInbox
            OptimoveInApp.maybeRunInboxUpdatedHandler(inboxNeedsUpdate: inboxUpdated)
        }
    }

    private func removeNotificationTickle(id: Int64) {
        if pendingTickleIds.contains(id) {
            pendingTickleIds.remove(id)
        }

        if #available(iOS 10, *) {
            let tickleNotificationId = "k-in-app-message:\(id)"
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [tickleNotificationId])
            pendingNoticationHelper.remove(identifier: tickleNotificationId)
        }
    }

    private func evictMessages(context: NSManagedObjectContext) -> ([Int64], Bool) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
        fetchRequest.includesPendingChanges = true

        let messageExpiredCondition = "(expiresAt != nil AND expiresAt <= %@)"

        let noInboxAndMessageDismissed = "(inboxConfig = nil AND dismissedAt != nil)"
        let noInboxAndMessageExpired = "(inboxConfig = nil AND " + messageExpiredCondition + ")"
        let inboxExpiredAndMessageDismissedOrExpired = "(inboxTo != nil AND inboxTo < %@ AND (dismissedAt != nil OR " + messageExpiredCondition + "))"

        let predicate: NSPredicate? =
            NSPredicate(format: noInboxAndMessageDismissed + " OR " + noInboxAndMessageExpired + " OR " + inboxExpiredAndMessageDismissedOrExpired, NSDate(), NSDate(), NSDate())
        fetchRequest.predicate = predicate

        var toEvict: [InAppMessageEntity]
        do {
            toEvict = try context.fetch(fetchRequest) as! [InAppMessageEntity]
        } catch {
            print("Failed to evict messages: \(error)")
            return ([], false)
        }

        var idsEvicted: [Int64] = []
        var evictedInbox = false
        for messageToEvict in toEvict {
            idsEvicted.append(messageToEvict.id)
            if messageToEvict.inboxConfig != nil {
                evictedInbox = true
            }
            context.delete(messageToEvict)
        }

        return (idsEvicted, evictedInbox)
    }

    private func evictMessagesExceedingLimit(context: NSManagedObjectContext) -> ([Int64], Bool) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "sentAt", ascending: false),
            NSSortDescriptor(key: "updatedAt", ascending: false),
            NSSortDescriptor(key: "id", ascending: false),
        ]
        fetchRequest.fetchOffset = STORED_IN_APP_LIMIT

        var toEvict: [InAppMessageEntity]
        do {
            toEvict = try context.fetch(fetchRequest) as! [InAppMessageEntity]
        } catch {
            print("Failed to evict exceeding messages: \(error)")
            return ([], false)
        }

        var idsEvicted: [Int64] = []
        var evictedInbox = false
        for messageToEvict in toEvict {
            idsEvicted.append(messageToEvict.id)
            if messageToEvict.inboxConfig != nil {
                evictedInbox = true
            }
            context.delete(messageToEvict)
        }

        return (idsEvicted, evictedInbox)
    }

    private func getMessagesToPresent(_ presentedWhenOptions: [String]) -> [InAppMessage] {
        var messages: [InAppMessage] = []
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in getMessagesToPresent")
            return messages
        }

        context.performAndWait {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: context)

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.entity = entity
            fetchRequest.includesPendingChanges = false
            fetchRequest.returnsObjectsAsFaults = false

            let predicate = NSPredicate(format: "((presentedWhen IN %@) OR (id IN %@)) AND (dismissedAt = nil) AND (expiresAt = nil OR expiresAt > %@)", presentedWhenOptions, self.pendingTickleIds, NSDate())
            fetchRequest.predicate = predicate

            fetchRequest.sortDescriptors = [
                NSSortDescriptor(key: "sentAt", ascending: true),
                NSSortDescriptor(key: "updatedAt", ascending: true),
                NSSortDescriptor(key: "id", ascending: true),
            ]

            var entities: [Any] = []
            do {
                entities = try context.fetch(fetchRequest)
            } catch {
                print("Failed to fetch: \(error)")
                return
            }

            if entities.isEmpty {
                return
            }

            messages = self.mapEntitiesToModels(entities: entities as! [InAppMessageEntity])
        }

        return messages
    }

    func handleMessageOpened(message: InAppMessage) {
        var markedRead = false
        if message.readAt == nil {
            markedRead = markInboxItemRead(withId: message.id, shouldWait: false)
        }

        if message.inboxConfig != nil {
            OptimoveInApp.maybeRunInboxUpdatedHandler(inboxNeedsUpdate: markedRead)
        }

        let props: [String: Any] = ["type": MESSAGE_TYPE_IN_APP, "id": message.id]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_OPENED, properties: props)
    }

    func markMessageDismissed(message: InAppMessage) {
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in markMessageDismissed")
            return
        }

        let props: [String: Any] = ["type": MESSAGE_TYPE_IN_APP, "id": message.id]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DISMISSED, properties: props)

        if pendingTickleIds.contains(message.id) {
            pendingTickleIds.remove(message.id)
        }

        context.performAndWait {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: context)

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.entity = entity
            fetchRequest.includesPendingChanges = false
            fetchRequest.predicate = NSPredicate(format: "id = %i", message.id)

            var messageEntities: [InAppMessageEntity]
            do {
                messageEntities = try context.fetch(fetchRequest) as! [InAppMessageEntity]
            } catch {
                print("Failed to evict messages: \(error)")
                return
            }

            if messageEntities.count == 1 {
                messageEntities[0].dismissedAt = NSDate()
                if messageEntities[0].readAt == nil {
                    messageEntities[0].readAt = NSDate()
                }
            }

            do {
                try context.save()
            } catch {
                print("Failed to update message: \(error)")
                return
            }
        }
    }

    private func trackMessageDelivery(messages: [[AnyHashable: Any]]) {
        for message in messages {
            let props: [String: Any] = ["type": MESSAGE_TYPE_IN_APP, "id": message["id"] as! Int]
            Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DELIVERED, properties: props)
        }
    }

    // MARK: Interop with other components

    func presentImmediateAndNextOpenContent() {
        objc_sync_enter(pendingTickleIds)
        defer { objc_sync_exit(self.pendingTickleIds) }

        let messagesToPresent = getMessagesToPresent([InAppPresented.IMMEDIATELY.rawValue, InAppPresented.NEXT_OPEN.rawValue])
        presenter.queueMessagesForPresentation(messages: messagesToPresent, tickleIds: pendingTickleIds)
    }

    func presentMessage(withId: Int64) -> Bool {
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in presentMessage")
            return false
        }

        var result = true

        context.performAndWait {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")

            fetchRequest.includesPendingChanges = false
            fetchRequest.returnsObjectsAsFaults = false
            fetchRequest.predicate = NSPredicate(format: "id = %i", withId)

            var items: [InAppMessageEntity]
            do {
                items = try context.fetch(fetchRequest) as! [InAppMessageEntity]
            } catch {
                result = false
                print("Failed to evict messages: \(error)")
                return
            }

            if items.count != 1 {
                result = false
                return
            }

            let message = InAppMessage(entity: items[0])
            let tickles = NSOrderedSet(array: [withId])
            presenter.queueMessagesForPresentation(messages: [message], tickleIds: tickles)
        }

        return result
    }

    func handlePushOpen(notification: PushNotification) {
        guard let deepLink = notification.deeplink, !inAppEnabled() else {
            return
        }

        DispatchQueue.global(qos: .default).async {
            objc_sync_enter(self.pendingTickleIds)
            defer { objc_sync_exit(self.pendingTickleIds) }

            self.pendingTickleIds.add(deepLink.id)

            let messagesToPresent = self.getMessagesToPresent([])

            let tickleMessageFound = messagesToPresent.contains(where: { message -> Bool in
                message.id == deepLink.id
            })

            if !tickleMessageFound {
                self.sync()
                return
            }

            self.presenter.queueMessagesForPresentation(messages: messagesToPresent, tickleIds: self.pendingTickleIds)
        }
    }

    func deleteMessageFromInbox(withId: Int64) -> Bool {
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in deleteMessageFromInbox")
            return false
        }

        let props: [String: Any] = ["type": MESSAGE_TYPE_IN_APP, "id": withId]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_DELETED_FROM_INBOX, properties: props)

        removeNotificationTickle(id: withId)

        var result = true
        context.performAndWait {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: context)

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.entity = entity
            fetchRequest.includesPendingChanges = false
            fetchRequest.predicate = NSPredicate(format: "id = %i", withId)

            var messageEntities: [InAppMessageEntity]
            do {
                messageEntities = try context.fetch(fetchRequest) as! [InAppMessageEntity]
            } catch {
                result = false
                print("Failed to delete message with id: \(withId) \(error)")
                return
            }

            // setting inbox columns to nil and dismissedAt to now turns this message into a message to be evicted
            if messageEntities.count == 1 {
                messageEntities[0].inboxTo = nil
                messageEntities[0].inboxFrom = nil
                messageEntities[0].inboxConfig = nil
                messageEntities[0].dismissedAt = NSDate()
                if messageEntities[0].readAt == nil {
                    messageEntities[0].readAt = NSDate()
                }
            }

            do {
                try context.save()
            } catch {
                result = false
                print("Failed to delete message with id: \(withId) \(error)")
                return
            }
        }

        OptimoveInApp.maybeRunInboxUpdatedHandler(inboxNeedsUpdate: result)

        return result
    }

    func markInboxItemRead(withId: Int64, shouldWait: Bool) -> Bool {
        guard let context = messagesContext else {
            NSLog("InAppManager: NSManagedObjectContext is nil in markInboxItemRead")
            return false
        }

        var result = true
        let block = {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: context)

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.entity = entity
            fetchRequest.includesPendingChanges = false
            fetchRequest.includesPropertyValues = false
            fetchRequest.predicate = NSPredicate(format: "id = %i AND readAt = nil", withId)

            var messageEntities: [InAppMessageEntity]
            do {
                messageEntities = try context.fetch(fetchRequest) as! [InAppMessageEntity]
            } catch {
                result = false
                print("Failed to mark as read message with id: \(withId) \(error)")
                return
            }

            if messageEntities.count == 0 {
                result = false
                return
            }

            if messageEntities.count == 1 {
                messageEntities[0].readAt = NSDate()
            }

            do {
                try context.save()
            } catch {
                result = false
                print("Failed to mark as read message with id: \(withId) \(error)")
                return
            }
        }
        shouldWait ? context.performAndWait(block) : context.perform(block)

        if !result {
            return result
        }

        let props: [String: Any] = ["type": MESSAGE_TYPE_IN_APP, "id": withId]
        Optimobile.trackEvent(eventType: OptimobileEvent.MESSAGE_READ, properties: props)

        removeNotificationTickle(id: withId)

        return result
    }

    func markAllInboxItemsAsRead() -> Bool {
        var result = true
        let inboxItems = OptimoveInApp.getInboxItems(storage: storage)
        var inboxNeedsUpdate = false
        for item in inboxItems {
            if item.isRead() {
                continue
            }

            let success = markInboxItemRead(withId: item.id, shouldWait: true)
            if success, !inboxNeedsUpdate {
                inboxNeedsUpdate = true
            }

            if !success {
                result = false
            }
        }

        OptimoveInApp.maybeRunInboxUpdatedHandler(inboxNeedsUpdate: inboxNeedsUpdate)

        return result
    }

    func readInboxSummary(inboxSummaryBlock: @escaping InboxSummaryBlock) {
        guard let context = Optimobile.sharedInstance.inAppManager.messagesContext else {
            fireInboxSummaryCallback(callback: inboxSummaryBlock, summary: nil)
            return
        }

        context.perform {
            let request = NSFetchRequest<InAppMessageEntity>(entityName: "Message")
            request.includesPendingChanges = false
            request.predicate = NSPredicate(format: "(inboxConfig != nil)")
            request.propertiesToFetch = ["inboxFrom", "inboxTo", "readAt"]

            var items: [InAppMessageEntity] = []
            do {
                items = try context.fetch(request) as [InAppMessageEntity]
            } catch {
                print("Failed to fetch items: \(error)")

                self.fireInboxSummaryCallback(callback: inboxSummaryBlock, summary: nil)
                return
            }

            var totalCount: Int64 = 0
            var unreadCount: Int64 = 0
            for item in items {
                if !item.isAvailable() {
                    continue
                }

                totalCount += 1
                if item.readAt == nil {
                    unreadCount += 1
                }
            }

            self.fireInboxSummaryCallback(callback: inboxSummaryBlock, summary: InAppInboxSummary(totalCount: totalCount, unreadCount: unreadCount))
        }
    }

    private func fireInboxSummaryCallback(callback: @escaping InboxSummaryBlock, summary: InAppInboxSummary?) {
        DispatchQueue.main.async {
            callback(summary)
        }
    }

    // MARK: Data model

    private func mapEntitiesToModels(entities: [InAppMessageEntity]) -> [InAppMessage] {
        var models: [InAppMessage] = []
        models.reserveCapacity(entities.count)

        for entity in entities {
            let model = InAppMessage(entity: entity)
            models.append(model)
        }

        return models
    }

    private func getDataModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let messageEntity = NSEntityDescription()
        messageEntity.name = "Message"
        messageEntity.managedObjectClassName = NSStringFromClass(InAppMessageEntity.self)

        var messageProps: [NSAttributeDescription] = []
        messageProps.reserveCapacity(13)

        let partId = NSAttributeDescription()
        partId.name = "id"
        partId.attributeType = NSAttributeType.integer64AttributeType
        partId.isOptional = false
        messageProps.append(partId)

        let updatedAt = NSAttributeDescription()
        updatedAt.name = "updatedAt"
        updatedAt.attributeType = NSAttributeType.dateAttributeType
        updatedAt.isOptional = false
        messageProps.append(updatedAt)

        let presentedWhen = NSAttributeDescription()
        presentedWhen.name = "presentedWhen"
        presentedWhen.attributeType = NSAttributeType.stringAttributeType
        presentedWhen.isOptional = false
        messageProps.append(presentedWhen)

        let content = NSAttributeDescription()
        content.name = "content"
        content.attributeType = NSAttributeType.transformableAttributeType
        content.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.self)
        content.isOptional = false
        messageProps.append(content)

        let data = NSAttributeDescription()
        data.name = "data"
        data.attributeType = NSAttributeType.transformableAttributeType
        data.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.self)
        data.isOptional = true
        messageProps.append(data)

        let badgeConfig = NSAttributeDescription()
        badgeConfig.name = "badgeConfig"
        badgeConfig.attributeType = NSAttributeType.transformableAttributeType
        badgeConfig.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.self)
        badgeConfig.isOptional = true
        messageProps.append(badgeConfig)

        let inboxConfig = NSAttributeDescription()
        inboxConfig.name = "inboxConfig"
        inboxConfig.attributeType = NSAttributeType.transformableAttributeType
        inboxConfig.valueTransformerName = NSStringFromClass(KSJsonValueTransformer.self)
        inboxConfig.isOptional = true
        messageProps.append(inboxConfig)

        let inboxFrom = NSAttributeDescription()
        inboxFrom.name = "inboxFrom"
        inboxFrom.attributeType = NSAttributeType.dateAttributeType
        inboxFrom.isOptional = true
        messageProps.append(inboxFrom)

        let inboxTo = NSAttributeDescription()
        inboxTo.name = "inboxTo"
        inboxTo.attributeType = NSAttributeType.dateAttributeType
        inboxTo.isOptional = true
        messageProps.append(inboxTo)

        let dismissedAt = NSAttributeDescription()
        dismissedAt.name = "dismissedAt"
        dismissedAt.attributeType = NSAttributeType.dateAttributeType
        dismissedAt.isOptional = true
        messageProps.append(dismissedAt)

        let expiresAt = NSAttributeDescription()
        expiresAt.name = "expiresAt"
        expiresAt.attributeType = NSAttributeType.dateAttributeType
        expiresAt.isOptional = true
        messageProps.append(expiresAt)

        let readAt = NSAttributeDescription()
        readAt.name = "readAt"
        readAt.attributeType = NSAttributeType.dateAttributeType
        readAt.isOptional = true
        messageProps.append(readAt)

        let sentAt = NSAttributeDescription()
        sentAt.name = "sentAt"
        sentAt.attributeType = NSAttributeType.dateAttributeType
        sentAt.isOptional = true
        messageProps.append(sentAt)

        messageEntity.properties = messageProps

        model.entities = [messageEntity]

        return model
    }

    @objc
    class KSJsonValueTransformer: ValueTransformer {
        override class func transformedValueClass() -> AnyClass {
            return NSDictionary.self
        }

        override class func allowsReverseTransformation() -> Bool {
            return true
        }

        override func transformedValue(_ value: Any?) -> Any? {
            if value == nil || value is NSNull {
                return nil
            }

            if let value = value {
                if !JSONSerialization.isValidJSONObject(value) {
                    print("Object cannot be transformed to JSON data object!")
                    return nil
                }
            }

            var data: Data?
            do {
                if let value = value {
                    data = try JSONSerialization.data(withJSONObject: value, options: [])
                }
            } catch {
                print("Failed to transform JSON to data object")
            }

            return data
        }

        override func reverseTransformedValue(_ value: Any?) -> Any? {
            var obj: Any?
            do {
                if let value = value as? Data {
                    obj = try JSONSerialization.jsonObject(with: value, options: [])
                }
            } catch {
                print("Failed to transform data to JSON object")
            }

            return obj
        }
    }
}
