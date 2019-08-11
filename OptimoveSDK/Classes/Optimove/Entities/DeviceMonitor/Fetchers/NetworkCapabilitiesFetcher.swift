import Reachability

final class NetworkCapabilitiesFetcher: Fetchable {

    private let reachability = Reachability(hostname: "google.com")

    /// NOTE: All closures are run on the main queue.
    func fetch(completion: @escaping ResultBlockWithBool) {
        reachability?.whenReachable = { _ in
            completion(true)
        }
        reachability?.whenUnreachable = { _ in
            completion(false)
        }
        do {
            try reachability?.startNotifier()
        } catch { }
    }

    deinit {
        reachability?.stopNotifier()
    }
}
