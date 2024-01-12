//
//  BottomPanel.swift
//  BottomPanel
//
//  Created by Szabó Zoltán on 13/11/2023.
//

import Foundation
import UIKit

public class BottomPanel {
  var window: UIWindow?
  let panel = UIView()
  let actionContainer = UIStackView()
  let handle = UIView()
  let backgroundView = UIView()
  let container = UIView()
  let dimmingView = UIView()
  var containerHeight: NSLayoutConstraint!
  weak var parentViewController: UIViewController?
  weak var contentViewController: UIViewController?

  let animationDuration: CGFloat = 0.25
  let cornerRadius: CGFloat = 20
  let handleMaxOpacity: CGFloat = 0.5
  let handleSpaceHeight: CGFloat = 20
  let expandingVelocity: CGFloat = 1

  var collapsedHeight: CGFloat { config.collapsedHeight - handleSpaceHeight }
  var expandedHeight: CGFloat {
    var height = CGFloat(UIScreen.main.bounds.height) - handleSpaceHeight
    if let safeAreaInsets = backgroundView.window?.safeAreaInsets {
      height -= safeAreaInsets.top
    }
    return height
  }
  var isClosing: Bool { closeInterpolation.progress != 0 }

  var config: BottomPanel.Config = Config() {
    didSet {
      handle.alpha = config.isExpandable || config.closingByGesture ? handleMaxOpacity : 0
    }
  }
  internal (set) public var currentPanelPosition: PanelPosition = .collapsed {
    didSet {
      switch currentPanelPosition {
      case .collapsed:
        dimmingView.alpha = config.backgroundDimmingOnCollapsedState ? 1 : 0
        scrollObservation?.isDamping = config.isExpandable
      case .expanded:
        dimmingView.alpha = 1
        scrollObservation?.isDamping = false
      }
    }
  }
  public var onClosedWithGesture: (() -> Void)?

  private var scrollObservation: CustomScrollingBehavior?

  public var backgroundColor: UIColor? {
    get {
      backgroundView.backgroundColor
    }
    set {
      backgroundView.backgroundColor = newValue
      container.backgroundColor = newValue
    }
  }

  deinit {
    contentViewController?.remove()
    dimmingView.removeFromSuperview()
    panel.removeFromSuperview()
    window?.resignKey()
    window = nil
  }

  public init(
    on surface: Surface,
    showing content: UIViewController,
    config: Config = Config()
  ) {
    self.config = config
    let parentView = getParentView(on: surface)
    initDimmingView(on: parentView)
    initPanel(on: parentView)
    initBackground()
    initContainer(on: parentView)
    initHandle()
    initActionContainer()

    // in case the surface is a winddow
    window?.layoutIfNeeded()
    window?.isHidden = false

    add(content, to: surface)

    if let scrollStateObservable = content as? ScrollStateObservable {
      observeScrollView(scrollStateObservable.observedScrollView)
    }
  }

  public func replace(
    content newContent: UIViewController,
    config: Config = Config()
  ) {
    self.config = config
    newContent.view.backgroundColor = backgroundColor

    guard let contentViewController else { return }
    parentViewController?.replace(
      child: contentViewController,
      to: newContent,
      in: container
    )
    self.contentViewController = newContent
    if let scrollStateObservable = newContent as? ScrollStateObservable {
      observeScrollView(scrollStateObservable.observedScrollView)
    }
    heightInterpolation = createHeightInterpolation()
    currentPanelPosition = .collapsed
    if collapsedHeight != containerHeight.constant {
      let transition = Interpolate(
        values: [containerHeight.constant, collapsedHeight],
        function: BasicInterpolation.linear,
        apply: { [weak self] (constant: CGFloat) in
          self?.containerHeight.constant = constant
          self?.adjustDimmingViewAlpha()
          self?.panel.updateConstraints()
        }
      )
      transition.animate(1, duration: animationDuration)
    }
  }

  public func setAction(_ button: UIButton?) {
    actionContainer.arrangedSubviews.forEach { actionContainer.removeArrangedSubview($0) }
    actionContainer.subviews.forEach { $0.removeFromSuperview() }
    if let button {
      actionContainer.addArrangedSubview(button)
      button.layer.shadowColor = UIColor.black.cgColor
      button.layer.shadowRadius = 12
      button.layer.shadowOpacity = 0.2
      button.layer.shadowOffset = CGSize(width: 0, height: -2)
    }
    actionContainer.alpha = 1
  }

  public func observeScrollView(_ scrollView: UIScrollView) {
    scrollObservation = CustomScrollingBehavior()
    scrollObservation?.scrollerDelegate = self
    scrollObservation?.scrollView = scrollView
    scrollObservation?.isDamping = config.isExpandable || config.closingByGesture
  }

  public func show(
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    panel.setNeedsLayout()
    panel.layoutIfNeeded()
    closeInterpolation.progress = 1
    closeInterpolation.animate(0, duration: animated ? animationDuration : 0) {
      completion?()
    }
  }

  public func hide(
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    closeInterpolation.animate(1, duration: animated ? animationDuration : 0) {
      completion?()
    }
  }

  // MARK: Adjusting interpolator's progress
  private func adjustDimmingViewAlpha() {
    if isClosing && config.backgroundDimmingOnCollapsedState {
      let currentCloseProgress = closeInterpolation.progress
      dimmingView.alpha = config.backgroundDimmingOnCollapsedState ? (1 - (1 * currentCloseProgress)) : 0
    } else {
      let currentHeightProgress = heightInterpolation.progress
      dimmingView.alpha = config.backgroundDimmingOnCollapsedState ? 1 : (1 * currentHeightProgress)
    }
  }

