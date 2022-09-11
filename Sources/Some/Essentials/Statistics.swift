//
//  Statistics.swift
//  StatisticsTest
//
//  Created by Dmitry Kozlov on 28/10/2020.
//

import Foundation

/*
 "user.0.playtime.0.1.120".average(10)
 */

enum St {
  enum Operation {
    case average, min, max, total
  }
  static var time: Time { 1577826000 }
  struct Records {
    var list = SortedArray<Record>()
    func index(from time: Time, size: Time) -> Int {
      (St.time - time) / size
    }
    mutating func add(value: Int, operation: Operation, time: Time, size: Time) {
      let index = self.index(from: time, size: size)
      var item = list.at(value, create: { .init(index: index, count: 0, value: 0) })
      item.value.add(value: value, operation: operation)
      list.array[item.index] = item.value
    }
  }
  struct Record: ComparsionValue {
    var _valueToCompare: Int { index }
    var index: Int
    var count: Int = 0
    var value: Int = 0
    mutating func add(value: Int, operation: Operation) {
      if count > 0 {
        switch operation {
        case .average, .total:
          self.value += value
        case .min:
          self.value.set(min: value)
        case .max:
          self.value.set(max: value)
        }
      } else {
        self.value = value
      }
      count += 1
    }
  }
}

public enum Statistics {
  open class Manager {
    public var items = [String: Items]()
    public let queue = OperationQueue()
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
      if let statistics = items[name] {
        statistics.add(value: value, time: time, manager: self)
      } else {
        createDefaultItems(name: name)
        items[name]?.add(value: value, time: time, manager: self)
      }
    }
    open func createDefaultItems(name: String) {
      
    }
    // called in self.queue
    open func added(value: Int, transaction: Indexed<Int?>, path: Path) {
      
    }
    
