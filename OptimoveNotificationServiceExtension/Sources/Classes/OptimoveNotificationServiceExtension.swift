//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import UserNotifications
import os.log
import OptimoveCore

@objc public class OptimoveNotificationServiceExtension: NSObject {

    @objc public private(set) var isHandledByOptimove: Bool = false

    let service: Service?

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

    init(bundleIdentifier: String) {
        self.service = Service.init(bundleIdentifier: bundleIdentifier)
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
            guard let service = self.service else {
                os_log("Service not found", log: OSLog.notification, type: .fault)
                return false
            }
            isHandledByOptimove = false
            let payload = try verifyAndCreatePayload(request)
            isHandledByOptimove = true

            self.bestAttemptContent = createBestAttemptContent(request: request, payload: payload)
            self.contentHandler = contentHandler

            let operations = [
                NotificationDeliveryReporter(
                    bundleIdentifier: service.bundleIdentifier,
                    notificationPayload: payload,
                    networking: service.networking,
                    storage: service.storage
                ),
                MediaAttachmentDownloader(
                    notificationPayload: payload,
                    completionHandler: { [weak self] (attachment) in
                        self?.bestAttemptContent?.attachments =
                            (self?.bestAttemptContent?.attachments ?? [])
                            + [attachment]
                    }
                )
            ]

            // The completion operation going to be executed right after all operations are finished.
            let completionOperation = BlockOperation { [weak self] in
                guard let bestAttemptContent = self?.bestAttemptContent else { return }
                bestAttemptContent.userInfo[NotificationKey.wasHandledByOptimoveNSE] = true
                self?.bestAttemptContent = bestAttemptContent
                contentHandler(bestAttemptContent)
                self?.bestAttemptContent = nil
                os_log("Operations were completed", log: OSLog.notification, type: .info)
            }

            operations.forEach {
                // Set the completion operation as dependent for all operations before they start executing.
                completionOperation.addDependency($0)
                service.operationQueue.addOperation($0)
            }

            // The completion operation is performing on the main queue.
            OperationQueue.main.addOperation(completionOperation)

            os_log("Operations were scheduled", log: OSLog.notification, type: .info)

        } catch {
            // TODO: switch error types
            os_log(
                "Unable to cast to Optimove notification. %{PUBLIC}@",
                log: OSLog.notification, type: .error, error.localizedDescription
            )
        }
        return isHandledByOptimove
    }

    /// The method called by system in case if `didReceive(_:withContentHandler:)` takes to long to execute or
    /// out of memory.
    @objc public func serviceExtensionTimeWillExpire() {
        self.service?.operationQueue.cancelAllOperations()
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

    func verifyAndCreatePayload(_ request: UNNotificationRequest) throws -> NotificationPayload {
        let userInfo = request.content.userInfo
        let data = try JSONSerialization.data(withJSONObject: userInfo)
        return try JSONDecoder().decode(NotificationPayload.self, from: data)
    }

    func createBestAttemptContent(request: UNNotificationRequest,
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

final class Service {

    let bundleIdentifier: String
    let operationQueue: OperationQueue
    let storage: OptimoveStorage
    let networking: OptistreamNetworking

    init?(bundleIdentifier: String) {
        do {
            self.storage = StorageFacade(
                groupedStorage: try UserDefaults.grouped(
                    tenantBundleIdentifier: bundleIdentifier
                ),
                sharedStorage: nil,
                fileStorage: nil
            )
            self.networking = OptistreamNetworkingImpl(
                networkClient: NetworkClientImpl(),
                endpoint: try unwrap(storage.optitrackEndpoint)
            )
            self.bundleIdentifier = bundleIdentifier
            operationQueue = OperationQueue()
            operationQueue.qualityOfService = .userInitiated
        } catch {
            os_log(
                "Service initialization error: %{PUBLIC}@",
                log: OSLog.notification,
                type: .error, error.localizedDescription)
            return nil
        }
    }
}
