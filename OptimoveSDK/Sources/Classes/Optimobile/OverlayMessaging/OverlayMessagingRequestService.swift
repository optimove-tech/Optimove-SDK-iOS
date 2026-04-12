//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

class OverlayMessagingRequestService {

    private let httpClient: KSHttpClient

    init(httpClient: KSHttpClient) {
        self.httpClient = httpClient
    }

    func readOverlayMessage(type: OverlayMessagingMessage.MessageType, onComplete: @escaping (OverlayMessagingMessage?) -> Void) {
        guard let encodedIdentifier = KSHttpUtil.urlEncode(OptimobileHelper.currentUserIdentifier) else {
            onComplete(nil)
            return
        }

        let messageType = type == .session ? "session" : "immediate"
        let path = "/api/v1/users/\(encodedIdentifier)/messages/mobile?messageType=\(messageType)"

        httpClient.sendRequest(.GET, toPath: path, data: nil, onSuccess: { response, decodedBody in
            if response?.statusCode == 204 {
                onComplete(nil)
                return
            }
            onComplete(Self.buildMessage(from: decodedBody, type: type))
        }, onFailure: { _, _, _ in
            onComplete(nil)
        })
    }

    private static func buildMessage(from body: Any?, type: OverlayMessagingMessage.MessageType) -> OverlayMessagingMessage? {
        guard let json = body as? [AnyHashable: Any],
              let id = (json["id"] as? NSNumber)?.int64Value,
              let content = json["content"] as? NSDictionary else {
            return nil
        }
        let data = json["data"] as? NSDictionary
        return OverlayMessagingMessage(id: id, content: content, data: data, type: type)
    }
}
