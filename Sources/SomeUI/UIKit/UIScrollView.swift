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
  var loadMoreBottom: Bool {
    contentSize.height - bottomOffset < 200
  }
  var loadMoreTop: Bool {
    contentOffset.y < 200
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
  func scrollToTop(animated: Bool) {
    setContentOffset(y: -(contentInset.top + safeAreaInsets.top), animated: animated)
  }
  func setContentOffset(x: CGFloat, animated: Bool) {
    setContentOffset(CGPoint(x, contentOffset.y), animated: animated)
  }
  func setContentOffset(y: CGFloat, animated: Bool) {
    setContentOffset(CGPoint(contentOffset.x, y), animated: animated)
  }
}

public extension UIScrollView {
  enum ScrollAlignment {
    case top, bottom, closest
  }
  var leftInset: CGFloat { contentInset.left + safeAreaInsets.left }
  var rightInset: CGFloat { contentInset.right + safeAreaInsets.right }
  var horizontalInsets: CGFloat { leftInset + rightInset }
  var verticalInsets: CGFloat { topInset + bottomInset }
  var topInset: CGFloat { contentInset.top + safeAreaInsets.top }
  var bottomInset: CGFloat { contentInset.bottom + safeAreaInsets.bottom }
  var contentWidth: CGFloat { contentSize.width + horizontalInsets }
  var contentHeight: CGFloat { contentSize.height + verticalInsets }
  var minX: CGFloat { -leftInset }
  var maxX: CGFloat { Swift.max(contentSize.width - frame.width, minX) }
  var minY: CGFloat { -topInset }
  var maxY: CGFloat { Swift.max(contentSize.height - frame.height, minY) }
  var visibleMinX: CGFloat { contentOffset.x + leftInset }
  var visibleMaxX: CGFloat { contentOffset.x + frame.width - horizontalInsets  }
  var visibleMinY: CGFloat { contentOffset.y + topInset }
  var visibleMaxY: CGFloat { contentOffset.y + frame.height - verticalInsets }
  var visibleFrameWidth: CGFloat { frame.width - horizontalInsets }
  var visibleFrameHeight: CGFloat { frame.height - verticalInsets }
  var visibleFrame: CGRect { CGRect(visibleMinX, visibleMinY, visibleFrameWidth, visibleFrameHeight) }
  var contentFrame: CGRect { CGRect(minX, minY, contentWidth, contentHeight) }
  func safeScroll(to offset: CGPoint) {
    var offset = offset
    offset.x = offset.x.limit(in: minX...maxX)
    offset.y = offset.y.limit(in: minY...maxY)
    if contentOffset != offset {
      contentOffset = offset
    }
  }
  func safeScroll(x: CGFloat) {
    var offset = contentOffset
    offset.x = x.limit(in: minX...maxX)
    if contentOffset != offset {
      contentOffset = offset
    }
  }
  func safeScroll(y: CGFloat) {
    var offset = contentOffset
    offset.y = y.limit(in: minY...maxY)
    if contentOffset != offset {
      contentOffset = offset
    }
  }
  func scrollX(to rect: CGRect, alignment: ScrollAlignment, always: Bool = false) {
    switch alignment {
    case .top:
      safeScroll(x: rect.minX.limit(in: visibleMinX...visibleMaxX))
    case .bottom:
      safeScroll(x: rect.maxX.limit(in: visibleMinX...visibleMaxX))
    case .closest:
      let min = visibleMinX
      let max = visibleMaxX
      if rect.minX < min {
        safeScroll(x: rect.minX)
      } else if rect.maxX > max {
        safeScroll(x: rect.maxX)
      }
    }
  }
  func scrollY(to rect: CGRect, alignment: ScrollAlignment) {
    switch alignment {
    case .top:
      safeScroll(y: rect.minY)
    case .bottom:
      safeScroll(y: rect.maxY)
    case .closest:
      let min = visibleMinY
      let max = visibleMaxY
      if rect.minY < min {
        safeScroll(y: rect.minY)
      } else if rect.maxY > max {
        safeScroll(y: rect.maxY)
      }
    }
  }
  func noDelegate(block: ()->()) {
    let d = delegate
    let co = contentOffset
    delegate = nil
    defer {
      delegate = d
      contentOffset = co
    }
    block()
  }
}

public extension UIScrollView {
  var maxInset: CGPoint {
    CGPoint(contentSize.width + contentInset.right + safeAreaInsets.right - frame.w, contentSize.height + contentInset.bottom + safeAreaInsets.bottom - frame.h)
  }
  func scrollToBottom() {
    contentOffset.y = maxY
  }
  func scrollToBottom(animated: Bool) {
    if animated {
      if contentSize.height > bounds.h - contentInset.bottom {
        let target = contentSize.height + contentInset.bottom - frame.h
        let distance = target - contentOffset.y
        let maxDistance: CGFloat = 1000
        if distance > maxDistance {
          setContentOffset(CGPoint(0,  target-maxDistance), animated: false)
          setContentOffset(CGPoint(0,  target), animated: true)
        } else if distance < -maxDistance {
          setContentOffset(CGPoint(0,  target+maxDistance), animated: false)
          setContentOffset(CGPoint(0,  target), animated: true)
        } else {
          setContentOffset(CGPoint(0,  target), animated: true)
        }
      }
    } else {
      if contentSize.height > bounds.h - contentInset.bottom {
        contentOffset.y = contentSize.height + contentInset.bottom - frame.h
      }
    }
  }
}
#endif
