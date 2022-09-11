#if os(iOS)
//
//  TableLayout.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 6/20/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

public struct TableInfo {
  public unowned var table: TableController
  public var index: Int
}

public protocol TableCell: CellLayout, DisplayableCell, CustomStringConvertible {
  var position: CGPoint { set get }
  var size: CGSize { set get }
  var tableInfo: TableInfo? { get set }
}
public protocol DisplayableCell: AnyObject {
  var view: UIView! { get set }
  var isVisible: Bool { get }
  func loaded()
  func unloaded()
  func display(to view: UIView, context: DisplayContext)
  func hide(animator: Animator?, removed: Bool)
  func updateFrame()
  func scrolled(context: CellScrollContext)
}
public protocol CellLayout {
  var customGap: CGFloat? { get }
  func size(fitting: CGSize, max: CGSize) -> CGSize
}

extension TableCell {
  public var frame: CGRect { CGRect(origin: position, size: size) }
}
extension TableCell {
  var index: Int {
    get { tableInfo!.index }
    set { tableInfo!.index = newValue }
  }
  var table: TableController? {
    get { tableInfo?.table }
  }
}
extension TableCell {
  var shouldUpdateFrame: Bool {
    return view.frame.origin != position || view.frame.size != size
  }
}


open class TableLayout {
  public static var vertical: TableLayout { Vertical() }
  public static var horizontal: TableLayout { Horizontal() }
  public static var verticalGrid: TableLayout { VerticalGrid() }
  public static var horizontalGrid: TableLayout { HorizontalGrid() }
  
  public typealias Cell = TableCell
  public typealias Cells = ArraySlice<TableCell>
  public weak var table: TableControllerDelegate!
  
  
  public struct Data {
    public enum Action {
      case added, resized, removed
    }
    public let action: Action
    public let previous: Cells
    public let next: Cells
    public let update: (Cell,CGRect)->()
  }
  public struct MovingData {
    public let previous: Cells
    public let next: Cells
    public let between: Cells
    public let from: Int
    public let update: (Cell,CGRect)->()
  }
  public struct Result {
    public var offset: CGFloat = 0
    public var changedCells: Range<Int> = 0..<0
  }
  open func insetsChanged(oldValue: UIEdgeInsets, newValue: UIEdgeInsets, contentSize: inout CGFloat) {
    
  }
  open func update(cells: Cells, data: Data) -> Result {
    fatalError()
  }
  open func move(cells: Cells, to: Int, data: Data) -> Result {
    fatalError()
  }
  
  private func setChangedRange(_ result: inout Result, _ cells: Cells, data: Data) {
    switch data.action {
    case .added, .resized:
      if let index = cells.first?.index {
        result.changedCells = index..<cells.last!.index + 1
      }
    case .removed:
      if let index = data.next.first?.index {
        result.changedCells = index..<index
      }
    }
  }
  private func extendChangedRange(_ result: inout Result, _ cells: Cells, data: Data) {
    if let index = data.next.last?.index {
      result.changedCells.last = index
    }
  }
  
