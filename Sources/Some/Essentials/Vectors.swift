//
//  Vectors.swift
//  SomeFunctions
//
//  Created by Dmitry on 26/09/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

public struct Vector2<T> {
  public var a: T
  public var b: T
  public subscript(_ index: Int) -> T {
    get { index == 0 ? a : b }
    set {
      if index == 0 {
        a = newValue
      } else {
        b = newValue
      }
    }
  }
  public init(sorted a: T, _ b: T, sorting: (T,T)->(Bool)) {
    if sorting(a,b) {
      self.a = a
      self.b = b
    } else {
      self.a = b
      self.b = a
    }
  }
  public init(_ a: T, _ b: T) {
    self.a = a
    self.b = b
  }
  public var array: [T] {
    return [a, b]
  }
  public mutating func swap() {
    Swift.swap(&a, &b)
  }
}
extension Vector2: Equatable where T: Equatable { }
extension Vector2: Hashable where T: Hashable { }

public extension Vector2 where T: Equatable {
  func opposite(of value: T) -> T {
    return value == a ? b : a
  }
  func contains(_ value: T) -> Bool {
    return value == a || value == b
  }
  func index(of item: T) -> Int? {
    switch item {
    case a:
      return 0
    case b:
      return 1
    default:
      return nil
    }
  }
}
public extension Vector2 where T: ComparsionValue {
  subscript(value value: T.ValueToCompare) -> T {
    get { with(value) }
    set {
      self[index(of: value)!] = newValue
    }
  }
  func opposite(of value: T.ValueToCompare) -> T {
    return value == a._valueToCompare ? b : a
  }
  mutating func editOpposite(of value: T.ValueToCompare, edit: (inout T)->()) {
    if value == a._valueToCompare {
      edit(&b)
    } else {
      edit(&a)
    }
  }
  func index(of value: T.ValueToCompare) -> Int? {
    switch value {
    case a._valueToCompare:
      return 0
    case b._valueToCompare:
      return 1
    default:
      return nil
    }
  }
  func with(_ value: T.ValueToCompare) -> T {
    return value == a._valueToCompare ? a : b
  }
  func find(_ value: T.ValueToCompare) -> T? {
    return value == a._valueToCompare ? a : value == b._valueToCompare ? b : nil
  }
  func contains(_ value: T.ValueToCompare) -> Bool {
    return value == a._valueToCompare || value == b._valueToCompare
  }
}

public struct Vector3<T> {
  public var a: T
  public var b: T
  public var c: T
  public init(_ a: T, _ b: T, _ c: T) {
    self.a = a
    self.b = b
    self.c = c
  }
}
extension Vector3: DataRepresentable where T: DataRepresentable {
  public init(data: DataReader) throws {
    a = try data.next()
    b = try data.next()
    c = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(a)
    data.append(b)
    data.append(c)
  }
}
extension Vector3: EmptyInit where T: EmptyInit {
  public init() {
    self.a = T()
    self.b = T()
    self.c = T()
  }
}
extension Vector3: Equatable where T: Equatable {
  
}
extension Vector3: Hashable where T: Hashable {
  
}
public struct Vector4<T> {
  public var a: T
  public var b: T
  public var c: T
  public var d: T
  public init(_ a: T, _ b: T, _ c: T, _ d: T) {
    self.a = a
    self.b = b
    self.c = c
    self.d = d
  }
}
extension Vector4: EmptyInit where T: EmptyInit {
  public init() {
    self.a = T()
    self.b = T()
    self.c = T()
    self.d = T()
  }
}
extension Vector4: DataRepresentable where T: DataRepresentable {
  
  public init(data: DataReader) throws {
    try a = data.next()
    try b = data.next()
    try c = data.next()
    try d = data.next()
  }
  public func save(data: DataWriter) {
    data.append(a)
    data.append(b)
    data.append(c)
    data.append(d)
  }
}
