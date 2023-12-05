//
//  BottomPanel.swift
//  BottomPanel
//
//  Created by Szabó Zoltán on 13/11/2023.
//

import Foundation
import UIKit

public protocol ScrollStateObservable {
  var observedScrollView: UIScrollView { get }
}

public class BottomPanel {
  public enum PanelPosition {
    case collapsed, expanded
  }

  public enum Surface {
    case window, viewController(UIViewController)
  }

  private var window: UIWindow?
  private let panel = UIView()
  private let actionContainer = UIStackView()
  private let handle = UIView()
  private let backgroundView = UIView()
  private let container = UIView()
  private weak var content: UIViewController?
  private var panelHeight: NSLayoutConstraint!
  private weak var parentViewController: UIViewController?
  private weak var contentViewController: UIViewController?

  private let animationDuration: CGFloat = 0.25
  private let cornerRadius: CGFloat = 20
  private let handleMaxOpacity: CGFloat = 0.5
  private let handleSpaceHeight: CGFloat = 20
  private let expandingVelocity: CGFloat = 1
  private var collapsedHeight: CGFloat = 400
  private var expandedHeight: CGFloat = CGFloat(UIScreen.main.bounds.height)
  private var isExpandable = true {
    didSet {
      handle.isHidden = !isExpandable
    }
  }
  private (set) public var currentPanelPosition: PanelPosition = .collapsed {
    didSet {
      switch currentPanelPosition {
      case .collapsed:
        scrollObservation?.isDamping = isExpandable
      case .expanded:
        scrollObservation?.isDamping = false
      }
    }
  }

  private var scrollObservation: CustomScrollingBehavior?

  public var backgroundColor: UIColor? {
    get {
      backgroundView.backgroundColor
    }
    set {
      backgroundView.backgroundColor = newValue
    }
  }

  deinit {
    contentViewController?.remove()
    panel.removeFromSuperview()
    window?.resignKey()
    window = nil
  }

