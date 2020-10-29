//
//  Weak.swift
//  
//
//  Created by Dmitry Kozlov on 5/14/20.
//

import Swift

public struct Unowned<T: AnyObject> { // 8 bytes
  public unowned var value: T
  public init(_ value: T) {
    self.value = value
  }
}
public struct Weak<T: AnyObject> { // 40 bytes
  public weak var value : T?
  public init (_ value: T) {
    self.value = value
  }
  @discardableResult
  public func `do`(_ action: (T)->()) -> Bool {
    guard let value = value else { return false }
    action(value)
    return true
  }
}

// MARK: WeakArray
public class WeakArray<T: AnyObject> {
  private var content = [Weak<T>]()
  public init() {}
  public var isEmpty: Bool { count == 0 }
  public var count: Int {
    update()
    return content.count
  }
  public var allObjects: [T] {
    update()
    var array = [T]()
    for object in content {
      guard let value = object.value else { continue }
      array.append(value)
    }
    return array
  }
  
  public func removeObject(_ object: T) {
    guard let index = content.firstIndex(where: { $0.value === object }) else { return }
    content.remove(at: index)
  }
  
  public func append(_ object: T) {
    content.append(Weak(object))
  }
  
  public func forEach(_ action: (T)->()) {
    content = content.filter { $0.do(action) }
  }
  public func forEach<U>(as type: U.Type, _ action: (U)->()) {
    // increased code to reduce stack size for pipes
    update()
    content.forEach {
      if let value = $0.value as? U {
        action(value)
      }
    }
  }
  
  private func update() {
    content = content.filter { $0.value != nil }
  }
}

