#if os(iOS)
//
//  CGExtensions.swift
//  SomeTable
//
//  Created by Дмитрий Козлов on 7/18/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

// public // should be internal in when you use it with Some Framework
extension CGSize {
  func with(bounds size: CGSize) -> CGSize {
    let width = size.width == 0 ? self.width : size.width
    let height = size.height == 0 ? self.height : size.height
    return CGSize(width,height)
  }
}

// public // should be internal in when you use it with Some Framework
extension CGRect {
  init(_ origin: CGPoint, _ size: CGSize) {
    self.init(origin: origin, size: size)
  }
  init(_ origin: CGPoint) {
    self.init(origin: origin, size: .zero)
  }
  init(_ size: CGSize) {
    self.init(origin: .zero, size: size)
  }
}

public struct FunctionInfo: CustomStringConvertible {
  public var function: String
  public var file: String
  public var line: Int
  public init(_ fn: String = #function, _ fl: String = #file, _ ln: Int = #line) {
    self.function = fn
    self.file = fl
    self.line = ln
  }
  public var description: String {
    return "(File: \(file), function: \(function), line: \(line))"
  }
}
#endif
