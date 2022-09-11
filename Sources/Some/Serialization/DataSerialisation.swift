//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 29.01.2020.
//

import Foundation

// MARK: RawRepresentable
public extension DataReader {
  func next<T,S>() throws -> T where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    let value: S = try next()
    if let v = T(rawValue: value) {
      return v
    } else {
      throw corrupted
    }
  }
  func next<T,S>() throws -> T? where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    let value: S? = try next()
    if let value = value {
      if let v = T(rawValue: value) {
        return v
      } else {
        throw corrupted
      }
    } else {
      return nil
    }
  }
  func next<T,S>() throws -> [T] where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    try array { try next() }
  }
}
public extension DataWriter {
  func append<T,S>(_ value: T) where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    append(value.rawValue)
  }
  func append<T,S>(_ value: T?) where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    append(value?.rawValue)
  }
  func append<T,S>(_ value: T) where T: RawRepresentable, S: DataEncodable, T.RawValue == S {
    append(value.rawValue)
  }
  func append<T,S>(_ value: [T]) where T: RawRepresentable, S: DataRepresentable, T.RawValue == S {
    append(value.count)
    value.forEach {
      append($0)
    }
  }
}


// MARK: Dictionary Array
public extension DataReader {
  func array<T>(body: () throws -> (T)) throws -> [T] {
    let count = try intCount()
    var array = [T]()
    array.reserveCapacity(count)
    for _ in 0..<count {
      let value = try body()
      array.append(value)
    }
    return array
  }
  func enumerated(_ build: (Int) throws -> ()) throws {
    let count = try intCount()
    for i in 0..<count {
      try build(i)
    }
  }
  func dictionaryArray<Value: Id>() throws -> [Value.IdType: Value]
    where Value: DataDecodable {
      try dictionaryArray { $0.id }
  }
  func dictionaryArray<Key,Value>(_ path: KeyPath<Value, Key>) throws -> [Key: Value]
    where Key: Hashable, Value: DataDecodable {
      try dictionaryArray { $0[keyPath: path] }
  }
  func dictionary<Key: Hashable, Value>(_ build: () throws -> (Key, Value)) throws -> [Key: Value] {
    var dictionary = [Key: Value]()
    try enumerated { _ in
      let (key, value) = try build()
      dictionary[key] = value
    }
    return dictionary
  }
  func dictionaryArray<Key,Value>(_ getKey: (Value)->(Key)) throws -> [Key: Value]
    where Key: Hashable, Value: DataDecodable {
      try dictionary {
        let value: Value = try next()
        let key: Key = getKey(value)
        return (key, value)
      }
  }
  func dictionaryArray<Key, Value>(version: Int, _ path: KeyPath<Value, Key>) throws -> [Key: Value]
    where Key: Hashable, Value: DataRepresentableVersionable {
      try dictionaryArray(version: version) { $0[keyPath: path] }
  }
  func dictionaryArray<Key,Value>(version: Int, _ getKey: (Value)->(Key)) throws -> [Key: Value]
    where Key: Hashable, Value: DataRepresentableVersionable {
      try dictionary {
        let value: Value = try next(version: version)
        let key: Key = getKey(value)
        return (key, value)
      }
  }
}
