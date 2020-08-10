//
//  Observable.swift
//  SomeFunctions
//
//  Created by Dmitry on 10/09/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

open class Var<T>: P<T>, RawRepresentable, CustomStringConvertible {
  open override var storesValues: Bool { true }
  
  public private(set) var rawValue: T
  public var v: T {
    get { rawValue }
    set { send(newValue) }
  }
  public var _v: T {
    get { rawValue }
    set { rawValue = newValue }
  }
  
  public init(_ value: T) {
    self.rawValue = value
  }
  required public init(rawValue: T) {
    self.rawValue = rawValue
  }
  open override func send(_ content: T) {
    rawValue = content
    super.send(content)
  }
  public func set(_ value: T) {
    send(value)
  }
  open override func add(child: S) {
    super.add(child: child)
    (child as? P<T>)?.send(rawValue)
  }
  open override func request(from child: S) {
    send(rawValue)
  }
  public var description: String { "\(rawValue)" }
}

open class O<T>: P<T>, RawRepresentable, CustomStringConvertible {
  open override var storesValues: Bool { true }
  
  public private(set) var rawValue: T?
  public override init() {
    self.rawValue = nil
  }
  public init(_ value: T) {
    self.rawValue = value
  }
  public init(_ value: T?) {
    self.rawValue = value
  }
  required public init(rawValue: T?) {
    self.rawValue = rawValue
  }
  open override func send(_ content: T) {
    rawValue = content
    super.send(content)
  }
  public func set(_ value: T) {
    send(value)
  }
  open override func add(child: S) {
    super.add(child: child)
    // if let rawValue = rawValue {
    //   (child as? P<T>)?.send(rawValue)
    // }
  }
  open override func request(from child: S) {
    guard let rawValue = rawValue else { return }
    send(rawValue)
  }
  public var description: String {
    if let rawValue = rawValue {
      return "\(rawValue)"
    } else {
      return "none"
    }
  }
}
