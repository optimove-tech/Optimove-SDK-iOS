//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation

class KSEventModel: NSManagedObject {
    @NSManaged var uuid: String
    @NSManaged var userIdentifier: String
    @NSManaged var happenedAt: NSNumber
    @NSManaged var eventType: String
    @NSManaged var properties: Data?
}

typealias SyncCompletedBlock = (Error?) -> Void

final class AnalyticsHelper {
    let eventsHttpClient: KSHttpClient
    private var analyticsContext: NSManagedObjectContext?
    private var migrationAnalyticsContext: NSManagedObjectContext?
    private var finishedInitializationToken: NSObjectProtocol?
    private let serialQueue : DispatchQueue

    // MARK: Initialization

    init(httpClient: KSHttpClient) {
        analyticsContext = nil
        migrationAnalyticsContext = nil
        serialQueue = DispatchQueue(label: "com.optimove.optimobile.serial-q", target: .global(qos: .utility))

        eventsHttpClient = httpClient

        initContext()

        finishedInitializationToken = NotificationCenter.default
            .addObserver(forName: .optimobileInializationFinished, object: nil, queue: nil) { [weak self] notification in
                DispatchQueue.global().async {
                    guard let self = self else { return }
                    self.flushEvents()
                }
                Logger.debug("Notification \(notification.name.rawValue) was processed")
            }
    }

    deinit {
        eventsHttpClient.invalidateSessionCancellingTasks(false)
    }

    func flushEvents() {
        if migrationAnalyticsContext != nil {
            syncEvents(context: migrationAnalyticsContext)
        }
        syncEvents(context: analyticsContext)
    }

    private func getMainStoreUrl(appGroupExists: Bool) -> URL? {
        if !appGroupExists {
            return getAppDbUrl()
        }

        return getSharedDbUrl()
    }

    private func getAppDbUrl() -> URL? {
        let docsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let appDbUrl = URL(string: "KAnalyticsDb.sqlite", relativeTo: docsUrl)

        return appDbUrl
    }

    private func getSharedDbUrl() -> URL? {
        let sharedContainerPath: URL? = AppGroupsHelper.getSharedContainerPath()
        if sharedContainerPath == nil {
            return nil
        }

        return URL(string: "KAnalyticsDbShared.sqlite", relativeTo: sharedContainerPath)
    }

    private func initContext() {
        let appDbUrl = getAppDbUrl()
        let appDbExists = appDbUrl == nil ? false : FileManager.default.fileExists(atPath: appDbUrl!.path)
        let appGroupExists = AppGroupsHelper.isKumulosAppGroupDefined()

        let storeUrl = getMainStoreUrl(appGroupExists: appGroupExists)

        if appGroupExists, appDbExists {
            migrationAnalyticsContext = getManagedObjectContext(storeUrl: appDbUrl)
        }

        analyticsContext = getManagedObjectContext(storeUrl: storeUrl)
    }

    private func getManagedObjectContext(storeUrl: URL?) -> NSManagedObjectContext? {
        let objectModel = getCoreDataModel()
        let storeCoordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        let opts = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]

