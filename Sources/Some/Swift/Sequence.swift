//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/25/20.
//

import Foundation

public extension Sequence {
  func enumerate(_ block: (Element, inout Bool)->()) {
    var stop = false
    for element in self {
      block(element, &stop)
      if stop {
        return
      }
    }
  }
  func enumerateFilter(_ block: (Element, inout Bool)->(Bool)) -> [Element] {
    var array = [Element]()
    enumerate { element, stop in
      if block(element, &stop) {
        array.append(element)
      }
    }
    return array
  }
  func filter(limit: Int, _ isIncluded: (Element)->Bool) -> [Element] {
    var count = 0
    return enumerateFilter { element, stop in
      guard isIncluded(element) else { return false }
      count += 1
      if count == limit {
        stop = true
      }
      return true
    }
  }
}
public extension Sequence where Iterator.Element == UInt8 {
  var data: Data {
    if let data = self as? Data {
      return data
    } else if let array = self as? Array<UInt8> {
      return array.withUnsafeBufferPointer {
        Data($0)
      }
    } else if let slice = self as? ArraySlice<UInt8> {
      return slice.withUnsafeBufferPointer {
        Data($0)
      }
    } else {
      return Array(self).withUnsafeBufferPointer {
        Data($0)
      }
    }
  }
  var string: String! {
    return String(bytes: self, encoding: .utf8)
  }
}
