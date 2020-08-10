#if os(iOS)
//
//  CellPicker.swift
//  SomeTable
//
//  Created by Dmitry on 8/27/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

public protocol CellPickerEvents {
  func shouldPick() -> Bool
  func willPick(cell: Cell, animator: Animator)
  func didPick(cell: Cell, animator: Animator)
  
  func shouldPop(cell: Cell, in table: Table) -> Bool
  func willPop(cell: Cell, animator: Animator)
  func didPop(cell: Cell, animator: Animator)
}

private class DefaultCellPickerEvents: CellPickerEvents {
  func willPick(cell: Cell, animator: Animator) {
    
  }
  
  func didPick(cell: Cell, animator: Animator) {
    guard let view = cell.view else { return }
    animator.animate {
      view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
      view.alpha = 0.5
    }
  }
  
  func shouldPop(cell: Cell, in table: Table) -> Bool {
    return true
  }
  
  func willPop(cell: Cell, animator: Animator) {
    guard let view = cell.view else { return }
    animator.animate {
      view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
      view.alpha = 0.5
    }
  }
  
  func didPop(cell: Cell, animator: Animator) {
    
  }
  
  func shouldPick() -> Bool {
    return true
  }
  
  
  let cell: Cell
  init(cell: Cell) {
    self.cell = cell
  }
}

private extension Cell {
  var events: CellPickerEvents {
    return self as? CellPickerEvents ?? DefaultCellPickerEvents(cell: self)
  }
}

public extension Cell {
  @discardableResult
  func pick(animated: Bool) -> CellPicker {
    assert(self.tableInfo != nil, "Trying to pick cell thats not in table")
    let tableInfo = self.tableInfo!
    let index = tableInfo.index
    let table = tableInfo.table
    let events = self.events
    let animator = Animator()
    animator.isAnimated = animated
    events.willPick(cell: self, animator: animator)
    let picker = CellPicker(cell: self)
    table.cells[index] = picker
    events.didPick(cell: self, animator: animator)
    return picker
  }
  
  
}

public class CellPicker: EmptyCell {
  let cell: Cell
  weak var superview: UIView?
  var isDisplayed: Bool
  init(cell: Cell) {
    self.cell = cell
    isDisplayed = cell.isVisible
    super.init()
    self.tableInfo = cell.tableInfo
  }
  public override func display(to view: UIView, context: DisplayContext) {
    superview = view
  }
  public override func hide(animator: Animator?, removed: Bool) {
    superview = nil
  }
  public override func size(fitting: CGSize, max: CGSize) -> CGSize {
    return cell.size(fitting:fitting, max: max)
  }
  func pop(animated: Bool) {
    tableInfo!.table.remove(cell: self, animated: animated)
  }
  @discardableResult
  func cancel(animated: Bool) -> Animator {
    let animator = Animator()
    animator.isAnimated = animated
    let tableInfo = self.tableInfo!
    let index = tableInfo.index
    let table = tableInfo.table
    let events = cell.events
    cell.position = position
    cell.size = size
    cell.updateFrame()
    
    events.willPop(cell: cell, animator: animator)
    
    table.cells[index] = cell
    if let view = superview {
      cell.display(to: view, context: DisplayContext(animator: animator, created: false, from: .picker))
    }
    
    events.didPop(cell: cell, animator: animator)
    return animator
  }
}
#endif
