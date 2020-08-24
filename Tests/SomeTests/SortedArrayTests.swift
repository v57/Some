//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/21/20.
//

import XCTest
@testable import Some

final class CacheTests: XCTestCase {
  var count: Int { 100_000 }
  private struct Item: ComparsionValue, Hashable {
    var _valueToCompare: Int { id }
    var id: Int
  }
  func testDictionaryWritePerformance() {
    var table = [Int: Item]()
    var items = [Item]()
    items.reserveCapacity(count)
    for i in 0..<count {
      items.append(Item(id: i))
    }
    measure {
      for i in 0..<count {
        table[i] = items[i]
      }
    }
  }
  func testDictionaryReadPerformance() {
    var table = [Int: Item]()
    var items = [Item]()
    items.reserveCapacity(count)
    for i in 0..<count {
      items.append(Item(id: i))
    }
    for i in 0..<count {
      table[i] = items[i]
    }
    var a: Item?
    measure {
      for i in 0..<count {
        a = table[i]
      }
    }
  }
  func testSortedArrayWritePerformance() {
    var table = SortedArray<Item>()
    var items = [Item]()
    items.reserveCapacity(count)
    for i in 0..<count {
      items.append(Item(id: i))
    }
    measure {
      for i in 0..<count {
        table.insert(items[i])
      }
    }
  }
  func testSortedArrayReadPerformance() {
    var table = SortedArray<Item>()
    var items = [Item]()
    items.reserveCapacity(count)
    for i in 0..<count {
      items.append(Item(id: i))
    }
    for i in 0..<count {
      table.insert(items[i])
    }
    var a: Item?
    measure {
      for i in 0..<count {
        a = table.at(i)
      }
    }
  }

}
