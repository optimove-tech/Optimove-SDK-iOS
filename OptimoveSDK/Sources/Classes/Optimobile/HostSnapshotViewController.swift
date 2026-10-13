//  Copyright © 2026 Optimove. All rights reserved.

import UIKit

/// Root view controller for SDK-owned windows (in-app, overlay messaging).
/// Stands in for the host app's top view controller as it was when the window
/// was created, answering UIKit with the host's settings instead of defaults.
/// Currently carries over supported orientations only.
final class HostSnapshotViewController: UIViewController {
    private let hostOrientations: UIInterfaceOrientationMask?

    /// - Parameter window: the SDK window this controller will be root of; must not be visible yet.
    init(for window: UIWindow) {
        hostOrientations = HostSnapshotViewController.hostOrientations(for: window)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return hostOrientations ?? super.supportedInterfaceOrientations
    }

    private static func hostOrientations(for window: UIWindow) -> UIInterfaceOrientationMask? {
        var windows = UIApplication.shared.windows
        if #available(iOS 13.0, *), let scene = window.windowScene {
            windows = scene.windows
        }
        
        windows = windows.filter { $0 !== window }

        // Not the key window: other SDKs' popups often take key. Staying below .alert
        // skips those and system windows; a wrong pick here is usually a plain overlay
        // whose defaults match pre-existing behaviour.
        let hostWindow = windows
            .filter { !$0.isHidden && $0.windowLevel < .alert && $0.rootViewController != nil }
            .max { $0.windowLevel.rawValue < $1.windowLevel.rawValue }

        var top = hostWindow?.rootViewController
        // Stop before a VC that is going away; its orientations are about to stop applying.
        while let presented = top?.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        guard let orientations = top?.supportedInterfaceOrientations else {
            return nil
        }

        // UIKit throws if a window's root VC and the app (Info.plist / app delegate)
        // share no orientation; keep UIKit defaults rather than risk it.
        let appOrientations = UIApplication.shared.supportedInterfaceOrientations(for: window)
        if orientations.intersection(appOrientations).isEmpty {
            return nil
        }
        return orientations
    }
}
