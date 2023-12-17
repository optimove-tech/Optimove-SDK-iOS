//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation
import GenericJSON
import OptimoveCore
import UIKit

public enum InAppMessagePresentationResult: String {
    case PRESENTED = "presented"
    case EXPIRED = "expired"
    case FAILED = "failed"
    case PAUSED = "paused"
}

enum InAppPresented: String {
    case IMMEDIATELY = "immediately"
    case NEXT_OPEN = "next-open"
    case NEVER = "never"
}

typealias kumulos_applicationPerformFetchWithCompletionHandler = @convention(c) (_ obj: Any, _ _cmd: Selector, _ application: UIApplication, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
typealias fetchBlock = @convention(block) (_ obj: Any, _ application: UIApplication, _ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Void
private var ks_existingBackgroundFetchDelegate: IMP?

typealias InAppSyncCompletionHandler = (_ result: Int) -> Void

final class InAppManager {
    let context: NSManagedObjectContext
    let httpClient: KSHttpClient
    let storage: OptimoveStorage
    let pendingNoticationHelper: PendingNotificationHelper
    let optimobileHelper: OptimobileHelper
    private(set) var presenter: InAppPresenter
    private var pendingTickleIds = NSMutableOrderedSet(capacity: 1)

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
        optimobileHelper: OptimobileHelper,
        container: PersistentContainer
    ) throws {
        try container.loadPersistentStores(
            storeName: "KSMessagesDb"
        )
        context = container.newBackgroundContext()
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
        return UserDefaults.standard.bool(forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue)
    }

    func updateUserConsent(consentGiven: Bool) {
        Optimobile.trackEventImmediately(
            eventType: OptimobileEvent.IN_APP_CONSENT_CHANGED.rawValue,
            properties: ["consented": consentGiven]
        )

        if consentGiven {
            UserDefaults.standard.set(consentGiven, forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue)
            handleEnrollmentAndSyncSetup()
        } else {
            DispatchQueue.global(qos: .default).async {
                try? self.resetMessagingState()
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
            try? self.resetMessagingState()
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

    private func resetMessagingState() throws {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        UserDefaults.standard.removeObject(forKey: OptimobileUserDefaultsKey.IN_APP_CONSENTED.rawValue)
        UserDefaults.standard.removeObject(forKey: OptimobileUserDefaultsKey.IN_APP_LAST_SYNCED_AT.rawValue)
        UserDefaults.standard.removeObject(forKey: OptimobileUserDefaultsKey.IN_APP_MOST_RECENT_UPDATED_AT.rawValue)

        try context.safeTryPerformAndWait { _ in
            try InAppMessageEntity.delete(in: context) { request in
                request.returnsObjectsAsFaults = false
                request.includesPendingChanges = false
            }
        }
    }

    // MARK: Message management

    func syncDebounced(_ onComplete: InAppSyncCompletionHandler? = nil) {
        syncQueue.async {
            let lastSyncedAt = UserDefaults.standard.object(forKey: OptimobileUserDefaultsKey.IN_APP_LAST_SYNCED_AT.rawValue) as? Date ?? Date(timeIntervalSince1970: 0)

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

            let mostRecentUpdate = UserDefaults.standard.object(forKey: OptimobileUserDefaultsKey.IN_APP_MOST_RECENT_UPDATED_AT.rawValue) as? NSDate
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
                    UserDefaults.standard.set(Date(), forKey: OptimobileUserDefaultsKey.IN_APP_LAST_SYNCED_AT.rawValue)
                    syncBarrier.signal()
                }
                do {
                    guard let decodedBody = decodedBody else {
                        onComplete?(0)
                        return
                    }
                    let messagesToPersist = try JSON(decodedBody)
                    if messagesToPersist == nil || messagesToPersist.count == 0 {
                        onComplete?(0)
                        return
                    }

                    self.persistInAppMessages(messages: messagesToPersist)
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
                } catch {
                    Logger.error(error.localizedDescription)
                    onComplete?(-1)
                    syncBarrier.signal()
                }
            }, onFailure: { _, _, _ in
                onComplete?(-1)
                syncBarrier.signal()
            })

            syncBarrier.wait()
        }
    }

    private func persistInAppMessages(messages: JSON) {
        context.performAndWait {
            do {
                // TODO: Use InAppMessageEntity
                guard let entity = NSEntityDescription.entity(forEntityName: "Message", in: context) else {
                    print("Failed to get entity description for Message, aborting!")
                    return
                }

                var mostRecentUpdate = Date(timeIntervalSince1970: 0)
                let dateParser = DateFormatter()
                dateParser.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
                dateParser.locale = Locale(identifier: "en_US_POSIX")
                dateParser.timeZone = TimeZone(secondsFromGMT: 0)

                for message in try unwrap(messages.arrayValue) {
                    guard let partId = message.id?.doubleValue,
                          let updatedAtString = message.updatedAt?.stringValue,
                          let presentedWhenString = message.presentedWhen?.stringValue
                    else {
                        continue
                    }

                    let fetchRequest: NSFetchRequest<InAppMessageEntity> = NSFetchRequest(entityName: "Message")
                    fetchRequest.entity = entity
                    fetchRequest.predicate = NSPredicate(format: "id = %lld", partId)

                    let fetchedObjects: [InAppMessageEntity]
                    do {
                        fetchedObjects = try context.fetch(fetchRequest)
                    } catch {
                        continue
                    }

                    // Upsert
                    let model: InAppMessageEntity = fetchedObjects.count == 1 ? fetchedObjects[0] : InAppMessageEntity(entity: entity, insertInto: context)

                    model.id = Int64(partId)
                    model.updatedAt = dateParser.date(from: updatedAtString)!
                    model.dismissedAt = dateParser.date(from: message["openedAt"]?.stringValue ?? "")
                    model.presentedWhen = presentedWhenString

                    if model.readAt == nil {
                        model.readAt = dateParser.date(from: message["readAt"]?.stringValue ?? "")
                    }

                    if model.sentAt == nil {
                        model.sentAt = dateParser.date(from: message["sentAt"]?.stringValue ?? "")
                    }

                    model.content = ObjcJSON(json: message["content"] ?? .null)
                    model.data = ObjcJSON(json: message["data"] ?? .null)
                    model.badgeConfig = ObjcJSON(json: message["badge"] ?? .null)
                    model.inboxConfig = ObjcJSON(json: message["inbox"] ?? .null)

                    if let inbox = model.inboxConfig?.toGenericJSON() {
                        model.inboxFrom = dateParser.date(from: inbox["from"]?.stringValue ?? "")
                        model.inboxTo = dateParser.date(from: inbox["to"]?.stringValue ?? "")
                    }

                    if let inboxDeletedAt = message["inboxDeletedAt"]?.stringValue {
                        model.inboxConfig = nil
                        model.inboxFrom = nil
                        model.inboxTo = nil
                        if model.dismissedAt == nil {
                            model.dismissedAt = dateParser.date(from: inboxDeletedAt)
                        }
                    }

                    model.expiresAt = dateParser.date(from: message["expiresAt"]?.stringValue ?? "")

                    if model.updatedAt.timeIntervalSince1970 > mostRecentUpdate.timeIntervalSince1970 {
                        mostRecentUpdate = model.updatedAt
                    }
                }

                // The rest of your method's code would go here...

                // Example of how you would update UserDefaults with the `mostRecentUpdate` Date:
                UserDefaults.standard.set(mostRecentUpdate, forKey: OptimobileUserDefaultsKey.IN_APP_MOST_RECENT_UPDATED_AT.rawValue)
            } catch {
                Logger.error(error.localizedDescription)
            }
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
        context.performAndWait {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: context)

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.entity = entity
            fetchRequest.includesPendingChanges = false
            fetchRequest.returnsObjectsAsFaults = false

            let predicate = NSPredicate(format: "((presentedWhen IN %@) OR (id IN %@)) AND (dismissedAt = nil) AND (expiresAt = nil OR expiresAt > %@)", presentedWhenOptions, self.pendingTickleIds, Date() as CVarArg)
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
                messageEntities[0].dismissedAt = Date()
                if messageEntities[0].readAt == nil {
                    messageEntities[0].readAt = Date()
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
                messageEntities[0].dismissedAt = Date()
                if messageEntities[0].readAt == nil {
                    messageEntities[0].readAt = Date()
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
        var result = true
        let block = {
            let entity: NSEntityDescription? = NSEntityDescription.entity(forEntityName: "Message", in: self.context)

            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Message")
            fetchRequest.entity = entity
            fetchRequest.includesPendingChanges = false
            fetchRequest.includesPropertyValues = false
            fetchRequest.predicate = NSPredicate(format: "id = %i AND readAt = nil", withId)

            var messageEntities: [InAppMessageEntity]
            do {
                messageEntities = try self.context.fetch(fetchRequest) as! [InAppMessageEntity]
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
                messageEntities[0].readAt = Date()
            }

            do {
                try self.context.save()
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
        let inboxItems = OptimoveInApp.getInboxItems(storage: storage, context: context)
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
        context.perform {
            let request = NSFetchRequest<InAppMessageEntity>(entityName: "Message")
            request.includesPendingChanges = false
            request.predicate = NSPredicate(format: "(inboxConfig != nil)")
            request.propertiesToFetch = ["inboxFrom", "inboxTo", "readAt"]

            var items: [InAppMessageEntity] = []
            do {
                items = try self.context.fetch(request) as [InAppMessageEntity]
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
}
