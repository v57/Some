//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 07/11/2019.
//

import Foundation

public typealias FutureResult<T> = Swift.Result<T, Error>
public extension Result {
  init(_ value: @autoclosure () -> Success, _ error: Failure?) {
    if let error = error {
      self = .failure(error)
    } else {
      self = .success(value())
    }
  }
  var value: Success! {
    guard case let .success(value) = self else { return nil }
    return value
  }
  var error: Error! {
    guard case let .failure(error) = self else { return nil }
    return error
  }
  func onSuccess(_ action: (Success) throws -> ()) rethrows {
    switch self {
    case .success(let value):
      try action(value)
    default: break
    }
  }
  func onFailure(_ action: (Error) throws -> ()) rethrows {
    switch self {
    case .failure(let error):
      try action(error)
    default: break
    }
  }
}

// open class F<T>: P<T> {
//   public typealias T = T
//   public private(set) var value: T?
//   public var v: T? {
//     get { value }
//     set {
//       if let v = newValue {
//         send(v)
//       }
//     }
//   }
//   
//   public override init() {
//     
//   }
//   public init(_ value: T) {
//     self.value = value
//   }
//   open override func send(_ content: T) {
//     value = content
//     super.send(content)
//   }
//   public func set(_ value: T) {
//     send(value)
//   }
//   open override func connect(_ connection: Connection<T>) {
//     super.connect(connection)
//     if let value = value {
//       _ = connection.send(value)
//     }
//   }
// }
