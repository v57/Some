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
}
extension Vector2: Equatable where T: Equatable {
  func opposite(of value: T) -> T {
    return value == a ? b : a
  }
  func contains(_ value: T) -> Bool {
    return value == a || value == b
  }
}
extension Vector2: Hashable where T: Hashable {  }

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
