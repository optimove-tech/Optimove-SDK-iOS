//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

class OverlayMessagingRequestService {

    /// The result of a scheduled fetch. When the fetch failed, `nextFetchInSeconds` is the retry backoff
    /// instead of the server's, so the caller handles both the same way.
    struct ScheduledFetchResult {
        let message: OverlayMessagingMessage?
        let nextFetchInSeconds: Int64
    }

    // After a failed scheduled fetch: 1 minute, doubling up to 1 hour, reset by a success
    private static let minRetrySeconds: Int64 = 60
    private static let maxRetrySeconds: Int64 = 3600

    private let httpClient: KSHttpClient
    // Only one scheduled fetch is in flight at a time, so this needs no lock
    private var retrySeconds = minRetrySeconds

    init(httpClient: KSHttpClient) {
        self.httpClient = httpClient
    }

    /// Fetches from the v2 scheduled endpoint: at most one message, and when to fetch next. A failure, including an
    /// error status (the server's 504 when it couldn't read the messages in time), gives the retry backoff.
    func readScheduledMessage(onComplete: @escaping (ScheduledFetchResult) -> Void) {
        guard let encodedIdentifier = KSHttpUtil.urlEncode(OptimobileHelper.currentUserIdentifier) else {
            onComplete(retryLater())
            return
        }

        let path = "/api/v2/users/\(encodedIdentifier)/messages/scheduled/mobile"

        httpClient.sendRequest(.GET, toPath: path, data: nil, authUserId: OptimobileHelper.associatedUserId, onSuccess: { _, decodedBody in
            guard let result = Self.parseScheduledResponse(decodedBody) else {
                onComplete(self.retryLater())
                return
            }
            self.resetRetry()
            onComplete(result)
        }, onFailure: { _, _, _ in
            onComplete(self.retryLater())
        })
    }

    static func parseScheduledResponse(_ body: Any?) -> ScheduledFetchResult? {
        guard let json = body as? [AnyHashable: Any],
              let nextFetchInSeconds = (json["nextFetchInSeconds"] as? NSNumber)?.int64Value else {
            return nil
        }
        let first = (json["messages"] as? [Any])?.first
        return ScheduledFetchResult(message: first.flatMap { buildMessage(from: $0, type: .session) },
                                    nextFetchInSeconds: nextFetchInSeconds)
    }

    func retryLater() -> ScheduledFetchResult {
        let nextFetchInSeconds = retrySeconds
        retrySeconds = min(retrySeconds * 2, Self.maxRetrySeconds)
        return ScheduledFetchResult(message: nil, nextFetchInSeconds: nextFetchInSeconds)
    }

    func resetRetry() {
        retrySeconds = Self.minRetrySeconds
    }

    func readOverlayMessage(type: OverlayMessagingMessage.MessageType, onComplete: @escaping (OverlayMessagingMessage?) -> Void) {
        guard let encodedIdentifier = KSHttpUtil.urlEncode(OptimobileHelper.currentUserIdentifier) else {
            onComplete(nil)
            return
        }
        
        let messageType = type == .session ? "session" : "immediate"
        let path = "/api/v1/users/\(encodedIdentifier)/messages/mobile?messageType=\(messageType)"
        
        httpClient.sendRequest(.GET, toPath: path, data: nil, authUserId: OptimobileHelper.associatedUserId, onSuccess: { response, decodedBody in
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
