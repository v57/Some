#if os(iOS)
//
//  TableVision.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 6/20/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

private extension Range where Bound: Numeric {
  static var zero: Range<Bound> { return 0..<0 }
  init() {
    self = 0..<0
  }
  mutating func close() {
    self = lowerBound..<lowerBound
  }
}

public class TableCamera {
  public static var vertical: TableCamera { Vertical() }
  public static var horizontal: TableCamera { Horizontal() }
  weak var table: TableControllerDelegate!
  
  typealias Cell = TableCell
  typealias Cells = Array<TableCell>
  class UpdateResult {
    var unloadedTop = Range<Int>()
    var unloadedBottom = Range<Int>()
    var loadedTop = Range<Int>()
    var loadedBottom = Range<Int>()
    var unloaded: [Range<Int>] { return [unloadedTop,unloadedBottom] }
    var loaded: [Range<Int>] { return [loadedTop,loadedBottom] }
  }
  
  var cells: Cells {
    return table.cells
  }
  var loadedRange = Range<Int>()
  func open() -> UpdateResult {
    return update()
  }
  func close() {
    loadedRange.close()
  }
  func update() -> UpdateResult {
    let result = UpdateResult()
    if !cells.isEmpty {
    //  print("camera: updating \(cells)")
      check(result)
    }
  //  print("camera: updated",result.loadedBottom.count, result.loadedTop.count, result.unloadedTop.count, result.unloadedBottom.count)
    return result
  }
  func isVisible(_ cell: TableCell) -> Bool {
    return !isBelowCamera(cell) && !isAboveCamera(cell)
  }
  func isAboveCamera(_ cell: Cell) -> Bool {
    return false
  }
  func isBelowCamera(_ cell: Cell) -> Bool {
    return false
  }
  var frame: CGRect {
    get { .zero }
    set { }
  }
  class Vertical: TableCamera {
    var frameHeight: CGFloat { table.cameraSize.height }
    var offsetY: CGFloat = 0
    override var frame: CGRect {
      get { CGRect(0, offsetY, 0, 0) }
      set {
        offsetY = newValue.origin.y
      }
    }
    override func isAboveCamera(_ cell: TableCamera.Cell) -> Bool {
      return cell.position.y + cell.size.height <= offsetY
    }
    override func isBelowCamera(_ cell: TableCamera.Cell) -> Bool {
      return cell.position.y >= offsetY + frameHeight
    }
  }
  class Horizontal: TableCamera {
    var frameWidth: CGFloat { table.cameraSize.width }
    var offsetX: CGFloat = 0
    override var frame: CGRect {
      get { CGRect(offsetX, 0, 0, 0) }
      set {
        offsetX = newValue.origin.y
      }
    }
    override func isAboveCamera(_ cell: TableCamera.Cell) -> Bool {
      return cell.position.x + cell.size.width < offsetX
    }
    override func isBelowCamera(_ cell: TableCamera.Cell) -> Bool {
      return cell.position.x > offsetX + frameWidth
    }
  }
}

// private
private extension TableCamera {
  func check(_ result: UpdateResult) {
    let shouldCheckBottom = checkTop(result)
    if shouldCheckBottom {
      checkBottom(result)
    }
    
    loadedRange.removeBound(result.unloadedTop)
    loadedRange.removeBound(result.unloadedBottom)
    
    loadedRange.merge(with: result.loadedTop)
    
    loadedRange.merge(with: result.loadedBottom)
  }
  
  private func checkTop(_ result: UpdateResult) -> Bool {
    let start = loadedRange.lowerBound
  //  print("checking top from \(start) camera frame: \(frame)")
    if start == cells.count || isVisible(cells[start]) {
    //  print("top is visible. checking top cells to load")
      result.loadedTop = range(from: start, reversed: true, until: { cell, index in
      //  print("above camera: \(isAboveCamera(cell))")
        return isAboveCamera(cell) })
    //  print("loading top \(result.loadedTop)")
      return true
    } else if isBelowCamera(cells[start]) {
      result.unloadedBottom = loadedRange
    //  print("top is not visible and below camera. unloading all cells and searching for loaded cells")
      let skippedRange = range(from: start, reversed: true, until: { cell, index in
      //  print("not below camera: \(!isBelowCamera(cell))")
        return !isBelowCamera(cell)
      })
    //  print("found bottom loaded cell at \(skippedRange.lowerBound). skipped \(skippedRange)")
    //  print("searching for top loaded cell from \(skippedRange.lowerBound)")
      result.loadedTop = range(from: skippedRange.lowerBound, reversed: true, until: { cell, index in
      //  print("above camera: \(isAboveCamera(cell))")
        return isAboveCamera(cell) })
    //  print("unloaded \(result.unloadedBottom)")
    //  print("loaded \(result.loadedTop)")
      return false
    } else if !loadedRange.isEmpty {
    //  print("top is not visible. checking bottom cells to unload")
      var unloaded = range(from: start+1, reversed: false, until: { cell, index in
      //  print("not above camera: \(!isAboveCamera(cell))")
        return !isAboveCamera(cell) || !loadedRange.contains(index) })
      unloaded.expandLeft(by: 1)
    //  print("unloading top \(unloaded)")
      result.unloadedTop = unloaded
      return true
    } else {
    //  print("top is not visible and no cells loaded. check bottom will solve this problem")
      return true
    }
  }
  
