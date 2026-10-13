//  Copyright © 2026 Optimove. All rights reserved.

import Foundation

/// Pairs the loyalty widget's READY signal with the auth token that goes into INIT.
///
/// The token request starts as soon as the widget opens so it overlaps page load; INIT is sent once READY has
/// arrived and the token has resolved, in whichever order they land. A failed token fetch ends the handshake — the
/// widget is never handed an INIT without the JWT auth requires.
final class LoyaltyInitHandshake {
    private let sendInit: (String?) -> Void
    private let onTokenFailed: (Error) -> Void

    private var readyPending = false
    private var tokenResolved = false
    private var finished = false
    private var token: String?

    init(sendInit: @escaping (String?) -> Void, onTokenFailed: @escaping (Error) -> Void) {
        self.sendInit = sendInit
        self.onTokenFailed = onTokenFailed
    }

    func onReady() {
        guard !finished else { return }
        readyPending = true
        maybeSendInit()
    }

    func onTokenResult(_ result: Result<String?, Error>) {
        guard !finished, !tokenResolved else { return }
        switch result {
        case let .success(token):
            self.token = token
            tokenResolved = true
            maybeSendInit()
        case let .failure(error):
            finished = true
            onTokenFailed(error)
        }
    }

    func cancel() {
        finished = true
    }

    private func maybeSendInit() {
        guard readyPending, tokenResolved else { return }
        readyPending = false
        sendInit(token)
    }
}
