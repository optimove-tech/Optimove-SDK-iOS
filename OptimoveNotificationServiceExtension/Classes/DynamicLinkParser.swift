import Foundation

final class DynamicLinkParser: NSObject, URLSessionDataDelegate {
    private var session: URLSession!
    private var parsingCallback: (Result<URL, Error>) -> Void

    init(parsingCallback: @escaping (Result<URL, Error>) -> Void) {
        self.parsingCallback = parsingCallback
        super.init()
        session = URLSession(
            configuration: .default,
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
