//
//  UIButton+Blur.swift
//
//
//  Created by Szabó Zoltán on 15/01/2024.
//

import UIKit

extension UIButton {
  func addBlurEffect(
    style: UIBlurEffect.Style = .regular,
    padding: CGFloat = 0
  ) {
    backgroundColor = .clear
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: style))
    blurView.isUserInteractionEnabled = false
    blurView.backgroundColor = .clear
    self.insertSubview(blurView, at: 0)

    blurView.translatesAutoresizingMaskIntoConstraints = false
    self.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: padding).isActive = true
    self.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -padding).isActive = true
    self.topAnchor.constraint(equalTo: blurView.topAnchor, constant: padding).isActive = true
    self.bottomAnchor.constraint(equalTo: blurView.bottomAnchor, constant: -padding).isActive = true

    if let imageView = self.imageView {
      imageView.backgroundColor = .clear
      self.bringSubviewToFront(imageView)
    }
  }
}
