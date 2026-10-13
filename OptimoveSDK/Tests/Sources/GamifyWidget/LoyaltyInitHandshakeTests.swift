import XCTest
@testable import OptimoveSDK

final class LoyaltyInitHandshakeTests: XCTestCase {
    private struct TokenError: Error {}

    private var inits: [String?] = []
    private var failures: [Error] = []
    private var handshake: LoyaltyInitHandshake!

    override func setUp() {
        super.setUp()
        inits = []
        failures = []
        handshake = LoyaltyInitHandshake(
            sendInit: { [unowned self] token in self.inits.append(token) },
            onTokenFailed: { [unowned self] error in self.failures.append(error) }
        )
    }

    func testReadyBeforeTokenSendsInitOnceTokenResolves() {
        handshake.onReady()
        XCTAssertTrue(inits.isEmpty)

        handshake.onTokenResult(.success("jwt"))
        XCTAssertEqual(inits, ["jwt"])
    }

    func testTokenBeforeReadySendsInitOnReady() {
        handshake.onTokenResult(.success("jwt"))
        XCTAssertTrue(inits.isEmpty)

        handshake.onReady()
        XCTAssertEqual(inits, ["jwt"])
    }

    func testNilTokenWithoutErrorSendsInitWithNilToken() {
        handshake.onTokenResult(.success(nil))
        handshake.onReady()

        XCTAssertEqual(inits.count, 1)
        XCTAssertNil(inits[0])
    }

    func testEveryReadyIsAnswered() {
        handshake.onTokenResult(.success("jwt"))
        handshake.onReady()
        handshake.onReady()

        XCTAssertEqual(inits, ["jwt", "jwt"])
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