  public init(
    on surface: Surface,
    showing content: UIViewController,
    collapsedHeight: CGFloat = 400,
    isExpandable: Bool = true
  ) {
    self.collapsedHeight = collapsedHeight
    self.isExpandable = isExpandable
    initPanel(on: surface)
    initBackground()
    initContainer()
    initHandle()
    initActionContainer()

    panel.transform = CGAffineTransform(translationX: 0, y: panelHeight.constant)

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
    collapsedHeight: CGFloat = 400,
    isExpandable: Bool = true
  ) {
    self.collapsedHeight = collapsedHeight
    self.isExpandable = isExpandable

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
    if collapsedHeight != panelHeight.constant {
      let transition = Interpolate(
        values: [panelHeight.constant, collapsedHeight],
        function: BasicInterpolation.easeInOut,
        apply: { [weak self] (constant: CGFloat) in
          self?.panelHeight.constant = constant
          self?.adjustCornerRadius()
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
  }

  public func observeScrollView(_ scrollView: UIScrollView) {
    scrollObservation = CustomScrollingBehavior()
    scrollObservation?.scrollerDelegate = self
    scrollObservation?.scrollView = scrollView
    scrollObservation?.isDamping = isExpandable
  }

  public func show(
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    UIView.animate(
      withDuration: animated ? animationDuration : 0,
      delay: 0,
      options: .curveEaseInOut,
      animations: {
        self.panel.transform = .identity
      },
      completion: { _ in
        completion?()
      }
    )
  }

  public func hide(
    animated: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    UIView.animate(
      withDuration: animated ? animationDuration : 0,
      delay: 0,
      options: .curveEaseInOut,
      animations: {
        self.panel.transform = CGAffineTransform(translationX: 0, y: self.panelHeight.constant)
      },
      completion: { _ in
        completion?()
      }
    )
  }

  // MARK: Pan gesture on panel
  @objc private func onPanelPan(recognizer: UIPanGestureRecognizer) {
    guard isExpandable else { return }
    switch recognizer.state {
    case .changed:
      let movement = -recognizer.translation(in: recognizer.view).y
      recognizer.setTranslation(.zero, in: recognizer.view)
      _ = adjustPanelPosition(by: movement)
    case .ended, .cancelled, .failed:
      let velocity = recognizer.velocity(in: recognizer.view)
      scrollerWillEndDragging(velocity: CGPoint(x: 0, y: (-velocity.y / 1000)))
    default:
      break
    }
  }

  private func adjustPanelPosition(by movement: CGFloat) -> Bool {
    guard isExpandable else { return true }
    if heightInterpolation.progress == 1 && movement > 0 {
      return true
    }
    if heightInterpolation.progress == 0 && movement < 0 {
      return true
    }
    let step = abs(1 / (expandedHeight - collapsedHeight))
    let progress = heightInterpolation.progress + (movement * step)
    let normalizedProgress = min(max(progress, 0), 1)

    heightInterpolation.progress = normalizedProgress

    if normalizedProgress == 0 {
      currentPanelPosition = .collapsed
    } else if normalizedProgress == 1 {
      currentPanelPosition = .expanded
    }
    return false
  }

  private func adjustCornerRadius() {
    let currentHeightProgress = heightInterpolation.progress
    if currentHeightProgress <= 0.75 {
      cornerRadiuisInterpolation.progress = 0
    } else {
      cornerRadiuisInterpolation.progress = (currentHeightProgress - 0.75) * 4
    }
  }

  private func adjustActionOpacity() {
    actionOpacityInterpolation.progress = heightInterpolation.progress
  }

  private func adjusthandleOpacity() {
    handleOpacityInterpolation.progress = heightInterpolation.progress
  }

  private func snapToPredefinedPosition() {
    let isOverHalf = heightInterpolation.progress > 0.5
    heightInterpolation.animate(isOverHalf ? 1 : 0, duration: animationDuration)
  }

  // MARK: Interpolations
  private lazy var cornerRadiuisInterpolation = Interpolate(
    values: [cornerRadius, 0],
    apply: { [weak self] cornerRadius in
      self?.backgroundView.roundCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: cornerRadius)
    }
  )

  private lazy var actionOpacityInterpolation = Interpolate(
    values: [1, 0],
    function: BasicInterpolation.easeInOut,
    apply: { [weak self] opacity in
      self?.actionContainer.alpha = opacity
    }
  )

  private lazy var handleOpacityInterpolation = Interpolate(
    values: [handleMaxOpacity, 0],
    function: BasicInterpolation.easeInOut,
    apply: { [weak self] opacity in
      self?.handle.alpha = opacity
    }
  )

  private lazy var heightInterpolation: Interpolate = {
    createHeightInterpolation()
  }()

  private func createHeightInterpolation() -> Interpolate {
    Interpolate(
      values: [collapsedHeight, expandedHeight],
      function: BasicInterpolation.easeInOut,
      apply: { [weak self] (constant: CGFloat) in
        self?.panelHeight.constant = constant
        self?.adjustCornerRadius()
        self?.adjustActionOpacity()
        self?.adjusthandleOpacity()
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
    let absVelocity = abs(velocity.y)
    let flingUp = currentPanelPosition == .collapsed && velocity.y > 0
    let flingDown = currentPanelPosition == .expanded && velocity.y < 0
    guard absVelocity > 0.8, (flingUp || flingDown) else {
      snapToPredefinedPosition()
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

  func scrollerDidScroll(movement: CGFloat) -> Bool {
    adjustPanelPosition(by: movement)
  }
}

// MARK: Layout
extension BottomPanel {
  private func initPanel(on surface: Surface) {
    let parent: UIView
    switch surface {
    case .window:
      window = initWindow()
      parent = window!.rootViewController!.view
    case .viewController(let vc):
      parent = vc.view
    }
    panel.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(panel)

    panel.layer.shadowColor = UIColor.black.cgColor
    panel.layer.shadowRadius = 12
    panel.layer.shadowOpacity = 0.2
    panel.layer.shadowOffset = CGSize(width: 0, height: -2)

    panelHeight = panel.heightAnchor.constraint(equalToConstant: collapsedHeight)
    NSLayoutConstraint.activate([
      panel.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
      panel.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
      panel.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
      panelHeight
    ])

    let pan = UIPanGestureRecognizer(target: self, action: #selector(onPanelPan(recognizer:)))
    panel.addGestureRecognizer(pan)
  }

  private func initBackground() {
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.roundCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: cornerRadius)
    backgroundView.clipsToBounds = true
    panel.addSubview(backgroundView)
    backgroundView.bindFrameToSuperviewBounds()
  }

  private func initContainer() {
    container.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.addSubview(container)
    NSLayoutConstraint.activate([
      container.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
      container.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      container.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      container.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: handleSpaceHeight)
    ])
  }

  private func initWindow() -> UIWindow {
    let window = TouchThroughWindow(frame: UIScreen.main.bounds)
    window.rootViewController = TouchThroughViewController()
    window.windowLevel = .normal
    window.backgroundColor = .clear
    window.isHidden = true
    return window
  }

  private func initActionContainer() {
    actionContainer.translatesAutoresizingMaskIntoConstraints = false
    actionContainer.axis = .horizontal
    actionContainer.spacing = 12
    panel.addSubview(actionContainer)
    NSLayoutConstraint.activate([
      panel.topAnchor.constraint(equalTo: actionContainer.topAnchor, constant: 16),
      panel.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor, constant: 32)
    ])
  }

  private func initHandle() {
    handle.translatesAutoresizingMaskIntoConstraints = false
    handle.backgroundColor = .lightGray
    handle.alpha = handleMaxOpacity
    handle.clipsToBounds = true
    handle.layer.cornerRadius = 3
    panel.addSubview(handle)
    NSLayoutConstraint.activate([
      handle.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
      handle.topAnchor.constraint(equalTo: panel.topAnchor, constant: 12),
      handle.widthAnchor.constraint(equalToConstant: 36),
      handle.heightAnchor.constraint(equalToConstant: 6)
    ])
  }

  private func add(_ content: UIViewController, to surface: Surface) {
    switch surface {
    case .window:
      parentViewController = window?.rootViewController
    case .viewController(let viewController):
      parentViewController = viewController
    }
    contentViewController = content
    parentViewController?.add(content, to: container)
  }
}

