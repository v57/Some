//
//  File.swift
//  
//
//  Created by Дмитрий Козлов on 19.02.2021.
//

import Foundation

/*
 @TempValue var number: Int
 
 number += 1
 let connection = $number.connect()
 connection.value += 1
 */

@propertyWrapper
public struct TempValue<Value: BinaryInteger> {
  @inlinable // trivially forwarding
  public init(initialValue: Value) {
    self.init(wrappedValue: initialValue)
  }
  public init(wrappedValue: Value) {
    value = wrappedValue
  }
  
  public private(set) var value: Value
  private var publisher: Publisher?
  public var projectedValue: Publisher {
    mutating get {
      publisher.lazy { Publisher(value) }
    }
  }
  public var wrappedValue: Value {
    get { value }
    set {
      guard value != newValue else { return }
      value = newValue
      if let publisher = publisher {
        DispatchQueue.main.async {
          publisher.ownerSend(newValue)
        }
      }
    }
  }
  public class Publisher: Var<Value> {
    var connections = WeakArray<Connection>()
    public func connect() -> Connection {
      let connection = Connection()
      connections.append(connection)
      connection.connect(pipe: self)
      return connection
    }
    public override func send(_ content: Value) {
      super.send(content)
    }
    public func ownerSend(_ content: Value) {
      connections.forEach { $0.reset() }
      v = content
    }
  }
  public class Connection {
    weak var pipe: Publisher?
    public var _rawValue: Value = 0
    public var rawValue: Value {
      get { _rawValue }
      set {
        let diff = newValue - rawValue
        _rawValue = newValue
        pipe?.v += diff
      }
    }
    public func connect(pipe: Publisher) {
      if self.pipe != nil {
        disconnect()
      }
      self.pipe = pipe
      guard rawValue != 0 else { return }
      pipe.v += rawValue
    }
    public func disconnect() {
      guard rawValue != 0 else { return }
      pipe?.v -= rawValue
      pipe = nil
    }
    public func reset() {
      _rawValue = 0
    }
    deinit {
      print("[ss] deinit")
      disconnect()
    }
  }
}
extension TempValue: CustomStringConvertible {
  public var description: String { "\(value) "}
}
