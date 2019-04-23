import Foundation

class DynamicLinkParser :NSObject, URLSessionDataDelegate
{
    private var session:URLSession!
    private var parsingCallback:(URL?) -> Void
    
    init(parsingCallback:@escaping (URL?) -> Void)
    {
        self.parsingCallback = parsingCallback
        super.init()
        session = URLSession(configuration: .default,
                             delegate: self,
                             delegateQueue: nil)
        
    }
    
    func parse(_ dynamicLink: URL) {
        session.dataTask(with: dynamicLink).resume()
    }
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void)
    {
        self.parsingCallback(request.url)
        completionHandler(nil)
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if error != nil {
            parsingCallback(nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            parsingCallback(nil)
        }
    }
}