  // MARK: Vertical
  public class Vertical: TableLayout {
    var offset: CGPoint {
      return table.insets.topLeft + table.safeArea.topLeft
    }
    var gap: CGFloat {
      table.gap.vertical
    }
    func gap(for cell: Cell) -> CGFloat {
      cell.customGap ?? gap
    }
    var width: CGFloat {
      return table.cameraSize.width - table.insets.width - table.safeArea.width
    }
    var async: Bool { false }
    public override func update(cells: Cells, data: Data) -> Result {
      var result = Result()
      setChangedRange(&result, cells, data: data)
      
      // max cell size
      let fittingSize = CGSize(width,0)
      
      // finding start position
      var position: CGPoint = self.offset
      if let previous = data.previous.last {
        position = previous.position + CGPoint(0,previous.size.height + gap(for: previous))
      }
      
      // updating current cell
      if async {
        let queue = OperationQueue()
        let lock = NSLock()
        switch data.action {
        case .added:
        for chunk in cells.chunks(30) {
          queue.addOperation {
            for cell in chunk {
              cell.size = cell.size(fitting: fittingSize, max: fittingSize)
            }
          }
        }
        case .resized:
          for chunk in cells.chunks(30) {
            queue.addOperation {
              var offset: CGFloat = 0
              for cell in chunk {
                let height = cell.size.height
                cell.size = cell.size(fitting: fittingSize, max: fittingSize)
                offset += cell.size.height - height
              }
              lock.lock()
              result.offset += offset
              lock.unlock()
            }
          }
        case .removed: break
        }
        queue.waitUntilAllOperationsAreFinished()
        switch data.action {
        case .added:
          for cell in cells {
            let size = cell.size
            
            let offset = size.height + gap(for: cell)
            result.offset += offset
            data.update(cell,CGRect(position,size))
            
            position.y += offset
          }
        case .resized:
          for cell in cells {
            let size = cell.size
            
            if position != cell.position || offset != .zero {
              data.update(cell,CGRect(position,size))
            }
            position.y += size.height + gap(for: cell)
          }
        case .removed:
          for cell in cells {
            let offset = cell.size.height + gap(for: cell)
            result.offset -= offset
          }
        }
      } else {
        for cell in cells {
          switch data.action {
          case .added:
            let size = cell.size(fitting: fittingSize, max: fittingSize)
            
            let offset = size.height + gap(for: cell)
            result.offset += offset
            data.update(cell,CGRect(position,size))
            
            position.y += offset
          case .resized:
            let size = cell.size(fitting: fittingSize, max: fittingSize)
            
            let offset = size - cell.size
            result.offset += offset.height
            
            if position != cell.position || offset != .zero {
              data.update(cell,CGRect(position,size))
            }
            position.y += size.height + gap(for: cell)
          case .removed:
            let offset = cell.size.height + gap(for: cell)
            result.offset -= offset
          }
        }
      }
      
      // updating next cells if needed
      guard result.offset != 0 else { return result }
      
      extendChangedRange(&result, cells, data: data)
      
      for cell in data.next { data.update(cell,CGRect(cell.position+CGPoint(0,result.offset),cell.size))
      }
      return result
    }
  }
  
  // MARK: Horizontal
  public class Horizontal: TableLayout {
    var offset: CGPoint {
      return table.insets.topLeft + table.safeArea.topLeft
    }
    var gap: CGFloat {
      return table.gap.horizontal
    }
    var height: CGFloat {
      return table.cameraSize.height - table.insets.height - table.safeArea.height
    }
    
    public override func update(cells: Cells, data: Data) -> Result {
      var result = Result()
      setChangedRange(&result, cells, data: data)
      
      // max cell size
      let fittingSize = CGSize(0,height)
      
      // finding start position
      var position: CGPoint = self.offset
      if let previous = data.previous.last {
        position = previous.position + CGPoint(previous.size.width + gap,0)
      }
      
      
      // updating current cell
      for cell in cells {
        switch data.action {
        case .added:
          let size = cell.size(fitting: fittingSize, max: fittingSize)
          
          let offset = size.width + gap
          result.offset += offset
          data.update(cell,CGRect(position,size))
          
          position.x += offset
        case .resized:
          let size = cell.size(fitting: fittingSize, max: fittingSize)
          
          let offset = size - cell.size
          result.offset += offset.width
          
          guard position != cell.position || offset != .zero else { continue }
          data.update(cell,CGRect(position,size))
          
          position.x += size.width + gap
        case .removed:
          let offset = cell.size.width + gap
          result.offset -= offset
        }
      }
      
      // updating next cells if needed
      guard result.offset != 0 else { return result }
      
      for cell in data.next { data.update(cell,CGRect(cell.position+CGPoint(result.offset,0),cell.size))
      }
      return result
    }
  }
  
  // MARK: Vertical Grid
  public class VerticalGrid: TableLayout {
    var offset: CGPoint {
      return table.insets.topLeft + table.safeArea.topLeft
    }
    var vgap: CGFloat {
      return table.gap.vertical
    }
    var hgap: CGFloat {
      return table.gap.horizontal
    }
    var horizontal: Bool {
      return false
    }
    
    func currentLineHeight(cells: Cells, data: Data) -> CGFloat {
      let firstY = cells.first!.position.y
      var lineHeight: CGFloat = 0
      for cell in data.previous.reversed() {
        guard firstY == cell.position.y else { return lineHeight }
        lineHeight.set(max: cell.size.height)
      }
      return lineHeight
    }
    
