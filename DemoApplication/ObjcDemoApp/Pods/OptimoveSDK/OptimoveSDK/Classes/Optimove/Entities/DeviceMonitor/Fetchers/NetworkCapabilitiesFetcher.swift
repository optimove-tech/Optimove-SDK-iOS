

import SystemConfiguration

class NetworkCapabilitiesFetcher: Fetchable
{
    let reachability = Reachability(hostname: "google.com")
    func fetch(completionHandler: @escaping ResultBlockWithBool) {
       
        reachability?.whenReachable = {_ in
            completionHandler(true)
        }
        reachability?.whenUnreachable = { _ in
            completionHandler(false)
        }
        do
        {
            try reachability?.startNotifier()
        } catch {
        }
    }
    deinit {
        reachability?.stopNotifier()
    }
}

