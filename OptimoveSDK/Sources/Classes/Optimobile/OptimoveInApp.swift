//  Copyright © 2022 Optimove. All rights reserved.

import CoreData
import Foundation
import OptimoveCore

class InAppInboxItem {
    private(set) var id: Int64
    private(set) var title: String
    private(set) var subtitle: String
    private(set) var availableFrom: Date?
    private(set) var availableTo: Date?
    private(set) var dismissedAt: Date?
    private(set) var sentAt: Date
    private(set) var data: NSDictionary?
    private var readAt: Date?
    private var imagePath: String?

    private static let defaultImageWidth: UInt = 300
    let mediaHelper: MediaHelper

    init(entity: InAppMessageEntity, mediaHelper: MediaHelper) {
        id = Int64(entity.id)
        self.mediaHelper = mediaHelper

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

    func isAvailable() -> Bool {
        if availableFrom != nil, availableFrom!.timeIntervalSinceNow > 0 {
            return false
        } else if availableTo != nil, availableTo!.timeIntervalSinceNow < 0 {
            return false
        }

        return true
    }

    func isRead() -> Bool {
        return readAt != nil
    }

    func getImageUrl() -> URL? {
        return getImageUrl(width: InAppInboxItem.defaultImageWidth)
    }

    func getImageUrl(width: UInt) -> URL? {
        if let imagePathNotNil = imagePath {
            return try? mediaHelper.getCompletePictureUrl(
                pictureUrlString: imagePathNotNil,
                width: width
            )
        }

        return nil
    }
}

struct InAppInboxSummary {
    let totalCount: Int64
    let unreadCount: Int64
}

typealias InboxUpdatedHandlerBlock = () -> Void
typealias InboxSummaryBlock = (InAppInboxSummary?) -> Void

enum OptimoveInApp {
    private static var _inboxUpdatedHandlerBlock: InboxUpdatedHandlerBlock?

    static func updateConsent(forUser consentGiven: Bool) {
        if Optimobile.inAppConsentStrategy != InAppConsentStrategy.explicitByUser {
            NSException(name: NSExceptionName(rawValue: "Optimobile: Invalid In-app consent strategy"), reason: "You can only manage in-app messaging consent when the feature is enabled and strategy is set to InAppConsentStrategyExplicitByUser", userInfo: nil).raise()

            return
        }

        Optimobile.sharedInstance.inAppManager.updateUserConsent(consentGiven: consentGiven)
    }

    static func setDisplayMode(mode: InAppDisplayMode) {
        Optimobile.sharedInstance.inAppManager.presenter.setDisplayMode(mode)
    }

    static func getDisplayMode() -> InAppDisplayMode {
        return Optimobile.sharedInstance.inAppManager.presenter.getDisplayMode()
    }

    static func getInboxItems(storage: OptimoveStorage) -> [InAppInboxItem] {
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
                let inboxItem = InAppInboxItem(
                    entity: item,
                    mediaHelper: MediaHelper(storage: storage)
                )

                if inboxItem.isAvailable() == false {
                    continue
                }

                results.append(inboxItem)
            }
        }

        return results
    }

    static func presentInboxMessage(item: InAppInboxItem) -> InAppMessagePresentationResult {
        if getDisplayMode() == .paused {
            return .PAUSED
        }

        if item.isAvailable() == false {
            return InAppMessagePresentationResult.EXPIRED
        }

        let result = Optimobile.sharedInstance.inAppManager.presentMessage(withId: item.id)

        return result ? InAppMessagePresentationResult.PRESENTED : InAppMessagePresentationResult.FAILED
    }

    static func deleteMessageFromInbox(item: InAppInboxItem) -> Bool {
        return Optimobile.sharedInstance.inAppManager.deleteMessageFromInbox(withId: item.id)
    }

    static func markAsRead(item: InAppInboxItem) -> Bool {
        if item.isRead() {
            return false
        }
        let res = Optimobile.sharedInstance.inAppManager.markInboxItemRead(withId: item.id, shouldWait: true)
        maybeRunInboxUpdatedHandler(inboxNeedsUpdate: res)

        return res
    }

    static func markAllInboxItemsAsRead() -> Bool {
        return Optimobile.sharedInstance.inAppManager.markAllInboxItemsAsRead()
    }

    static func setOnInboxUpdated(inboxUpdatedHandlerBlock: InboxUpdatedHandlerBlock?) {
        _inboxUpdatedHandlerBlock = inboxUpdatedHandlerBlock
    }

    static func getInboxSummaryAsync(inboxSummaryBlock: @escaping InboxSummaryBlock) {
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
