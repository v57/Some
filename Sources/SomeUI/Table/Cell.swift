#if os(iOS)
//
//  Cell.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 6/20/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit
import Some

public class CellCache: Cache<Cell> {
  public override init() {
    super.init()
    size = 200 * 1024 * 1024 // 200mb
    capacity = 50
  }
}

public extension UIView {
  func addSubview(_ cell: Cell) {
    let size = cell.size(fitting: frame.size, max: frame.size)
    cell.position = .zero
    cell.size = size
    cell.display(to: self, context: DisplayContext(animator: nil, created: true, from: .addSubview, group: 0))
  }
}

public extension Cell {
  static let cache = CellCache()
  var cache: CellCache { return Cell.cache }
  func remove() {
    table?.remove(cell: self, animated: Animator.isAnimating)
  }
  func move(to index: Int) {
    table?.move(cell: self, to: index, animated: Animator.isAnimating)
  }
}
public extension Array where Element: Cell {
  func removeFromTable(animated: Bool = false) {
    guard let info = first?.tableInfo else { return }
    info.table.remove(range: info.index..<info.index + count, animated: animated)
  }
}

open class EmptyCell: TableCell {
  public var tableInfo: TableInfo?
  public var position: CGPoint = .zero
  public var size: CGSize = .zero
  open var customGap: CGFloat? { nil }
  open func size(fitting: CGSize, max: CGSize) -> CGSize {
    return fitting
  }
  open var isVisible: Bool { false }
  open var view: UIView! {
    get { nil }
    set { }
  }
  
  open func loaded() {
  }
  
  open func unloaded() {
  }
  
  open func display(to view: UIView, context: DisplayContext) {
  }
  
  open func hide(animator: Animator?, removed: Bool) {
  }
  
  open func updateFrame() {
  }
  open func scrolled(context: CellScrollContext) {
    
  }
  open var description: String {
    return "Empty: \(position) \(size)"
  }
  public init() {}
  
}

public struct DisplayContext {
  public var animator: Animator?
  public var created: Bool
  public var from: From
  public var group: Int
  
  public init(animator: Animator? = nil, created: Bool, from: DisplayContext.From, group: Int) {
    self.animator = animator
    self.created = created
    self.from = from
    self.group = group
  }
  public enum From {
    case remove, append, addSubview, scroll, move, picker, resize, insert, update, loaded
  }
}

open class Cell: TableCell, Cachable {
  
  open var tableInfo: TableInfo?
  open var position: CGPoint = .zero
  open var size: CGSize = .zero
  open var customGap: CGFloat? { nil }
  
  open var view: UIView!
  
  public var isVisible = false
  open var isCachable: Bool { true }
  open var isUnloadable: Bool { true }
  
  public init() {}
  
  open func size(fitting: CGSize, max: CGSize) -> CGSize {
    return fitting
  }
  
  open func loaded() {
    
  }
  open func unloaded() {
    
  }
  
  open func reloadView() {
    guard let view = self.view else { return }
    guard let superview = view.superview else { return }
    purged()
    isVisible = false
    display(to: superview, context: DisplayContext(animator: nil, created: true, from: .addSubview, group: 0))
  }
  open func display(to superview: UIView, context: DisplayContext) {
//    assert(!isVisible)
    guard !isVisible else { return }
    if let view = view {
      if isCachable {
        view.isHidden = false
        cache.remove(self)
      }
      if view.superview != superview {
        superview.addSubview(view)
      }
      isVisible = true
//      update(frame: frame)
    } else {
      let view = makeView()
      self.view = view
      superview.addSubview(view)
      isVisible = true
      loaded()
      updateFrame()
    }
  }
  
  open func hide(animator: Animator?, removed: Bool) {
    guard isVisible else { return }
//    assert(isVisible)
    if removed {
      purged()
    } else if isCachable {
      view.isHidden = true
      cache.append(self)
    } else if isUnloadable {
      purged()
    } else {
      /// cell не выгружается, ничего с ней не делаем
    }
    isVisible = false
  }
  public func unload() {
    
  }
  
  open func scrolled(context: CellScrollContext) {
    
  }
  
  open func updateFrame() {
    self.view?.frame = frame
  }
  
  open func makeView() -> UIView {
    return UIView(frame: frame)
  }
  
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
  public static func == (lhs: Cell, rhs: Cell) -> Bool {
    return lhs === rhs
  }
  
  open var cacheSize: Int { Int(size.width * size.height) }
  open func purged() {
    view.removeFromSuperview()
    view = nil
    unloaded()
  }
  @discardableResult
  open func resize(size: CGSize, animated: Bool) -> Animator? {
    guard let tableInfo = tableInfo else { return nil }
    return tableInfo.table.resize(range: tableInfo.index..<tableInfo.index+1, animated: animated)
  }
  
  
  open var description: String { "\(frame)" }
}

#endif
