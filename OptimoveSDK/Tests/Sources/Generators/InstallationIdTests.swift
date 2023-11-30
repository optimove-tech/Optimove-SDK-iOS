//  Copyright © 2020 Optimove. All rights reserved.

@testable import OptimoveSDK
import XCTest

final class InstallationIdTests: OptimoveTestCase {
    var generator: InstallationIdGenerator!

    override func setUp() {
        generator = InstallationIdGenerator(storage: storage)
    }

    func test_installation_generation_on_the_first_launch() {
        // given
        prefillStorageWithConfiguration()

        // then
        let installationIdExpectation = expectation(description: "SetInstallationId was not generated.")
        storage.assertFunction = { _, key in
            if key == .installationID {
                installationIdExpectation.fulfill()
            }
        }

        // when
        generator.generate()

        wait(
            for: [
                installationIdExpectation,
            ],
            timeout: defaultTimeout
        )
    }

    func test_installation_generation_on_an_update_from_old_version() {
        // given
        prefillStorageWithConfiguration()
        storage.initialVisitorId = StubConstants.initialVisitorId

        // then
        let installationIdExpectation = expectation(description: "SetInstallationId was not generated.")
        storage.assertFunction = { _, key in
            if key == .installationID {
                installationIdExpectation.fulfill()
            }
        }

        // when
        generator.generate()

        wait(
            for: [
                installationIdExpectation,
            ],
            timeout: defaultTimeout
        )
    }

    func test_installation_generation_on_an_update() {
        // given
        prefillStorageAsVisitor()

        // then
        let installationIdExpectation = expectation(description: "SetInstallationId was not generated.")
        installationIdExpectation.isInverted.toggle()
        storage.assertFunction = { _, key in
            if key == .installationID {
                installationIdExpectation.fulfill()
            }
        }

        // when
        generator.generate()

        wait(
            for: [
                installationIdExpectation,
            ],
            timeout: defaultTimeout
        )
    }
}