    public override func update(cells: Cells, data: Data) -> Result {
      var result = Result()
      setChangedRange(&result, cells, data: data)
      
      let fwidth = table.cameraSize.width - table.insets.right - table.safeArea.width
      let maxSize = CGSize(fwidth - table.insets.left,0)
      
      var position: CGPoint = self.offset
      if let previous = data.previous.last {
        position = CGPoint(previous.position.x + previous.size.width + hgap, previous.position.y)
      }
      
      var oldLineHeight = currentLineHeight(cells: cells, data: data)
      var lineHeight = oldLineHeight
      var shouldReset: CGFloat = 0
      
      switch data.action {
      case .added:
        for cell in cells {
          let fitting = CGSize(fwidth - position.x, lineHeight)
          let size = cell.size(fitting: fitting, max: maxSize)
          
          if size.width > fitting.width {
            result.offset += lineHeight - oldLineHeight
            oldLineHeight = 0
            
            position.x = table.insets.left
            position.y += lineHeight + vgap
            lineHeight = size.height
            shouldReset = size.height
          } else {
            lineHeight.set(max: size.height)
            shouldReset = lineHeight
          }
          data.update(cell, CGRect(position,size))
          position.x += size.width + hgap
        }
        var shouldOffset = false
        for cell in data.next {
          if shouldOffset {
            var position = cell.position
            position.y += result.offset
            data.update(cell, CGRect(position,cell.size))
          } else {
            let fitting = CGSize(fwidth - position.x, lineHeight)
            let size = cell.size(fitting: fitting, max: maxSize)
            
            if size.width > fitting.width {
              if oldLineHeight != 0 {
                result.offset += oldLineHeight - lineHeight
              }
              position.x = table.insets.left
              position.y += lineHeight + vgap
              lineHeight = size.height
              shouldReset = lineHeight
            } else {
              lineHeight.set(max: size.height)
              shouldReset = 0
            }
            if cell.position == position && cell.size == size {
              if result.offset > 0 {
                shouldOffset = true
                result.changedCells.last = data.next.last!.index
              }
            } else {
              data.update(cell,CGRect(position,size))
              position.x += size.width + hgap
              result.changedCells.end += 1
            }
          }
        }
        result.offset += shouldReset
      case .resized:
        // Привет долбаеб из будущего. Короче такая хуйня. Нужно удалить result.offset += везде и заменить на сравнение position.y последней клетки + высота последней линии до и после изменений

        for cell in cells {
          
          let fitting = CGSize(fwidth - position.x, lineHeight)
          let size = cell.size(fitting: fitting, max: maxSize)
          
          if size.width > fitting.width {
            if lineHeight == 0 {
              lineHeight = oldLineHeight
            }
            if oldLineHeight != 0 {
              result.offset += lineHeight - oldLineHeight
              #if TableLogs
              print("result.offset += lineHeight - oldLineHeight \(result.offset) += \(lineHeight) - \(oldLineHeight) (1)")
              #endif
            }
            position.x = table.insets.left
            position.y += lineHeight + vgap
            lineHeight = size.height
            shouldReset = lineHeight
          } else {
            oldLineHeight.set(max: cell.size.height)
            lineHeight.set(max: size.height)
            shouldReset = 0
          }
          data.update(cell,CGRect(position,size))
          position.x += size.width + hgap
        }
        shouldReset = lineHeight - oldLineHeight
        
        var shouldOffset = false
        for cell in data.next {
          if shouldOffset {
            var position = cell.position
            position.y += result.offset
            data.update(cell, CGRect(position,cell.size))
          } else {
            oldLineHeight.set(max: cell.size.height)
            
            let fitting = CGSize(fwidth - position.x, lineHeight)
            let size = cell.size(fitting: fitting, max: maxSize)
            
            if size.width > fitting.width {
              if oldLineHeight != 0 {
                result.offset += lineHeight - oldLineHeight
                #if TableLogs
                print("result.offset += lineHeight - oldLineHeight \(result.offset) += \(lineHeight) - \(oldLineHeight) (2)")
                #endif
              }
              position.x = table.insets.left
              position.y += lineHeight + vgap
              #if TableLogs
              print(position)
              #endif
              lineHeight = size.height
//              shouldReset = lineHeight
            } else {
              lineHeight.set(max: size.height)
              shouldReset = 0
            }
            if cell.position == position && cell.size == size {
              if result.offset > 0 {
                shouldOffset = true
                result.changedCells.last = data.next.last!.index
              } else {
                break
              }
            } else {
              data.update(cell,CGRect(position,size))
              position.x += size.width + hgap
              result.changedCells.end += 1
            }
          }
        }
        
        result.offset += shouldReset
        #if TableLogs
        print("result.offset += shouldReset \(result.offset) += \(shouldReset)")
        if result.offset > 0 {
          print("offset +\(result.offset), \(result.changedCells)")
        } else {
          print("offset \(result.offset), \(result.changedCells)")
        }
        #endif
      case .removed:
        if data.next.count == 0 {
          do {
            var i = 0
            if lineHeight > 0 {
              var first = Line()
              first.size = lineHeight
              first.parse(i: &i, y: position.y, cells: cells)
              let offset = lineHeight - first.size
              if offset < 0 {
                result.offset += offset
              }
              #if TableLogs
              print("offset: \(result.offset)")
              #endif
            }
            var last = Line()
            while i < cells.count {
              last.parse(i: &i, cells: cells, horizontal: horizontal)
              result.offset -= last.size
              #if TableLogs
              print("offset: \(result.offset)")
              #endif
            }
            if last.size > 0 { // last
              i = 0
              var next = Line()
              next.size = last.size
              next.parse(i: &i, y: cells.last!.position.y, cells: data.next)
              let offset = next.size - last.size
              if offset < 0 {
                result.offset += offset
                #if TableLogs
                print("offset: \(result.offset)")
                #endif
              }
            }
          }
        }
        
        if data.next.count > 0 {
          let lastY = data.next.last!.position.y
          
          var shouldOffset = false
          for cell in data.next {
            if shouldOffset {
              var position = cell.position
              position.y += result.offset
              data.update(cell, CGRect(position,cell.size))
            } else {
              oldLineHeight.set(max: cell.size.height)
              
              let fitting = CGSize(fwidth - position.x, lineHeight)
              let size = cell.size(fitting: fitting, max: maxSize)
              
              if size.width > fitting.width {
                if oldLineHeight != 0 {
                  result.offset += lineHeight - oldLineHeight
                }
                position.x = table.insets.left
                position.y += lineHeight + vgap
                lineHeight = size.height
                //              shouldReset = lineHeight
              } else {
                lineHeight.set(max: size.height)
                shouldReset = 0
              }
              if cell.position == position && cell.size == size {
                if result.offset > 0 {
                  shouldOffset = true
                  result.changedCells.last = data.next.last!.index
                } else {
                  break
                }
              } else {
                data.update(cell,CGRect(position,size))
                position.x += size.width + hgap
                result.changedCells.end += 1
              }
            }
          }
          result.offset += data.next.last!.position.y - lastY
        }
      }
      let newContentSize = Line(reversed: cells, data: data, horizontal: horizontal, completed: true).bottom
      result.offset = 0
      table.contentSize = newContentSize
      return result
    }
  }
  
