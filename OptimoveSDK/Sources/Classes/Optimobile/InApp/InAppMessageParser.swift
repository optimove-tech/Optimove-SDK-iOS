//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Required fields for persisting an in-app message from the sync API payload.
struct InAppMessageRequiredFields {
    let id: Int64
    let content: NSDictionary
    let updatedAt: Date
    let presentedWhen: String
}

/// Parses untyped JSON dictionaries from `/v1/users/{id}/messages`.
/// Mirrors the defensive approach used by `OverlayMessagingRequestService.buildMessage`.
enum InAppMessageParser {
    static func makeDateParser() -> DateFormatter {
        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateParser.locale = Locale(identifier: "en_US_POSIX")
        dateParser.timeZone = TimeZone(secondsFromGMT: 0)
        return dateParser
    }

    static func parseRequiredFields(
        from message: [AnyHashable: Any],
        dateParser: DateFormatter = makeDateParser()
    ) -> InAppMessageRequiredFields? {
        guard let id = (message["id"] as? NSNumber)?.int64Value,
              let content = message["content"] as? NSDictionary,
              let updatedAtString = message["updatedAt"] as? String,
              let updatedAt = dateParser.date(from: updatedAtString),
              let presentedWhen = message["presentedWhen"] as? String
        else {
            return nil
        }

        return InAppMessageRequiredFields(
            id: id,
            content: content,
            updatedAt: updatedAt,
            presentedWhen: presentedWhen
        )
    }
}
