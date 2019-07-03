import Foundation

class SetUserAgent: OptimoveCoreEvent {
    var userAgent1: String
    var userAgent2: String?

    var name: String { return OptimoveKeys.Configuration.setUserAgent.rawValue }
    var parameters: [String: Any]

    init(userAgent: String) {
        if userAgent.count <= 255 {
            self.userAgent1 = userAgent
            self.parameters = [OptimoveKeys.Configuration.userAgentHeader1.rawValue: self.userAgent1]
            return
        }
        let firstIndex = userAgent.startIndex
        let lastIndex = userAgent.index(firstIndex, offsetBy: 254)

        self.userAgent1 = String(userAgent[firstIndex...lastIndex])
        self.userAgent2 = userAgent
        self.userAgent2?.removeSubrange(firstIndex...lastIndex)

        var params = [OptimoveKeys.Configuration.userAgentHeader1.rawValue: self.userAgent1]
        if userAgent2 != nil {
            params[OptimoveKeys.Configuration.userAgentHeader2.rawValue] = self.userAgent2!
        }
        self.parameters = params
    }
}
