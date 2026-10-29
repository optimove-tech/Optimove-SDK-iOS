import XCTest
@testable import OptimoveSDK

final class LoyaltyInitHandshakeTests: XCTestCase {
    private struct TokenError: Error {}

    private var tokenRequests = 0
    private var inits: [String?] = []
    private var failures: [Error] = []
    private var handshake: LoyaltyInitHandshake!

    override func setUp() {
        super.setUp()
        tokenRequests = 0
        inits = []
        failures = []
        handshake = LoyaltyInitHandshake(
            requestToken: { [unowned self] in self.tokenRequests += 1 },
            sendInit: { [unowned self] token in self.inits.append(token) },
            onTokenFailed: { [unowned self] error in self.failures.append(error) }
        )
        handshake.start()
    }

    func testStartRequestsTokenOnce() {
        handshake.start()

        XCTAssertEqual(tokenRequests, 1)
    }

    func testReadyBeforeTokenSendsInitOnceTokenResolves() {
        handshake.onReady()
        XCTAssertTrue(inits.isEmpty)
        XCTAssertEqual(tokenRequests, 1)

        handshake.onTokenResult(.success("jwt"))
        XCTAssertEqual(inits, ["jwt"])
    }

    func testTokenBeforeReadySendsInitOnReady() {
        handshake.onTokenResult(.success("jwt"))
        XCTAssertTrue(inits.isEmpty)

        handshake.onReady()
        XCTAssertEqual(inits, ["jwt"])
        XCTAssertEqual(tokenRequests, 1)
    }

    func testNilTokenWithoutErrorSendsInitWithNilToken() {
        handshake.onTokenResult(.success(nil))
        handshake.onReady()

        XCTAssertEqual(inits.count, 1)
        XCTAssertNil(inits[0])
    }

    func testRepeatedReadyRequestsFreshToken() {
        handshake.onTokenResult(.success("jwt-1"))
        handshake.onReady()
        handshake.onReady()

        XCTAssertEqual(inits, ["jwt-1"])
        XCTAssertEqual(tokenRequests, 2)

        handshake.onTokenResult(.success("jwt-2"))
        XCTAssertEqual(inits, ["jwt-1", "jwt-2"])
    }

    func testReadyWhileFreshTokenInFlightDoesNotRequestAgain() {
        handshake.onTokenResult(.success("jwt-1"))
        handshake.onReady()
        handshake.onReady()
        handshake.onReady()

        XCTAssertEqual(tokenRequests, 2)

        handshake.onTokenResult(.success("jwt-2"))
        XCTAssertEqual(inits, ["jwt-1", "jwt-2"])
    }

    func testFailedFreshTokenReportsFailure() {
        handshake.onTokenResult(.success("jwt-1"))
        handshake.onReady()
        handshake.onReady()
        handshake.onTokenResult(.failure(TokenError()))
        handshake.onReady()

        XCTAssertEqual(inits, ["jwt-1"])
        XCTAssertEqual(failures.count, 1)
        XCTAssertEqual(tokenRequests, 2)
    }

    func testTokenFailureReportsAndNeverSendsInit() {
        handshake.onReady()
        handshake.onTokenResult(.failure(TokenError()))
        handshake.onReady()

        XCTAssertTrue(inits.isEmpty)
        XCTAssertEqual(failures.count, 1)
    }

    func testCancelledWhileTokenInFlightDoesNotSendInit() {
        handshake.onReady()
        handshake.cancel()
        handshake.onTokenResult(.success("jwt"))

        XCTAssertTrue(inits.isEmpty)
        XCTAssertTrue(failures.isEmpty)
    }
}
