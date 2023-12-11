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
      panel.topAnchor.constraint(greaterThanOrEqualTo: parent.topAnchor),
      container.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
      container.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
      container.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
      container.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: handleSpaceHeight),
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
    NSLayoutConstraint.activate([
      panel.topAnchor.constraint(equalTo: actionContainer.topAnchor, constant: 16),
      panel.trailingAnchor.constraint(equalTo: actionContainer.trailingAnchor, constant: 32)
    ])
  }

  func initHandle() {
    handle.translatesAutoresizingMaskIntoConstraints = false
    handle.backgroundColor = .lightGray
    handle.alpha = config.isExpandable || config.closingByGesture ? handleMaxOpacity : 0
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
