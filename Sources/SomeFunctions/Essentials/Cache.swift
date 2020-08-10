//
//  cache.swift
//  SomeFunctions
//
//  Created by Димасик on 4/20/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

import Foundation

public protocol Cachable: Hashable {
  var cacheSize: Int { get }
  func purged()
}
public extension Cachable {
  var cacheSize: Int { 0 }
  func purged() {}
}

public protocol KeyedCachable: Cachable {
  associatedtype CacheKey: Hashable
  var cacheKey: CacheKey { get }
}
open class Cache<T: Cachable> {
  public var array = [T]()
  public var capacity: Int
  public var size: Int
  public var used = 0
  public var purged: ((T)->())?
  public init(capacity: Int, size: Int) {
    self.capacity = capacity
    self.size = size
  }
  public func append(_ value: T) {
    array.append(value)
    used += value.cacheSize
    purge()
  }
  public func remove(_ value: T) {
    guard let index = array.firstIndex(of: value) else { return }
    array.remove(at: index)
    used -= value.cacheSize
  }
  public func removeAll() {
    used = 0
    array.removeAll()
  }
  public func replace(cacheSize: Int, with size: Int) {
    let offset = size - cacheSize
    used += offset
    if offset > 0 {
      purge()
    }
  }
  func purge() {
    while array.count > capacity {
      let a = array.removeFirst()
      purge(a)
    }
    while used > size {
      let a = array.removeFirst()
      purge(a)
    }
  }
  func purge(_ value: T) {
    used -= value.cacheSize
    value.purged()
    purged?(value)
  }
}

public class KeyedCache<Value: KeyedCachable>: Cache<Value> {
  public typealias Key = Value.CacheKey
  public var dictionary = Dictionary<Key,Value>()
  public override init(capacity: Int, size: Int) {
    super.init(capacity: capacity, size: size)
  }
  public subscript(key: Key) -> Value? {
    get {
      return dictionary[key]
    } set {
      if let value = newValue {
        guard dictionary[key] == nil else { return }
        dictionary[key] = value
        append(value)
      } else {
        guard let value = dictionary[key] else { return }
        dictionary[key] = nil
        remove(value)
      }
    }
  }
  override func purge(_ value: Value) {
    super.purge(value)
    dictionary[value.cacheKey] = nil
  }
}

public class TempKeyedCache<Value: KeyedCachable>: Cache<Value> {
  public typealias Key = Value.CacheKey
  public var lifetime: Time
  public var dictionary = Dictionary<Key,(time: Time, data: Value)>()
  public init(lifetime: Time, capacity: Int, size: Int) {
    self.lifetime = lifetime
    super.init(capacity: capacity, size: size)
  }
  public subscript(key: Key) -> Value? {
    get {
      if let value = dictionary[key] {
        if Time.now - value.time < lifetime {
          return value.data
        } else {
          remove(value.data)
          return nil
        }
      } else {
        return nil
      }
    } set {
      if let value = newValue {
        guard dictionary[key] == nil else { return }
        dictionary[key] = (.now,value)
        append(value)
      } else {
        guard let value = dictionary[key] else { return }
        dictionary[key] = nil
        remove(value.data)
      }
    }
  }
  override func purge(_ value: Value) {
    super.purge(value)
    dictionary[value.cacheKey] = nil
  }
  public func insert(_ value: Value) {
    let key = value.cacheKey
    dictionary[key] = (.now,value)
    append(value)
  }
}