        do {
            try storeCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeUrl, options: opts)
        } catch {
            print("Failed to set up persistent store: " + error.localizedDescription)
            return nil
        }

        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.performAndWait {
            context.persistentStoreCoordinator = storeCoordinator
        }

        return context
    }

    // MARK: Event Tracking

    func trackEvent(eventType: String, properties: [String: Any]?, immediateFlush: Bool) {
        trackEvent(eventType: eventType, atTime: Date(), properties: properties, immediateFlush: immediateFlush)
    }

    func trackEvent(eventType: String, atTime: Date, properties: [String: Any]?, immediateFlush: Bool, onSyncComplete: SyncCompletedBlock? = nil) {
        if eventType == "" || (properties != nil && !JSONSerialization.isValidJSONObject(properties as Any)) {
            print("Ignoring invalid event with empty type or non-serializable properties")
            return
        }

        let work = {
            guard let context = self.analyticsContext else {
                print("No context, aborting")
                return
            }

            guard let entity = NSEntityDescription.entity(forEntityName: "Event", in: context) else {
                print("Can't create entity, aborting")
                return
            }

            let event = KSEventModel(entity: entity, insertInto: nil)

            event.uuid = UUID().uuidString.lowercased()
            event.happenedAt = NSNumber(value: Int64(atTime.timeIntervalSince1970 * 1000))
            event.eventType = eventType
            event.userIdentifier = OptimobileHelper.currentUserIdentifier

            if properties != nil {
                let propsJson = try? JSONSerialization.data(withJSONObject: properties as Any, options: JSONSerialization.WritingOptions(rawValue: 0))

                event.properties = propsJson
            }

            context.insert(event)
            do {
                try context.save()

                if immediateFlush {
                    self.syncEvents(context: self.analyticsContext, onSyncComplete)
                }
            } catch {
                print("Failed to record event")
                print(error)
            }
        }

        analyticsContext?.perform(work)
    }

    private func syncEvents(context: NSManagedObjectContext?, _ onSyncComplete: SyncCompletedBlock? = nil) {
        self.serialQueue.async {
            self.syncEventsImpl(context: context, onSyncComplete)
        }
    }

    private func syncEventsImpl(context: NSManagedObjectContext?, _ onSyncComplete: SyncCompletedBlock? = nil) {
        context?.performAndWait {
            let results = fetchEventsBatch(context)

            if results.count == 0 {
                onSyncComplete?(nil)

                if context === migrationAnalyticsContext {
                    removeAppDatabase()
                }
            } else if results.count > 0 {
                syncEventsBatch(context, events: results, onSyncComplete)
                return
            }
        }
    }

    private func removeAppDatabase() {
        if migrationAnalyticsContext == nil {
            return
        }

        guard let persStoreCoord = migrationAnalyticsContext!.persistentStoreCoordinator else {
            return
        }

        guard let store = persStoreCoord.persistentStores.last else {
            return
        }

        let storeUrl = persStoreCoord.url(for: store)

        migrationAnalyticsContext!.performAndWait {
            migrationAnalyticsContext!.reset()
            do {
                try persStoreCoord.remove(store)
                try FileManager.default.removeItem(at: storeUrl)
            } catch {}
        }
        migrationAnalyticsContext = nil
    }

    private func syncEventsBatch(_ context: NSManagedObjectContext?, events: [KSEventModel], _ onSyncComplete: SyncCompletedBlock? = nil) {
        var data = [] as [[String: Any?]]
        var eventIds = [] as [NSManagedObjectID]

        for event in events {
            var jsonProps = nil as Any?
            if let props = event.properties {
                jsonProps = try? JSONSerialization.jsonObject(with: props, options: JSONSerialization.ReadingOptions(rawValue: 0))
            }

            data.append([
                "type": event.eventType,
                "uuid": event.uuid,
                "timestamp": event.happenedAt,
                "data": jsonProps,
                "userId": event.userIdentifier,
            ])
            eventIds.append(event.objectID)
        }

        let path = "/v1/app-installs/\(OptimobileHelper.installId)/events"

        var err : Error? = nil
        let networkBarrier = DispatchSemaphore(value: 0)

        eventsHttpClient.sendRequest(.POST, toPath: path, data: data, onSuccess: { _, _ in
            networkBarrier.signal()
        }) { _, error, _ in
            err = error
            print("Failed to send events \(err?.localizedDescription ?? "")")
            networkBarrier.signal()
        }

        networkBarrier.wait()

        if err != nil {
            onSyncComplete?(err)
            return
        }

        if let err = self.pruneEventsBatch(context, eventIds) {
            print("Failed to prune events batch: " + err.localizedDescription)
            onSyncComplete?(err)
            return
        }

        self.syncEventsImpl(context: context, onSyncComplete)
    }

    private func pruneEventsBatch(_ context: NSManagedObjectContext?, _ eventIds: [NSManagedObjectID]) -> Error? {
        var err: Error?

        context?.performAndWait {
            let request = NSBatchDeleteRequest(objectIDs: eventIds)

            do {
                try context?.execute(request)
            } catch {
                err = error
            }
        }

        return err
    }

    private func fetchEventsBatch(_ context: NSManagedObjectContext?) -> [KSEventModel] {
        guard let context = context else {
            return []
        }

        let request = NSFetchRequest<KSEventModel>(entityName: "Event")
        request.returnsObjectsAsFaults = false
        request.sortDescriptors = [NSSortDescriptor(key: "happenedAt", ascending: true)]
        request.fetchLimit = 100
        request.includesPendingChanges = false

        do {
            let results = try context.fetch(request)
            return results
        } catch {
            print("Failed to fetch events batch: " + error.localizedDescription)
            return []
        }
    }

    // MARK: CoreData model definition

    private func getCoreDataModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let eventEntity = NSEntityDescription()
        eventEntity.name = "Event"
        eventEntity.managedObjectClassName = NSStringFromClass(KSEventModel.self)

        var eventProps: [NSAttributeDescription] = []

        let eventTypeProp = NSAttributeDescription()
        eventTypeProp.name = "eventType"
        eventTypeProp.attributeType = .stringAttributeType
        eventTypeProp.isOptional = false
        eventProps.append(eventTypeProp)

        let happenedAtProp = NSAttributeDescription()
        happenedAtProp.name = "happenedAt"
        happenedAtProp.attributeType = .integer64AttributeType
        happenedAtProp.isOptional = false
        happenedAtProp.defaultValue = 0
        eventProps.append(happenedAtProp)

        let propertiesProp = NSAttributeDescription()
        propertiesProp.name = "properties"
        propertiesProp.attributeType = .binaryDataAttributeType
        propertiesProp.isOptional = true
        eventProps.append(propertiesProp)

        let uuidProp = NSAttributeDescription()
        uuidProp.name = "uuid"
        uuidProp.attributeType = .stringAttributeType
        uuidProp.isOptional = false
        eventProps.append(uuidProp)

        let userIdProp = NSAttributeDescription()
        userIdProp.name = "userIdentifier"
        userIdProp.attributeType = .stringAttributeType
        userIdProp.isOptional = true
        eventProps.append(userIdProp)

        eventEntity.properties = eventProps
        model.entities = [eventEntity]

        return model
    }
}
