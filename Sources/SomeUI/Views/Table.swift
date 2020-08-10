#if os(iOS)

//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit

//extension UIScrollView {
//  func add(offsetY: CGFloat) {
//    var a = contentOffset.y
//    a += offsetY
//    a = min(a,maxOffsetY)
//    contentOffset.y = a
//  }
//  var maxOffsetY: CGFloat {
//    return contentSize.height + contentInset.bottom - frame.h
//  }
//}

/* v5.0 */
/*
open class TableView: DFScrollView, UIScrollViewDelegate {
  public enum Focus {
    case top, bottom
  }
  public var didScroll: (()->())?
  public var isInverted = false
  
  public func updateAllCells(focus: Focus) {
    var height = self.tableHeight
    for cell in cells {
      height -= cell.height
    }
    for cell in cells {
      cell.y = height
      height += cell.height
    }
    self.tableHeight = height
    scrollToBottom()
  }
  
  private var _topInset: CGFloat = 0
  private var _bottomInset: CGFloat = 0
  public func setTopInset(inset: CGFloat) {
    let offset = inset - _topInset
    _topInset = inset
    tableFrame += offset
    tableOffset -= offset
  }
  public func setBottomInset(inset: CGFloat) {
    let offset = inset - _bottomInset
    _bottomInset = inset
    tableFrame += offset
  }
  
  public override init() {
    super.init()
    alwaysBounceVertical = true
    delegate = self
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    UIView.performWithoutAnimation {
      self.scroll(scrollView.contentOffset.y - _topInset)
    }
    didScroll?()
  }
  
  public var scrollIfAppearsOnScreen = true
  public var autoscroll = true
  func offset(from: Int, to: Int?, offset: CGFloat, index: Int, y: CGFloat, animated: Bool) {
    let end = (to ?? cells.count - 1) + 1
    if from < end {
      for i in from..<end {
        let cell = cells[i]
        cell.i += index
        cell.move(to: cell.y+offset, animated: animated, animatedVisible: false)
      }
    }
    guard to == nil else { return }
    guard tableHeight >= tableFrame else { return }
    if scrollIfAppearsOnScreen {
      if y < self.tableOffset + self.tableFrame + 100 {
        contentOffset.y += offset
      }
    } else {
      if y < self.tableOffset {
        contentOffset.y += offset
      }
    }
  }
  
  open func append(_ cells: [Cell]) {
    for cell in cells {
      _append(cell, animated: false)
    }
  }
  
  open func append(_ cell: Cell?, animated: Bool = true) {
    guard let cell = cell else { return }
    if isInverted && cells.count > 0 {
      insert(0, cell, animated: animated)
    } else {
      _append(cell, animated: animated)
    }
  }
  
  private func insert(_ index: Int, _ cell: Cell, animated: Bool) {
    _insert(index, cell)
    guard !scrollIfAppearsOnScreen else { return }
    guard index == 0 else { return }
    guard animated else { return }
    guard contentOffset.y + contentInset.top == 0 else { return }
    contentOffset.y += cell.height
    jellyAnimation {
      self.contentOffset.y -= cell.height
    }
  }
  
  private func _append(_ cell: Cell, animated: Bool) {
    cell.i = cells.count
    cell.table = self
    if let last = cells.last {
      cell.move(to: last.y + last.height, animated: false, animatedVisible: false)
    } else {
      cell.move(to: 0, animated: false, animatedVisible: false)
    }
    tableHeight += cell.height
    cells.append(cell)
    
    guard superview != nil else { return }
    var h = frame.h
    h -= contentInset.bottom
    if tableHeight >= h {
      if tableOffset+tableFrame >= cell.y && isScrollable {
        if autoscroll {
          if animated {
            jellyAnimation {
              self.scrollToBottom()
            }
          } else {
            scrollToBottom()
          }
        }
      }
    } else {
      let y = cell.y
      cell.y = frame.h
      if animated {
        jellyAnimation2 {
          cell.y = y
        }
      } else {
        cell.y = y
      }
    }
  }
  
  
  
  
  
  
  
  
  
  
  public fileprivate(set) var cells = [Cell]()
  open var visibleCells = ArraySlice<Cell>()
  
  open var tableFrame: CGFloat {
    get {
      return frame.h
    }
    set {
      frame.h = newValue
    }
  }
  open var tableHeight: CGFloat {
    get {
      return contentSize.height
    } set {
      contentSize.height = newValue
    }
  }
  open var tableOffset: CGFloat = 0
  
  open var start = -1
  open var end = -1
  open var last: Cell? { return cells.last }
  
  /// scroll
  open func scroll(_ o: CGFloat) {
    let frame = self.tableFrame
    if start == -1 {
      tableOffset = o
      if cells.count > 0 {
        updateVisible()
      }
      return
    }
    guard o != tableOffset else { return }
    let cob = o + frame
    if o > tableOffset {
      var t = start
      while t < cells.count {
        if t > 0 {
          let cell = cells[t]
          if cell.y + cell.height > o {
            break
          }
          cell.set(visible: false, animated: false)
        }
        t += 1
      }
      start = t
      var b = max(end,start)
      while b < cells.count {
        if b > 0 {
          let cell = cells[b]
          if cell.y > cob {
            break
          }
          cell.set(visible: true, animated: false)
        }
        b += 1
      }
      end = min(b,cells.count-1)
    } else {
      var t = start - 1
      while t >= 0 {
        if t < cells.count {
          let cell = cells[t]
          if cell.y + cell.height < o {
            break
          }
          cell.set(visible: true, animated: false)
        }
        t -= 1
      }
      start = t + 1
      var b = end - 1
      while b >= 0 {
        if b < cells.count {
          let cell = cells[b]
          if cell.y < cob {
            break
          }
          cell.set(visible: false, animated: false)
        }
        b -= 1
      }
      end = b + 1
    }
    tableOffset = o
  }
  
  open func updateVisible() {
    guard cells.count > 0 else { return }
    start = -1
    end = -1
    var last = 0
    for (i,cell) in cells.enumerated() {
      if cell.y + cell.height > tableOffset {
        if cell.y < tableOffset + tableFrame {
          last = i
          if start == -1 {
            start = last
          }
          cell.set(visible: true, animated: false)
        } else {
          end = last
          break
        }
      } else {
        end = last
        continue
      }
    }
  }
  
  /// cell
  open subscript(index: Int) -> Cell! {
    get {
      let index = isInverted ? cells.count - index : index
      guard index >= 0 && index < cells.count else { return nil }
      return cells[index]
    }
    set {
      let index = isInverted ? cells.count - index : index
      if let cell = newValue {
        guard newValue.table == nil else { return }
        if index >= 0 && index < cells.count {
          insert(index, newValue, animated: false)
        } else {
          _append(cell, animated: false)
        }
      } else {
        if index == -1 {
          removeAll()
        } else {
          remove(index, animated: false)
        }
      }
    }
  }
  
  open func removeAll() {
    for cell in cells {
      cell.set(visible: false, animated: false)
      cell.table = nil
    }
    tableHeight = 0
    cells.removeAll()
  }
  
  private func offset(_ cell: Cell?) {
    guard let cell = cell else { return }
    cell.i = cells.count
    cell.table = self
    if let last = cells.last {
      cell.move(to: last.y + last.height, animated: false, animatedVisible: false)
    } else {
      cell.move(to: 0, animated: false, animatedVisible: false)
    }
    tableHeight += cell.height
    cells.append(cell)
  }
  private func _insert(_ index: Int, _ cell: Cell) {
    let c = cells[index]
    cell.table = self
    cell.move(to: c.y, animated: false, animatedVisible: true)
    let animated = cell.isVisible
    cell.i = index
    tableHeight += cell.height
    offset(from: index, to: nil, offset: cell.height, index: 1, y: cell.y, animated: animated)
    cells.insert(cell, at: index)
  }
  open func remove(_ index: Int, animated: Bool = true) {
    let cell = cells[index]
    let animated = cell.isVisible
    cell.set(visible: false, animated: animated)
    cell.table = nil
    cells.remove(at: index)
    offset(from: cell.index, to: nil, offset: -cell.height, index: -1, y: cell.y, animated: animated)
    animateif(animated) {
      tableHeight -= cell.height
    }
  }
  
  open func swap(cell: Cell, with cell2: Cell) {
    let o = cell2.height - cell.height
    if cell.isVisible {
      cell.set(visible: false, animated: false)
    }
    cell.table = nil
    cell2.table = self
    cell2.i = cell.i
    cells[cell.index] = cell2
    tableHeight += o
    offset(from: cell.index, to: nil, offset: o, index: 0, y: cell.y, animated: false)
  }
  
  fileprivate func move(_ cell: Cell, index: Int) {
    guard cell.index != index else { return }
    if cell.index > index {
      offset(from: index, to: cell.index-1, offset: cell.height, index: 1, y: 0, animated: false)
      cells.remove(at: cell.index)
      cells.insert(cell, at: index)
    } else {
      offset(from: cell.index+1, to: index, offset: cell.height, index: -1, y: 0, animated: false)
      cells.insert(cell, at: index)
      cells.remove(at: cell.index)
    }
  }
  
  open override var description: String {
    return "cells: \(cells.count) height: \(tableHeight)"
  }
}

open class Cell: CustomStringConvertible {
  public init() {}
  
  open weak var table: TableView!
  open var height: CGFloat = 0
  open func set(height: CGFloat, animated: Bool) {
    guard self.height != height else { return }
    let offset = height - self.height
    self.height = height
    if let view = view {
      animateif(animated) {
        view.frame.h = height
      }
    }
    guard let table = table else { return }
    table.offset(from: index+1, to: nil, offset: offset, index: 0, y: y, animated: animated)
    table.tableHeight += offset
  }
  
  public var view: UIView!
  public func addSubview(_ view: UIView) {
    self.view.addSubview(view)
  }
  
  
  open var y: CGFloat = 0 {
    didSet {
      view?.frame.y = y
    }
  }
  fileprivate var i: Int = 0
  public var index: Int {
    get {
      return i
    }
    set {
      guard table != nil else { return }
      let i = max(0,min(table.cells.count, newValue))
      if self.i != i {
        table.move(self, index: i)
        self.i = newValue
      }
    }
  }
  
  open func swap(with cell: Cell) {
    table?.swap(cell: self, with: cell)
  }
  public var inTable: Bool { table != nil }
  
  open func move(to y: CGFloat, animated: Bool, animatedVisible: Bool) {
    let old = isVisible
    let new = willVisible(at: y)
    
    animateif(animated) {
      self.y = y
    }
    if old != new {
      if new {
        set(visible: true, animated: animatedVisible)
      } else {
        set(visible: false, animated: false)
      }
    }
  }
  open func remove(animated: Bool = true) {
    table?.remove(i, animated: animated)
  }
  func set(visible: Bool, animated: Bool) {
    guard visible != isVisible else { return }
    self.isVisible = visible
    if visible {
      view = UIView(frame: CGRect(0,y,table.frame.w,height))
      view.clipsToBounds = true
      table.display(view, options: .vertical(.top), animated: animated)
      load()
    } else {
      view = view.destroy(options: .vertical(.top), animated: animated)
      unload()
    }
  }
  open func load() {}
  open func unload() {}
  public private(set) var isVisible: Bool = false
  func willVisible(at y: CGFloat) -> Bool {
    guard let table = table else { return false }
    return y + height > table.tableOffset && y < table.tableOffset + table.tableFrame
  }
  
  public var description: String {
    let inTable = self.inTable ? "in" : "out"
    return "[\(index)] \(inTable) [\(Int(y)) - \(Int(y+height)) (\(Int(height)))]"
  }
}
*/

