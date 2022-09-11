//
//  DictionaryReader.swift
//  web3swift-iOS
//
//  Created by Dmitry on 28/10/2018.
//  Copyright © 2018 Bankex Foundation. All rights reserved.
//

import Foundation

public protocol AnyReaderDecodable {
  init(_ data: AnyReader) throws
}

/**
 Dictionary Reader
 
 Used for easy dictionary parsing
 */
public class AnyReader {
  /// Errors
  public enum Error: Swift.Error {
    /// Throws if key cannot be found in a dictionary
    case notFound(key: String, dictionary: [String: Any])
    /// Throws if key cannot be found in a dictionary
    case elementNotFound(index: Int, array: [Any])
    /// Throws if value cannot be converted to desired type
    case unconvertible(value: Any, expected: String)
    /// Printable / user displayable description
    public var localizedDescription: String {
      switch self {
      case let .notFound(key, dictionary):
        return "Cannot find object at key \(key) in \(dictionary)"
      case let .elementNotFound(index, array):
        return "Cannot find element at index \(index) in \(array)"
      case let .unconvertible(value, expected):
        return "Cannot convert \(value) to \(expected)"
      }
    }
  }
  /// Raw value
  public var raw: Any
  /// Init with any value
  public init(_ data: Any) {
    self.raw = data
  }
  public init(_ data: Any?) throws {
    guard let data = data else { throw Error.notFound(key: "root", dictionary: [:]) }
    self.raw = data
  }
  /// Init with any value
  public init(json data: Data) throws {
    self.raw = try JSONSerialization.jsonObject(with: data, options: [])
  }
  
  public func unconvertible(to expected: String) -> Error {
    return Error.unconvertible(value: raw, expected: expected)
  }
  
  /// Tries to represent raw as dictionary and gets value at key from it
  /// - Parameter key: Dictionary key
  /// - Returns: DictionaryReader with found value
  /// - Throws: DictionaryReader.Error(if unconvertible to [String: Any] or if key not found in dictionary)
  public func at(_ key: String) throws -> AnyReader {
    guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
    guard let value = data[key] else { throw Error.notFound(key: key, dictionary: data) }
    return AnyReader(value)
  }
  
  /// Tries to represent raw as dictionary and gets value at key from it
  /// - Parameter key: Dictionary key
  /// - Returns: DictionaryReader with found value or nil if not found
  /// - Throws: DictionaryReader.Error(if unconvertible to [String: Any] or if key not found in dictionary)
  public func optional(_ key: String) throws -> AnyReader? {
    guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
    guard let value = data[key] else { return nil }
    return AnyReader(value)
  }
  
  public func optional(_ key: String, action: (AnyReader) throws -> ()) throws {
    guard let value = try optional(key) else { return }
    try action(value)
  }
  
  /// Tries to represent raw as dictionary and calls forEach on it.
  /// Same as [String: Any]().map { key, value in ... }
  /// - Parameter block: callback for every key and value of dictionary
  /// - Throws: DictionaryReader.Error(if unconvertible to [String: Any])
  public func dictionary(body: (AnyReader, AnyReader) throws -> ()) throws {
    guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
    try data.forEach {
      try body(AnyReader($0), AnyReader($1))
    }
  }
  public func dictionary() throws -> [String: Any] {
    guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
    return data
  }
  
  public func darray<T>(body: (AnyReader, AnyReader) throws -> (T)) throws -> [T] {
    guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
    return try data.map { try body(AnyReader($0), AnyReader($1)) }
  }
  
  /// Tries to represent raw as array and calls forEach on it.
  /// Same as [Any]().forEach { value in ... }
  /// - Parameter body: Callback for every value in array
  /// - Throws: DictionaryReader.Error(if unconvertible to [Any])
  public func array(_ body: (AnyReader) throws -> ()) throws {
    guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
    try data.forEach {
      try body(AnyReader($0))
    }
  }
  
  /// Tries to represent raw as array.
  /// - Throws: DictionaryReader.Error(if unconvertible to [Any])
  public func array() throws -> [AnyReader] {
    guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
    return data.map(AnyReader.init)
  }
  
  /// - Returns: Raw if raw is array. Array with self if its not an array
  public func forceArray() -> [AnyReader] {
    if let array = raw as? [Any] {
      return array.map(AnyReader.init)
    } else {
      return [self]
    }
  }
  
  /// Tries to represent raw as array and converts it to Array<T>
  /// - Throws: DictionaryReader.Error(if unconvertible to [Any])
  public func array<T>(_ mapped: (AnyReader) throws -> (T)) throws -> [T] {
    guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
    return try data.map { try mapped(AnyReader($0)) }
  }
  
  public func set<T: Hashable>(_ mapped: (AnyReader) throws -> (T)) throws -> Set<T> {
    guard let data = raw as? [Any] else { throw unconvertible(to: "[Any]") }
    return try Set(data.map { try mapped(AnyReader($0)) })
  }
  
  /// Tries to represent raw as string
  /// - Returns: String
  /// - Throws: DictionaryReader.Error.unconvertible
  @discardableResult
  public func string() throws -> String {
    if let value = raw as? String {
      return value
    } else if let value = raw as? Int {
      return value.description
    } else {
      throw unconvertible(to: "String")
    }
  }
  /// Tries to represent raw as url
  /// - Returns: URL
  /// - Throws: DictionaryReader.Error.unconvertible
  @discardableResult
  public func url() throws -> URL {
    if let value = raw as? String {
      guard let url = URL(string: value) else { throw unconvertible(to: "URL") }
      return url
    } else {
      throw unconvertible(to: "URL")
    }
  }
  
