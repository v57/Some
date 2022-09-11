#if os(iOS)
//
//  TableController.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 6/20/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

public protocol TableControllerDelegate: AnyObject {
  var view: UIView! { get }
  var cells: TableController.Cells { get set }
  
  var contentSize: CGFloat { get set }
  var insets: UIEdgeInsets { get }
  var safeArea: UIEdgeInsets { get }
  var gap: UIOffset { get }
  var size: CGSize { get }
  var cameraSize: CGSize { get }
  var cameraOffset: CGPoint { get }
  var cameraInsets: UIEdgeInsets { get }
  
  var isVisible: Bool { get }
  
  var camera: TableCamera { get }
  var layout: TableLayout { get }
  var controller: TableController { get }
  var isHorizontal: Bool { get }
  var isInitialised: Bool { get set }
  var animator: Animator? { get set }
  
  func animate(animations: @escaping ()->(), completion: @escaping ()->())
}

public class TableController {
  public typealias Cell = TableCell
  public typealias Cells = [TableCell]
  
  public weak var table: TableControllerDelegate!
  
  var isHorizontal: Bool { table.isHorizontal }
  var isInitialised: Bool { table.isInitialised }
  var camera: TableCamera { table.camera }
  var layout: TableLayout { table.layout }
  var cells: [Cell] {
    get { table.cells }
    set { table.cells = newValue }
  }
  public var contentSize: CGFloat {
    get { table.contentSize }
    set { table.contentSize = newValue }
  }
  public var isLoaded: Bool { table.isVisible }
  public func move(cell: Cell, to index: Int, animated: Bool) {
    guard index != cell.index else { return }
    if index > cell.index {
      cells[cell.index+1..<index].forEach {
        $0.index -= 1
      }
    } else {
      cells[index..<cell.index+1].forEach {
        $0.index -= 1
      }
    }
  }
  @discardableResult
  public func remove(cell: Cell, animated: Bool) -> Animator? {
    guard cell.tableInfo?.table === self else { return nil }
    return remove(range: cell.index..<cell.index+1, animated: animated)
  }
  @discardableResult
  public func remove(range: Range<Int>, animated: Bool) -> Animator? {
    guard range.count > 0 else { return nil }
    let removedCells = cells[range]
    cells[range].forEach { $0.tableInfo = nil }
    cells.removeSubrange(range)
    next(range.lowerBound).forEach { $0.index -= range.count }
    
    /*
     - next(range.lowerBound) стоит потому что все в range уже удалены
    */
    let data = TableLayout.Data(action: .removed, previous: previous(range), next: next(range.lowerBound)) { cell, frame in
    //  print("moving cell \(cell.index) \(cell.frame) to \(frame)")
      cell.position = frame.origin
      cell.size = frame.size
    }
    let result = layout.update(cells: removedCells, data: data)
    defer { contentSize += result.offset }
    
    guard isLoaded else { return nil }
    let animator = self.animator(animated)
    let view = table.view!
    // print("removing \(range) from loaded range \(camera.loadedRange)")
    if camera.loadedRange.remove(range) {
      // print("removed \(range.count) cells")

      for cell in removedCells {
        guard cell.table == nil else { continue }
        guard cell.isVisible else { continue }
        cell.hide(animator: animator, removed: true)
      }
    }
    // print("loaded range: \(camera.loadedRange)")
    let cameraResult = camera.update()
    
    cameraResult.unloaded.loop { index in
      let cell = cells[index]
      assert(cell.shouldUpdateFrame)
      animator.animate(cell.updateFrame)
      animator.completion {
        if cell.isVisible {
          cell.hide(animator: nil, removed: false)
        }
      }
    }
    
    for index in result.changedCells {
      let cell = cells[index]
      // в ренже могут быть целки, которые не менялись
      guard cell.view != nil else { continue }
      if cell.shouldUpdateFrame {
        animator.animate(cell.updateFrame)
      }
    }
    
    let context = DisplayContext(animator: nil, created: false, from: .remove)
    cameraResult.loaded.loop { index in
      let cell = cells[index]
      guard !cell.isVisible else { return }
      cell.display(to: view, context: context)
    }
    animate(animator)
    return animator
  }
  