/* v4.0 */
/*
open class TableView: Table, UIScrollViewDelegate {
  public enum Focus {
    case top, bottom
  }
  public let view: DFScrollView
  public override var scrollView: UIScrollView2! {
    return view
  }
  public var didScroll: (()->())?
  
  public func updateAllCells(focus: Focus) {
    var height = self.height
    for cell in cells {
      height -= cell.height
      cell.updateHeight()
    }
    for cell in cells {
      cell.y = height
      height += cell.height
    }
    self.height = height
    scrollToBottom()
  }
  
  private var _topInset = 0
  private var _bottomInset = 0
  public func setTopInset(inset: Int) {
    let offset = inset - _topInset
    _topInset = inset
    self.frame += offset
    self.offset -= offset
  }
  public func setBottomInset(inset: Int) {
    let offset = inset - _bottomInset
    _bottomInset = inset
    frame += offset
  }
  
  public override init() {
    view = DFScrollView()
    super.init()
    view.alwaysBounceVertical = true
    view.delegate = self
  }

  open func scrollViewDidScroll(_ scrollView: UIScrollView) {
    UIView.performWithoutAnimation {
      self.scroll(Int(scrollView.contentOffset.y) - _topInset)
    }
    didScroll?()
  }
  open override var frame: Int {
    get {
      return Int(view.frame.height)
    }
    set {
      view.frame.height = CGFloat(frame)
    }
  }
  open override var height: Int {
    didSet {
      view.contentSize.height = CGFloat(height)
    }
  }
  
  open var scrollIfAppearsOnScreen = true
  fileprivate override func offset(_ from: Int, _ to: Int?, _ offset: Int, _ index: Int, _ y: Int) {
    super.offset(from, to, offset, index, y)
    guard to == nil else { return }
    guard height >= frame else { return }
    if scrollIfAppearsOnScreen {
      if y < self.offset + self.height + 100 {
        scrollView.contentOffset.y += CGFloat(offset)
      }
    } else {
      if y < self.offset {
        scrollView.contentOffset.y += CGFloat(offset)
      }
    }
  }
  
  open func append(_ cells: [Cell]) {
    for cell in cells {
      super.append(cell)
      append(cell, animated: false)
    }
  }
  
  open override func append(_ cell: Cell?) {
    guard let cell = cell else { return }
    super.append(cell)
    append(cell, animated: true)
  }
  
  override func insert(_ index: Int, _ cell: Cell) {
    super.insert(index, cell)
    guard !scrollIfAppearsOnScreen else { return }
    guard index == 0 else { return }
    guard view.contentOffset.y + view.contentInset.top == 0 else { return }
    view.contentOffset.y += CGFloat(cell.height)
    jellyAnimation2 {
      self.view.contentOffset.y -= CGFloat(cell.height)
    }
  }
  
  private func append(_ cell: Cell, animated: Bool) {
    guard view.superview != nil else { return }
    var h = scrollView.frame.height
    h -= scrollView.contentInset.bottom
    if CGFloat(height) >= h {
      if offset+frame >= cell.y && view.isScrollable {
        jellyAnimation2 {
          self.view.scrollToBottom()
        }
      }
    } else {
      let y = cell.y
      cell.y = Int(scrollView.frame.height)
      jellyAnimation2 {
        cell.y = y
      }
      
    }
  }
  
  open func scrollToBottom() {
    let ch = view.contentSize.height + view.contentInset.bottom
    let fh = view.frame.height
    if fh > ch {
      view.contentOffset.y = -view.contentInset.top
    } else {
      view.contentOffset.y = ch - fh
    }
  }
}
extension Table {
  public var scrollView: UIScrollView2! {
    return nil
  }
}

open class Table: NSObject {
  public fileprivate(set) var cells = [Cell]()
  
  open var frame: Int = 10
  open var height: Int = 0
  open var offset: Int = 0
  
  open var visibleCells = ArraySlice<Cell>()
  open var start = -1
  open var end = -1
  open var last: Cell? { return cells.last }
  
  /// scroll
  open func scroll(_ o: Int) {
    let frame = self.frame + Int(scrollView.frame.height)
    if start == -1 {
      offset = o
      if cells.count > 0 {
        updateVisible()
      }
      return
    }
    guard o != offset else { return }
    let cob = o + frame
    if o > offset {
      var t = start
      while t < cells.count {
        if t > 0 {
          let cell = cells[t]
          if cell.y + cell.height > o {
            break
          }
          cell.isVisible = false
        }
        t += 1
      }
      start = t
      var b = max(end,start)
      while b < cells.count {
        if b > 0 {
          let cell = cells[b]
          if cell.y > cob {
            break
          }
          cell.isVisible = true
        }
        b += 1
      }
      end = min(b,cells.count-1)
    } else {
      var t = start - 1
      while t >= 0 {
        if t < cells.count {
          let cell = cells[t]
          if cell.y + cell.height < o {
            break
          }
          cell.isVisible = true
        }
        t -= 1
      }
      start = t + 1
      var b = end - 1
      while b >= 0 {
        if b < cells.count {
          let cell = cells[b]
          if cell.y < cob {
            break
          }
          cell.isVisible = false
        }
        b -= 1
      }
      end = b + 1
    }
    offset = o
  }
  
  open func updateVisible() {
    guard cells.count > 0 else { return }
    start = -1
    end = -1
    var last = 0
    for (i,cell) in cells.enumerated() {
      if cell.y + cell.height > offset {
        if cell.y < offset + frame {
          last = i
          if start == -1 {
            start = last
          }
          cell.isVisible = true
        } else {
          end = last
          break
        }
      } else {
        end = last
        continue
      }
    }
  }
  
  /// cell
  open subscript(index: Int) -> Cell! {
    get {
      guard index >= 0 && index < cells.count else { return nil }
      return cells[index]
    }
    set {
      if newValue != nil {
        guard newValue.table == nil else { return }
        if index >= 0 && index < cells.count {
          insert(index, newValue)
        } else {
          append(newValue)
        }
      } else {
        if index == -1 {
          removeAll()
        } else {
          remove(index)
        }
      }
    }
  }
  
  open func removeAll() {
    for cell in cells {
      cell.isVisible = false
      cell.table = nil
    }
    height = 0
    cells.removeAll()
  }
  
  open func append(_ cell: Cell?) {
    guard let cell = cell else { return }
    cell.i = cells.count
    cell.table = self
    if let last = cells.last {
      cell.move(last.y + last.height)
    } else {
      cell.move(0)
    }
    height += cell.height
    cells.append(cell)
  }
  
  func insert(_ index: Int, _ cell: Cell) {
    let c = cells[index]
    cell.table = self
    cell.move(c.y)
    cell.i = index
    height += cell.height
    offset(index, nil, cell.height, 1, cell.y)
    cells.insert(cell, at: index)
  }
  fileprivate func remove(_ index: Int) {
    let cell = cells[index]
    cell.isVisible = false
    cell.table = nil
    cells.remove(at: index)
    offset(cell.index, nil, -cell.height, -1, cell.y)
    height -= cell.height
  }
  
  fileprivate func offset(_ from: Int, _ to: Int?, _ offset: Int, _ index: Int, _ y: Int) {
    let end = (to ?? cells.count - 1) + 1
    guard from < end else { return }
    for i in from..<end {
      cells[i].i += index
      cells[i].offset(offset)
    }
  }
  
  fileprivate func swap(_ cell: Cell, cell2: Cell) {
    let o = cell2.height - cell.height
    if cell.isVisible {
      cell.isVisible = false
    }
    cell.table = nil
    cell2.table = self
    cell2.i = cell.i
    cells[cell.index] = cell2
    height += o
    offset(cell.index, nil, o, 0, cell.y)
  }
  
  fileprivate func move(_ cell: Cell, index: Int) {
    guard cell.index != index else { return }
    if cell.index > index {
      offset(index, cell.index-1, cell.height, 1, 0)
      cells.remove(at: cell.index)
      cells.insert(cell, at: index)
    } else {
      offset(cell.index+1, index, cell.height, -1, 0)
      cells.insert(cell, at: index)
      cells.remove(at: cell.index)
    }
  }
  
  open override var description: String {
    return "cells: \(cells.count) height: \(height)"
  }
}

open class Cell: CustomStringConvertible {
  public init() {}
  
  open weak var table: Table!
  open var isLocked = true
  open var height: Int = 0 {
    didSet {
      guard height != oldValue else { return }
      guard isLocked else { return }
      guard let table = table else { return }
      let offset = height - oldValue
      table.offset(index+1, nil, offset, 0, y)
      table.height += offset
    }
  }
  open func updateHeight() {}
  
  open var y: Int = 0
  fileprivate var i: Int = 0
  public var index: Int {
    get {
      return i
    }
    set {
      guard table != nil else { return }
      let i = max(0,min(table.cells.count, newValue))
      if self.i != i {
        table.move(self, index: i)
        self.i = newValue
      }
    }
  }
  
  func swap(_ cell: Cell) {
    table?.swap(self, cell2: cell)
  }
  public var inTable: Bool { table != nil }
  
  open func move(_ y: Int) {
    let old = isVisible
    let new = willVisible(at: y)
    
    if old != new {
      if new {
        UIView.performWithoutAnimation {
          isVisible = true
        }
      } else {
        isVisible = false
      }
    }
    self.y = y
  }
  open func remove() {
    table?.remove(i)
  }
  func offset(_ offset: Int) {
    y += offset
  }
  open func load() {}
  open func unload() {}
  final var isVisible: Bool = false {
    didSet {
      guard isVisible != oldValue else { return }
      isVisible ? load() : unload()
    }
  }
  open func willVisible(at y: Int) -> Bool {
    guard let table = table else { return false }
    return y + height > table.offset || y < table.offset + table.height
  }
  
  public var description: String {
    let inTable = self.inTable ? "in" : "out"
    return "[\(index)] \(inTable) [\(Int(y)) - \(Int(y+height)) (\(Int(height)))]"
  }
}
*/