  private func adjusthandleOpacity() {
    handleOpacityInterpolation.progress = heightInterpolation.progress
  }

  // MARK: Interpolations
  private lazy var handleOpacityInterpolation = Interpolate(
    values: [handleMaxOpacity, 0],
    function: BasicInterpolation.linear,
    apply: { [weak self] opacity in
      self?.handle.alpha = opacity
    }
  )

  private lazy var closeInterpolation: Interpolate = {
    createCloseInterpolation()
  }()

  private func createCloseInterpolation() -> Interpolate {
    Interpolate(
      values: [0, panel.bounds.height],
      function: BasicInterpolation.linear,
      apply: { [weak self] (translation: CGFloat) in
        self?.adjustDimmingViewAlpha()
        self?.panel.transform = CGAffineTransform(translationX: 0, y: translation)
      }
    )
  }

  private lazy var heightInterpolation: Interpolate = {
    createHeightInterpolation()
  }()

  private func createHeightInterpolation() -> Interpolate {
    Interpolate(
      values: [collapsedHeight, expandedHeight],
      function: BasicInterpolation.linear,
      apply: { [weak self] (constant: CGFloat) in
        self?.containerHeight.constant = constant
        self?.adjustDimmingViewAlpha()
        // self?.adjusthandleOpacity()
        if self?.heightInterpolation.progress == 0 {
          self?.currentPanelPosition = .collapsed
        } else if self?.heightInterpolation.progress == 1 {
          self?.currentPanelPosition = .expanded
        }
        self?.panel.updateConstraints()
      }
    )
  }
}


// MARK: ScrollerDelegate
extension BottomPanel: ScrollerDelegate {
  func willBeginDragging() {}

  func didEndDragging() {}

  func scrollerWillEndDragging(velocity: CGPoint) {
    if isClosing {
      closingWillEndDragging(velocity: velocity)
    } else {
      draggingPanelWillEnd(velocity: velocity)
    }
  }

  func scrollerDidScroll(movement: CGFloat) -> Bool {
    return adjustPanelPosition(by: movement)
  }
}

// MARK: Pan gesture on panel
extension BottomPanel {
  @objc func onPanelPan(recognizer: UIPanGestureRecognizer) {
    guard config.isExpandable || config.closingByGesture else { return }
    switch recognizer.state {
    case .changed:
      let movement = -recognizer.translation(in: recognizer.view).y
      recognizer.setTranslation(.zero, in: recognizer.view)
      _ = adjustPanelPosition(by: movement)
    case .ended, .cancelled, .failed:
      let velocity = recognizer.velocity(in: recognizer.view)
      let velocityPoint = CGPoint(x: 0, y: (-velocity.y / 1000))
      if isClosing {
        closingWillEndDragging(velocity: velocityPoint)
      } else if config.isExpandable {
        draggingPanelWillEnd(velocity: velocityPoint)
      }
    default:
      break
    }
  }

  func adjustPanelPosition(by movement: CGFloat) -> Bool {
    if heightInterpolation.progress == 1 && movement > 0 {
      return true
    }
    if (heightInterpolation.progress == 0 && movement < 0) || isClosing {
      if config.closingByGesture {
        controlCloseInterpolation(by: movement)
        return false
      }
      return true
    }
    if config.isExpandable {
      controlHeightInterpolation(by: movement)
      return false
    }
    return true
  }

  func closingWillEndDragging(velocity: CGPoint) {
    let absVelocity = abs(velocity.y)
    closeInterpolation.stopAnimation()
    if absVelocity < 0.8, closeInterpolation.progress < 0.5 {
      closeInterpolation.animate(0, duration: animationDuration)
    } else {
      closeInterpolation.animate(1, duration: animationDuration) { [weak self] in
        self?.onClosedWithGesture?()
      }
    }
  }

  func draggingPanelWillEnd(velocity: CGPoint) {
    let absVelocity = abs(velocity.y)
    let flingUp = currentPanelPosition == .collapsed && velocity.y > 0
    let flingDown = currentPanelPosition == .expanded && velocity.y < 0
    guard absVelocity > 0.8, (flingUp || flingDown) else {
      let isOverHalf = heightInterpolation.progress > 0.5
      heightInterpolation.animate(isOverHalf ? 1 : 0, duration: animationDuration)
      return
    }
    heightInterpolation.stopAnimation()
    switch currentPanelPosition {
    case .collapsed:
      heightInterpolation.animate(1, duration: animationDuration)
    case .expanded:
      heightInterpolation.animate(0, duration: animationDuration)
    }
  }

  func controlCloseInterpolation(by movement: CGFloat) {
    let step = abs(1 / panel.bounds.height)
    let progress = closeInterpolation.progress + (-movement * step)
    let normalizedProgress = min(max(progress, 0), 1)
    closeInterpolation.progress = normalizedProgress
  }

  func controlHeightInterpolation(by movement: CGFloat) {
    let step = abs(1 / (expandedHeight - collapsedHeight))
    let progress = heightInterpolation.progress + (movement * step)
    let normalizedProgress = min(max(progress, 0), 1)

    heightInterpolation.progress = normalizedProgress
    if normalizedProgress == 0 {
      currentPanelPosition = .collapsed
    } else if normalizedProgress == 1 {
      currentPanelPosition = .expanded
    }
  }
}