  @discardableResult
  public func resize(range: Range<Int>, animated: Bool) -> Animator? {
    let resizedCells = cells[range]
    
    // Поменял next(range.lowerBound) на next(range) потому что не работало
    let data = TableLayout.Data(action: .resized, previous: previous(range), next: next(range)) { cell, frame in
    //  print("moving cell \(cell.index) \(cell.frame) to \(frame)")
      cell.position = frame.origin
      cell.size = frame.size
    }
    let layoutResult = layout.update(cells: resizedCells, data: data)
    contentSize += layoutResult.offset
    
    guard isLoaded else { return nil }
    let view = table.view!
  //  print("loaded range: \(camera.loadedRange)")
    let cameraResult = camera.update()
    
    let animator = self.animator(animated)
    
    cameraResult.unloaded.loop { index in
      let cell = cells[index]
      assert(cell.shouldUpdateFrame)
      animator.animate(cell.updateFrame)
      animator.completion {
        if cell.isVisible {
          cell.hide(animator: nil, removed: false)
        }
      }
    }
    for index in layoutResult.changedCells {
      let cell = cells[index]
      // в ренже могут быть целки, которые не менялись
      guard cell.view != nil else { continue }
      if cell.shouldUpdateFrame {
        animator.animate(cell.updateFrame)
      }
    }
    let context = DisplayContext(animator: nil, created: false, from: .resize)
    cameraResult.loaded.loop { index in
      let cell = cells[index]
      if !cell.isVisible {
        cell.display(to: view, context: context)
      }
    }
    animate(animator)
    return animator
  }
  
  private func previous(_ range: Range<Int>) -> ArraySlice<Cell> {
    return cells[..<range.lowerBound]
  }
  private func next(_ from: Int) -> ArraySlice<Cell> {
    return cells[from...]
  }
  private func next(_ range: Range<Int>) -> ArraySlice<Cell> {
    return cells[range.upperBound...]
  }
  private func inRange(_ range: Range<Int>) -> ArraySlice<Cell> {
    return cells[range]
  }
  
  @discardableResult
  public func insert(cells newCells: [Cell], at index: Int, animated: Bool) -> Animator? {
    for (i,cell) in newCells.enumerated() {
      cell.tableInfo = TableInfo(table: self, index: index + i)
    }
    let start = index
    let end = index + newCells.count
    let range: Range<Int> = start..<end
    cells.insert(contentsOf: newCells, at: index)
    cells[end...].forEach { $0.index += range.count }
    let data = TableLayout.Data(action: .added, previous: previous(range), next: next(range)) { cell, frame in
      cell.position = frame.origin
      cell.size = frame.size
    }
    let result = layout.update(cells: cells[range], data: data)
    contentSize += result.offset
    
    guard isLoaded else { return nil }
    let animator = self.animator(animated)
    
    let view = table.view!
    let oldValue = camera.loadedRange
    if camera.loadedRange.insert(range) {
      let context = DisplayContext(animator: animator, created: true, from: .insert)
      for cell in newCells {
        if !cell.isVisible {
          cell.display(to: view, context: context)
        }
      }
    }
    if camera.loadedRange != oldValue {
      // print("loaded range changed \(oldValue) -> \(camera.loadedRange)")
    }
    let cameraResult = camera.update()
    
    cameraResult.unloaded.loop { index in
      let cell = cells[index]
      if cell.shouldUpdateFrame {
        animator.animate(cell.updateFrame)
      }
      animator.completion {
        if cell.isVisible {
          cell.hide(animator: nil, removed: false)
        }
      }
    }
    for index in result.changedCells {
      let cell = cells[index]
      // в ренже могут быть целки, которые не менялись
      guard cell.view != nil else { continue }
      if cell.shouldUpdateFrame {
        animator.animate(cell.updateFrame)
      }
    }
    cameraResult.loaded.loop { index in
      let cell = cells[index]
      let created = range.contains(index)
      if !cell.isVisible {
        let context = DisplayContext(animator: created ? animator : nil, created: created, from: .insert)
        cell.display(to: view, context: context)
      }
    }
    
    animate(animator)
    return animator
  }
  
