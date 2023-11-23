//
//  UIViewControllerExtensions.swift
//  GinceptionPOC
//
//  Created by Szabó Zoltán on 12/11/2023.
//

import Foundation
import UIKit

extension UIViewController {
  func add(_ child: UIViewController, to container: UIView) {
    child.view.translatesAutoresizingMaskIntoConstraints = false
    child.view.frame = container.bounds
    addChild(child)
    container.addSubview(child.view)
    child.view.bindFrameToSuperviewBounds()
    child.didMove(toParent: self)
  }

  func remove() {
    guard parent != nil else {
      return
    }

    willMove(toParent: nil)
    view.removeFromSuperview()
    removeFromParent()
  }

  func replace(
    child: UIViewController,
    to new: UIViewController,
    in container: UIView,
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    child.willMove(toParent: nil)
    new.view.translatesAutoresizingMaskIntoConstraints = true
    new.view.frame = container.bounds

    addChild(new)

    if animated {
      new.view.alpha = 0
      container.insertSubview(new.view, belowSubview: child.view)
    } else {
      container.addSubview(new.view)
      child.view.removeFromSuperview()
      child.removeFromParent()
      new.didMove(toParent: self)
    }
    new.view.bindFrameToSuperviewBounds()

    if animated {
      UIView.animate(
        withDuration: 0.3,
        animations: {
          new.view.alpha = 1
          child.view.alpha = 0
        },
        completion: { _ in
          child.view.removeFromSuperview()
          child.removeFromParent()
          new.didMove(toParent: self)
          completion?()
        }
      )
    }
  }
}
