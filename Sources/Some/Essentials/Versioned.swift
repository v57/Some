//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 6/16/20.
//

import Foundation

public struct Versioned<T> {
  public var version: Int
  public var _value: T
  public var value: T {
    get { _value }
    set {
      _value = newValue
      version &+= 1
    }
  }
  public init(_ value: T, _ version: Int = 0) {
    _value = value
    self.version = version
  }
}
extension Versioned: DataRepresentable where T: DataRepresentable {
  public init(data: DataReader) throws {
    version = try data.next()
    _value = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(version)
    data.append(_value)
  }
}
