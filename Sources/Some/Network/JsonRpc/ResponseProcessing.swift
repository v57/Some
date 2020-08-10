//
//  ResponseProcessing.swift
//  CoreBlockchain
//
//  Created by Dmitry on 09/01/2019.
//  Copyright © 2019 Bankex Foundation. All rights reserved.
//

import Foundation

public func _bool(_ data: AnyReader) throws -> Bool {
  return try data.bool()
}
public func _data(_ data: AnyReader) throws -> Data {
  return try data.data()
}
public func _string(_ data: AnyReader) throws -> String {
  return try data.string()
}
public func _int(_ data: AnyReader) throws -> Int {
  return try data.int()
}

public extension Future where T == AnyReader {
  func bool() -> Future<Bool> {
    return map(on: .some, _bool)
  }
  func data() -> Future<Data> {
    return map(on: .some, _data)
  }
  func string() -> Future<String> {
    return map(on: .some, _string)
  }
  func int() -> Future<Int> {
    return map(on: .some, _int)
  }
  func array<T>(_ convert: @escaping (AnyReader)throws->(T)) -> Future<[T]> {
    return map(on: .some) { try $0.array().map(convert) }
  }
}
