//
//  Keyboard+LayoutGuide.swift
//  KeyboardLayoutGuide
//
//  Created by Sacha DSO on 14/11/2017.
//  Copyright © 2017 freshos. All rights reserved.
//

import UIKit

internal class Keyboard {
    static let shared = Keyboard()
    var currentHeight: CGFloat = 0
}

extension UIView {
    private enum Identifiers {
        static var usingSafeArea = "KeyboardLayoutGuideUsingSafeArea"
        static var notUsingSafeArea = "KeyboardLayoutGuideNotUsingSafeArea"
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard or the bottom of safe area.
    public var keyboardLayoutGuideSafeArea: UILayoutGuide {
        getOrCreateKeyboardLayoutGuide(identifier: Identifiers.usingSafeArea, usesSafeArea: true)
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard or the bottom of the view.
    public var keyboardLayoutGuideNoSafeArea: UILayoutGuide {
        getOrCreateKeyboardLayoutGuide(identifier: Identifiers.notUsingSafeArea, usesSafeArea: false)
    }

    private func getOrCreateKeyboardLayoutGuide(identifier: String, usesSafeArea: Bool) -> UILayoutGuide {
        if let existing = layoutGuides.first(where: { $0.identifier == identifier }) {
            return existing
        }
        let new = KeyboardLayoutGuide()
        new.usesSafeArea = usesSafeArea
        new.identifier = identifier
        addLayoutGuide(new)
        new.setUp()
        return new
    }
}

public final class KeyboardLayoutGuide: UILayoutGuide {
    public var usesSafeArea = true {
        didSet {
            updateBottomAnchor()
        }
    }

    private var bottomConstraint: NSLayoutConstraint?

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        super.init()
        // Observe keyboardWillChangeFrame notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustKeyboard(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        // Observe keyboardWillHide notifications
        notificationCenter.addObserver(
            self,
            selector: #selector(adjustKeyboard(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    internal func setUp() {
        guard let view = owningView else { return }
        NSLayoutConstraint.activate(
            [
                heightAnchor.constraint(equalToConstant: Keyboard.shared.currentHeight),
                leftAnchor.constraint(equalTo: view.leftAnchor),
                rightAnchor.constraint(equalTo: view.rightAnchor),
            ]
        )
        updateBottomAnchor()
    }

    func updateBottomAnchor() {
        if let bottomConstraint = bottomConstraint {
            bottomConstraint.isActive = false
        }

        guard let view = owningView else { return }

        let viewBottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11.0, *), usesSafeArea {
            viewBottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            viewBottomAnchor = view.bottomAnchor
        }

        bottomConstraint = bottomAnchor.constraint(equalTo: viewBottomAnchor)
        bottomConstraint?.isActive = true
    }

    @objc
    private func adjustKeyboard(_ note: Notification) {
        guard var height = note.keyboardHeight, let duration = note.animationDuration else { return }

        if #available(iOS 11.0, *), usesSafeArea, height > 0, let bottom = owningView?.safeAreaInsets.bottom {
            height -= bottom
        }
        heightConstraint?.constant = height
        if duration > 0.0 {
            animate(note)
        }
        Keyboard.shared.currentHeight = height
    }

    private func animate(_ note: Notification) {
        if let owningView = owningView, isVisible(view: owningView) {
            owningView.layoutIfNeeded()
        } else {
            UIView.performWithoutAnimation {
                owningView?.layoutIfNeeded()
            }
        }
    }
}

// MARK: - Helpers

internal extension UILayoutGuide {
    var heightConstraint: NSLayoutConstraint? {
        owningView?.constraints.first {
            $0.firstItem as? UILayoutGuide == self && $0.firstAttribute == .height
        }
    }
}

private extension Notification {
    var keyboardHeight: CGFloat? {
        guard let keyboardEndFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return nil
        }

        let keyboardMinY = keyboardEndFrame.minY
        let screenBounds = UIApplication.shared.activeWindow?.bounds ?? UIScreen.main.bounds
        let isKeyboardFloating: Bool = {
            !(screenBounds.maxX == keyboardEndFrame.maxX &&
                screenBounds.maxY == keyboardEndFrame.maxY &&
                screenBounds.width == keyboardEndFrame.width)
        }()

        return isKeyboardFloating ?
            0 :
            screenBounds.height - keyboardMinY
    }

    var animationDuration: CGFloat? {
        self.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? CGFloat
    }
}

// Credits to John Gibb for this nice helper :)
// https://stackoverflow.com/questions/1536923/determine-if-uiview-is-visible-to-the-user
private func isVisible(view: UIView) -> Bool {
    func isVisible(view: UIView, inView: UIView?) -> Bool {
        guard let inView = inView else { return true }
        let viewFrame = inView.convert(view.bounds, from: view)
        if viewFrame.intersects(inView.bounds) {
            return isVisible(view: view, inView: inView.superview)
        }
        return false
    }
    return isVisible(view: view, inView: view.superview)
}

extension UIApplication {
    // Finds the currently active window, This works similar to the
    // deprecated `keyWindow` however it supports multi-window'd
    // iPad apps
    var activeWindow: UIWindow? {
        if #available(iOS 13, *) {
            return connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .map { $0 as? UIWindowScene }
                .compactMap { $0 }
                .first?.windows
                .first { $0.isKeyWindow }
        } else {
            return keyWindow
        }
    }
}
