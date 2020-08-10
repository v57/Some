#if os(iOS)
//
//  RangeExtension.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 5/26/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import Foundation

// public // should be internal in when you use it with Some Framework
extension Range where Bound == Int {
  var start: Int {
    get { lowerBound }
    set { self = newValue..<Swift.max(upperBound,newValue) }
  }
  var end: Int {
    get { upperBound }
    set { self = lowerBound..<newValue }
  }
  var last: Int {
    get { upperBound-1 }
    set { self = lowerBound..<newValue+1 }
  }
//  mutating func left() {
//    self = lowerBound - 1..<upperBound - 1
//  }
//
//  mutating func upLeft() {
//    self = lowerBound..<upperBound - 1
//  }
//
//  mutating func right() {
//    self = lowerBound + 1..<upperBound + 1
//  }
//
//  mutating func upRight() {
//    self = lowerBound..<upperBound + 1
//  }
//
//  mutating func left(by offset: Int) {
//    self = lowerBound - offset..<upperBound - offset
//  }
//
  mutating func expandLeft(by offset: Int) {
    self = lowerBound - offset..<upperBound
  }
  
  mutating func expandRight(by offset: Int) {
    self = lowerBound..<upperBound + offset
  }
  
  mutating func reduceLeft(by offset: Int) {
    self = lowerBound + offset..<upperBound
  }
  
  mutating func reduceRight(by offset: Int) {
    self = lowerBound..<upperBound - offset
  }
  
  mutating func move(by offset: Int) {
    self = lowerBound + offset..<upperBound + offset
  }
  
  mutating func insert(_ range: Range<Int>) -> Bool {
    if range.lowerBound <= lowerBound {
      move(by: range.count)
      return false
    } else if range.lowerBound < upperBound {
      expandRight(by: range.count)
      return true
    } else {
      return false
    }
  }
//  mutating func insert(_ element: Int) -> Bool {
//    if element <= lowerBound {
//      move(by: 1)
//      return false
//    } else if element < upperBound {
//      expandRight(by: 1)
//      return true
//    } else {
//      return false
//    }
//  }
  mutating func remove(_ range: Range<Int>) -> Bool {
    if range.lowerBound < lowerBound {
      move(by: -range.count)
      return false
    } else if range.lowerBound < upperBound {
      reduceRight(by: (range.lowerBound..<Swift.min(range.upperBound, upperBound)).count)
      return true
    } else {
      return false
    }
  }
//  mutating func remove(_ element: Int) -> Bool {
//    if element <= lowerBound {
//      move(by: -1)
//      return false
//    } else if element < upperBound {
//      reduceRight(by: 1)
//      return true
//    } else {
//      return false
//    }
//  }
  
  mutating func merge(with range: Range<Int>) {
    guard !range.isEmpty else { return }
    if isEmpty {
      self = range
    } else if lowerBound == range.upperBound {
      expandLeft(by: range.count)
    } else if upperBound == range.lowerBound {
      expandRight(by: range.count)
    }
  }
  
  mutating func removeBound(_ range: Range<Int>) {
    guard !range.isEmpty else { return }
    if lowerBound == range.lowerBound {
      reduceLeft(by: range.count)
    } else if upperBound == range.upperBound {
      reduceRight(by: range.count)
    }
  }
  
//  mutating func removeBound(_ element: Int) {
//    if element < lowerBound {
//      left()
//    } else if element < upperBound {
//      upLeft()
//    }
//  }
  
//  mutating func insert(_ element: Int) {
//    if element <= lowerBound {
//      right()
//    } else if element < upperBound {
//      upRight()
//    }
//  }
//  
//  mutating func insert2(_ element: Int) {
//    if element <= lowerBound {
//      right()
//    } else if element <= upperBound {
//      upRight()
//    }
//  }
  
//  var shortDescription: String {
//    let a = lowerBound
//    let b = upperBound - 1
//    if a == b {
//      return a.description
//    } else if a - b == 1 {
//      return "\(lowerBound)..<\(upperBound)"
//    } else {
//      return "\(a)...\(b)"
//    }
//  }
}

// public // should be internal in when you use it with Some Framework
extension Array where Element == Range<Int> {
  func loop(_ execute: (Int) -> ()) {
    for range in self {
      for index in range {
        execute(index)
      }
    }
  }
}
#endif
