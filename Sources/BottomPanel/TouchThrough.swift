//
//  TouchThrough.swift
//  GinceptionPOC
//
//  Created by Szabó Zoltán on 13/11/2023.
//

import Foundation
import UIKit

class TouchThroughWindow: UIWindow {
  override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)
    return view != self ? view: nil
  }
}

class TouchThroughViewController: UIViewController {
  override var prefersStatusBarHidden: Bool {
    view.window?.windowScene?.statusBarManager?.isStatusBarHidden ?? false
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    view.window?.windowScene?.statusBarManager?.statusBarStyle ?? .default
  }

  override func loadView() {
    view = TouchThroughView()
  }
}

class TouchThroughView: UIView {
  override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let view = super.hitTest(point, with: event)
    return view != self ? view: nil
  }
}
