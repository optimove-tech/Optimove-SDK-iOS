//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import os.log
import OptimoveCore

@objc public class OptimoveNotificationServiceExtension: NSObject {

    @objc public private(set) var isHandledByOptimove: Bool = false

    private let bundleIdentifier: String
    private let operationQueue: OperationQueue

    private var bestAttemptContent: UNMutableNotificationContent?
    private var contentHandler: ((UNNotificationContent) -> Void)?

    @available(*, deprecated, message: "For automatically fetching the bundle identifier, please use convenience init()")
    @objc public convenience init(appBundleId: String) {
        self.init(bundleIdentifier: appBundleId)
    }

    /// The convenience init will fetch the bundle identifier automatically.
    @objc public convenience override init() {
        guard let bundleIdentifier = Bundle.hostAppBundle()?.bundleIdentifier else {
            fatalError("Unable to find a bundle identifier.")
        }
        self.init(bundleIdentifier: bundleIdentifier)
    }

    private init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier

        operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
    }

    /// The method verified that a request belong to Optimove channel. The Oprimove request might be modified.
    ///
    /// - Parameters:
    ///   - request: The original notification request.
    ///   - contentHandler: A UNNotificationContent object with the content to be displayed to the user.
    /// - Returns: Returns `true` if the message was consumed by Optimove, otherwise this request is not  from Optimove.
    @objc public func didReceive(_ request: UNNotificationRequest,
                                 withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) -> Bool {
        do {
            let payload: NotificationPayload
            payload = try extractNotificationPayload(request)
            isHandledByOptimove = true
            let bestAttemptContent = try unwrap(createBestAttemptBaseContent(request: request, payload: payload))
            self.bestAttemptContent = bestAttemptContent
            self.contentHandler = contentHandler
            let storage = StorageFacade(
                groupedStorage: try UserDefaults.grouped(tenantBundleIdentifier: bundleIdentifier),
                sharedStorage: try UserDefaults.shared(tenantBundleIdentifier: bundleIdentifier),
                fileStorage: try FileStorageImpl(bundleIdentifier: bundleIdentifier, fileManager: .default)
            )
            try handleNotification(
                payload: payload,
                optitrack: OptitrackNSEImpl(
                    storage: storage,
                    repository: ConfigurationRepositoryImpl(
                        storage: storage
                    )
                ),
                bestAttemptContent: bestAttemptContent,
                contentHandler: contentHandler
            )
        } catch {
            os_log(
                "Unable to cast to Optimove notification. %{PUBLIC}@",
                log: OSLog.notification, type: .error, error.localizedDescription
            )
            contentHandler(request.content)
            return false
        }
        return true
    }

    /// The method called by system in case if `didReceive(_:withContentHandler:)` takes to long to execute or
    /// out of memory.
    @objc public func serviceExtensionTimeWillExpire() {
        if let bestAttemptContent = bestAttemptContent {
            contentHandler?(bestAttemptContent)
        }
    }
}

extension OptimoveNotificationServiceExtension {

    func extractNotificationPayload(_ request: UNNotificationRequest) throws -> NotificationPayload {
        let userInfo = request.content.userInfo
        let data = try JSONSerialization.data(withJSONObject: userInfo)
        let decoder = JSONDecoder()
        return try decoder.decode(NotificationPayload.self, from: data)
    }

    func createBestAttemptBaseContent(request: UNNotificationRequest,
                                      payload: NotificationPayload) -> UNMutableNotificationContent? {
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            os_log("Unable to copy content.", log: OSLog.notification, type: .fault)
            return nil
        }
        if let title = payload.title {
            bestAttemptContent.title = title
        }
        bestAttemptContent.body = payload.content
        return bestAttemptContent
    }

    func handleNotification(
        payload: NotificationPayload,
        optitrack: OptitrackNSE,
        bestAttemptContent: UNMutableNotificationContent,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) throws {
        let operationsToExecute: [Operation] = [
            DeeplinkExtracter(
                bundleIdentifier: bundleIdentifier,
                notificationPayload: payload,
                bestAttemptContent: bestAttemptContent
            ),
            NotificationDeliveryReporter(
                bundleIdentifier: bundleIdentifier,
                notificationPayload: payload,
                optitrack: optitrack
            ),
            MediaAttachmentDownloader(
                notificationPayload: payload,
                bestAttemptContent: try unwrap(bestAttemptContent)
            )
        ]
        // The completion operation going to be executed right after all operations are finished.
        let completionOperation = BlockOperation {
            bestAttemptContent.userInfo[NotificationKey.wasHandledByOptimoveNSE] = true
            contentHandler(bestAttemptContent)
            os_log("Operations were completed", log: OSLog.notification, type: .info)
        }
        os_log("Operations were scheduled", log: OSLog.notification, type: .info)
        operationsToExecute.forEach {
            // Set the completion operation as dependent for all operations before they start executing.
            completionOperation.addDependency($0)
            operationQueue.addOperation($0)
        }
        // The completion operation is performing on the main queue.
        OperationQueue.main.addOperation(completionOperation)
    }
}

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier!
    static let notification = OSLog(subsystem: subsystem, category: "notification")
}
