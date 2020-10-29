//
//  Statistics.swift
//  StatisticsTest
//
//  Created by Dmitry Kozlov on 28/10/2020.
//

import Foundation

public enum Statistics {
  public class Manager {
    public var items = [String: Items]()
    let queue = OperationQueue()
    public init() {
      queue.maxConcurrentOperationCount = 1
    }
    // thread safe
    public func add(value: Int, name: String) {
      let time = Microseconds.now
      queue.addOperation {
        self.addSync(value: value, name: name, time: time)
      }
    }
    // called in self.queue
    public func addSync(value: Int, name: String, time: Microseconds) {
      if var statistics = items[name] {
        statistics.add(value: value, time: time, manager: self)
        items[name] = statistics
      } else {
        print("[statistics] unknown statistics with name '\(name)'. Creating a new one with type .total for every day")
      }
    }
    // called in self.queue
    open func added(value: Int, transaction: Transaction?, path: Path) {
      
    }
    
    // setup
    public func add(name: String, type: Accumulator, intervals: Interval..., from: Microseconds) {
      if items[name] == nil {
        items[name] = Items(name: name, items: intervals.map { $0.item(start: .now, accumulator: type) })
      }
    }
  }
  // MARK:- Interval
  public enum Interval {
    case minute
    case hour
    case day
    case week
    case lastMinute
    case lastHour
    case lastDay
    case lastWeekByDays
    case lastMonthByDays
    case lastYearByDays
    case custom(Int, Microseconds)
    public func item(start: Microseconds, accumulator: Accumulator) -> Item {
      switch self {
      case .minute:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .s(1))
      case .hour:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .m(1))
      case .day:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .h(1))
      case .week:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .d(1))
      case .lastMinute:
        return Item(accumulator: accumulator, storage: .size(60), start: start, interval: .s(1))
      case .lastHour:
        return Item(accumulator: accumulator, storage: .size(60), start: start, interval: .m(1))
      case .lastDay:
        return Item(accumulator: accumulator, storage: .size(24), start: start, interval: .h(1))
      case .lastWeekByDays:
        return Item(accumulator: accumulator, storage: .size(7), start: start, interval: .d(1))
      case .lastMonthByDays:
        return Item(accumulator: accumulator, storage: .size(30), start: start, interval: .d(1))
      case .lastYearByDays:
        return Item(accumulator: accumulator, storage: .size(365), start: start, interval: .d(1))
      case let .custom(size, interval):
        return Item(accumulator: accumulator, storage: .size(size), start: start, interval: interval)
      }
    }
  }
  // MARK:- Items
  public struct Items {
    public var name: String
    public var items: [Item]
    public mutating func add(value: Int, time: Microseconds, manager: Manager) {
      for i in 0..<items.count {
        let transaction = items[i].add(value: value, time: time)
        manager.added(value: value, transaction: transaction, path: .init(name: name, index: i))
      }
    }
  }
  // MARK:- Item
  public struct Item {
    public var accumulator: Accumulator
    public var current: Int
    public var storage: Storage
    
    public var start: Microseconds
    public var interval: Microseconds
    public init(accumulator: Accumulator, storage: Storage, start: Microseconds, interval: Microseconds) {
      self.accumulator = accumulator
      self.storage = storage
      self.start = start
      self.interval = interval
      self.current = 0
    }
    
    
    public mutating func add(value: Int, time: Microseconds) -> Transaction? {
      defer { accumulator.add(value) }
      let i = ((time - start) / interval).rawValue
      print(i, current, time - start, interval)
      if i != current, let value = accumulator.value {
        let transaction = Transaction(value: value, index: current)
        accumulator.reset()
        current = i
        storage.append(transaction)
        return transaction
      } else {
        return nil
      }
    }
  }
  public struct Path {
    public var name: String
    public var index: Int
  }
  public struct Transaction {
    public var value: Int
    public var index: Int
  }
  
  // MARK:- Accumulators
  public enum AccumulatorType {
    case max, min, total, average
    public var make: Accumulator {
      switch self {
      case .max: return .max(nil)
      case .min: return .min(nil)
      case .total: return .total(nil)
      case .average: return .average(0,0)
      }
    }
  }
  public enum Accumulator {
    case max(Int?), min(Int?), total(Int?), average(Int, Int)
    
    public mutating func reset() {
      switch self {
      case .max: self = .max(nil)
      case .min: self = .min(nil)
      case .total: self = .total(nil)
      case .average: self = .average(0,0)
      }
    }
    public var value: Int? {
      switch self {
      case let .max(c), let .min(c), let .total(c):
        return c
      case let .average(c, count):
        return count == 0 ? nil : c / count
      }
    }
    public mutating func add(_ value: Int) {
      switch self {
      case let .max(c):
        if let c = c {
          if value > c {
            self = .max(c)
          }
        } else {
          self = .max(c)
        }
      case let .min(c):
        if let c = c {
          if value < c {
            self = .min(c)
          }
        } else {
          self = .min(c)
        }
      case let .total(c):
        self = .total((c ?? 0) + value)
      case let .average(c, count):
        self = .average(c+value, count+1)
      }
    }
  }
  
  // MARK:- Storage
  public enum Storage: ArrayMap {
    public static func size(_ size: Int) -> Self {
      if size == 0 {
        return .unlimited([])
      } else {
        return .limited(.init(count: size))
      }
    }
    
    case unlimited([Transaction])
    case limited(LimitedArray<Transaction>)
    
    public typealias Element = Transaction
    
    public init() {
      self = .unlimited([])
    }
    public func at(_ index: Int) -> Element? {
      guard index >= 0 && index < count else { return nil }
      return self[index]
    }
    public mutating func append(_ newElement: Statistics.Transaction) {
      switch self {
      case .limited(var a):
        a.append(newElement)
        self = .limited(a)
      case .unlimited(var a):
        a.append(newElement)
        self = .unlimited(a)
      }
    }
    public var array: [Statistics.Transaction] {
      get {
        switch self {
        case .limited(let a): return a.array
        case .unlimited(let a): return a
        }
      } set {
        switch self {
        case .limited(var a):
          a.array = newValue
          self = .limited(a)
        case .unlimited:
          self = .unlimited(newValue)
        }
      }
    }
    
    public var startIndex: Int {
      switch self {
      case .limited(let a): return a.startIndex
      case .unlimited(let a): return a.startIndex
      }
    }
    public var endIndex: Int {
      switch self {
      case .limited(let a): return a.endIndex
      case .unlimited(let a): return a.endIndex
      }
    }
    public subscript(position: Int) -> Element {
      get {
        switch self {
        case .limited(let a): return a[position]
        case .unlimited(let a): return a[position]
        }
      }
      set {
        switch self {
        case .limited(var a):
          a[position] = newValue
          self = .limited(a)
        case .unlimited(var a):
          a[position] = newValue
          self = .unlimited(a)
        }
      }
    }
    // Todo: scroll array
    public subscript(bounds: Range<Int>) -> [Element] {
      get {
        switch self {
        case .limited(let a): return a[bounds]
        case .unlimited(let a): return Array(a[bounds])
        }
      }
      set {
        switch self {
        case .limited(var a):
          a[bounds] = newValue
          self = .limited(a)
        case .unlimited(var a):
          a.replaceSubrange(bounds, with: newValue)
          self = .unlimited(a)
        }
      }
    }
  }
}
