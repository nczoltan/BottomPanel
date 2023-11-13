//
//  ScrollViewDelegateProxy.swift
//  MemberAppPOC
//
//  Created by Zoltan Szabo on 2020. 07. 18..
//  Copyright © 2020. ddits. All rights reserved.
//

import Foundation
import UIKit
import DelegateProxy

class ScrollViewDelegateProxy: DelegateProxy, UIScrollViewDelegate {
  @nonobjc convenience init(delegates: [UIScrollViewDelegate]) {
    self.init(__delegates: delegates)
  }
}
