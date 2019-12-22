//  Copyright © 2019 Optimove. All rights reserved.

import XCTest

// https://oleb.net/blog/2018/02/xctkvoexpectation-swift-keypaths/
// https://medium.com/@sting.su/the-replacement-of-kvo-key-value-observing-in-swift-3e2a3d7a3608
final class KVOExpectation: XCTestExpectation {
    private var kvoToken: NSKeyValueObservation?

    /// Creates an expectation that is fulfilled when a KVO change causes the
    /// specified key path of the observed object to have an expected value.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter expectedValue: The expected value for the observed key path.
    ///
    /// This initializer sets up KVO observation for keyPath with the
    /// `NSKeyValueObservingOptions.initial` option set. This means that the
    /// observed key path will be checked immediately after initialization.
    convenience init<Object: NSObject, Value: Equatable>(
        object objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        expectedValue: Value, file: StaticString = #file, line: Int = #line) {
        self.init(object: objectToObserve, keyPath: keyPath, options: .initial) { (obj, change) -> Bool in
            return obj[keyPath: keyPath] == expectedValue
        }
    }

    /// Creates an expectation that is fulfilled by a KVO change for which the
    /// provided handler returns `true`.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter options: KVO options to be used for the observation.
    ///   The default value is `[]`.
    /// - Parameter handler: An optional handler block that will be invoked for
    ///   every KVO event. Return `true` to signal that the expectation should
    ///   be fulfilled. If you pass `nil` (the default value), the expectation
    ///   will be fulfilled by the first KVO event.
    ///
    /// When changes to the value are detected, the handler block is called to
    /// assess the new value to see if the expectation has been fulfilled. Every
    /// KVO event will run the handler block until it either returns `true` (to
    /// fulfill the expectation), or the wait times out.
    init<Object: NSObject, Value>(
        object objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [],
        file: StaticString = #file, line: Int = #line,
        handler: ((Object, NSKeyValueObservedChange<Value>) -> Bool)? = nil) {
        super.init(description: KVOExpectation.description(forObject: objectToObserve, keyPath: keyPath, file: file, line: line))
        kvoToken = objectToObserve.observe(keyPath, options: options) { (object, change) in
            let isFulfilled = handler == nil || handler?(object, change) == true
            if isFulfilled {
                self.kvoToken = nil
                self.fulfill()
            }
        }
    }

    fileprivate static func description<Object: NSObject, Value>(forObject object: Object, keyPath: KeyPath<Object, Value>, file: StaticString, line: Int) -> String {
        return "\(file):\(line) – KVO expectation – object: \(object) – keyPath: \(keyPath)"
    }
}

extension XCTestCase {
    /// Creates an expectation that is fulfilled when a KVO change causes the
    /// specified key path of the observed object to have an expected value.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter expectedValue: The expected value for the observed key path.
    ///
    /// This initializer sets up KVO observation for keyPath with the
    /// `NSKeyValueObservingOptions.initial` option set. This means that the
    /// observed key path will be checked immediately after initialization.
    @discardableResult
    func keyValueObservingExpectation<Object: NSObject, Value: Equatable>(
        for objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        expectedValue: Value, file: StaticString = #file, line: Int = #line)
        -> XCTestExpectation {
        return keyValueObservingExpectation(for: objectToObserve, keyPath: keyPath, options: [.initial]) { (obj, change) -> Bool in
            return obj[keyPath: keyPath] == expectedValue
        }
    }

    /// Creates an expectation that is fulfilled by a KVO change for which the
    /// provided handler returns `true`.
    ///
    /// - Parameter objectToObserve: The object to observe.
    /// - Parameter keyPath: The key path to observe.
    /// - Parameter options: KVO options to be used for the observation.
    ///   The default value is `[]`.
    /// - Parameter handler: An optional handler block that will be invoked for
    ///   every KVO event. Return `true` to signal that the expectation should
    ///   be fulfilled. If you pass `nil` (the default value), the expectation
    ///   will be fulfilled by the first KVO event.
    ///
    /// When changes to the value are detected, the handler block is called to
    /// assess the new value to see if the expectation has been fulfilled. Every
    /// KVO event will run the handler block until it either returns `true` (to
    /// fulfill the expectation), or the wait times out.
    @discardableResult
    func keyValueObservingExpectation<Object: NSObject, Value>(
        for objectToObserve: Object, keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [],
        file: StaticString = #file, line: Int = #line,
        handler: ((Object, NSKeyValueObservedChange<Value>) -> Bool)? = nil)
        -> XCTestExpectation {
        let wrapper = expectation(description: KVOExpectation.description(forObject: objectToObserve, keyPath: keyPath, file: file, line: line))
        // Following XCTest precedent, which sets `assertForOverFulfill` to true by default
        // for expectations created with `XCTestCase` convenience methods.
        wrapper.assertForOverFulfill = true
        // The KVO handler inside KVOExpectation retains its parent object while the observation is active.
        // That's why we can get away with not retaining the KVOExpectation here.
        _ = KVOExpectation(object: objectToObserve, keyPath: keyPath, options: options) { (object, change) in
            let isFulfilled = handler == nil || handler?(object, change) == true
            if isFulfilled {
                wrapper.fulfill()
                return true
            } else {
                return false
            }
        }
        return wrapper
    }
}
