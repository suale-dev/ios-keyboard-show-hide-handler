//
//  KeyboardHandler.swift
//  KeyboardShowHideHandler
//
//  Created by Sua Le on 4/21/23.
//

import Foundation
import UIKit

/// Protocol to have default handle keyboard show or hide
public protocol KeyboardHandler where Self: UIViewController {
  /// Handle keyboard show/hide for these support types.
  /// Default is `[UITextField.self, UITextView.self]`
  var supportViewTypes: [UIView.Type] { get }

  /// scrollView contains everything of ViewController as you conform this protocol
  var contentScrollView: UIScrollView { get }

  /// Distance between `bottomAnchor` of `input view` and `topAnchor` of keyboard. Default is `10`
  var distanceToKeyboard: Int { get }

  /// Tap outside of `supportViewTypes` will dimiss `keyboard`, default is `true`
  var tapAnywhereToDismissKeyboard: Bool { get }

  /// Just leave this method with default implements. Must call from `viewWillAppear`
  func addObservingKeyboard()

  /// Just leave this method with default implements. Must call from `viewWillDisappear`
  func removeObservingKeyboard()
}

/// Default implement
extension KeyboardHandler {
  private var keyboardManager: KeyboardManager {
    var keyboardManager = view.layer.value(forKey: KeyboardManager.instanceKey) as? KeyboardManager
    if nil == keyboardManager {
      keyboardManager = KeyboardManager(
        contentView: view,
        scrollView: contentScrollView,
        supportViewTypes: supportViewTypes,
        distanceToKeyboard: distanceToKeyboard,
        tapAnywhereToDismissKeyboard: tapAnywhereToDismissKeyboard)
      view.layer.setValue(keyboardManager, forKey: KeyboardManager.instanceKey)
    }
    return keyboardManager!
  }

  public var supportViewTypes: [UIView.Type] {
    return [UITextField.self, UITextView.self]
  }

  public var distanceToKeyboard: Int {
    return 10
  }

  public var tapAnywhereToDismissKeyboard: Bool {
    return true
  }

  public func addObservingKeyboard() {
    keyboardManager.addObservingKeyboard()
  }

  public func removeObservingKeyboard() {
    keyboardManager.removeObservingKeyboard()
  }
}


