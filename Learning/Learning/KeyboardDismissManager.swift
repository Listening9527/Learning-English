import UIKit

final class KeyboardDismissManager: NSObject, UIGestureRecognizerDelegate {
    static let shared = KeyboardDismissManager()

    private let recognizerName = "GlobalKeyboardDismissTap"

    private override init() {
        super.init()
    }

    func installIfNeeded() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            return
        }

        for window in windowScene.windows {
            guard window.isKeyWindow else { continue }
            installRecognizerIfNeeded(on: window)
        }
    }

    private func installRecognizerIfNeeded(on window: UIWindow) {
        let hasInstalled = window.gestureRecognizers?.contains(where: { $0.name == recognizerName }) ?? false
        guard !hasInstalled else { return }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.name = recognizerName
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
    }

    @objc
    private func handleTap(_ gesture: UITapGestureRecognizer) {
        gesture.view?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }

        if touchedView.nearestSuperview(of: UITextField.self) != nil {
            return false
        }

        if touchedView.nearestSuperview(of: UITextView.self) != nil {
            return false
        }

        if touchedView.nearestSuperview(of: UIControl.self) != nil {
            return false
        }

        return true
    }
}

private extension UIView {
    func nearestSuperview<T: UIView>(of type: T.Type) -> T? {
        var node: UIView? = self
        while let current = node {
            if let casted = current as? T {
                return casted
            }
            node = current.superview
        }
        return nil
    }
}
