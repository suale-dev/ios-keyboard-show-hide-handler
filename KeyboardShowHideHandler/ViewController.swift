//
//  ViewController.swift
//  KeyboardShowHideHandler
//
//  Created by Kem on 4/21/23.
//

import UIKit

class ViewController: UIViewController {
  @IBOutlet var scrollView: UIScrollView!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

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

  /// Optional

  var distanceToKeyboard: Int {
    return 20
  }

  var tapAnywhereToDismissKeyboard: Bool {
    return true
  }

  var supportViewTypes: [UIView.Type] {
    return [UITextField.self, UITextView.self]
  }
}