  // MARK: Horizontal Grid
  public class HorizontalGrid: TableLayout {
    var offset: CGPoint {
      return table.insets.topLeft + table.safeArea.topLeft
    }
    var vgap: CGFloat {
      return table.gap.vertical
    }
    var hgap: CGFloat {
      return table.gap.horizontal
    }
    
    public override func update(cells: Cells, data: Data) -> Result {
      var result = Result()
      setChangedRange(&result, cells, data: data)
      
      let fheight = table.cameraSize.height - table.insets.bottom - table.safeArea.height
      let maxSize = CGSize(0,fheight - table.insets.top)
      
      var position: CGPoint = self.offset
      var lineWidth: CGFloat = 0
      
      if let leftCell = data.previous.last {
        position = leftCell.position + CGPoint(0,leftCell.size.height + vgap)
        for cell in data.previous.reversed() {
          guard cell.position.x == position.x else { break }
          lineWidth = max(cell.size.width,lineWidth)
        }
        if fheight - position.y <= 0 {
          position.y = table.insets.top
          position.x += lineWidth + hgap
        }
      }
      
      if data.action == .added || data.action == .resized {
        for cell in cells {
          let fitting = CGSize(lineWidth, fheight - position.y)
          
          let size = cell.size(fitting: fitting, max: maxSize)
          if size.height > fitting.height {
            lineWidth = size.width
            position.y = table.insets.top
            position.x += lineWidth + hgap
          } else {
            lineWidth = max(cell.size.width,lineWidth)
          }
          data.update(cell,CGRect(position,size))
          position.y += size.height + vgap
        }
      }
      
      for cell in data.next {
        let fitting = CGSize(lineWidth, fheight - position.y)
        
        let size = cell.size(fitting: fitting, max: maxSize)
        if size.height > fitting.height {
          lineWidth = size.width
          position.y = table.insets.top
          position.x += lineWidth + hgap
        } else {
          lineWidth = max(cell.size.width,lineWidth)
        }
        if cell.position == position && cell.size == size {
          break
        }
        data.update(cell,CGRect(position,size))
        position.y += size.height + vgap
      }
      extendChangedRange(&result, cells, data: data)
      result.offset = position.x + lineWidth
      return result
    }
  }
}




