import Foundation

public class PreferenceUpdateRequestObjc: NSObject, Codable {
    @nonobjc let preferenceUpdateRequest: PreferenceUpdateRequest
    public var topicId: String {
        return preferenceUpdateRequest.topicId
    }

    public var channelSubscription: [Channel] {
        return preferenceUpdateRequest.channelSubscription
    }

    init(preferenceUpdateRequest: PreferenceUpdateRequest) {
        self.preferenceUpdateRequest = preferenceUpdateRequest
    }

    public init(topicId: String, channelSubscription: [Channel]) {
        self.preferenceUpdateRequest = PreferenceUpdateRequest(topicId: topicId, channelSubscription: channelSubscription)
    }
}

public struct PreferenceUpdateRequest: Codable {
    public let topicId: String
    public let channelSubscription: [Channel]

    public init(topicId: String, channelSubscription: [Channel]) {
        self.topicId = topicId
        self.channelSubscription = channelSubscription
    }
}