fileprivate class KeyboardManager: NSObject {
  static var instanceKey = "@KeyboardManager@"
  private weak var scrollView: UIScrollView?
  private weak var contentView: UIView?
  private let supportViewTypes: [UIView.Type]
  private var distanceToKeyboard: Int
  private let tapGesture: UITapGestureRecognizer
  private let tapAnywhereToDismissKeyboard: Bool

  private let originScrollViewContentInsetBottom: CGFloat

  private let visibleFrameHeightMin: CGFloat = 20

  init(
    contentView: UIView,
    scrollView: UIScrollView,
    supportViewTypes: [UIView.Type],
    distanceToKeyboard: Int,
    tapAnywhereToDismissKeyboard: Bool) {
      self.scrollView = scrollView
      self.contentView = contentView
      originScrollViewContentInsetBottom = scrollView.contentInset.bottom
      self.supportViewTypes = supportViewTypes
      self.distanceToKeyboard = distanceToKeyboard
      self.tapAnywhereToDismissKeyboard = tapAnywhereToDismissKeyboard

      tapGesture = UITapGestureRecognizer()
      tapGesture.cancelsTouchesInView = false
    }

  func addObservingKeyboard() {
    if tapAnywhereToDismissKeyboard {
      tapGesture.delegate = self
      contentView?.addGestureRecognizer(tapGesture)
    }

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillChangeFrame(_:)),
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(keyboardWillHide(_:)),
      name: UIResponder.keyboardWillHideNotification,
      object: nil)
  }

  func removeObservingKeyboard() {
    if tapAnywhereToDismissKeyboard {
      tapGesture.delegate = nil
      contentView?.removeGestureRecognizer(tapGesture)
    }
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardWillChangeFrameNotification,
      object: nil)
    NotificationCenter.default.removeObserver(
      self,
      name: UIResponder.keyboardWillHideNotification,
      object: nil)
  }

  @objc dynamic func keyboardWillChangeFrame(_ notification: Notification) {
    guard
      let window = UIApplication.shared.mainWindow,
      let contentView = contentView,
      let scrollView = scrollView,
      let focusView = UIResponder.currentFirstResponder as? UIView,
      nil != supportViewTypes.firstIndex(where: { focusView.isKind(of: $0) })
    else { return }

    // We will transform all frames to `contentView` coordinates to calculate
    var visibleFrame = contentView.frame
    var focusFrame = contentView.convert(focusView.frame, from: focusView.superview)

    let scrollFrame = contentView.convert(scrollView.frame, from: scrollView.superview)

    let safeAreaInsetBottom = window.safeAreaInsets.bottom

    // Adjust `focusFrame` with `distanceToKeyboard`
    focusFrame.size.height += CGFloat(distanceToKeyboard)

    var contentOffset = scrollView.contentOffset
    var contentInset = scrollView.contentInset

    Self.keyboardAnimation(from: notification) { [weak self] keyboardFrame in
      guard let self = self else { return }
      // Transform `keyboardFrame` to `contentView` coordinate
      let keyboardFrameInContentView = contentView.convert(keyboardFrame, from: window)

      // Update visible frame
      visibleFrame.size.height = keyboardFrameInContentView.minY
      if visibleFrame.size.height < self.visibleFrameHeightMin {
        return
      }

      let scrollViewIsOverlappedHeight = scrollFrame.maxY - keyboardFrameInContentView.minY

      // Adjust `contentInset` for overlapped area
      contentInset.bottom = self.originScrollViewContentInsetBottom
      + scrollViewIsOverlappedHeight
      // `contentInset` should ignore `safeAreaInsetBottom`
      - safeAreaInsetBottom
      // Add `distanceToKeyboard` to `contentInset`
      + CGFloat(self.distanceToKeyboard)

      scrollView.contentInset = contentInset
      scrollView.scrollIndicatorInsets = contentInset

      if visibleFrame.contains(focusFrame) {
        return
      }

      // Adjust `contentOffset.y` to move `focusView` to visible frame (for UITextView)
      let focusViewIsOverlappedHeight = focusFrame.maxY - visibleFrame.maxY
      contentOffset.y += focusViewIsOverlappedHeight

      scrollView.contentOffset = contentOffset
    }
  }

  @objc dynamic func keyboardWillHide(_ notification: Notification) {
    guard let scrollView = scrollView else { return }
    var contentInset = scrollView.contentInset
    contentInset.bottom = self.originScrollViewContentInsetBottom
    scrollView.contentInset = contentInset
  }

  deinit {
    removeObservingKeyboard()
  }

  static func keyboardAnimation(
    from notification: Notification,
    animations: @escaping (CGRect) -> Void
  ) {
    let frameKey = UIResponder.keyboardFrameEndUserInfoKey
    let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
    let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey

    guard
      let frame = (notification.userInfo?[frameKey] as? NSValue)?.cgRectValue,
      let duration = notification.userInfo?[durationKey] as? Double,
      let curve = notification.userInfo?[curveKey] as? UInt
    else {
      animations(.zero)
      return
    }

    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: UIView.AnimationOptions(rawValue: curve),
      animations: { animations(frame) })
  }
}

fileprivate extension UIResponder {
  private weak static var _currentFirstResponder: UIResponder?
  static var currentFirstResponder: UIResponder? {
    Self._currentFirstResponder = nil
    UIApplication.shared.sendAction(
      #selector(findFirstResponder(sender:)),
      to: nil,
      from: nil,
      for: nil)
    return Self._currentFirstResponder
  }

  @objc func findFirstResponder(sender: AnyObject) {
    Self._currentFirstResponder = self
  }
}

extension KeyboardManager: UIGestureRecognizerDelegate {
  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldReceive touch: UITouch) -> Bool {
      guard
        let focusView = UIResponder.currentFirstResponder as? UIView,
        nil != supportViewTypes.firstIndex(where: { focusView.isKind(of: $0) }),
        let touchView = touch.view,
        nil == supportViewTypes.firstIndex(where: { touchView.isKind(of: $0) })
      else { return true }
      UIResponder.currentFirstResponder?.resignFirstResponder()
      return true
    }
}

fileprivate extension UIApplication {
  var mainWindow: UIWindow? {
    // Get connected scenes
    // swiftlint:disable first_where
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
      // Keep only active scenes, onscreen and visible to the user
        .filter { $0.activationState == .foregroundActive }
      // Keep only the first `UIWindowScene`
        .first(where: { $0 is UIWindowScene })
      // Get its associated windows
        .flatMap({ $0 as? UIWindowScene })?.windows
      // Finally, keep only the key window
        .first(where: \.isKeyWindow)
    } else {
      return UIApplication.shared.keyWindow
    }
  }
}
