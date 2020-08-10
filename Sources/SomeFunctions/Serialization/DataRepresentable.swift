//
//  DataRepresentable.swift
//  Some
//
//  Created by Димасик on 12/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public protocol DataEncodable {
  func save(data: DataWriter)
}
public protocol DataDecodable {
  init(data: DataReader) throws
}

public typealias DataRepresentable = DataDecodable&DataEncodable

public protocol DataLoadable: DataEncodable {
  init()
  func load(data: DataReader) throws
}

public struct DVoid: DataRepresentable, ExpressibleByNilLiteral, CustomStringConvertible {
  public init(data: DataReader) throws { }
  public func save(data: DataWriter) { }
  public init(nilLiteral: ()) {}
  public init() {}
  public var description: String { "" }
}
public struct DRaw<Value: RawRepresentable> where Value.RawValue: DataRepresentable {
  public var value: Value
  public init(_ value: Value) {
    self.value = value
  }
}
extension DRaw: DataRepresentable, CustomStringConvertible {
  public init(data: DataReader) throws {
    value = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(value)
  }
  public var description: String { "\(value)" }
}
extension RawRepresentable where RawValue: DataRepresentable {
  public func draw() -> DRaw<Self> {
    DRaw(self)
  }
}

public enum DataVersion {
  case latest
  case current
  case custom(Int)
  public static var versions = [String: Int]()
  public func version(for type: Versionable.Type) -> Int {
    switch self {
    case .latest:
      return DataVersion.versions[type.className] ?? type.version
    case .current:
      return type.version
    case .custom(let version):
      return version
    }
  }
}
public typealias DataRepresentableVersionable = DataDecodableVersionable&DataEncodableVersionable
public protocol DataEncodableVersionable {
  func save(data: DataWriter, version: Int)
}
public protocol DataDecodableVersionable {
  init(data: DataReader, version: Int) throws
}

public protocol Storable {
  static var keys: [PartialKeyPath<Self>] { get }
  init()
}

extension Dictionary: DataRepresentable where Key: DataRepresentable, Value: DataRepresentable {
  public init(data: DataReader) throws {
    let count = try data.intCount()
    self.init()
    for _ in 0..<count {
      let key: Key = try data.next()
      let value: Value = try data.next()
      self[key] = value
    }
  }
  public func save(data: DataWriter) {
    data.append(count)
    forEach {
      data.append($0)
      data.append($1)
    }
  }
}

extension Dictionary.Values: DataEncodable where Element: DataEncodable {
  public func save(data: DataWriter) {
    data.append(count)
    forEach {
      data.append($0)
    }
  }
}

extension Array: DataRepresentable where Element: DataRepresentable {
  public init(data: DataReader) throws {
    let count: Int = try data.intCount()
    self = Array<Element>()
    reserveCapacity(count)
    for _ in 0..<count {
      let value: Element = try data.next()
      append(value)
    }
  }
  
  public func save(data: DataWriter) {
    data.append(count)
    forEach {
      data.append($0)
    }
  }
}

extension Set: DataRepresentable where Element: DataRepresentable {
  public init(data: DataReader) throws {
    let count: Int = try data.intCount()
    self = Set<Element>()
    reserveCapacity(count)
    for _ in 0..<count {
      let value: Element = try data.next()
      insert(value)
    }
  }
  
  public func save(data: DataWriter) {
    data.append(count)
    forEach {
      data.append($0)
    }
  }
}

extension ArraySlice: DataEncodable where Element: DataEncodable {
  public func save(data: DataWriter) {
    data.append(count)
    forEach {
      data.append($0)
    }
  }
}

extension Optional: DataRepresentable where Wrapped: DataRepresentable {
  public init(data: DataReader) throws {
    let bool: Bool = try data.next()
    if bool {
      let some: Wrapped = try data.next()
      self = Optional.some(some)
    } else {
      self = Optional.none
    }
  }
  
  public func save(data: DataWriter) {
    switch self {
    case .some(let some):
      data.append(true)
      data.append(some)
    case .none:
      data.append(false)
    }
  }
}

// extension RawRepresentable: DataRepresentable where RawValue: DataRepresentable {
//   public init(data: DataReader) throws {
//     let value: RawValue = try data.next()
//     if let v = Self(rawValue: value) {
//       self = v
//     } else {
//       throw corrupted
//     }
//   }
//   
//   public func save(data: DataWriter) {
//     data.append(rawValue)
//   }
// }

extension String: DataRepresentable {
  public init(data: DataReader) throws {
    if let string = try String(data: data.next(), encoding: .utf8) {
      self = string
    } else {
      throw corrupted
    }
  }
  public func save(data: DataWriter) {
    data.append(self.data(using: .utf8)!)
  }
}

extension Data: DataRepresentable {
  public init(data: DataReader) throws {
    let count = try data.intCount()
    self = try data.subdata(count)
  }
  public func save(data: DataWriter) {
    data.append(count)
    data.data.append(self)
  }
}

extension Vector2: DataRepresentable where T: DataRepresentable {
  public init(data: DataReader) throws {
    try self.init(data.next(), data.next())
  }
  public func save(data: DataWriter) {
    data.append(a)
    data.append(b)
  }
}
