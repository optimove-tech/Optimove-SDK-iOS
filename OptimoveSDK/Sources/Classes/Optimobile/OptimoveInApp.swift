//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation

public class InAppInboxItem {
    public internal(set) var id: Int64
    public internal(set) var title: String
    public internal(set) var subtitle: String
    public internal(set) var availableFrom: Date?
    public internal(set) var availableTo: Date?
    public internal(set) var dismissedAt: Date?
    public internal(set) var sentAt: Date
    public internal(set) var data: NSDictionary?
    private var readAt: Date?
    private var imagePath: String?

    private static let defaultImageWidth: UInt = 300

    init(entity: InAppMessageEntity) {
        id = Int64(entity.id)

        let inboxConfig = entity.inboxConfig?.copy() as! [String: Any]

        title = inboxConfig["title"] as! String
        subtitle = inboxConfig["subtitle"] as! String

        availableFrom = entity.inboxFrom?.copy() as? Date
        availableTo = entity.inboxTo?.copy() as? Date
        dismissedAt = entity.dismissedAt?.copy() as? Date
        readAt = entity.readAt?.copy() as? Date
        data = entity.data?.copy() as? NSDictionary

        if let sentAtNonNil = entity.sentAt?.copy() as? Date {
            sentAt = sentAtNonNil
        } else {
            sentAt = entity.updatedAt.copy() as! Date
        }

        imagePath = inboxConfig["imagePath"] as? String
    }

    public func isAvailable() -> Bool {
        if availableFrom != nil, availableFrom!.timeIntervalSinceNow > 0 {
            return false
        } else if availableTo != nil, availableTo!.timeIntervalSinceNow < 0 {
            return false
        }

        return true
    }

    public func isRead() -> Bool {
        return readAt != nil
    }

    public func getImageUrl() -> URL? {
        return getImageUrl(width: InAppInboxItem.defaultImageWidth)
    }

    public func getImageUrl(width: UInt) -> URL? {
        if let imagePathNotNil = imagePath {
            return MediaHelper.getCompletePictureUrl(pictureUrl: imagePathNotNil, width: width)
        }

        return nil
    }
}

public struct InAppInboxSummary {
    public let totalCount: Int64
    public let unreadCount: Int64
}

public typealias InboxUpdatedHandlerBlock = () -> Void
public typealias InboxSummaryBlock = (InAppInboxSummary?) -> Void

public enum OptimoveInApp {
    private static var _inboxUpdatedHandlerBlock: InboxUpdatedHandlerBlock?

    public static func updateConsent(forUser consentGiven: Bool) {
        if Optimobile.inAppConsentStrategy != InAppConsentStrategy.explicitByUser {
            NSException(name: NSExceptionName(rawValue: "Optimobile: Invalid In-app consent strategy"), reason: "You can only manage in-app messaging consent when the feature is enabled and strategy is set to InAppConsentStrategyExplicitByUser", userInfo: nil).raise()

            return
        }

        Optimobile.sharedInstance.inAppManager.updateUserConsent(consentGiven: consentGiven)
    }

    public static func setDisplayMode(mode: InAppDisplayMode) {
        Optimobile.sharedInstance.inAppManager.presenter.setDisplayMode(mode)
    }

    public static func getDisplayMode() -> InAppDisplayMode {
        return Optimobile.sharedInstance.inAppManager.presenter.getDisplayMode()
    }

    public static func getInboxItems() -> [InAppInboxItem] {
        guard let context = Optimobile.sharedInstance.inAppManager.messagesContext else {
            return []
        }

        var results: [InAppInboxItem] = []
        context.performAndWait {
            let request = NSFetchRequest<InAppMessageEntity>(entityName: "Message")
            request.includesPendingChanges = false
            request.sortDescriptors = [
                NSSortDescriptor(key: "sentAt", ascending: false),
                NSSortDescriptor(key: "updatedAt", ascending: false),
                NSSortDescriptor(key: "id", ascending: false),
            ]
            request.predicate = NSPredicate(format: "(inboxConfig != nil)")
            request.propertiesToFetch = ["id", "inboxConfig", "inboxFrom", "inboxTo", "dismissedAt", "readAt", "sentAt", "data", "updatedAt"]

            var items: [InAppMessageEntity] = []
            do {
                items = try context.fetch(request) as [InAppMessageEntity]
            } catch {
                print("Failed to fetch items: \(error)")

                return
            }

            for item in items {
                let inboxItem = InAppInboxItem(entity: item)

                if inboxItem.isAvailable() == false {
                    continue
                }

                results.append(inboxItem)
            }
        }

        return results
    }

    public static func presentInboxMessage(item: InAppInboxItem) -> InAppMessagePresentationResult {
        if getDisplayMode() == .paused {
            return .PAUSED
        }

        if item.isAvailable() == false {
            return InAppMessagePresentationResult.EXPIRED
        }

        let result = Optimobile.sharedInstance.inAppManager.presentMessage(withId: item.id)

        return result ? InAppMessagePresentationResult.PRESENTED : InAppMessagePresentationResult.FAILED
    }

    public static func deleteMessageFromInbox(item: InAppInboxItem) -> Bool {
        return Optimobile.sharedInstance.inAppManager.deleteMessageFromInbox(withId: item.id)
    }

    public static func markAsRead(item: InAppInboxItem) -> Bool {
        if item.isRead() {
            return false
        }
        let res = Optimobile.sharedInstance.inAppManager.markInboxItemRead(withId: item.id, shouldWait: true)
        maybeRunInboxUpdatedHandler(inboxNeedsUpdate: res)

        return res
    }

    public static func markAllInboxItemsAsRead() -> Bool {
        return Optimobile.sharedInstance.inAppManager.markAllInboxItemsAsRead()
    }

    public static func setOnInboxUpdated(inboxUpdatedHandlerBlock: InboxUpdatedHandlerBlock?) {
        _inboxUpdatedHandlerBlock = inboxUpdatedHandlerBlock
    }

    public static func getInboxSummaryAsync(inboxSummaryBlock: @escaping InboxSummaryBlock) {
        Optimobile.sharedInstance.inAppManager.readInboxSummary(inboxSummaryBlock: inboxSummaryBlock)
    }

    // Internal helpers
    static func maybeRunInboxUpdatedHandler(inboxNeedsUpdate: Bool) {
        if !inboxNeedsUpdate {
            return
        }

        if let inboxUpdatedHandler = _inboxUpdatedHandlerBlock {
            DispatchQueue.main.async {
                inboxUpdatedHandler()
            }
        }
    }
}