/* v3.0
public class TableView: Table, UIScrollViewDelegate {
  public let view: DFScrollView
  override public var scrollView: UIScrollView2! {
    return view
  }
  public var didScroll: (()->())?
  
  private var _topInset = 0
  private var _bottomInset = 0
  public func setTopInset(inset: Int) {
    let offset = inset - _topInset
    _topInset = inset
    self.frame += offset
    self.offset -= offset
  }
  public func setBottomInset(inset: Int) {
    let offset = inset - _bottomInset
    _bottomInset = inset
    frame += offset
  }
  public override init() {
    view = DFScrollView()
    super.init()
    view.alwaysBounceVertical = true
    view.delegate = self
  }
  public func scrollViewDidScroll(_ scrollView: UIScrollView2) {
    UIView.performWithoutAnimation {
      self.scroll(Int(scrollView.contentOffset.y) - _topInset)
    }
    didScroll?()
  }
  override public var height: Int {
    didSet {
      view.contentSize.height = CGFloat(height)
    }
  }
  
  public var scrollIfAppearsOnScreen = true
  fileprivate override func offset(_ from: Int, _ to: Int?, _ offset: Int, _ index: Int, _ y: Int) {
    super.offset(from, to, offset, index, y)
    guard to == nil else { return }
    guard height >= frame else { return }
    if scrollIfAppearsOnScreen {
      if y < self.offset + self.height + 100 {
        scrollView.contentOffset.y += CGFloat(offset)
      }
    } else {
      if y + abs(offset) > self.offset {
        scrollView.contentOffset.y += CGFloat(offset)
      }
    }
  }
  
  public override func append(_ cell: Cell) {
    super.append(cell)
    guard view.superview != nil else { return }
    guard height >= frame else { return }
    let offset = cell.height
    let y = cell.y
    if scrollIfAppearsOnScreen {
      if y < self.offset + self.height + 100 {
        animate {
          scrollView.contentOffset.y += CGFloat(offset)
        }
      }
    } else {
      if y + abs(offset) > self.offset {
        animate {
          scrollView.contentOffset.y += CGFloat(offset)
        }
      }
    }
  }
  
  public func scrollToBottom() {
    let ch = view.contentSize.height + view.contentInset.bottom
    let fh = view.frame.height
    if fh > ch {
      view.contentOffset.y = -view.contentInset.top
    } else {
      view.contentOffset.y = ch - fh
    }
  }
}
extension Table {
  public var scrollView: UIScrollView2! {
    return nil
  }
}

open class Table: NSObject {
  fileprivate(set) var cells = [Cell]()
  
  public var frame: Int = 10
  public var height: Int = 0
  public var offset: Int = 0
  
  public var visibleCells = ArraySlice<Cell>()
  public var start = -1
  public var end = -1
  
  
  /// scroll
  public func scroll(_ o: Int) {
    let frame = self.frame + Int(scrollView.frame.height)
    if start == -1 {
      offset = o
      if cells.count > 0 {
        updateVisible()
      }
      return
    }
    guard o != offset else { return }
    let cob = o + frame
    if o > offset {
      var t = start
      while t < cells.count {
        if t > 0 {
          let cell = cells[t]
          if cell.y + cell.height > o {
            break
          }
          cell.unload()
        }
        t += 1
      }
      start = t
      var b = max(end,start)
      while b < cells.count {
        if b > 0 {
          let cell = cells[b]
          if cell.y > cob {
            break
          }
          cell.load()
        }
        b += 1
      }
      end = min(b,cells.count-1)
    } else {
      var t = start - 1
      while t >= 0 {
        if t < cells.count {
          let cell = cells[t]
          if cell.y + cell.height < o {
            break
          }
          cell.load()
        }
        t -= 1
      }
      start = t + 1
      var b = end - 1
      while b >= 0 {
        if b < cells.count {
          let cell = cells[b]
          if cell.y < cob {
            break
          }
          cell.unload()
        }
        b -= 1
      }
      end = b + 1
    }
    offset = o
  }
  
  public func updateVisible() {
    guard cells.count > 0 else { return }
    start = -1
    end = -1
    var last = 0
    for (i,cell) in cells.enumerated() {
      if cell.y + cell.height > offset {
        if cell.y < offset + frame {
          last = i
          if start == -1 {
            start = last
          }
          cell.load()
        } else {
          end = last
          break
        }
      } else {
        end = last
        continue
      }
    }
  }
  
  /// cell
  public subscript(index: Int) -> Cell! {
    get {
      guard index >= 0 && index < cells.count else { return nil }
      return cells[index]
    }
    set {
      if newValue != nil {
        guard newValue.table == nil else { return }
        if index >= 0 && index < cells.count {
          insert(index, newValue)
        } else {
          append(newValue)
        }
      } else {
        if index == -1 {
          removeAll()
        } else {
          remove(index)
        }
      }
    }
  }
  
  public func removeAll() {
    for cell in cells {
      cell.unload()
      cell.table = nil
    }
    height = 0
    cells.removeAll()
  }
  
  public func append(_ cell: Cell) {
    cell.i = cells.count
    cell.table = self
    if let last = cells.last {
      cell.move(last.y + last.height)
    } else {
      cell.move(0)
    }
    height += cell.height
    cells.append(cell)
  }
  
  fileprivate func insert(_ index: Int, _ cell: Cell) {
    let c = cells[index]
    cell.table = self
    cell.move(c.y)
    cell.i = index
    height += cell.height
    offset(index, nil, cell.height, 1, cell.y)
    cells.insert(cell, at: index)
  }
  fileprivate func remove(_ index: Int) {
    let cell = cells[index]
    cell.unload()
    cell.table = nil
    cells.remove(at: index)
    offset(cell.index, nil, -cell.height, -1, cell.y)
    height -= cell.height
  }
  
  fileprivate func offset(_ from: Int, _ to: Int?, _ offset: Int, _ index: Int, _ y: Int) {
    let end = (to ?? cells.count - 1) + 1
    guard from < end else { return }
    for i in from..<end {
      cells[i].i += index
      cells[i].offset(offset)
    }
  }
  
  fileprivate func swap(_ cell: Cell, cell2: Cell) {
    let o = cell2.height - cell.height
    if cell.isVisible {
      cell.unload()
    }
    cell.table = nil
    cell2.table = self
    cell2.i = cell.i
    cells[cell.index] = cell2
    height += o
    offset(cell.index, nil, o, 0, cell.y)
  }
  
  fileprivate func move(_ cell: Cell, index: Int) {
    guard cell.index != index else { return }
    if cell.index > index {
      offset(index, cell.index-1, cell.height, 1, 0)
      cells.remove(at: cell.index)
      cells.insert(cell, at: index)
    } else {
      offset(cell.index+1, index, cell.height, -1, 0)
      cells.insert(cell, at: index)
      cells.remove(at: cell.index)
    }
  }
  
  open override var description: String {
    return "cells: \(cells.count) height: \(height)"
  }
}

open class Cell: CustomStringConvertible {
  public init() {}
  public weak var table: Table!
  public var height: Int = 0 {
    didSet {
      guard height != oldValue else { return }
      guard let table = table else { return }
      let offset = height - oldValue
      table.offset(index+1, nil, offset, 0, y)
      table.height += offset
    }
  }
  open var y: Int = 0
  fileprivate var i: Int = 0
  open var index: Int {
    get {
      return i
    }
    set {
      guard table != nil else { return }
      let i = max(0,min(table.cells.count, newValue))
      if self.i != i {
        table.move(self, index: i)
        self.i = newValue
      }
    }
  }
  
  public func swap(_ cell: Cell) {
    table?.swap(self, cell2: cell)
  }
  public var inTable: Bool { table != nil }
  
  public func move(_ y: Int) {
    let old = isVisible
    let new = willVisible(at: y)
    
    if old != new {
      if new {
        UIView.performWithoutAnimation {
          load()
        }
      } else {
        unload()
      }
    }
    self.y = y
  }
  public func remove() {
    table?.remove(i)
  }
  public func offset(_ offset: Int) {
    y += offset
  }
  open func load() {}
  open func unload() {}
  public var isVisible: Bool {
    guard let table = table else { return false }
    return y + height > table.offset || y < table.offset + table.height
  }
  public func willVisible(at y: Int) -> Bool {
    guard let table = table else { return false }
    return y + height > table.offset || y < table.offset + table.height
  }
  
  public var description: String {
    let inTable = self.inTable ? "in" : "out"
    return "[\(index)] \(inTable) [\(Int(y)) - \(Int(y+height)) (\(Int(height)))]"
  }
}
 */