  private func checkBottom(_ result: UpdateResult) {
    let start = loadedRange.upperBound
    assert(start <= cells.count)
//    guard start <= cells.count else {
//    //  print("loadedRange.upperBound(\(loadedRange.upperBound)) >= cells.count(\(cells.count)) skipping bottom")
//      return }
  //  print("checking bottom from \(start)")
    if loadedRange.upperBound != cells.count && isVisible(cells[start]) {
    //  print("bottom is visible. checking bottom cells to load")
      let loaded = range(from: start, reversed: false, until: { cell, index in
      //  print("below camera: \(isBelowCamera(cell))")
        return isBelowCamera(cell) })
    //  print("loading \(loaded)")
    //  print("loading bottom \(loaded)")
      guard !loaded.isEmpty else { return }
//      loaded.reduceRight(by: 1)
      result.loadedBottom = loaded
    } else if loadedRange.upperBound != cells.count && isAboveCamera(cells[start]) {
    //  print("bottom unloaded cell is not visible and above camera. searching for first loaded")
    //  print("(checkTop should unload all cells)")
      let skippedRange = range(from: start, reversed: false, until: { cell, index in
      //  print("not above camera: \(!isAboveCamera(cell))")
        return !isAboveCamera(cell)
      })
    //  print("found first loaded cell at \(skippedRange.upperBound). skipped \(skippedRange)")
    //  print("searching for last loaded cell from \(skippedRange.upperBound)")
      result.loadedBottom = range(from: skippedRange.upperBound, reversed: false, until: { cell, index in
      //  print("below camera: \(isBelowCamera(cell))")
        return isBelowCamera(cell)
      })
    //  print("unloaded \(result.unloadedTop)")
    //  print("loaded \(result.loadedBottom)")
    } else {
    //  print("bottom is not visible. checking top cells to unload")
      let unloaded = range(from: start, reversed: true, until: { cell, index in
      //  print("not below camera: \(!isBelowCamera(cell))")
        return !isBelowCamera(cell) })
//      unloaded.expandRight(by: 1)
    //  print("unloading bottom \(unloaded)")
      result.unloadedBottom = unloaded
    }
  }
  
  private func loadBottom(_ result: UpdateResult) {
  //  print("first load")
    let unloaded = range(from: -1, reversed: false, until: { cell, index in
    //  print("not above camera: \(!isAboveCamera(cell))")
      return !isAboveCamera(cell) })
    //    unloaded.move(by: -1)
    var loaded = range(from: unloaded.upperBound - 1, reversed: false, until: { cell, index in isBelowCamera(cell) })
    loaded.move(by: -1)
    result.loadedBottom = loaded
  }
  
  private func range(from: Int, reversed: Bool, until: (Cell,Int) -> Bool) -> Range<Int> {
    if reversed {
      guard from >= 1 else { return 0..<0 }
      for i in (0..<from).reversed() {
        let cell = cells[i]
      //  print("cell \(i) \(cell)", terminator: " ")
        if until(cell,i) {
        //  print("stopped. setting range \(i+1)..<\(from)")
          return i + 1..<from
        }
      }
    //  print("not stopped. setting range 0..<\(from)")
      return 0..<from
    } else {
      let count = cells.count
      guard from < count else { return count..<count }
      for i in from..<count {
        let cell = cells[i]
      //  print("cell \(i) \(cell)", terminator: " ")
        if until(cell,i) {
        //  print("stopped. setting range \(from)..<\(i)")
          return from..<i
        }
      }
    //  print("not stopped. setting range \(from)..<\(count)")
      return from..<count
    }
  }
}
#endif
