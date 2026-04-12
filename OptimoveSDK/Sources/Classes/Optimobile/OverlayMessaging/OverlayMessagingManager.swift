//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

class OverlayMessagingManager {

    private static let sessionSlotCapacity = 1
    private static let immediateSlotCapacity = 1

    private var sessionSlotCount = 0
    private var immediateSlotCount = 0

    private var displayQueue: [OverlayMessagingMessage] = []
    private let requestService: OverlayMessagingRequestService

    init(httpClient: KSHttpClient) {
        requestService = OverlayMessagingRequestService(httpClient: httpClient)
    }

    // MARK: - Triggers

    func onTriggerReceived(_ type: OverlayMessagingMessage.MessageType) {
        switch type {
        case .session:
            guard sessionSlotCount < Self.sessionSlotCapacity else { return }
            sessionSlotCount += 1
            loadMessage(type)
        case .immediate:
            guard immediateSlotCount < Self.immediateSlotCapacity else { return }
            immediateSlotCount += 1
            loadMessage(type)
        }
    }

    // MARK: - Slots

    private func onSlotCleared(_ type: OverlayMessagingMessage.MessageType) {
        switch type {
        case .session:
            sessionSlotCount = max(0, sessionSlotCount - 1)
        case .immediate:
            immediateSlotCount = max(0, immediateSlotCount - 1)
        }
    }

    // MARK: - Loading

    private func loadMessage(_ type: OverlayMessagingMessage.MessageType) {
        requestService.readOverlayMessage(type: type) { message in
            DispatchQueue.main.async {
                self.onMessageLoaded(type: type, message: message)
            }
        }
    }

    private func onMessageLoaded(type: OverlayMessagingMessage.MessageType, message: OverlayMessagingMessage?) {
        guard let message = message else {
            onSlotCleared(type)
            return
        }
        processMessage(message)
    }

    private func processMessage(_ message: OverlayMessagingMessage) {
        // TODO: interceptor + display queue + view
    }
}
