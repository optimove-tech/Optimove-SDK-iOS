import Foundation
import FirebaseMessaging
import FirebaseCore

class FirebaseOptionsBuilder {
    var webApiKey: String = ""
    var appId: String = ""
    var dbUrl: String = ""
    var senderId: String = ""
    var storageBucket: String = ""
    var projectId: String = ""

    @discardableResult
    func set(webApiKey: String) -> FirebaseOptionsBuilder {
        self.webApiKey = webApiKey
        return self
    }
    @discardableResult
    func set(appId: String) -> FirebaseOptionsBuilder {
        self.appId = appId
        return self
    }
    @discardableResult
    func set(dbUrl: String) -> FirebaseOptionsBuilder {
        self.dbUrl = dbUrl
        return self
    }

    @discardableResult
    func set(senderId: String) -> FirebaseOptionsBuilder {
        self.senderId = senderId
        return self
    }

    @discardableResult
    func set(storageBucket: String) -> FirebaseOptionsBuilder {
        self.storageBucket = storageBucket
        return self
    }
    @discardableResult
    func set(projectId: String) -> FirebaseOptionsBuilder {
        self.projectId = projectId
        return self
    }

    func build() -> FirebaseOptions {
        let options = FirebaseOptions(googleAppID: appId, gcmSenderID: senderId)
        options.apiKey = webApiKey
        options.databaseURL = dbUrl
        options.storageBucket = storageBucket
        options.projectID = projectId
        options.bundleID = Bundle.main.bundleIdentifier!
        options.clientID = "gibrish"
        return options
    }
}
