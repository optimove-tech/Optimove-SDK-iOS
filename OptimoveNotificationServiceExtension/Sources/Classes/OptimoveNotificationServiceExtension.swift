//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import os.log
import OptimoveCore

@objc public class OptimoveNotificationServiceExtension: NSObject {

    @objc public private(set) var isHandledByOptimove: Bool = false

    let bundleIdentifier: String
    let operationQueue: OperationQueue
    let storage: OptimoveStorage
    let networking: OptistreamNetworking
    var bestAttemptContent: UNMutableNotificationContent?
    var contentHandler: ((UNNotificationContent) -> Void)?

    /// Initializer with a custom application bundle indentifier. Also, you can simply use the common init.
    /// In this case Optimove will fetch the bundle identifier automatically.
    /// - Parameter appBundleId: Bundle indentifier
    @objc public convenience init(appBundleId: String) {
        self.init(bundleIdentifier: appBundleId)
    }

    /// The convenience init will fetch the bundle identifier automatically.
    @objc public convenience override init() {
        do {
            let bundleIdentifier = try customUnwrap(
                Bundle.hostAppBundle()?.bundleIdentifier,
                CastError.customMessage(message: "Unable to find a bundle identifier.")
            )
            self.init(bundleIdentifier: bundleIdentifier)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    convenience init(bundleIdentifier: String) {
        do {
            let storage = StorageFacade(
                groupedStorage: try UserDefaults.grouped(
                    tenantBundleIdentifier: bundleIdentifier
                ),
                sharedStorage: try UserDefaults.shared(
                    tenantBundleIdentifier: bundleIdentifier
                ),
                fileStorage: try FileStorageImpl(
                    bundleIdentifier: bundleIdentifier,
                    fileManager: FileManager.default
                )
            )
            let networking = OptistreamNetworkingImpl(
                networkClient: NetworkClientImpl(),
                endpoint: try unwrap(storage.optitrackEndpoint)
            )
            self.init(bundleIdentifier: bundleIdentifier, storage: storage, networking: networking)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    required init(
        bundleIdentifier: String,
        storage: OptimoveStorage,
        networking: OptistreamNetworking
    ) {
        self.storage = storage
        self.networking = networking
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
    @objc public func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) -> Bool {
        do {
            let payload: NotificationPayload
            payload = try extractNotificationPayload(request)
            isHandledByOptimove = true
            let bestAttemptContent = try unwrap(createBestAttemptBaseContent(request: request, payload: payload))
            self.bestAttemptContent = bestAttemptContent
            self.contentHandler = contentHandler

            let builder = OptistreamEventBuilder(
                tenantID: try unwrap(storage.tenantID),
                storage: storage,
                airshipIntegration: OptimoveAirshipIntegration(
                    storage: storage,
                    isSupportedAirship: false
                )
            )

            let operationsToExecute = [
                DeeplinkExtracter(
                    bundleIdentifier: bundleIdentifier,
                    notificationPayload: payload,
                    completionHandler: { [weak self] urlString in
                        self?.bestAttemptContent?.userInfo[DeeplinkExtracter.Constants.dynamicLinksKey] = urlString
                    }
                ),
                NotificationDeliveryReporter(
                    bundleIdentifier: bundleIdentifier,
                    notificationPayload: payload,
                    networking: networking,
                    builder: builder
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
        operationQueue.cancelAllOperations()
        if let bestAttemptContent = bestAttemptContent {
            contentHandler?(bestAttemptContent)
        }
        os_log(
            "Notification Service Extension time was expire.",
            log: OSLog.notification, type: .error
        )
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

}

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier!
    static let notification = OSLog(subsystem: subsystem, category: "notification")
}
