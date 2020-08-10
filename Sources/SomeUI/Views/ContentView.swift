
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

public let pageDeleteIcon = UIImage(named: "DeleteIcon")!

@objc public protocol ContentViewDelegate {
  @objc optional func blockSelected(_ block: Block)
  
  @objc optional func blockTap(_ block: Block)
  @objc optional func blockTouchDown(_ block: Block)
  @objc optional func blockTouchUp(_ block: Block)
}

open class LoadingBlock: Block {
  let view = LoadingViewDefault(center: CGPoint(screen.center.x,15))
  
  open func shows(_ page: ContentView, at: Int) {
    view.animating = true
    page.insert(self, at: at)
  }
  
  open func hide() {
    view.animating = false
    tableView?.remove(self)
  }
  
  public init() {
    super.init(height: 30)
    addSubview(view)
  }
  
  override open func didMoveToSuperview() {
    super.didMoveToSuperview()
    view.center = CGPoint(screen.center.x,15)
  }
  
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

open class ScrollViewBlock: Block {
  open override func didMoveToSuperview() {
    defer { super.didMoveToSuperview() }
    guard let scrollView = superview as? UIScrollView2 else { return }
    var size = scrollView.contentSize
    size.height += height
    scrollView.contentSize = size
    
  }
  open override func removeFromSuperview() {
    defer { super.removeFromSuperview() }
    guard let scrollView = superview as? UIScrollView2 else { return }
    var size = scrollView.contentSize
    size.height -= height
    scrollView.contentSize = size
  }
  open override func heightChanged(_ oldValue: CGFloat) {
    super.heightChanged(oldValue)
    guard let scrollView = superview as? UIScrollView2 else { return }
    let offset = height - oldValue
    scrollView.contentSize = scrollView.contentSize + CGSize(0,offset)
  }
}

open class Block: UIView {
  open var index: Int = 0
  open weak var tableView: ContentView?
  
  open var selectable = false {
    didSet {
      if selectable != oldValue {
        if selectable {
          tapGesture = UITapGestureRecognizer(target: self, action: #selector(Block.tap(_:)))
          holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(Block.hold(_:)))
          addGestureRecognizer(tapGesture!)
          addGestureRecognizer(holdGesture!)
        } else {
          removeGestureRecognizer(tapGesture!)
          removeGestureRecognizer(holdGesture!)
          tapGesture = nil
          holdGesture = nil
        }
      }
    }
  }
  
  private var tapGesture: UITapGestureRecognizer?
  private var holdGesture: UILongPressGestureRecognizer?
  
  open var height: CGFloat = 0 {
    didSet {
      if height != oldValue {
        heightChanged(oldValue)
      }
    }
  }
  
  public init(height: CGFloat) {
    self.height = height
    super.init(frame: CGRect(0, 0, 0, height))
    clipsToBounds = true
    //self.alpha = 0.0
    //self.backgroundColor = UIColor.blackColor()
  }
  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  open func addSubview(_ view: UIView, changeHeight: Bool) {addSubview(view)}
  open func addSubviews(_ views: [UIView], changeHeight: Bool) {}
  override open func didMoveToSuperview() {
    super.didMoveToSuperview()
    guard superview != nil else { return }
    var f = frame
    if superview is ContentView {
      f.w = max(superview!.frame.w, (superview! as! ContentView).contentSize.width)
    } else {
      f.w = superview!.frame.w
    }
    frame = f
  }
  
  @objc open func tap(_ gesture: UITapGestureRecognizer) {
    tableView?.blockTap(self)
    selectAndDeselect()
    selected()
  }
  @objc open func hold(_ gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
      tableView?.blockTouchDown(self)
      isSelected = true
      select()
    case .changed:
      let pos = gesture.location(in: self)
      let inside = self.bounds.contains(pos)
      if isSelected {
        if !inside {
          isSelected = false
          deselect()
        }
      } else if inside {
        isSelected = true
        select()
      }
    case .ended:
      if isSelected {
        tableView?.blockTouchUp(self)
        isSelected = false
        deselect()
        selected()
      }
    default:
      break
    }
  }
  
  private(set) var isSelected = false
  open func selectAndDeselect() {
    alpha = 0.5
    animate {
      self.alpha = 1.0
    }
  }
  open func select() {
    UIView.animate(withDuration: 0.15, animations: {
      self.alpha = 0.5
    }) 
  }
  open func deselect() {
    animate {
      self.alpha = 1.0
    }
  }
  open func selected() { }
  open func load() { }
  open func unload() { }
  open func heightChanged(_ oldValue: CGFloat) {
    if tableView != nil {
      let offset = height - oldValue
      tableView!.height += offset
      tableView!.offset(offset, from: index + 1)
      var f = frame
      f.h = height
      animateif(tableView!.animated) {
        self.frame = f
      }
    } else {
      var f = frame
      f.h = height
      frame = f
    }
  }
}

