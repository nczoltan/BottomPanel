//
//  Interpolate+.swift
//  GinceptionPOC
//
//  Created by Szabó Zoltán on 13/11/2023.
//

import Foundation

extension Optional where Wrapped == Interpolate {
  var progress: CGFloat {
    set {
      switch self {
      case .none:
        break
      case .some(let interpolate):
        interpolate.progress = newValue
      }
    }
    get { self?.progress ?? 0 }
  }
}