private extension ArraySlice {
  func at(_ index: Int) -> Element {
    return self[startIndex+index]
  }
}



private struct Line {
  var position: CGFloat = 0
  var size: CGFloat = 0.0
  var bottom: CGFloat {
    return position + size
  }
  init() {}
  init(reversed cells: TableLayout.Cells, data: TableLayout.Data, horizontal: Bool, completed: Bool) {
    var i = 0
    var checkMiddle = cells.count > 0
    #if TableLogs
    defer { print("Line \(position) \(size) \(completed)") }
    #endif
    if (!completed && data.action == .added) || (completed && data.action == .removed) {
      checkMiddle = false
    }
    if data.next.count > 0 {
      i = data.next.count - 1
      reverseParse(i: &i, cells: data.next, horizontal: horizontal)
      guard i == 0 else { return }
    }
    if checkMiddle {
      i = cells.count - 1
      reverseParse(i: &i, cells: cells, horizontal: horizontal)
      guard i == 0 else { return }
    }
    if data.previous.count > 0 {
      i = data.previous.count - 1
      reverseParse(i: &i, cells: data.previous, horizontal: horizontal)
    }
  }
  init(cells: TableLayout.Cells, data: TableLayout.Data, completed: Bool, horizontal: Bool) {
    var i = 0
    var checkMiddle = cells.count > 0
    if (!completed && data.action == .added) || (completed && data.action == .removed) {
      checkMiddle = false
    }
    if data.previous.count > 0 {
      reverseParse(i: &i, cells: data.previous, horizontal: horizontal)
      guard i == data.previous.count - 1 else { return }
    }
    if checkMiddle {
      reverseParse(i: &i, cells: cells, horizontal: horizontal)
      guard i == cells.count - 1 else { return }
    }
    if data.next.count > 0 {
      reverseParse(i: &i, cells: data.next, horizontal: horizontal)
    }
    #if TableLogs
    print("Line \(position) \(size)")
    #endif
  }
  
  mutating func parse(i: inout Int, cells: ArraySlice<TableLayout.Cell>, horizontal: Bool) {
    if horizontal {
      if position == 0 {
        position = cells.at(i).position.x
      }
      parse(i: &i, x: position, cells: cells)
    } else {
      if position == 0 {
        position = cells.at(i).position.y
      }
      parse(i: &i, y: position, cells: cells)
    }
  }
  mutating func reverseParse(i: inout Int, cells: ArraySlice<TableLayout.Cell>, horizontal: Bool) {
    if horizontal {
      if position == 0 {
        position = cells.at(i).position.x
      }
      parse(i: &i, x: position, cells: cells)
    } else {
      if position == 0 {
        position = cells.at(i).position.y
      }
      parse(i: &i, y: position, cells: cells)
    }
  }
  mutating func parse(i: inout Int, x: CGFloat, cells: ArraySlice<TableLayout.Cell>) {
    while i < cells.count {
      let cell = cells.at(i)
      i += 1
      guard cell.position.x == x else { break }
      size.set(max: cell.frame.size.width)
    }
  }
  mutating func reverseParse(i: inout Int, x: CGFloat, cells: ArraySlice<TableLayout.Cell>) {
    while i < cells.count {
      let cell = cells.at(i)
      i -= 1
      guard cell.position.x == x else { break }
      size.set(max: cell.frame.size.width)
    }
  }
  mutating func parse(i: inout Int, y: CGFloat, cells: ArraySlice<TableLayout.Cell>) {
    while i < cells.count {
      let cell = cells.at(i)
      i += 1
      guard cell.position.y == y else { break }
      size.set(max: cell.frame.size.height)
    }
  }
  mutating func reverseParse(i: inout Int, y: CGFloat, cells: ArraySlice<TableLayout.Cell>) {
    while i < cells.count {
      let cell = cells.at(i)
      i -= 1
      guard cell.position.y == y else { break }
      size.set(max: cell.frame.size.height)
    }
  }
}

extension ArraySlice {
  func chunks(_ chunkSize: Int) -> [ArraySlice<Element>] {
    var slices = [ArraySlice<Element>]()
    let chunks = count / chunkSize
    slices.reserveCapacity(chunks)
    for i in 0..<chunks {
      let a = i*chunkSize
      slices.append(self[startIndex+a..<startIndex+a+chunkSize])
    }
    let lastChunkSize = count % chunkSize
    if lastChunkSize > 0 {
      let a = chunkSize*chunks
      slices.append(self[startIndex+a..<startIndex+a+lastChunkSize])
    }
    return slices
  }
}
#endif
