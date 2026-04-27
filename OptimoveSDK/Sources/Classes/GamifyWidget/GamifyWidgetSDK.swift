// Copyright © 2024 Optimove. All rights reserved.

import UIKit

/// Entry point for the Gamify Widget SDK.
///
/// Usage:
///   GamifyWidgetSDK.initialize(widgetUrl: "https://your-widget.example.com")
///   GamifyWidgetSDK.open(from: viewController, userId: "u123")
public final class GamifyWidgetSDK {

    internal static var widgetUrl: String = ""

    private init() {}

    /// Configure the widget URL before opening.
    public static func initialize(widgetUrl: String) {
        self.widgetUrl = widgetUrl
    }

    /// Present the widget in a modal sheet.
    ///
    /// - Parameters:
    ///   - viewController: The presenting UIViewController.
    ///   - userId: Optional user ID injected via INIT handshake.
    ///   - token: Optional auth token injected via INIT handshake.
    public static func open(
        from viewController: UIViewController,
        userId: String? = nil,
        token: String? = nil
    ) {
        let vc = GamifyWidgetViewController(
            widgetUrl: widgetUrl,
            userId: userId,
            token: token
        )
        if #available(iOS 15.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
            }
        } else {
            vc.modalPresentationStyle = .pageSheet
        }
        viewController.present(vc, animated: true)
    }
}
