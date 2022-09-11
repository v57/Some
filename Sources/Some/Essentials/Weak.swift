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
  
  public func removeAll() {
    content.removeAll()
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


// MARK: WeakDictionary
public class WeakDictionary<T: AnyObject> {
  private var content = [String: Weak<T>]()
  public init() {}
  public init(_ collection: [String: T]) {
    content = collection.mapValues { Weak($0) }
  }
  public var isEmpty: Bool { count == 0 }
  public var count: Int {
    update()
    return content.count
  }
  public var values: [T] {
    var array = [T]()
    var deletedKeys = [String]()
    for (key, value) in content {
      guard let value = value.value else {
        deletedKeys.append(key)
        continue }
      array.append(value)
    }
    deletedKeys.forEach {
      content[$0] = nil
    }
    return array
  }
  public func value(at key: String, default: ()->(T)) -> T {
    if let value = self[key] {
      return value
    } else {
      let value = `default`()
      content[key] = Weak(value)
      return value
    }
  }
  public func removeAll() {
    content.removeAll()
  }
  public subscript(_ key: String) -> T? {
    get {
      guard let value = content[key] else { return nil }
      if let value = value.value {
        return value
      } else {
        content[key] = nil
        return nil
      }
    } set {
      if let newValue = newValue {
        content[key] = Weak(newValue)
      } else {
        content[key] = nil
      }
    }
  }
  private func update() {
    content = content.filter { $0.value.value != nil }
  }
}

//// MARK: WeakSet
//public class WeakSortedArray<T: AnyObject & Comparable> {
//  private var content = SortedArray<Weak<T>>()
//  public init() {}
//  public init<C: Collection>(_ collection: C) where C.Element == T {
//    content = collection.map { Weak($0) }
//  }
//  public var isEmpty: Bool { count == 0 }
//  public var count: Int {
//    update()
//    return content.count
//  }
//  public var allObjects: [T] {
//    update()
//    var array = [T]()
//    for object in content {
//      guard let value = object.value else { continue }
//      array.append(value)
//    }
//    return array
//  }
//
//  public func removeObject(_ object: T) {
//    guard let index = content.firstIndex(where: { $0.value === object }) else { return }
//    content.remove(at: index)
//  }
//
//  public func removeAll() {
//    content.removeAll()
//  }
//  public func append(_ object: T) {
//    content.append(Weak(object))
//  }
//
//  public func forEach(_ action: (T)->()) {
//    content = content.filter { $0.do(action) }
//  }
//  public func forEach<U>(as type: U.Type, _ action: (U)->()) {
//    // increased code to reduce stack size for pipes
//    update()
//    content.forEach {
//      if let value = $0.value as? U {
//        action(value)
//      }
//    }
//  }
//
//  private func update() {
//    content = content.filter { $0.value != nil }
//  }
//}

