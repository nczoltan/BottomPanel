//
//  BottomPanel+Config.swift
//  BottomPanel
//
//  Created by Szabó Zoltán on 11/12/2023.
//

import Foundation

public extension BottomPanel {
  struct Config {
    public var collapsedHeight: CGFloat
    public var isExpandable: Bool
    public var closingByGesture: Bool
    public var backgroundDimmingOnCollapsedState: Bool

    public init(
      collapsedHeight: CGFloat = 400,
      isExpandable: Bool = true,
      closingByGesture: Bool = true,
      backgroundDimmingOnCollapsedState: Bool = false
    ) {
      self.collapsedHeight = collapsedHeight
      self.isExpandable = isExpandable
      self.closingByGesture = closingByGesture
      self.backgroundDimmingOnCollapsedState = backgroundDimmingOnCollapsedState
    }
  }
}
