import FirebaseCore

final class FirebaseOptionsBuilder {

    private struct Constants {
        static let clientID = "gibrish"
    }

    private let provider: FirebaseKeys
    private let bundleID: String

    init(provider: FirebaseKeys,
         bundleID: String) {
        self.provider = provider
        self.bundleID = bundleID
    }

    func build() -> FirebaseOptions {
        let options = FirebaseOptions(
            googleAppID: provider.appid,
            gcmSenderID: provider.senderId
        )
        options.apiKey = provider.webApiKey
        options.databaseURL = provider.dbUrl
        options.storageBucket = provider.storageBucket
        options.projectID = provider.projectId
        options.bundleID = bundleID
        options.clientID = Constants.clientID
        return options
    }
}
