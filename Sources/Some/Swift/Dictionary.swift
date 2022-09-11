//
//  dictionary.swift
//  SomeFunctions
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension Dictionary {
  public static func += (left: inout [Key: Value], right: [Key: Value]) {
    for (k, v) in right {
      left[k] = v
    }
  }
  public var any: Value {
    return Array(self.values).any
  }
  public subscript(at key: Key, default: ()->(Value)) -> Value {
    get {
      self[key] ?? `default`()
    } set {
      self[key] = newValue
    }
  }
  public mutating func value(at key: Key, default: ()->(Value)) -> Value {
    if let value = self[key] {
      return value
    } else {
      let value = `default`()
      self[key] = value
      return value
    }
  }
  @discardableResult
  public mutating func mutate(at key: Key, default: ()->(Value), mutate: (inout Value)->()) -> Value {
    var value = self[key] ?? `default`()
    mutate(&value)
    self[key] = value
    return value
  }
}

public class SafeDictionary<Key: Hashable, Value> {
  private var dictionary = [Key: Value]()
  private let queue: DispatchQueue
  public init() {
    queue = DispatchQueue(label: "safe-items", attributes: .concurrent)
  }
  public subscript(key: Key) -> Value? {
    get {
      queue.read { dictionary[key] }
    } set {
      queue.write { self.dictionary[key] = newValue }
    }
  }
  public var count: Int {
    queue.read { dictionary.count }
  }
  public func read<T>(_ read: ([Key: Value])->(T)) -> T {
    queue.read {
      read(dictionary)
    }
  }
  public func write(_ write: @escaping (inout [Key: Value])->()) {
    queue.write {
      write(&self.dictionary)
    }
  }
  @discardableResult
  public func syncWrite<T>(_ write: (inout [Key: Value]) throws -> T) rethrows -> T {
    try queue.syncWrite {
      try write(&self.dictionary)
    }
  }
}

public struct DictionaryOfArrays<K: Hashable,V> {
  public var data: [K: [V]] = [:]
  public init() {}
  public subscript(key: K) -> [V] {
    return data[key] ?? []
  }
  public mutating func edit(_ key: K, edit: (inout [V])->()) {
    var array = self[key]
    edit(&array)
    data[key] = array
  }
  public mutating func append(_ value: V, at key: K) {
    edit(key) { $0.append(value) }
  }
}

@dynamicMemberLookup
public struct DictionaryBuilder<Key, Value>
where Key: ExpressibleByStringLiteral & Hashable {
  public var _body = Dictionary<Key, Value>()
  public init() {}
  public subscript(dynamicMember key: Key) -> Value? {
    get {
      _body[key]
    } set {
      _body[key] = newValue
    }
  }
}
