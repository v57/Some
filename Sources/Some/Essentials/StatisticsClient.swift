//
//  StatisticsClient.swift
//  StatisticsTest
//
//  Created by Dmitry Kozlov on 29/10/2020.
//

#if canImport(Combine)
import Foundation

extension Statistics {
  open class CLManager {
    public var items = [String: CLItems]()
    public init() { }
    open func added(items: Items) {
      self.items[items.name] = CLItems(items.items.map(CLItem.init))
    }
    open func updated(item: Item, for path: Path) {
      if let clItem = items[path.name] {
        clItem.items[path.index].item = item
      }
    }
    open func added(value: Int, transaction: Indexed<Int?>, path: Path) {
      items[path.name]?.items[path.index].item.added(value: value, transaction: transaction)
    }
  }
  public class CLItems {
    public var items: [CLItem]
    public init(_ items: [CLItem]) {
      self.items = items
    }
  }
  public class CLItem {
    @Published var item: Item
    public init() {
      item = Item(accumulator: .max(nil), storage: .unlimited([]), start: .now, interval: .s(1))
    }
    public init(item: Item) {
      self.item = item
    }
    public func set(item: Item) {
      self.item = item
    }
  }
}
public extension Statistics.Item {
  mutating func added(value: Int, transaction: Indexed<Int?>) {
    if let transaction = transaction.compactMap() {
      storage.append(transaction)
      self.current = transaction.index + 1
      self.accumulator.set(nil)
    } else {
      self.accumulator.add(value)
    }
  }
}
public extension Statistics.Accumulator {
  mutating func set(_ value: Int?) {
    switch self {
    case .max:
      self = .max(value)
    case .min:
      self = .min(value)
    case .total:
      self = .total(value)
    case .average:
      if let value = value {
        self = .average(1, value)
      } else {
        self = .average(0, 0)
      }
    }
  }
}

let testStatisticsManager = TestStatisticsManager()
class TestStatisticsManager: Statistics.CLManager {
  public var testItems: Statistics.CLItems!
  override init() {
    super.init()
    let items = testStatisticsServer.connect()
    self.added(items: items)
    testItems = self.items["test"]
  }
}
let testStatisticsServer = TestStatisticsServer()
class TestStatisticsServer: Statistics.Manager {
  let testQueue = DispatchQueue(label: "test")
  override init() {
    super.init()
    add(name: "test", type: .total(nil), start: .now, intervals: .custom(0, .ms(1000/60)), from: .now)
  }
  public func connect() -> Statistics.Items {
    start()
    return self.items["test"]!
  }
  override func added(value: Int, transaction: Indexed<Int?>, path: Statistics.Path) {
    DispatchQueue.main.async {
      testStatisticsManager.added(value: value, transaction: transaction, path: path)
    }
  }
  public func start() {
    testQueue.asyncAfter(deadline: .now() + .milliseconds(1000/60)) {
      self.add(value: .random(in: 0..<10), name: "test")
      self.start()
    }
  }
}


// MARK: - Statistics item extensions
public extension Statistics.Item {
  func data(length: Int) -> [Int] {
    var array = [Int]()
    let previous: Statistics.Transaction?
    var i = storage.count-1
    if let value = accumulator.value {
      previous = Statistics.Transaction(index: current, value: value)
    } else if let transaction = storage.at(i) {
      previous = transaction
      i -= 1
    } else {
      previous = nil
    }
    if var previous = previous {
      array.append(previous.value)
      while let next = storage.at(i) {
        i -= 1
        for _ in 1..<(previous.index-next.index) {
          array.append(0)
          if array.count == length {
            return Array(array.reversed())
          }
        }
        array.append(next.value)
        if array.count == length {
          return Array(array.reversed())
        }
        previous = next
      }
    }
    if array.count < length {
      array.append(contentsOf: [Int](repeating: 0, count: length - array.count))
    }
    return Array(array.reversed())
  }
}

#endif
