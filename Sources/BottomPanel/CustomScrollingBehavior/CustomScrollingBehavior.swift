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
  func scrollerDidScroll(movement: CGFloat) -> Bool
}

class CustomScrollingBehavior: NSObject {

  weak var scrollerDelegate: ScrollerDelegate?
  private var isDragging = false
  private var scrollViewOffset = CGPoint.zero

  public weak var delegate: UIScrollViewDelegate? {
    didSet {
      var delegates: [UIScrollViewDelegate] = [self]
      if let delegate = delegate {
        delegates.append(delegate)
      }
      print("DelegateProxy created with \(delegates.count) delegates")
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
    isDragging = true
    scrollerDelegate?.willBeginDragging()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    isDragging = false
    scrollerDelegate?.didEndDragging()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let movement = scrollView.contentOffset.y - scrollViewOffset.y
    guard movement != 0 else { return }
    if  (isDragging) &&
          ((movement > 0 && scrollView.contentOffset.y > 0)
           || (movement < 0 && scrollView.contentOffset.y < 0)) &&
          (scrollerDelegate?.scrollerDidScroll(movement: movement)) == false {
      scrollView.contentOffset = scrollViewOffset
    } else {
      scrollViewOffset = scrollView.contentOffset
    }
  }
}
