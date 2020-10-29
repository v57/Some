//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 27/10/2020.
//

import Foundation

public typealias Bound = Direction
public typealias Bounds = Bound.Set
public typealias Directions = Direction.Set
public enum Direction: UInt8 {
  case top, bottom, left, right
}
public extension Options where Enum == Direction {
  static var top: Self { [.top] }
  static var bottom: Self { [.bottom] }
  static var left: Self { [.left] }
  static var right: Self { [.right] }
  static var any: Self { 0b1111 }
  static var all: Self { 0b1111 }
  static var horizontal: Self { 0b1100 }
  static var vertical: Self { 0b0011 }
}
