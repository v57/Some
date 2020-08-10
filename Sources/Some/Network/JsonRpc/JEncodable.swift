//
//  JEncodable.swift
//  Tests
//
//  Created by Dmitry on 18/12/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

public protocol JEncodable {
  func jsonRpcValue(with network: NetworkProvider) -> Any
}

extension Int: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return self
  }
}
extension UInt: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return self
  }
}
extension Bool: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return self
  }
}
extension String: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return self
  }
}
extension Data: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return hex.withHex
  }
}
extension Future: JEncodable where T: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return map { $0 as Any }
  }
}
extension Array: JEncodable where Element: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return map { $0.jsonRpcValue(with: network) }
  }
}
extension Dictionary: JEncodable where Value: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return mapValues { $0.jsonRpcValue(with: network) }
  }
}
extension Set: JEncodable where Element: JEncodable {
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return map { $0.jsonRpcValue(with: network) }
  }
}

public protocol JKeyedEncodable {
  func write(to dictionary: JDictionary)
}

open class JValue: JEncodable {
  public var raw: Any
  public init(_ value: Any) {
    raw = value
  }
  public init?(_ value: Any?) {
    guard let value = value else { return nil }
    raw = value
  }
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return raw
  }
}
open class JDictionary: JEncodable {
  public var dictionary = [String: JEncodable]()
  
  public init() {}
  
  @discardableResult
  open func at(_ key: String) -> JsonRpcDictionaryKey {
    return JsonRpcDictionaryKey(parent: self, key: key)
  }
  
  @discardableResult
  open func set(_ value: JKeyedEncodable) -> Self {
    value.write(to: self)
    return self
  }
  
  @discardableResult
  open func set(_ key: String, _ value: JEncodable?) -> Self {
    if let value = value {
      set(key, value)
    }
    return self
  }
  
  @discardableResult
  open func set(_ key: String, _ value: JEncodable) -> Self {
    dictionary[key] = value
    return self
  }
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return dictionary.mapValues { $0.jsonRpcValue(with: network) }
  }
}
open class JArray: JEncodable {
  public var array = [JEncodable]()
  
  public init() {}
  public init(_ array: [JEncodable]) {
    guard !array.isEmpty else { return }
    self.array = array
  }
  public init?(_ array: [JEncodable]?) {
    guard let array = array else { return nil }
    guard !array.isEmpty else { return }
    self.array = array
  }
  open func nilIfEmpty() -> Self? {
    return array.isEmpty ? nil : self
  }
  open func append(_ element: JEncodable) -> Self {
    array.append(element)
    return self
  }
  public func jsonRpcValue(with network: NetworkProvider) -> Any {
    return array.map { $0.jsonRpcValue(with: network) }
  }
}
public struct JsonRpcDictionaryKey {
  public var parent: JDictionary
  public var key: String
  public func set(_ value: JEncodable) {
    parent.dictionary[key] = value
  }
  // do nothing
  public func set(_ value: JEncodable?) {}
  public func dictionary(_ build: (JDictionary)->()) {
    let dictionary = JDictionary()
    build(dictionary)
    set(dictionary)
  }
}


