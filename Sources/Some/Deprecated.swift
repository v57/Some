//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/8/20.
//

import Foundation

@available (*, deprecated, message: "Use another function")
public func setNil<T>(of value: inout T?, with: ()->(T)) {
  guard value == nil else { return }
  value = with()
}
@available (*, deprecated, message: "Use another function")
public func unnil<T>(_ value: T?, _ error: Error) throws -> T {
  if let value = value {
    return value
  } else {
    throw error
  }
}
