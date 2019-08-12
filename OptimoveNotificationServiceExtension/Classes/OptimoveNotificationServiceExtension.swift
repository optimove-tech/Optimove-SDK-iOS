import Foundation
import UserNotifications
import os.log

@objc public class OptimoveNotificationServiceExtension: NSObject {

    @objc public private(set) var isHandledByOptimove: Bool = false
    
    private let bundleIdentifier: String
    private let tenantInfo: NotificationExtensionTenantInfo
    private let configurationRepository = ConfigurationRepository()
    private let sharedDefaults: UserDefaults
    private var bestAttemptContent: UNMutableNotificationContent!
    private var contentHandler: ((UNNotificationContent) -> Void)!
    private lazy var operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        return queue
    }()

    @objc public init(appBundleId: String) {
        bundleIdentifier = appBundleId
        sharedDefaults = UserDefaults(suiteName: "group.\(appBundleId).optimove")!
        tenantInfo = NotificationExtensionTenantInfo(sharedUserDefaults: sharedDefaults)
    }
    
    @objc public convenience override init() {
        guard let bundleIdentifier = Bundle.extractHostAppBundle()?.bundleIdentifier else {
            fatalError("Unable to find a bundle identifier.")
        }
        self.init(appBundleId: bundleIdentifier)
    }

    // Returns true if the message was consumed by Optimove
    @objc public func didReceive(_ request: UNNotificationRequest,
                                 withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) -> Bool {
        let payload: NotificationPayload
        do {
            payload = try extractNotificationPayload(request)
            self.bestAttemptContent = try unwrap(createBestAttemptBaseContent(request: request, payload: payload))
        } catch {
            contentHandler(request.content)
            return false
        }
        self.isHandledByOptimove = true
        self.contentHandler = contentHandler

        let configurationFetcher = ConfigurationFetcher(
            tenantInfo: tenantInfo,
            repository: configurationRepository,
            bundleIdentifier: bundleIdentifier
        )
        let notificationDeliveryReporter = NotificationDeliveryReporter(
            repository: configurationRepository,
            bundleIdentifier: bundleIdentifier,
            sharedDefaults: sharedDefaults,
            notificationPayload: payload
        )

        // `NotificationDeliveryReporter` operation should be executed after `ConfigurationFetcher` operation
        // because it has the dependency on a configuration, that provides by `ConfigurationRepository`.
        notificationDeliveryReporter.addDependency(configurationFetcher)
        
        let operations: [Operation] = [
            configurationFetcher,
            notificationDeliveryReporter,
            DeeplinkExtracter(
                bundleIdentifier: bundleIdentifier,
                notificationPayload: payload,
                bestAttemptContent: bestAttemptContent
            ),
            MediaAttachmentDownloader(
                notificationPayload: payload,
                bestAttemptContent: bestAttemptContent
            )
        ]

        // The completion operation going to be executed right after all operations are finished.
        let completionOperation = BlockOperation {
            os_log("Operations were completed", log: OSLog.notification, type: .info)
            contentHandler(self.bestAttemptContent)
        }
        os_log("Operations were scheduled", log: OSLog.notification, type: .info)
        operations.forEach {
            // Set the completion operation as dependent for all operations before they start executing.
            completionOperation.addDependency($0)
            operationQueue.addOperation($0)
        }
        // The completion operation is performing on the main queue.
        OperationQueue.main.addOperation(completionOperation)
        
        return true
    }

    @objc public func serviceExtensionTimeWillExpire() {
        if let bestAttemptContent = bestAttemptContent, let contentHandler = contentHandler {
            contentHandler(bestAttemptContent)
        }
    }
}

private extension OptimoveNotificationServiceExtension {
    
    func extractNotificationPayload(_ request: UNNotificationRequest) throws -> NotificationPayload {
        let userInfo = request.content.userInfo
        let data = try JSONSerialization.data(
            withJSONObject: userInfo,
            options: JSONSerialization.WritingOptions(rawValue: 0)
        )
        let decoder = JSONDecoder()
        return try decoder.decode(NotificationPayload.self, from: data)
    }
    
    func createBestAttemptBaseContent(request: UNNotificationRequest,
                                      payload: NotificationPayload) -> UNMutableNotificationContent? {
        guard let bestAttemptContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            os_log("Unable to copy content.", log: OSLog.notification, type: .fault)
            return nil
        }
        bestAttemptContent.title = payload.title
        bestAttemptContent.body = payload.content
        return bestAttemptContent
    }
}

extension OSLog {
    static var subsystem = Bundle.main.bundleIdentifier!
    static let notification = OSLog(subsystem: subsystem, category: "notification")
}
