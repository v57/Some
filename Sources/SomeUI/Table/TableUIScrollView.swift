#if os(iOS)
//
//  UIScrollView.swift
//  SomeTable
//
//  Created by Dmitry on 06/11/2018.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import Foundation
import UIKit

public protocol TableScrollViewCore {
  func contentSizeChanged(from: CGFloat, to: CGFloat)
  func contentOffsetChanged(from: CGFloat, to: CGFloat)
}

public struct CellScrollContext {
  public var y: CGFloat
  public var offset: CGFloat
  public var scrollView: UIScrollView?
  public init(y: CGFloat, offset: CGFloat, scrollView: UIScrollView?) {
    self.y = y
    self.offset = offset
    self.scrollView = scrollView
  }
}

open class TableUIScrollView: PScrollView, UIScrollViewDelegate, TableScrollViewCore {
  open weak var table: Table?
  public var _contentOffset: CGFloat { y(contentOffset) }
  public var transformContentSize: (CGFloat)->(CGFloat) = { $0 }
  var tableIsHorizontal: Bool { table?.isHorizontal ?? false }
  public init(table: Table) {
    self.table = table
    super.init(frame: CGRect(table.position,table.size))
    if let parent = table.table, parent.isHorizontal == table.isHorizontal {
      frame.size[keyPath: _height] = table.contentSize
    }
    contentSize[keyPath: _height] = table.contentSize
    pipe.didScroll.forEach { [unowned self] in
      self.scrollViewDidScroll($0)
    }.store(in: self)
    pipe.didEndDecelerating.forEach { [unowned self] in
      self.scrollViewDidEndDecelerating($0)
    }.store(in: self)
  }
  var previousScrollOffset: CGFloat = 0
  lazy var heightConstraint: NSLayoutConstraint = {
    let constraint = self.heightAnchor.constraint(equalToConstant: 0)
    constraint.isActive = true
    addConstraint(constraint)
    return constraint
  }()
  open override func layoutSubviews() {
    guard let table = table else {
      super.layoutSubviews()
      return }
    if table.hasAutolayout {
      let size = table._sizeThatFits(frame.size)
      if size != frame.size {
        heightConstraint.constant = size.height
      }
    }
    super.layoutSubviews()
  }
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    guard let table = table else { return .zero }
    if table.hasAutolayout {
      return table._sizeThatFits(size)
    } else {
      return super.sizeThatFits(size)
    }
  }
  open override var intrinsicContentSize: CGSize {
    guard let table = table else { return .zero }
    if table.hasAutolayout {
      _ = heightConstraint
      return table._intrinsicContentSize
    } else {
      return super.intrinsicContentSize
    }
  }
  
  required public init(coder: NSCoder) { fatalError() }
  
  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    guard let table = table else { return }
    let context = CellScrollContext(y: previousScrollOffset, offset: 0, scrollView: scrollView)
    table.scrolled(context: context)
  }
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let table = table else { return }
    defer { previousScrollOffset = y(scrollView.contentOffset) }
    guard !UIScrollView.isUpdating else { return }
    let newValue = y(scrollView.contentOffset)
    let offset = newValue - previousScrollOffset
    let context = CellScrollContext(y: newValue, offset: offset, scrollView: scrollView)
    table.scrolled(context: context)
    #if targetEnvironment(macCatalyst)
    // Fixing bug where when you stop scrolling, scrollViewDidEndDecelerating does not call
    if scrollView.isDecelerating {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if self.y(scrollView.contentOffset) == newValue {
          let context = CellScrollContext(y: self.previousScrollOffset, offset: 0, scrollView: scrollView)
          self.table.scrolled(context: context)
        }
      }
    }
    #endif
  }
  public func contentSizeChanged(from: CGFloat, to: CGFloat) {
    contentSize[keyPath: _height] = transformContentSize(to)
  }
  public func contentOffsetChanged(from: CGFloat, to: CGFloat) {
    contentOffset[keyPath: _y] = to
  }
  func x(_ point: CGPoint) -> CGFloat {
    return tableIsHorizontal ? point.y : point.x
  }
  func y(_ point: CGPoint) -> CGFloat {
    return tableIsHorizontal ? point.x : point.y
  }
  
  private var _height: WritableKeyPath<CGSize,CGFloat> {
    return tableIsHorizontal ? \.width : \.height
  }
//  private var _width: WritableKeyPath<CGSize,CGFloat> {
//    return table.isHorizontal ? \.height : \.width
//  }
//  private var _x: WritableKeyPath<CGPoint,CGFloat> {
//    return table.isHorizontal ? \.y : \.x
//  }
  private var _y: WritableKeyPath<CGPoint,CGFloat> {
    return tableIsHorizontal ? \.x : \.y
  }
}

public extension UIScrollView {
  static var isUpdating = false
  static var isAnimated = false
  private var min: CGFloat { -contentInset.top }
  private var max: CGFloat { ch - fh }
  private var ch: CGFloat { contentSize.height + contentInset.bottom }
  private var fh: CGFloat { frame.size.height }
  private var cy: CGFloat { contentOffset.y }
  // func update(animated: Bool = false, _ update: ()->()) {
  //   let oldValue = contentOffset.y
  //   let scrolled = (cy / max).limit(in: 0..<1)
  //   UIScrollView.isUpdating = true
  //   update()
  //   contentOffset.y = oldValue
  //   UIScrollView.isUpdating = false
  //   let animator = Animator()
  //   animator.isAnimated = animated
  //   let y = ((max) * scrolled).limit(in: min..<Swift.max(min,Swift.max(max,0)))
  //   animator.animate {
  //     self.contentOffset.y = y
  //   }
  //   animator.animate { (animations, completion) in
  //     UIView.animate(withDuration: 0.25, animations: animations, completion: { _ in completion() })
  //   }
  // }
}
#endif
