#if os(iOS)
//
//  Table.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 6/20/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

public extension Table {
  func move(_ cell: TableCell, to index: Int) {
    #if TableLogs
    print("\n\nmoving cell to \(index) \(cell)")
    let oldRange = controller.camera.loadedRange
    #endif
    controller.remove(cell: cell, animated: false)
    controller.insert(cells: [cell], at: index, animated: false)
    // controller.move(cell: cell, to: index, animated: false)
    #if TableLogs
    let newRange = controller.camera.loadedRange
    print("\n\n cell moved to \(index) \(cell). loaded range: \(oldRange) -> \(newRange)\n")
    #endif
  }
  func remove(_ cell: TableCell, animated: Bool = false) {
    #if TableLogs
    print("\n\nremoving cell \(cell)")
    let oldRange = controller.camera.loadedRange
    #endif
    controller.remove(cell: cell, animated: animated)
    #if TableLogs
    let newRange = controller.camera.loadedRange
    print("cell removed. loaded range: \(oldRange) -> \(newRange)\n")
    #endif
  }
  func insert(_ newCells: [TableCell], at index: Int, animated: Bool = false) {
    #if TableLogs
    print("\n\ninserting \(newCells.count) cells")
    let oldRange = controller.camera.loadedRange
    #endif
    controller.insert(cells: newCells, at: index, animated: animated)
    #if TableLogs
    let newRange = controller.camera.loadedRange
    print("inserted cells. loaded range: \(oldRange) -> \(newRange)\n")
    #endif
  }
  func insert(_ cell: TableCell, at index: Int, animated: Bool = false) {
    #if TableLogs
    print("\n\ninserting cell at \(index) \(cell)")
    let oldRange = controller.camera.loadedRange
    #endif
    controller.insert(cells: [cell], at: index, animated: animated)
    #if TableLogs
    let newRange = controller.camera.loadedRange
    print("inserted cell \(cell) loaded range: \(oldRange) -> \(newRange)\n")
    #endif
  }
  @discardableResult
  func append(_ newCells: [TableCell], animated: Bool = false) -> Animator? {
  //  print("\n\nadding \(newCells.count) cells")
    return controller.append(cells: newCells, animated: false)
  }
  func append(_ cell: TableCell, animated: Bool = false) {
    #if TableLogs
    print("\n\nadding cell \(cell)")
    #endif
    controller.append(cell: cell, animated: false)
    #if TableLogs
    print("added cell \(cell)\n")
    print("\n\n \(cell.index) \n\n")
    #endif
  }
}

open class Table: Cell, TableControllerDelegate {
  public enum Autolayout {
    case height(CGFloat)
    case width(CGFloat)
    case size(CGSize)
    case lines(Int)
    case fullSize
    case none
  }
  public var animator: Animator?
  public var isHorizontal: Bool { orientation == .horizontal }
  
  open override var customGap: CGFloat? { cells.isEmpty ? 0 : nil }
  
  open override var view: UIView! {
    didSet {
      guard let view = view else { return }
      // Adding loaded cells to a new view
      for cell in cells[camera.loadedRange] {
        if let v = cell.view, cell.isVisible {
          if v.superview != view {
            view.addSubview(v)
          } else {
            return // Cell is already is this view, so we skipping this loop
          }
        }
      }
    }
  }
  public var gap: UIOffset = .zero {
    didSet {
      guard gap != oldValue else { return }
      guard isInitialised else { return }
      controller.tableUpdated(animated: false)
    }
  }
  open override var size: CGSize {
    didSet {
      guard size != oldValue else { return }
      if let table = tableInfo?.table.table {
        cameraInsets = table.cameraInsets
        cameraSize = table.cameraSize
      } else {
        var _size = size
        _size.width += cameraInsets.width
        _size.height += cameraInsets.height
        cameraSize = _size
      }
      guard (isHorizontal && size.height > 0) || (!isHorizontal && size.width > 0) else { return }
      controller.tableUpdated(animated: false)
    }
  }

  public var nestedView: ()->UIView = { UIView() }
  public var cameraInsets = UIEdgeInsets.zero
  public var cameraSize: CGSize = .zero
  public var cameraOffset: CGPoint = .zero
  public var parent: TableController? { tableInfo?.table }
  public var didScroll = P<CellScrollContext>()
  
  public enum TableType {
    case table, grid
  }
  public typealias Orientation = NSLayoutConstraint.Axis
  public var cells: TableController.Cells = []
  public var contentSize: CGFloat = 0 {
    didSet {
      guard contentSize != oldValue else { return }
      if let tableInfo = tableInfo, !tableInfo.table.table.isUpdating && !isResizing {
        tableInfo.table.resize(range: tableInfo.index..<tableInfo.index+1, animated: false)
      }
      _scrollView?.contentSizeChanged(from: oldValue, to: contentSize)
    }
  }
  
  public var camera: TableCamera = .vertical
  public var layout: TableLayout = .vertical
  public var controller: TableController = TableController()
  public var isInitialised = false
  public var isUpdating = false
  public var isResizing = false
  
  public var scrollView: TableUIScrollView! { return view as? TableUIScrollView }
  public var autolayout: Autolayout = .none
  public var hasAutolayout: Bool {
    if case .none = autolayout {
      return false
    } else {
      return true
    }
  }
  
