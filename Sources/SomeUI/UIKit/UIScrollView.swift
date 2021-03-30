#if os(iOS)
//
//  UIScrollView.swift
//  SomeUI
//
//  Created by Димасик on 5/9/18.
//  Copyright © 2018 Димасик. All rights reserved.
//

import UIKit

open class UIScrollView2: UIScrollView {
  public init() {
    super.init(frame: .zero)
    ios11()
  }
  public override init(frame: CGRect) {
    super.init(frame: frame)
    ios11()
  }
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  func ios11() {
    if #available(iOS 11.0, *) {
      contentInsetAdjustmentBehavior = .never
    }
  }
}

public extension UIScrollView {
  var offsetTop: CGFloat {
    return contentOffset.y + contentInset.top
  }
  var bottomOffset: CGFloat { contentOffset.y + frame.size.height }
  var rightOffset: CGFloat { contentOffset.x + frame.size.width }
  var maxWidth: CGFloat { max(contentSize.width + contentInset.right, frame.size.width) }
  var maxHeight: CGFloat { max(contentSize.height + contentInset.bottom, frame.size.height) }
  var isHorizontal: Bool {
    alwaysBounceHorizontal || (!alwaysBounceVertical && contentSize.width + contentInset.width > frame.w) ? true : false
  }
  var boundHit: Direction? {
    if contentOffset.x < -contentInset.left {
      return .left
    } else if rightOffset > maxWidth {
      return .right
    } else if contentOffset.y < -contentInset.top {
      return .top
    } else if bottomOffset > maxHeight {
      return .bottom
    } else {
      return nil
    }
  }
  var isOutsideOfTheBounds: Bool {
    if isHorizontal {
      return contentOffset.x < -contentInset.left || rightOffset > maxWidth
    } else {
      return contentOffset.y < -contentInset.top || bottomOffset > maxHeight
    }
  }
  var page: Int {
    get {
      Int(round(pageProgress))
    } set {
      if isHorizontal {
        contentOffset.x = frame.w * CGFloat(newValue)
      } else {
        contentOffset.y = frame.h * CGFloat(newValue)
      }
    }
  }
  var pageProgress: CGFloat {
    pageProgress(for: contentOffset)
  }
  func pageProgress(for offset: CGPoint) -> CGFloat {
    if isHorizontal {
      return frame.w == 0 ? 0 : offset.x / frame.w
    } else {
      return frame.h == 0 ? 0 : offset.y / frame.h
    }
  }
  var isScrollable: Bool {
    var a = contentSize.height
    a += contentInset.top
    a += contentInset.bottom
    return a > frame.h
  }
  func scrollToTop() {
    contentOffset.y = -contentInset.top
  }
}

public extension UIScrollView {
  var maxInset: CGPoint {
    CGPoint(contentSize.width + contentInset.right + safeAreaInsets.right - frame.w, contentSize.height + contentInset.bottom + safeAreaInsets.bottom - frame.h)
  }
  func scrollToBottom() {
    if contentSize.height > bounds.h - contentInset.bottom {
      contentOffset.y = contentSize.height + contentInset.bottom - frame.h
    }
  }
}
#endif