  @discardableResult
  public func time() throws -> Time {
    do {
      return try Time(int())
    } catch {
      if let date = ISO8601DateFormatter().date(from: try string())?.time {
        return date
      } else {
        throw unconvertible(to: "Time")
      }
    }
  }

  public func date() throws -> Date {
    do {
      return try Time(int()).date
    } catch {
      if let date = DateFormatter.js.date(from: try string()) {
        return date
      } else {
        throw unconvertible(to: "Date")
      }
    }
  }
  
  /// Tries to represent raw as string
  /// - Returns: String
  /// - Throws: DictionaryReader.Error.unconvertible
  @discardableResult
  public func bool() throws -> Bool {
    if let value = raw as? Bool {
      return value
    } else if let value = raw as? Int {
      return value != 0
    } else if let value = raw as? String {
      switch value {
      case "true":
        return true
      case "false":
        return false
      default:
        throw unconvertible(to: "Bool")
      }
    } else {
      throw unconvertible(to: "Bool")
    }
  }
  
  /// Tries to represent raw as data or as hex string then as data
  /// - Throws: DictionaryReader.Error.unconvertible
  @discardableResult
  public func data() throws -> Data {
    if let value = raw as? Data {
      return value
    } else {
      return try string().hex
    }
  }
  
  /// Tries to represent raw as Int.
  ///
  /// Can convert:
  /// - "0x12312312"
  /// - 0x123123
  /// - "123123123"
  /// - Throws: DictionaryReader.Error.unconvertible
  @discardableResult
  public func int() throws -> Int {
    if let value = raw as? Int {
      return value
    } else if let value = raw as? String {
      if value.isHex {
        guard let value = Int(value.withoutHex, radix: 16) else { throw unconvertible(to: "Int") }
        return value
      } else {
        guard let value = Int(value) else { throw unconvertible(to: "Int") }
        return value
      }
    } else {
      throw unconvertible(to: "Int")
    }
  }
  @discardableResult
  public func double() throws -> Double {
    if let value = raw as? Double {
      return value
    } else if let value = raw as? Int {
      return Double(value)
    } else if let value = raw as? String {
      guard let value = Double(value) else { throw unconvertible(to: "Double") }
      return value
    } else {
      throw unconvertible(to: "Double")
    }
  }
  
  
  /// Tries to represent raw as Int.
  ///
  /// Can convert:
  /// - "0x12312312"
  /// - 0x123123
  /// - "123123123"
  /// - Throws: DictionaryReader.Error.unconvertible
  @discardableResult
  public func uint64() throws -> UInt64 {
    if let value = raw as? Int {
      return UInt64(value)
    } else if let value = raw as? String {
      if value.isHex {
        guard let value = UInt64(value.withoutHex, radix: 16) else { throw unconvertible(to: "UInt64") }
        return value
      } else {
        guard let value = UInt64(value) else { throw unconvertible(to: "UInt64") }
        return value
      }
    } else {
      throw unconvertible(to: "Int")
    }
  }
  
  public func dictionary<T>(_ body: (AnyReader) throws -> (T)) throws -> [String: T] {
    guard let data = raw as? [String: Any] else { throw unconvertible(to: "[String: Any]") }
    
    return try data.mapValues { try body(AnyReader($0)) }
  }
  
  public func isNull() -> Bool {
    return raw is NSNull
  }
  
  public func contains(_ key: String) -> Bool {
    return (try? at(key)) != nil
  }
  
  public func json() throws -> Data {
    return try JSONSerialization.data(withJSONObject: raw, options: .prettyPrinted)
  }
}

extension AnyReader: CustomStringConvertible {
  public var description: String {
    return "\(raw)"
  }
}

extension Dictionary where Key == String, Value == Any {
  public func notFound(at key: String) -> Error {
    return AnyReader.Error.notFound(key: key, dictionary: self)
  }
  var json: Data {
    return try! JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
  }
  var jsonDescription: String {
    return json.string
  }
  /// - Parameter key: Dictionary key
  /// - Returns: DictionaryReader with found value
  /// - Throws: DictionaryReader.Error(if key not found in dictionary)
  public func at(_ key: String) throws -> AnyReader {
    guard let value = self[key] else { throw notFound(at: key) }
    return AnyReader(value)
  }
}

extension Array where Element == AnyReader {
  func notFound(at index: Int) -> Error {
    return AnyReader.Error.elementNotFound(index: index, array: self)
  }
  public func at(_ index: Int) throws -> AnyReader {
    guard index >= 0 && index < count else { throw notFound(at: index) }
    return self[index]
  }
}

/// Some chains
enum ParsingError: Error {
  case stringPrefix(string: String, shouldHavePrefix: String)
  case stringEquals(string: String, shouldEqual: String)
}
public extension String {
  var jsonReader: AnyReader {
    return try! AnyReader(json: data)
  }
  @discardableResult
  func starts(with prefix: String) throws -> String {
    guard hasPrefix(prefix) else {
      throw ParsingError.stringPrefix(string: self, shouldHavePrefix: prefix)
    }
    return self
  }
  @discardableResult
  func equals(_ string: String) throws -> String {
    guard self == string else {
      throw ParsingError.stringEquals(string: self, shouldEqual: string)
    }
    return self
  }
}
