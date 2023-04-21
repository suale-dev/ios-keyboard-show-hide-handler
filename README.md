# Keyboard show hide handler for UIKit
Hanlde your view when keyboard show or hide, make sure that your input view is visible to user.

Simple, easy to use.

# Install
Step 1: `pod repo update` if need
Step 2: Add to `Podfile`
```pod
pod 'KeyboardShowHideHandler'
```
Step 3: `pod install`


# How to use
Make your view controller conform `KeyboardHandler`, at `viewWillAppear`/`viewWillDisappear` just call `addObservingKeyboard`/`removeObservingKeyboard` to register/unregister the listener.

```swift
class ViewController: UIViewController {
  @IBOutlet var scrollView: UIScrollView!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    addObservingKeyboard()
  }

  override func viewWillDisappear(_ animated: Bool) {
    removeObservingKeyboard()
  }
}

extension ViewController: KeyboardHandler {
  var contentScrollView: UIScrollView {
    scrollView
  }
}
```

# More setting
```swift
extension ViewController: KeyboardHandler {
  var contentScrollView: UIScrollView {
    scrollView
  }

  var distanceToKeyboard: Int {
    return 10 /// distance from target input to top of keyboard
  }

  var tapAnywhereToDismissKeyboard: Bool {
    return true /// tap outside target view to dismiss keyboard
  }

  var supportViewTypes: [UIView.Type] {
    /// Which views type to apply for
    return [
      UITextField.self, UITextView.self
    ]
  }
}
```

# Demo
When keyboard is hidden\
<img src="https://raw.githubusercontent.com/suale-dev/ios-keyboard-show-hide-handler/main/Images/keyboard-hide.png" width="200">


When keyboard is showed\
<img src="https://raw.githubusercontent.com/suale-dev/ios-keyboard-show-hide-handler/main/Images/keyboard-show.png" width="200">
