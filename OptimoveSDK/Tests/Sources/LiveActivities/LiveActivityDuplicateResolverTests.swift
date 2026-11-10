//  Copyright © 2026 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

final class LiveActivityDuplicateResolverTests: XCTestCase {
    private var resolver = LiveActivityDuplicateResolver()

    override func setUp() {
        super.setUp()
        resolver = LiveActivityDuplicateResolver()
    }

    func testFirstTileSeenIsKept() {
        XCTAssertEqual(resolver.activityToKeep(activityId: "a", key: "k", liveActivityIds: ["a"]), "a")
    }

    func testSecondTileForTheSameKeyIsNotKept() {
        _ = resolver.activityToKeep(activityId: "a", key: "k", liveActivityIds: ["a"])

        XCTAssertEqual(resolver.activityToKeep(activityId: "b", key: "k", liveActivityIds: ["a", "b"]), "a")
    }

    func testTwoTilesFoundTogetherKeepOnlyTheFirstSeen() {
        let live: Set<String> = ["a", "b"]

        XCTAssertEqual(resolver.activityToKeep(activityId: "a", key: "k", liveActivityIds: live), "a")
        XCTAssertEqual(resolver.activityToKeep(activityId: "b", key: "k", liveActivityIds: live), "a")
        XCTAssertEqual(resolver.activityToKeep(activityId: "a", key: "k", liveActivityIds: live), "a")
    }

    func testNewTileIsKeptOnceTheKeptOneIsGone() {
        _ = resolver.activityToKeep(activityId: "a", key: "k", liveActivityIds: ["a"])

        XCTAssertEqual(resolver.activityToKeep(activityId: "b", key: "k", liveActivityIds: ["b"]), "b")
    }

    func testKeysAreIndependent() {
        _ = resolver.activityToKeep(activityId: "a", key: "k1", liveActivityIds: ["a"])

        XCTAssertEqual(resolver.activityToKeep(activityId: "b", key: "k2", liveActivityIds: ["b"]), "b")
    }
}