open class ContentView: ScrollView {
  open var contentViewDelegate: ContentViewDelegate?
  open var cells = [Block]()
  open var animated = true
  open var height: CGFloat = 0 {
    didSet {
      if contentOffset.y + frame.h > height {
        
        animateif(animated) {
          self.contentSize = CGSize(self.contentSize.width,self.height)
        }
      } else {
        contentSize = CGSize(contentSize.width,height)
      }
    }
  }
  
  open func initCell(_ cell: Block) {
    cell.tableView = self
    height += cell.height
    insertSubview(cell, at: 0)
  }
  open func deinitCell(_ cell: Block) {
    cell.tableView = nil
    height -= cell.height
    cells.remove(at: cell.index)
  }
  
  open func insert(_ cell: Block, at index: Int, animated: Bool = true) { /// - Todo: Убрать анимацию, если блок появляется вне экрана
    var animated = animated
    if animated {
      animated = self.superview != nil
    }
    guard index < cells.count else {
      append(cell)
      return
    }
    
    cell.index = index
    cell.frame.origin = CGPoint(0,cells[index].frame.y)
    for i in index..<cells.count {
      let c = cells[i]
      c.index += 1
      animateif(animated) {
        c.frame.y += cell.height
      }
    }
    cells.insert(cell, at: index)
    initCell(cell)
    cell.frame.h = 0
    animateif(animated) {
      //cell.alpha = 1.0
      cell.frame.h = cell.height
      
    }
  }
  open func addXTo(_ cells: [Block], position: Int) { /// - Todo: Убрать анимацию, если блок появляется вне экрана
    if cells.count == 0 {
      print("[Error] No cells to add")
      return
    }
    if position >= self.cells.count {
      print("Can't insert \(position) in 0...\(self.cells.count). Adding cell...")
      addX(cells)
      return
    }
    var offset: CGFloat = 0
    let y = self.cells[position].frame.y
    var index = 0
    // Сдвигаем новые
    for cell in cells {
      index += 1
      cell.index = position
      cell.frame = CGRect(cell.frame.x,y,cell.frame.w,0)
      animateif(animated) {
        cell.frame = CGRect(cell.frame.x,y+offset,cell.frame.w,cell.height)
      }
      offset += cell.height
    }
    // Сдвигаем всех под ними
    for i in position...self.cells.count-1 {
      let c = self.cells[i]
      c.index += index
      animateif(animated) {
        c.frame = c.frame.offsetBy(dx: 0, dy: offset)
      }
    }
    // Добавляем новые
    let cc = cells.count-1
    for i in 0...cc {
      let cell = cells[cc-i]
      self.cells.insert(cell, at: position)
      initCell(cell)
    }
  }
  open func addX(_ cells: [Block], animated: Bool = true) { /// - Todo: Убрать анимацию, если блок появляется вне экрана
    var animated = animated
    if cells.count == 0 { return }
    if animated {
      animated = self.superview != nil
    }
    var offset: CGFloat = 0
    for cell in cells {
      if animated {
        //                var frame = CGRect(cell.frame.x,self.height,cell.frame.width,0)
        //                cell.frame = frame
        //                frame.height = cell.height
        //                animateif(animated) {
        //                    cell.frame = frame
        //                }
        cell.frame = CGRect(cell.frame.x,self.height,cell.frame.w,cell.height)
        cell.alpha = 0.0
        animateif(animated) {
          cell.alpha = 1.0
        }
      } else {
        cell.frame = CGRect(cell.frame.x,self.height,cell.frame.w,cell.height)
      }
      offset += cell.height
      cell.index = self.cells.count
      self.cells.append(cell)
      initCell(cell)
    }
    //cell.alpha = 1.0
  }
  open func append(_ cell: Block, animated: Bool = true) {
    var animated = animated
    if animated { animated = self.superview != nil }
    if animated {
      cell.frame = CGRect(cell.frame.x,max(contentSize.height, bounds.h),cell.frame.w,cell.height)
      animateif(animated) {
        cell.frame = cell.bounds.offsetBy(dx: 0, dy: self.height)
      }
    } else {
      cell.frame = CGRect(cell.frame.x,self.height,cell.frame.w,cell.height)
    }
    cell.index = cells.count
    cells.append(cell)
    initCell(cell)
  }
  open func remove(_ cell: Block, animated: Bool = true) { /// - Todo: Убрать анимацию, если блок удаляется вне экрана
    var animated = animated
    if animated { animated = self.superview != nil }
    let start = cell.index + 1
    let end = cells.count - 1
    if end >= start {
      for i in start...end {
        let c = cells[i]
        c.index -= 1
        if animated {
          animateif(animated) {
            c.frame = c.frame.offsetBy(dx: 0, dy: -cell.height)
          }
        } else {
          c.frame = c.frame.offsetBy(dx: 0, dy: -cell.height)
        }
      }
    }
    self.deinitCell(cell)
    if animated {
      animate ({
        cell.frame.h = 0
        //cell.alpha = 0.0
      }) {
        cell.removeFromSuperview()
      }
    } else {
      cell.removeFromSuperview()
    }
  }
  open func removeX(_ cells: [Block]) { /// - Todo: Убрать анимацию, если блок удаляется вне экрана
    if cells.count == 0 {
      print("[ERROR] No cells to remove")
      return
    }
    var height: CGFloat = 0
    let firstCell = cells.first!
    let firstCellIndex = firstCell.index
    for cell in cells {
      height += cell.height
      self.deinitCell(cell)
      animate ({
        cell.frame = CGRect(cell.frame.x,firstCell.frame.y,cell.frame.w,0)
      }) {
        cell.removeFromSuperview()
      }
    }
    if firstCellIndex < self.cells.count {
      for i in firstCellIndex...self.cells.count-1 {
        let c = self.cells[i]
        c.index -= cells.count
        animateif(animated) {
          c.frame = c.frame.offsetBy(dx: 0, dy: -height)
        }
      }
    }
  }
  open func removeAll() {
    var heightOffset: CGFloat = 0
    for cell in cells {
      cell.removeFromSuperview()
      cell.tableView = nil
      heightOffset += cell.height
    }
    cells.removeAll()
    height -= heightOffset
  }
  open func removeAll(handler: @escaping ()->()) {
    if self.cells.isEmpty {
      handler()
    } else {
      animate ({
        for cell in self.cells {
          cell.alpha = 0.0
        }
      }) {
        var h: CGFloat = 0
        for cell in self.cells {
          cell.tableView = nil
          h += cell.height
          cell.removeFromSuperview()
          self.cells.removeAll()
        }
        self.height -= h
        handler()
      }
    }
  }
  open func move(_ cell: Block, position: Int) { /// - Todo: Убрать анимацию, если блок двигается вне экрана
    if cell.index == position || position >= cells.count {
      print("TableView: Can't move \(cell.index) -> \(position) in 0...\(cells.count)")
      return
    }
    let y = cells[position].frame.y
    cells.remove(at: cell.index)
    cells.insert(cell, at: position)
    if cell.index > position {
      cell.frame.origin = CGPoint(0,y)
      for i in position + 1...cell.index {
        let c = self.cells[i]
        c.index += 1
        animateif(animated) {
          c.frame = c.frame.offsetBy(dx: 0, dy: cell.height)
        }
      }
    } else {
      cell.frame.origin = CGPoint(0,y)
      for i in cell.index...position-1 {
        let c = self.cells[i]
        c.index -= 1
        animateif(animated) {
          c.frame = c.frame.offsetBy(dx: 0, dy: -cell.height)
        }
      }
    }
    
    cell.index = position
  }
  open func offset(_ offset: CGFloat, from: Int) {
    //        print(from)
    //        print(cells.count)
    if from > self.cells.count - 1 { return }
    animateif(animated) {
      for i in from...self.cells.count-1 {
        let cell = self.cells[i]
        cell.frame = cell.frame.offsetBy(dx: 0, dy: offset)
      }
    }
  }
  
  open var cameraTop: CGFloat {
    return contentOffset.y
  }
  
  open var cameraBottom: CGFloat {
    return contentOffset.y + bounds.h
  }
  
  open func blockTouchDown(_ block: Block) {
    if contentViewDelegate?.blockTouchDown != nil {
      contentViewDelegate?.blockTouchDown!(block)
    }
  }
  open func blockTouchUp(_ block: Block) {
    if contentViewDelegate?.blockTouchUp != nil {
      contentViewDelegate?.blockTouchUp!(block)
    }
    blockSelected(block)
  }
  open func blockTap(_ block: Block) {
    if contentViewDelegate?.blockTap != nil {
      contentViewDelegate?.blockTap!(block)
    }
    blockSelected(block)
  }
  open func blockSelected(_ block: Block) {
    contentViewDelegate?.blockSelected?(block)
  }
  open override func resolutionChanged() {
    super.resolutionChanged()
    for cell in cells {
      cell.frame.w = self.frame.w
    }
  }
}

open class DFContentView: ContentView, DynamicFrame {
  public var dynamicFrame: DFrame?
}

open class DPContentView: ContentView, DynamicPos {
  public var dpos: DPos? { didSet { updateFrame() } }
}
