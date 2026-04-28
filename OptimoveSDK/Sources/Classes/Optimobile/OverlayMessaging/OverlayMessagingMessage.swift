//  Copyright © 2025 Optimove. All rights reserved.

import Foundation

public struct OverlayMessagingMessage {
    public enum MessageType {
        case session
        case immediate
    }
    
    public let id: Int64
    public let content: NSDictionary
    public let data: NSDictionary?
    public let type: MessageType
}