/* v2.0
open class Cell {
  open weak var table: Table!
  open var index = 0, y = CGFloat(0)
  
  open var height: CGFloat {
    didSet {
      let offset = height - oldValue
      table?.offset(offset, from: index + 1)
      guard loaded else { return }
      let locked = table?.locked ?? true
      animateif(!locked) {
        self.heightChanged(offset)
      }
    }
  }
  
  open func heightChanged(_ offset: CGFloat) {
    
  }
  
  public init(height: CGFloat) {
    self.height = height
  }
  open func added() {
    
  }
  open var loaded = false
  open func load() {
    if loaded { return }
    loaded = true
  }
  open func unload() {
    if !loaded { return }
    loaded = false
  }
  open func offset(_ offset: CGFloat) {
    y += offset
  }
  open func down() {}
  open func up() {}
  open func upInside() {}
}

open class Table: ScrollView {
  open var cells = [Cell]()
  override public init(frame: CGRect) {
    super.init(frame: frame)
    contentInset = UIEdgeInsets(top: frame.height, left: 0, bottom: 0, right: 0)
    contentOffset = CGPoint(0,-frame.height)
    self.delegate = self
    addTap(self,#selector(Table.tap(_:))))
  }
  
  func tap(_ gesture: UITapGestureRecognizer) {
    let location = gesture.location(in: self)
    
    for i in top...bottom where i >= 0 && i < cells.count {
      let cell = cells[i]
      if location.y > cell.y && location.y < cell.y + cell.height {
        cell.upInside()
        return
      }
    }
  }
  
  private var top = 0
  private var bottom = 0
  private var py: CGFloat = -1
  override open func scrollViewDidScroll(_ scrollView: UIScrollView2) {
    super.scrollViewDidScroll(scrollView)
    let co = contentOffset.y
    let pco = py
    let h = frame.height
    let cob = co + h
    if co > pco {
      var t = top
      while t < cells.count {
        let cell = cells[t]
        if cell.y + cell.height > co {
          break
        }
        cell.unload()
        t += 1
      }
      top = t
      var b = max(bottom,top)
      while b < cells.count {
        let cell = cells[b]
        if cell.y > cob {
          break
        }
        cell.load()
        b += 1
      }
      bottom = min(b,cells.count-1)
    } else {
      var t = top - 1
      while t >= 0 {
        let cell = cells[t]
        if cell.y + cell.height < co {
          break
        }
        cell.load()
        t -= 1
      }
      top = t + 1
      var b = bottom - 1
      while b >= 0 {
        let cell = cells[b]
        if cell.y < cob {
          break
        }
        cell.unload()
        b -= 1
      }
      bottom = b + 1
    }
    py = contentOffset.y
  }
  
  open func offset(_ offset: CGFloat, from: Int) {
    height += offset
    if offset < 0 {
      var b = bottom
      let sb = contentOffset.y + frame.height
      while b < cells.count {
        let cell = cells[b]
        if cell.y + offset > sb {
          break
        }
        cell.load()
        b += 1
      }
    }
    animateif(!locked) {
      for i in from..<self.cells.count {
        let cell = self.cells[i]
        cell.offset(offset)
      }
    }
  }
  
  open var height: CGFloat = 0 {
    didSet {
      let pinned = contentOffset.y + frame.height + 100 > contentSize.height
      animateif(!locked) {
        self.contentInset = UIEdgeInsets(top: max(self.frame.height - self.height, 20), left: 0, bottom: 0, right: 0)
        self.contentSize = CGSize(self.contentSize.width, self.height)
        if pinned {
          self.contentOffset = CGPoint(0,self.contentSize.height - self.frame.height)
        }
      }
    }
  }
  
  open var attachedToBottom: Bool {
    return true
  }
  
  open func update() {
    for i in top...bottom {
      let cell = cells[i]
      cell.unload()
    }
    top = 0
    bottom = cells.count-1
    scrollViewDidScroll(self)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  open func addX(_ cells: [Cell]) {
    var hsum: CGFloat = 0
    for cell in cells {
      if let last = self.cells.last {
        cell.y = last.y + last.height
      } else {
        cell.y = 0
      }
      
      cell.index = self.cells.count
      self.cells.append(cell)
      cell.table = self
      hsum += cell.height
    }
    height += hsum
  }
  open func append(_ cell: Cell) {
    if let last = cells.last {
      cell.y = last.y + last.height
    } else {
      cell.y = 0
    }
    
    cell.index = cells.count
    cells.append(cell)
    cell.table = self
    height += cell.height
    if cells.count == 1 {
      cell.load()
    }
  }
  fileprivate var locked = false
  open func undelegated(_ block: ()->()) {
    delegate = nil
    block()
    delegate = self
  }
  open func lock(_ block: ()->()) {
    delegate = nil
    locked = true
    block()
    locked = false
    delegate = self
  }
}
 
 */


