//
//  JsonEncodable.swift
//  SomeNetwork
//
//  Created by Dmitry on 14/03/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

public protocol JsonEncodable {
  func jsonValue() -> Any
}

extension Int: JsonEncodable {
  public func jsonValue() -> Any {
    return self
  }
}
extension UInt: JsonEncodable {
  public func jsonValue() -> Any {
    return self
  }
}
extension Bool: JsonEncodable {
  public func jsonValue() -> Any {
    return self
  }
}
extension String: JsonEncodable {
  public func jsonValue() -> Any {
    return self
  }
}
extension Data: JsonEncodable {
  public func jsonValue() -> Any {
    return hex.withHex
  }
}
extension Future: JsonEncodable where T: JsonEncodable {
  public func jsonValue() -> Any {
    return map { $0 as Any }
  }
}
extension Array: JsonEncodable where Element: JsonEncodable {
  public func jsonValue() -> Any {
    return map { $0.jsonValue() }
  }
}
extension Set: JsonEncodable where Element: JsonEncodable {
  public func jsonValue() -> Any {
    return map { $0.jsonValue() }
  }
}
extension Dictionary: JsonEncodable where Value: JsonEncodable {
  public func jsonValue() -> Any {
    return mapValues { $0.jsonValue() }
  }
}

public protocol JsonKeyedEncodable {
  func write(to dictionary: JsonDictionary)
}

open class JsonValue: JsonEncodable {
  public var raw: Any
  public init(_ value: Any) {
    raw = value
  }
  public init?(_ value: Any?) {
    guard let value = value else { return nil }
    raw = value
  }
  public func jsonValue() -> Any {
    return raw
  }
}
open class JsonDictionary: JsonEncodable {
  public var dictionary = [String: JsonEncodable]()
  
  public init() {}
  
  @discardableResult
  open func at(_ key: String) -> JsonDictionaryKey {
    return JsonDictionaryKey(parent: self, key: key)
  }
  
  @discardableResult
  open func set(_ value: JsonKeyedEncodable) -> Self {
    value.write(to: self)
    return self
  }
  
  @discardableResult
  open func set(_ key: String, _ value: JsonEncodable?) -> Self {
    if let value = value {
      set(key, value)
    }
    return self
  }
  
  @discardableResult
  open func set(_ key: String, _ value: JsonEncodable) -> Self {
    dictionary[key] = value
    return self
  }
  public func jsonValue() -> Any {
    return dictionary.mapValues { $0.jsonValue() }
  }
}
open class JsonArray: JsonEncodable {
  public var array = [JsonEncodable]()
  
  public init() {}
  public init(_ array: [JsonEncodable]) {
    guard !array.isEmpty else { return }
    self.array = array
  }
  public init?(_ array: [JsonEncodable]?) {
    guard let array = array else { return nil }
    guard !array.isEmpty else { return }
    self.array = array
  }
  open func nilIfEmpty() -> Self? {
    return array.isEmpty ? nil : self
  }
  open func append(_ element: JsonEncodable) -> Self {
    array.append(element)
    return self
  }
  public func jsonValue() -> Any {
    return array.map { $0.jsonValue() }
  }
}
public struct JsonDictionaryKey {
  public var parent: JsonDictionary
  public var key: String
  public func set(_ value: JsonEncodable) {
    parent.dictionary[key] = value
  }
  // do nothing
  public func set(_ value: JsonEncodable?) {}
  public func dictionary(_ build: (JsonDictionary)->()) {
    let dictionary = JsonDictionary()
    build(dictionary)
    set(dictionary)
  }
}


