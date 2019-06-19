import Foundation

class MbaasRequestBuilder {
    init(operation: MbaasOperations) {
        mbaasRequesstBody = MbaasRequestBody(operation: operation)
    }
    private var mbaasRequesstBody: MbaasRequestBody

    func setUserInfo(visitorId: String, customerId: String?) -> MbaasRequestBuilder {
        mbaasRequesstBody.visitorId = visitorId
        mbaasRequesstBody.publicCustomerId = customerId
        return self
    }

    func setToken(token: String) -> MbaasRequestBuilder {
        mbaasRequesstBody.token = token
        return self
    }

    func setOptIn(optIn: Bool) -> MbaasRequestBuilder {
        mbaasRequesstBody.optIn = optIn
        return self
    }

    var iosToken: [String: Any] = [:]
    var reuqest: [String: Any] = [:]

    func build() -> MbaasRequestBody {
        return mbaasRequesstBody
    }
}
