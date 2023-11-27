//  Copyright © 2023 Optimove. All rights reserved.

@testable import OptimoveNotificationServiceExtension
import XCTest

final class PendingAnalyticsTests: XCTestCase {
    var pendingAnalytics: PendingAnalytics!
    var storage: MockKeyValPersistent.Type!

    override func setUpWithError() throws {
        storage = MockKeyValPersistent.self
        pendingAnalytics = PendingAnalyticsImpl(storage: storage)
    }

    override func tearDownWithError() throws {
        pendingAnalytics = nil
        storage.removeAll()
    }

    func testAdd() throws {
        let metric = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric)
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric])
    }

    func testAddSameId() throws {
        let metric = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric)
        try pendingAnalytics.add(metric: metric)
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric])
    }

    func testReadAll() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "2", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.add(metric: metric2)
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric1, metric2])
    }

    func testRemove() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "2", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.add(metric: metric2)
        try pendingAnalytics.remove(id: "1")
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric2])
    }

    func testRemoveNonExisting() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "2", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.add(metric: metric2)
        try pendingAnalytics.remove(id: "3")
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric1, metric2])
    }

    func testRemoveEmpty() throws {
        try pendingAnalytics.remove(id: "3")
        XCTAssertEqual(try pendingAnalytics.readAll(), [])
    }

    func testRemoveAll() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "2", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.add(metric: metric2)
        try pendingAnalytics.removeAll()
        XCTAssertEqual(try pendingAnalytics.readAll(), [])
    }

    func testRemoveAllEmpty() throws {
        try pendingAnalytics.removeAll()
        XCTAssertEqual(try pendingAnalytics.readAll(), [])
    }

    func testAddRemoveAdd() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "2", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.remove(id: "1")
        try pendingAnalytics.add(metric: metric2)
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric2])
    }

    func testAddRemoveAddSameId() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.remove(id: "1")
        try pendingAnalytics.add(metric: metric2)
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric2])
    }

    func testAddRemoveAddSameId2() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        let metric2 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED)
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.add(metric: metric2)
        try pendingAnalytics.remove(id: "1")
        XCTAssertEqual(try pendingAnalytics.readAll(), [])
    }

    func testProperties() throws {
        let metric1 = PendingAnalyticMetric(id: "1", eventType: .MESSAGE_DELIVERED, properties: ["a": "b"])
        let metric2 = PendingAnalyticMetric(id: "2", eventType: .MESSAGE_DELIVERED, properties: ["c": "d"])
        try pendingAnalytics.add(metric: metric1)
        try pendingAnalytics.add(metric: metric2)
        XCTAssertEqual(try pendingAnalytics.readAll(), [metric1, metric2])
    }
}

var storage: [String: Any] = [:]

final class MockKeyValPersistent: KeyValPersistent {
    static func object(forKey: String) -> Any? {
        return storage[forKey]
    }

    static func removeObject(forKey: String) {
        storage.removeValue(forKey: forKey)
    }

    static func set(_ value: Any?, forKey: String) {
        storage[forKey] = value
    }

    static func removeAll() {
        storage.removeAll()
    }
}
