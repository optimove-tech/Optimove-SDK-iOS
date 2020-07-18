//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class DynamicLinkParser: NSObject, URLSessionDataDelegate {

    var session: URLSession!
    var parsingCallback: (Result<URL, Error>) -> Void

    init(
        configuration: URLSessionConfiguration = .default,
        parsingCallback: @escaping (Result<URL, Error>) -> Void
    ) {
        self.parsingCallback = parsingCallback
        super.init()
        session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
    }

    func parse(_ dynamicLink: URL) {
        session.dataTask(with: dynamicLink).resume()
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        if let url = request.url {
            parsingCallback(.success(url))
        }
        completionHandler(nil)
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            parsingCallback(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            parsingCallback(.failure(error))
        }
    }
}
