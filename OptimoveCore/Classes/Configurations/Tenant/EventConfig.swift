//  Copyright © 2017 Optimove.

public struct EventsConfig: Codable {
    public let id: Int
    public let supportedOnOptitrack: Bool
    public let supportedOnRealTime: Bool
    public let parameters: [String: Parameter]
}
