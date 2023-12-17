//  Copyright © 2023 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class InAppInboxItem {
    private(set) var id: Int64
    private(set) var title: String
    private(set) var subtitle: String
    private(set) var availableFrom: Date?
    private(set) var availableTo: Date?
    private(set) var dismissedAt: Date?
    private(set) var sentAt: Date
    private(set) var data: ObjcJSON?
    private var readAt: Date?
    private var imagePath: String?

    private static let defaultImageWidth: UInt = 300
    let mediaHelper: MediaHelper

    init(entity: InAppMessageEntity, mediaHelper: MediaHelper) {
        id = entity.id
        self.mediaHelper = mediaHelper

        guard let inboxConfig = entity.inboxConfig else {
            fatalError("InboxConfig is not a [String: Any] dictionary")
        }

        guard let titleString = inboxConfig["title"]?.string,
              let subtitleString = inboxConfig["subtitle"]?.string
        else {
            fatalError("Title or subtitle is not a String")
        }

        title = titleString
        subtitle = subtitleString

        availableFrom = entity.inboxFrom
        availableTo = entity.inboxTo
        dismissedAt = entity.dismissedAt
        readAt = entity.readAt
        data = entity.data

        sentAt = entity.sentAt ?? entity.updatedAt

        imagePath = inboxConfig["imagePath"]?.string
    }

    func isAvailable() -> Bool {
        if let availableFrom = availableFrom, availableFrom.timeIntervalSinceNow > 0 {
            return false
        } else if let availableTo = availableTo, availableTo.timeIntervalSinceNow < 0 {
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
        if let imagePath = imagePath {
            return try? mediaHelper.getCompletePictureUrl(pictureUrlString: imagePath, width: width)
        }

        return nil
    }
}
