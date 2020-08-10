#if os(iOS)
//
//  cache.swift
//  SomeFunctions
//
//  Created by Димасик on 4/20/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

import Some

//public extension Cachable {
//  var cacheSize: Int { 0 }
//  func purged() {}
//}

open class Cache<T: Cachable> {
  public var array = [T]()
  public var capacity = 1
  public var size = 1
  public var used = 0
  public var purged: ((T)->())?
  
  public init() {
    
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
    array.forEach {
      $0.purged()
      purged?($0)
    }
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
#endif
