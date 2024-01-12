//
//  CustomScrollingBehavior.swift
//  MemberAppPOC
//
//  Created by Zoltan Szabo on 2020. 07. 18..
//  Copyright © 2020. ddits. All rights reserved.
//

import Foundation
import UIKit

protocol ScrollerDelegate: AnyObject {
  func willBeginDragging()
  func didEndDragging()
  func scrollerWillEndDragging(velocity: CGPoint)
  func scrollerDidScroll(movement: CGFloat) -> Bool
  func contentOffsetDidChange(_ offset: CGPoint)
}

class CustomScrollingBehavior: NSObject {

  weak var scrollerDelegate: ScrollerDelegate?
  var isDamping = false
  private var isCustomBehaviorActivated = false
  private var isDragging = false
  private var scrollViewOffset = CGPoint.zero

  public weak var delegate: UIScrollViewDelegate? {
    didSet {
      var delegates: [UIScrollViewDelegate] = [self]
      if let delegate = delegate {
        delegates.append(delegate)
      }
      proxy = ScrollViewDelegateProxy(delegates: delegates)
    }
  }

  private var proxy: ScrollViewDelegateProxy? {
    didSet {
      scrollView?.delegate = proxy
    }
  }

  weak var scrollView: UIScrollView? {
    didSet {
      delegate = scrollView?.delegate
    }
  }
}

extension CustomScrollingBehavior: UITableViewDelegate {}
extension CustomScrollingBehavior: UICollectionViewDelegate {}
extension CustomScrollingBehavior: UICollectionViewDelegateFlowLayout {}
extension CustomScrollingBehavior: UIScrollViewDelegate {
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y <= 0 || isDamping {
      isDragging = true
      scrollerDelegate?.willBeginDragging()
    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    isDragging = false
    isCustomBehaviorActivated = false
    scrollerDelegate?.didEndDragging()
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    scrollerDelegate?.didEndDragging()
  }

  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if isCustomBehaviorActivated {
      scrollerDelegate?.scrollerWillEndDragging(velocity: velocity)
    }

    if isDamping { targetContentOffset.pointee = scrollView.contentOffset }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let movement = scrollView.contentOffset.y - scrollViewOffset.y
    guard movement != 0 else { return }
    let notOverScroll = (movement > 0 && scrollView.contentOffset.y > 0) || (movement < 0 && scrollView.contentOffset.y < 0)
    if (isDragging) && (notOverScroll) && (scrollerDelegate?.scrollerDidScroll(movement: movement)) == false {
      isCustomBehaviorActivated = true
      scrollView.contentOffset = scrollViewOffset
    } else {
      scrollViewOffset = scrollView.contentOffset
      scrollerDelegate?.contentOffsetDidChange(scrollViewOffset)
    }
  }
}
