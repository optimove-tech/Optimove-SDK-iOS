//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore

typealias SyncCompletedBlock = (Error?) -> Void

final class AnalyticsHelper {
    let eventsHttpClient: KSHttpClient
    let optimobileHelper: OptimobileHelper
    let container: PersistentContainer
    let context: NSManagedObjectContext
    var finishedInitializationToken: NSObjectProtocol?

    init(
        httpClient: KSHttpClient,
        optimobileHelper: OptimobileHelper,
        container: PersistentContainer
    ) throws {
        self.container = container
        try container.loadPersistentStores(
            storeName: "KAnalyticsDbShared"
        )
        context = container.newBackgroundContext()
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)

        eventsHttpClient = httpClient
        self.optimobileHelper = optimobileHelper

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
        syncEvents()
    }

    // MARK: Event Tracking

    func trackEvent(eventType: String, properties: [String: Any]?, immediateFlush: Bool) {
        trackEvent(
            eventType: eventType,
            atTime: Date(),
            properties: properties,
            immediateFlush: immediateFlush
        )
    }

    func trackEvent(eventType: String, atTime: Date, properties: [String: Any]?, immediateFlush: Bool, onSyncComplete: SyncCompletedBlock? = nil) {
        if eventType == "" || (properties != nil && !JSONSerialization.isValidJSONObject(properties as Any)) {
            Logger.error("Ignoring invalid event with empty type or non-serializable properties")
            return
        }
        Task {
            let currentUserIdentifier = optimobileHelper.currentUserIdentifier()
            do {
                try await context.safeTryPerform { context in
                    try KSEventModel.insert(
                        into: context,
                        atTime: atTime,
                        eventType: eventType,
                        userIdentifier: currentUserIdentifier
                    )
                    try context.save()
                }

                if immediateFlush {
                    syncEvents(onSyncComplete)
                }
            } catch {
                Logger.error("Error saving event: \(error.localizedDescription)")
            }
        }
    }

    private func syncEvents(_ onSyncComplete: SyncCompletedBlock? = nil) {
        context.performAndWait {
            // FIXME: Remove unnecessary performAndWait
            let results = (try? fetchEventsBatch()) ?? []

            if results.count == 0 {
                onSyncComplete?(nil)
            } else if results.count > 0 {
                syncEventsBatch(events: results, onSyncComplete)
                return
            }
        }
    }

    private func syncEventsBatch(
        events: [KSEventModel],
        _ onSyncComplete: SyncCompletedBlock? = nil
    ) {
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

        let path = "/v1/app-installs/\(optimobileHelper.installId())/events"

        eventsHttpClient.sendRequest(.POST, toPath: path, data: data, onSuccess: { _, _ in
            if let err = self.pruneEventsBatch(eventIds) {
                print("Failed to prune events batch: " + err.localizedDescription)
                onSyncComplete?(err)
                return
            }
            self.syncEvents(onSyncComplete)
        }) { _, error, _ in
            print("Failed to send events")
            onSyncComplete?(error)
        }
    }

    private func pruneEventsBatch(_ eventIds: [NSManagedObjectID]) -> Error? {
        var err: Error?

        context.performAndWait {
            let request = NSBatchDeleteRequest(objectIDs: eventIds)

            do {
                try context.execute(request)
            } catch {
                err = error
            }
        }

        return err
    }

    private func fetchEventsBatch() throws -> [KSEventModel] {
        return try context.safeTryPerformAndWait { _ in
            try KSEventModel.fetch(in: context) { request in
                request.fetchLimit = 100
                request.sortDescriptors = KSEventModel.defaultSortDescriptors
                request.returnsObjectsAsFaults = false
                request.includesPendingChanges = false
            }
        }
    }
}