  public var type = TableType.table {
    didSet {
      guard type != oldValue else { return }
      typeChanged()
    }
  }
  public var orientation = Orientation.vertical {
    didSet {
      guard orientation != oldValue else { return }
      typeChanged()
    }
  }
  public var insets: UIEdgeInsets = .zero {
    didSet {
      guard insets != oldValue else { return }
      if isHorizontal {
        contentSize += insets.width - oldValue.width
      } else {
        contentSize += insets.height - oldValue.height
      }
      guard isInitialised else { return }
      controller.tableUpdated(animated: false)
    }
  }
  
  public var safeArea: UIEdgeInsets = .zero {
    didSet {
      guard safeArea != oldValue else { return }
      if isHorizontal {
        contentSize += safeArea.width - oldValue.width
      } else {
        contentSize += safeArea.height - oldValue.height
      }
      guard isInitialised else { return }
      controller.tableUpdated(animated: false)
    }
  }
  public func updateCameraPosition() {
    guard let scrollView = scrollView else { return }
    camera.frame.origin.y = scrollView._contentOffset - cameraInsets.top
  }
  open override func scrolled(context: CellScrollContext) {
    defer {
      didScroll.send(context)
    }
    #if TableLogs
    let o = Int(context.offset)
    #endif
    camera.frame.origin.y = context.y - cameraInsets.top
    
    #if TableLogs
    print("\n\nscrolling to \(offset) (\(o > 0 ? "+\(o)" : "\(o)")) \(view != nil ? "loaded" : "unloaded")")
    let range = camera.loadedRange
    #endif
    let previousRange = camera.loadedRange
    controller.scrolled()
    var context = context
    if !previousRange.overlaps(camera.loadedRange) {
      context.offset = 0
    }
    cells[camera.loadedRange].forEach {
      var context = context
      context.y -= $0.position.y
      $0.scrolled(context: context)
    }
    #if TableLogs
    print("loaded range: \(range) -> \(camera.loadedRange)\n")
    #endif
  }
  
  public override init() {
    super.init()
    controller.table = self
    camera.table = self
    layout.table = self
  }
  
  open override func loaded() {
    let context = DisplayContext(animator: nil, created: false, from: .loaded, group: 0)
    controller.scrolled(context: context)
  }
  
  public func animate(delay: Double, animations: @escaping () -> (), completion: @escaping () -> ()) {
    UIView.animate(withDuration: 0.15, delay: delay, animations: animations, completion: { (_) in
      completion()
    })
  }
  
  override open func size(fitting: CGSize, max: CGSize) -> CGSize {
    return _sizeThatFits(max)
  }
  override open func makeView() -> UIView {
    if let table = tableInfo?.table, table.isHorizontal == isHorizontal {
      return nestedView()
    } else {
      return TableUIScrollView(table: self)
    }
  }
  deinit {
    cells.forEach { $0.tableInfo = nil }
  }
}

private extension Table {
  func typeChanged() {
    switch (type,orientation) {
    case (.table,.vertical):
      camera = .vertical
      layout = .vertical
    case (.grid,.vertical):
      camera = .vertical
      layout = .verticalGrid
    case (.table,.horizontal):
      camera = .horizontal
      layout = .horizontal
    case (.grid,.horizontal):
      camera = .horizontal
      layout = .horizontalGrid
    case (_, _):
      return
    }
    camera.table = self
    layout.table = self
  }
}

extension Table {
  fileprivate var _scrollView: TableScrollViewCore? {
    return view as? TableScrollViewCore
  }
  public func animate(using animator: Animator, animations: ()->()) {
    Animator.lock()
    defer { Animator.unlock() }
    self.animator = animator
    animations()
    self.animator = nil
  }
}

// MARK:- Autolayout
public extension Table {
  func autolayout(_ autolayout: Autolayout, scrollable: Bool = false) {
    self.autolayout = autolayout
    if view == nil {
      view = makeView()
      isVisible = true
    }
    let scrollView = (view as! TableUIScrollView)
    scrollView.isScrollEnabled = scrollable
  }
  func _sizeThatFits(_ size: CGSize) -> CGSize {
    var size = size
    isResizing = true
    defer {
      isResizing = false
    }
    switch autolayout {
    case .none:
      self.size.width = size.width
      size.height = contentSize
      return size
    case .fullSize:
      self.size.width = size.width
      self.size.height = contentSize
      return self.size
    case .width(let width):
      size.width = width
      self.size = size
    case .height(let height):
      size.height = height
      self.size = size
    case .lines(let lines):
      var line = 0
      var position: CGFloat = 0
      if isHorizontal {
        self.size.height = size.height
      } else {
        self.size.width = size.width
        if cells.count > 0 {
          line = 1
          position = cells[0].position.y
          for cell in cells {
            if cell.position.y != position {
              line += 1
              if line > lines {
                
                break
              } else {
                size.height = cell.size.height
                position = cell.position.y
              }
            } else {
              size.height = max(size.height, cell.size.height)
            }
          }
          size.height += position
          self.size = size
        }
      }
      return size
    case .size(let size):
      self.size = size
      return size
    }
    return size
  }
  var _intrinsicContentSize: CGSize {
    size
  }
}
#endif