    // setup
    @discardableResult
    public func add(name: String, type: Accumulator, start: Microseconds, intervals: Interval..., from: Microseconds) -> Items {
      if let items = items[name] {
        return items
      } else {
        let items = Items(name: name, items: intervals.map { $0.item(start: start, accumulator: type) })
        self.items[name] = items
        return items
      }
    }
  }
  // MARK: - Interval
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
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .m(1))
      case .hour:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .h(1))
      case .day:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .d(1))
      case .week:
        return Item(accumulator: accumulator, storage: .size(0), start: start, interval: .d(7))
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
    public var interval: Microseconds {
      switch self {
      case .minute: return .m(1)
      case .hour: return .h(1)
      case .day: return .d(1)
      case .week: return .d(7)
      case .lastMinute: return .s(1)
      case .lastHour: return .m(1)
      case .lastDay: return .h(1)
      case .lastWeekByDays: return .d(1)
      case .lastMonthByDays: return .d(1)
      case .lastYearByDays: return .d(1)
      case let .custom(_, interval): return interval
      }
    }
  }
  // MARK: - Items
  public class Items: DataRepresentable {
    public var name: String
    public var items: [Item]
    public func add(value: Int, time: Microseconds, manager: Manager?) {
      for i in 0..<items.count {
        let transaction = items[i].add(value: value, time: time)
        manager?.added(value: value, transaction: transaction, path: .init(name: name, index: i))
      }
    }
    public init(name: String, items: [Item]) {
      self.name = name
      self.items = items
    }
    required public init(data: DataReader) throws {
      name = try data.next()
      items = try data.next()
    }
    public func save(data: DataWriter) {
      data.append(name)
      data.append(items)
    }
  }
  // MARK: - Item
  public struct Item: DataRepresentable {
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
    public init(data: DataReader) throws {
      accumulator = try data.next()
      current = try data.next()
      storage = try data.next()
      start = try data.next()
      interval = try data.next()
    }
    public func save(data: DataWriter) {
      data.append(accumulator)
      data.append(current)
      data.append(storage)
      data.append(start)
      data.append(interval)
    }
    
    public mutating func add(value: Int, time: Microseconds) -> Indexed<Int?> {
      defer { accumulator.add(value) }
      let i = ((time - start) / interval).rawValue
      if i != current, let currentValue = accumulator.value, currentValue > 0 {
        let transaction = Transaction(current, currentValue)
        accumulator.reset()
        current = i
        storage.append(transaction)
        return Indexed(i, currentValue)
      } else if i != current {
        current = i
        return Indexed(i, nil)
      } else {
        return Indexed(i, nil)
      }
    }
    public func slice(in range: Range<Int>) -> ItemSlice {
      ItemSlice(item: self, range: range)
    }
  }
  public struct ItemSlice: DataRepresentable {
    public var range: Range<Int>
    public var accumulator: Accumulator
    public var current: Int
    public var storage: [Transaction]
    
    public var start: Microseconds
    public var interval: Microseconds
    
    public init(item: Item, range: Range<Int>) {
      self.accumulator = item.accumulator
      self.current = item.current
      self.storage = Array(item.storage.in(range: range))
      
      self.start = item.start
      self.interval = item.interval
      self.range = range
    }
    public init(data: DataReader) throws {
      accumulator = try data.next()
      current = try data.next()
      storage = try data.next()
      start = try data.next()
      interval = try data.next()
      range = try data.next()
    }
    public func save(data: DataWriter) {
      data.append(accumulator)
      data.append(current)
      data.append(storage)
      data.append(start)
      data.append(interval)
    }
    
    public mutating func add(value: Int, time: Microseconds) -> Transaction? {
      let i = ((time - start) / interval).rawValue
      guard range.contains(i) else { return nil }
      defer { accumulator.add(value) }
      if i != current, let value = accumulator.value {
        let transaction = Transaction(current, value)
        accumulator.reset()
        current = i
        storage.append(transaction)
        return transaction
      } else {
        return nil
      }
    }
  }
  public struct Path: DataRepresentable, Hashable, CustomStringConvertible {
    public var name: String
    public var index: Int
    public init(name: String, index: Int) {
      self.name = name
      self.index = index
    }
    public init(data: DataReader) throws {
      name = try data.next()
      index = try data.next()
    }
    public func save(data: DataWriter) {
      data.append(name)
      data.append(index)
    }
    public var description: String { "\(name)/\(index)" }
  }
  public struct SmartPath: DataRepresentable, Hashable, CustomStringConvertible {
    public var name: String
    public var index: SmartIndex
    public init(name: String, index: SmartIndex) {
      self.name = name
      self.index = index
    }
    public init(data: DataReader) throws {
      name = try data.next()
      index = try data.next()
    }
    public func save(data: DataWriter) {
      data.append(name)
      data.append(index)
    }
    public var description: String { "\(name)/\(index)" }
  }
  public enum SmartIndex: DataRepresentable, Hashable, CustomStringConvertible {
    case index(Int)
    case interval(Microseconds)
    
    public var description: String {
      switch self {
      case .index(let index):
        return "i\(index)"
      case .interval(let interval):
        return "mcs\(interval)"
      }
    }
    public init(data: DataReader) throws {
      switch try data.int() {
      case 0: self = .index(try data.next())
      case 1: self = .interval(try data.next())
      default: throw corrupted
      }
    }
    public func save(data: DataWriter) {
      switch self {
      case .index(let index):
        data.append(0)
        data.append(index)
      case .interval(let interval):
        data.append(1)
        data.append(interval)
      }
    }
  }
  public typealias Transaction = Indexed<Int>
  
  // MARK: - Accumulators
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
  public enum Accumulator: DataRepresentable {
    case max(Int?), min(Int?), total(Int?), average(Int, Int)
    public init(data: DataReader) throws {
      switch try data.int() {
      case 0:
        self = try .max(data.next())
      case 1:
        self = try .min(data.next())
      case 2:
        self = try .total(data.next())
      case 3:
        self = try .average(data.next(), data.next())
      default:
        throw corrupted
      }
    }
    public func save(data: DataWriter) {
      switch self {
      case let .max(c):
        data.append(0)
        data.append(c)
      case let .min(c):
        data.append(1)
        data.append(c)
      case let .total(c):
        data.append(2)
        data.append(c)
      case let .average(c, count):
        data.append(3)
        data.append(c)
        data.append(count)
      }
    }
    
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
  
  // MARK: - Storage
  public enum Storage: ArrayMap, DataRepresentable {
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
    public init(data: DataReader) throws {
      switch try data.bool() {
      case false:
        self = try .unlimited(data.next())
      case true:
        self = try .limited(data.next())
      }
    }
    public func save(data: DataWriter) {
      switch self {
      case let .unlimited(a):
        data.append(false)
        data.append(a)
      case let .limited(a):
        data.append(true)
        data.append(a)
      }
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
    public func `in`(range: Range<Int>) -> ArraySlice<Statistics.Transaction> {
      switch self {
      case .limited(let array):
        return array.alignedArray.binaryRange(range, \.index)
      case .unlimited(let array):
        return array.binaryRange(range, \.index)
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
