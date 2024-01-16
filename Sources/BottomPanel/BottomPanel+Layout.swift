//
//  BottomPanel+Layout.swift
//  BottomPanel
//
//  Created by Szabó Zoltán on 11/12/2023.
//

import UIKit

extension BottomPanel {

  func getParentView(on surface: Surface) -> UIView {
    let parent: UIView
    switch surface {
    case .window:
      window = initWindow()
      parent = window!.rootViewController!.view
    case .viewController(let vc):
      parent = vc.view
    }
    return parent
  }

  func initDimmingView(on parent: UIView) {
    dimmingView.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(dimmingView)
    dimmingView.alpha = 0
    dimmingView.bindFrameToSuperviewBounds()
    dimmingView.backgroundColor = .black.withAlphaComponent(0.7)
  }

  func initPanel(on parent: UIView) {
    panel.translatesAutoresizingMaskIntoConstraints = false
    parent.addSubview(panel)

    panel.layer.shadowColor = UIColor.black.cgColor
    panel.layer.shadowRadius = 12
    panel.layer.shadowOpacity = 0.2
    panel.layer.shadowOffset = CGSize(width: 0, height: -2)

    let sizeClass = UIScreen.main.traitCollection.horizontalSizeClass
    if sizeClass == .regular {
      NSLayoutConstraint.activate([
        panel.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        panel.centerXAnchor.constraint(equalTo: parent.centerXAnchor),
        panel.widthAnchor.constraint(equalToConstant: 600)
      ])
    } else  {
      NSLayoutConstraint.activate([
        panel.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
        panel.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        panel.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
      ])
    }

    let pan = UIPanGestureRecognizer(target: self, action: #selector(onPanelPan(recognizer:)))
    panel.addGestureRecognizer(pan)
    panelGestures = pan
  }

  func initBackground() {
    backgroundView.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.roundCorners(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner], radius: cornerRadius)
    backgroundView.clipsToBounds = true
    panel.addSubview(backgroundView)
    backgroundView.bindFrameToSuperviewBounds()
  }

  func initContainer(on parent: UIView) {
    container.translatesAutoresizingMaskIntoConstraints = false
    backgroundView.addSubview(container)
    containerHeight = container.heightAnchor.constraint(equalToConstant: collapsedHeight)
    containerHeight.priority = .defaultHigh
    NSLayoutConstraint.activate([
      container.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
      container.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      container.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      container.topAnchor.constraint(equalTo: backgroundView.topAnchor),
      containerHeight,
    ])
  }

  func initWindow() -> UIWindow {
    let window = TouchThroughWindow(frame: UIScreen.main.bounds)
    window.rootViewController = TouchThroughViewController()
    window.windowLevel = .normal
    window.backgroundColor = .clear
    window.isHidden = true
    return window
  }

  func initActionContainer() {
    actionContainer.translatesAutoresizingMaskIntoConstraints = false
    actionContainer.axis = .horizontal
    actionContainer.spacing = 12
    panel.addSubview(actionContainer)
    panel.innerView = actionContainer
    NSLayoutConstraint.activate([
      panel.topAnchor.constraint(equalTo: actionContainer.topAnchor, constant: 16),
      panel.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor, constant: 32)
    ])
  }

  func initHandle() {
    handle.translatesAutoresizingMaskIntoConstraints = false
    handle.backgroundColor = .lightGray
    handle.alpha = config.isExpandable || config.closingByGesture ? handleMaxOpacity : 0
    isHandleVisible = handle.alpha != 0
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

  func initCloseButton() {
    var config = UIButton.Configuration.filled()
    config.image = UIImage(systemName: "multiply")?.applyingSymbolConfiguration(.init(pointSize: 12))
    config.cornerStyle = .capsule
    config.contentInsets = .zero
    config.baseBackgroundColor = UIColor(dynamicProvider: { traitCollection in
      if traitCollection.userInterfaceStyle == .dark {
        return .gray.withAlphaComponent(0.3)
      } else {
        return .gray.withAlphaComponent(0.2)
      }
    })
    config.baseForegroundColor = UIColor(dynamicProvider: { traitCollection in
      if traitCollection.userInterfaceStyle == .dark {
        return .white
      } else {
        return .black
      }
    })

    let button = UIButton(
      configuration: config,
      primaryAction: UIAction() { [weak self] _ in
        self?.closeButtonDidPress?()
      }
    )
    button.translatesAutoresizingMaskIntoConstraints = false

    panel.addSubview(button)
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
      button.topAnchor.constraint(equalTo: panel.topAnchor, constant: 16),
      button.widthAnchor.constraint(equalToConstant: 28),
      button.heightAnchor.constraint(equalToConstant: 28)
    ])
  }

  func add(_ content: UIViewController, to surface: Surface) {
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

class TouchExtendingView: UIView {
  weak var innerView: UIView?

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    if let view = innerView, let v = view.hitTest(view.convert(point, from: self), with: event) {
      return v
    }
    return super.hitTest(point, with: event)
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    if super.point(inside: point, with: event) { return true }
    if let view = innerView {
      return !view.isHidden && view.point(inside: view.convert(point, from: self), with: event)
    }
    return false
  }
}