/* v1.0
class Cell {
  weak var table: Table!
  var index = 0, y = CGFloat(0)
  
  var height: CGFloat {
    didSet {
      let offset = height - oldValue
      table?.offset(offset, from: index + 1)
      guard loaded else { return }
      let locked = table?.locked ?? true
      animateif(!locked) {
        self.heightChanged(offset)
      }
    }
  }
  
  func heightChanged(offset: CGFloat) {
    
  }
  
  init(height: CGFloat) {
    self.height = height
  }
  func added() {
    
  }
  var loaded = false
  func load() {
    if loaded { return }
    loaded = true
  }
  func unload() {
    if !loaded { return }
    loaded = false
  }
  func offset(offset: CGFloat) {
    y += offset
  }
  func down() {}
  func up() {}
  func upInside() {}
}

class Table: ScrollView {
  var cells = [Cell]()
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.delegate = self
    addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tap:"))
  }
  
  func tap(gesture: UITapGestureRecognizer) {
    let location = gesture.locationInView(self)
    for i in top...bottom {
      let cell = cells[i]
      if location.y > cell.y && location.y < cell.y + cell.height {
        cell.upInside()
        return
      }
    }
  }
  
  private var top = 0
  private var bottom = 0
  private var py: CGFloat = -1
  override func scrollViewDidScroll(scrollView: UIScrollView2) {
    super.scrollViewDidScroll(scrollView)
    let co = contentOffset.y
    let pco = py
    let h = frame.height
    let cob = co + h
    if co > pco {
      var t = top
      while t < cells.count {
        let cell = cells[t]
        if cell.y + cell.height > co {
          break
        }
        cell.unload()
        t++
      }
      top = t
      var b = max(bottom,top)
      while b < cells.count {
        let cell = cells[b]
        if cell.y > cob {
          break
        }
        cell.load()
        b++
      }
      bottom = min(b,cells.count-1)
    } else {
      var t = top - 1
      while t >= 0 {
        let cell = cells[t]
        if cell.y + cell.height < co {
          break
        }
        cell.load()
        t--
      }
      top = t + 1
      var b = bottom - 1
      while b >= 0 {
        let cell = cells[b]
        if cell.y < cob {
          break
        }
        cell.unload()
        b--
      }
      bottom = b + 1
    }
    py = contentOffset.y
  }
  
  func offset(offset: CGFloat, from: Int) {
    height += offset
    if offset < 0 {
      var b = bottom
      let sb = contentOffset.y + frame.height
      while b < cells.count {
        let cell = cells[b]
        if cell.y + offset > sb {
          break
        }
        cell.load()
        b++
      }
    }
    animateif(!locked) {
      for i in from..<self.cells.count {
        let cell = self.cells[i]
        cell.offset(offset)
      }
    }
  }
  
  var height: CGFloat = 0 {
    didSet {
      print("height: \(height)")
      let pinned = contentOffset.y + frame.height + 100 > contentSize.height
      self.contentInset = UIEdgeInsets(top: max(self.frame.height - self.height, 20), left: 0, bottom: 0, right: 0)
      self.contentSize = CGSize(self.contentSize.width, self.height)
      if pinned {
        animateif(!locked) {
          self.contentOffset = CGPoint(0,self.contentSize.height - self.frame.height)
        }
      }
    }
  }
  
  var attachedToBottom: Bool {
    return true
  }
  
  func update() {
    for i in top...bottom {
      let cell = cells[i]
      cell.unload()
    }
    top = 0
    bottom = cells.count-1
    scrollViewDidScroll(self)
  }
  
  required init(coder: NSCoder) { fatalError() }
  func addX(cells: [Cell]) {
    var hsum: CGFloat = 0
    for cell in cells {
      if let last = self.cells.last {
        cell.y = last.y + last.height
      } else {
        cell.y = 0
      }
      
      cell.index = self.cells.count
      self.cells.append(cell)
      cell.table = self
      hsum += cell.height
    }
    height += hsum
  }
  func append(cell: Cell) {
    if let last = cells.last {
      cell.y = last.y + last.height
    } else {
      cell.y = 0
    }
    
    cell.index = cells.count
    cells.append(cell)
    cell.table = self
    height += cell.height
  }
  private var locked = false
  func lock(block: ()->()) {
    locked = true
    block()
    locked = false
  }
}
*/
#endif