  @discardableResult
  public func append(cells newCells: [Cell], animated: Bool) -> Animator? {
    for (i,cell) in newCells.enumerated() {
      cell.tableInfo = TableInfo(table: self, index: cells.count + i)
    //  print("settings cell index \(cell.index)")
    }
    let start = cells.count
    let end = start+newCells.count
    let range: Range<Int> = start..<end
    cells.append(contentsOf: newCells)
    
    guard isInitialised else { return nil }
    
    let data = TableLayout.Data(action: .added, previous: previous(range), next: [], update: { cell, frame in
      cell.position = frame.origin
      cell.size = frame.size
    })
    let result = layout.update(cells: cells[range], data: data)
    contentSize += result.offset
    guard isLoaded else { return nil }
    let cameraResult = camera.update()
    
    let view = table.view!
    
    let animator = self.animator(animated)
    
    cameraResult.loaded.loop { index in
      let cell = cells[index]
      if !cell.isVisible {
        let context = DisplayContext(animator: animator, created: true, from: .append)
        cell.display(to: view, context: context)
      }
    }
    animate(animator)
    return animator
  }
  @discardableResult
  public func append(cell: Cell, animated: Bool) -> Animator? {
    return append(cells: [cell], animated: animated)
  }
  private func animator(_ animated: Bool) -> Animator {
    if let customAnimator = table.animator {
      return customAnimator
    } else {
      let animator = Animator()
      animator.isAnimated = animated
      return animator
    }
  }
  private func animate(_ animator: Animator) {
    guard !animator.ignoreAnimations else { return }
    animator.animate { animations, completion in
      table.animate(animations: animations, completion: completion)
    }
  }
  @discardableResult
  public func edit(animated: Bool, block: (Animator)->()) -> Animator? {
    let animator = Animator()
    animator.isAnimated = animated
    animator.ignoreAnimations = true
    
    let oldAnimator = table.animator
    table.animator = animator
    defer { table.animator = oldAnimator }
    
    block(animator)
    animator.ignoreAnimations = false
    animate(animator)
    return animator
  }
  
  
  
  @discardableResult
  public func tableUpdated(animated: Bool) -> Animator? {
    var action: TableLayout.Data.Action = .resized
    if !isInitialised {
      table.isInitialised = true
      action = .added
    }
    guard !cells.isEmpty else { return nil }
    let data = TableLayout.Data(action: action, previous: [], next: [], update: { cell, frame in
      cell.position = frame.origin
      cell.size = frame.size
    })
    
    let layoutResult = layout.update(cells: ArraySlice(cells), data: data)
    contentSize += layoutResult.offset
    
    guard isLoaded else { return nil }
    let cameraResult = camera.update()
    let view = table.view!
    let animator = self.animator(animated)
    
    cameraResult.unloaded.loop { index in
      let cell = cells[index]
      // assert(cell.shouldUpdateFrame)
      animator.animate(cell.updateFrame)
      animator.completion {
        guard cell.isVisible else { return }
        cell.hide(animator: nil, removed: false)
      }
    }
    for index in layoutResult.changedCells {
      let cell = cells[index]
      // в ренже могут быть целки, которые не менялись
      guard cell.view != nil else { continue }
      if cell.shouldUpdateFrame {
        animator.animate(cell.updateFrame)
      }
    }
    cameraResult.loaded.loop { index in
      let cell = cells[index]
      guard !cell.isVisible else { return }
      let context = DisplayContext(animator: nil, created: false, from: .update)
      cell.display(to: view, context: context)
    }
    animate(animator)
    return animator
  }
}

extension TableController {
  public func scrolled() {
    let context = DisplayContext(animator: nil, created: false, from: .scroll)
    scrolled(context: context)
  }
  public func scrolled(context: DisplayContext) {
    guard isLoaded else { return }
  //  print("scrolling from \(camera.loadedRange)")
    
    let result = camera.update()
    
  //  print("loading top: \(result.loadedTop)/\(cells.count)")
  //  print("loading bottom: \(result.loadedBottom)/\(cells.count)")
  //  print("unloading top: \(result.unloadedTop)/\(cells.count)")
  //  print("unloading top: \(result.unloadedBottom)/\(cells.count)")
    
    display(result.loadedTop, context: context)
    display(result.loadedBottom, context: context)
    hide(result.unloadedTop)
    hide(result.unloadedBottom)
  }
  private func display(_ range: Range<Int>, context: DisplayContext) {
    let view = table.view!
    for index in range {
      let cell = cells[index]
      cell.display(to: view, context: context)
    }
  }
  private func hide(_ range: Range<Int>) {
    for index in range {
      let cell = cells[index]
      cell.hide(animator: nil, removed: false)
    }
  }
}
#endif
