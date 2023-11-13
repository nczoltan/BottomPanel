//
//  UIViewExtensions.swift
//  GinceptionPOC
//
//  Created by Szabó Zoltán on 13/11/2023.
//

import Foundation
import UIKit

extension UIView {
  func roundCorners(corners: CACornerMask, radius: CGFloat) {
    clipsToBounds = true
    layer.cornerRadius = radius
    layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
  }
  
  func bindFrameToSuperviewBounds() {
    guard let superview = self.superview else {
      return
    }
    
    translatesAutoresizingMaskIntoConstraints = false
    topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
    bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: 0).isActive = true
    leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0).isActive = true
    trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0).isActive = true
  }
}
