//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 6/9/20.
//

import Foundation

public class SetPipe<T: Hashable> {
  public var set: Set<T>
  public lazy var input: P<SetOperation<T>> = {
    let pipe = P<SetOperation<T>>()
    pipe.sink { [unowned self] in
      switch $0 {
      case let .insert(item):
        self.insert(item)
      case let .remove(item):
        self.remove(item)
      case let .set(items):
        self.set(items)
      case let .update(item):
        self.update(item)
      }
    }.store(in: bag)
    return pipe
  }()
  public let bag = Bag()
  public lazy var output = P<SetOperation<T>>()
  public init(_ set: Set<T>) {
    self.set = set
  }
  public init() {
    self.set = []
  }
  public func set(_ set: [T]) {
    let (added, removed) = self.set.merge(to: Set(set))
    if removed.count == self.set.count {
      output.send(.set(set))
    } else {
      removed.forEach {
        output.send(.remove($0))
      }
      added.forEach {
        output.send(.insert($0))
      }
    }
  }
  public func update(_ value: T) {
    if set.contains(value) {
      output.send(.update(value))
    }
  }
  @discardableResult
  public func insert(_ element: T) -> (inserted: Bool, memberAfterInsert: T) {
    let result = set.insert(element)
    if result.inserted {
      output.send(.insert(element))
    }
    return result
  }
  @discardableResult
  public func remove(_ element: T) -> T? {
    if let removed = set.remove(element) {
      output.send(.remove(element))
      return removed
    } else {
      return nil
    }
  }
}

public class SortedArrayPipe<T: Comparable> {
  public var array: SortedArray<T> {
    didSet {
      count = array.count
    }
  }
  @SV public var count: Int
  public lazy var input: P<SetOperation<T>> = {
    let pipe = P<SetOperation<T>>()
    pipe.sink { [unowned self] in
      switch $0 {
      case let .insert(item):
        self.insert(item)
      case let .remove(item):
        self.remove(item)
      case let .set(items):
        self.set(items, update: true)
      case let .update(item):
        self.update(item)
      }
    }.store(in: bag)
    return pipe
  }()
  public lazy var output = P<ListOperation<T>>()
  public lazy var combined = P<[ListOperation<T>]>()
  private var accumulated: [ListOperation<T>]?
  public var pipe: P<[T]> {
    let data = Var(array.array)
    combined.map { [unowned self] _ in
      self.array.array
    }.add(data)
    return data
  }
  public var updates: P<T> {
    output.compactMap {
      guard case let .update(element) = $0 else { return nil }
      return element.value
    }
  }
  public let bag = Bag()
  public init(_ set: SortedArray<T>) {
    self.array = set
    count = array.count
  }
  public init() {
    self.array = []
    count = array.count
  }
  public func update(_ update: ()->()) {
    if accumulated == nil {
      accumulated = []
      update()
      if let accumulated = accumulated {
        self.accumulated = nil
        if accumulated.count > 0 {
          combined.send(accumulated)
        }
      }
    } else {
      update()
    }
  }
  private func send(_ operation: ListOperation<T>) {
    output.send(operation)
    if accumulated == nil {
      combined.send([operation])
    } else {
      accumulated!.append(operation)
    }
  }
  public func set(_ array: [T], update: Bool) {
    set(SortedArray(array), update: update)
  }
  /// Update: Sends updates for exists elements
  public func set(_ sorted: SortedArray<T>, update: Bool) {
    if array.isEmpty {
      self.array = sorted
      send(.set(sorted.array))
      return
    }
    self.update {
      if update {
        let oldValue = self.array
        self.array = sorted
        for (index, item) in oldValue.enumerated().reversed() {
          if let index = sorted.index(of: item) {
            send(.update(Indexed(index, sorted.array[index])))
          } else {
            send(.remove(Indexed(index, item)))
          }
        }
        for (index, item) in sorted.enumerated() {
          send(.insert(Indexed(index, item)))
        }
      } else {
        let count = self.array.count
        let (added, removed) = self.array.merge(to: sorted)
        if removed.count == count {
          send(.set(sorted.array))
        } else {
          removed.enumerated().reversed().forEach {
            send(.remove($0.offset.indexed($0.element)))
          }
          added.enumerated().forEach {
            send(.insert($0.offset.indexed($0.element)))
          }
        }
      }
    }
  }
  public func removeAll() {
    self.array.removeAll()
    send(.set([]))
  }
  /// Updates or inserts element
  public func update(_ element: T) {
    if let index = array.index(of: element) {
      array.array[index] = element
      send(.update(index.indexed(element)))
    } else {
      insert(element)
    }
  }
  public func update(_ elements: [T]) {
    guard !elements.isEmpty else { return }
    update {
      if self.array.isEmpty {
        set(elements, update: false)
      } else {
        elements.forEach { update($0) }
      }
    }
  }
  public func insert(_ element: T) {
    insert(element, replace: true)
  }
  public func insert(_ elements: [T], replace: Bool) {
    update {
      if self.array.isEmpty {
        set(elements, update: false)
      } else {
        elements.forEach { insert($0, replace: replace) }
      }
    }
  }
  public func insert(_ element: T, replace: Bool) {
    guard !array.contains(element) else { return }
    let index = array.insert(element, replace: replace)
    send(.insert(index.indexed(element)))
  }
  @discardableResult
  public func remove(_ element: T) -> Indexed<T>? {
    if let removed = array.remove(element) {
      send(.remove(removed))
      return removed
    } else {
      return nil
    }
  }
  public func subscribe(_ element: T) -> P<T?> {
    output.compactMap {
      switch $0 {
      case let .insert(item), let .update(item):
        if item.value == element {
          return item.value
        }
      case let .remove(item):
        if item.value == element {
          return .some(.none)
        }
      case let .set(items):
        if let index = items.binarySearch(element) {
          return items[index]
        }
      }
      return nil
    }
  }
}
public extension SortedArrayPipe where T: ComparsionValue {
  @discardableResult
  func getAndSubscribe<U>(_ element: T.ValueToCompare, mapping: @escaping (T)->U) -> O<U?> {
    let pipe = O<U?>()
    if let a = array.at(element) {
      pipe.send(mapping(a))
    }
    output.compactMap {
      switch $0 {
      case let .insert(item), let .update(item):
        if item.value._valueToCompare == element {
          return mapping(item.value)
        }
      case let .remove(item):
        if item.value._valueToCompare == element {
          return .some(.none)
        }
      case let .set(items):
        if let index = items.binarySearch(element, \._valueToCompare) {
          return mapping(items[index])
        }
      }
      return nil
    }.add(pipe)
    return pipe
  }
  
  func subscribe(_ element: T.ValueToCompare) -> P<T?> {
    output.compactMap {
      switch $0 {
      case let .insert(item), let .update(item):
        if item.value._valueToCompare == element {
          return item.value
        }
      case let .remove(item):
        if item.value._valueToCompare == element {
          return .some(.none)
        }
      case let .set(items):
        if let index = items.binarySearch(element, { $0._valueToCompare }) {
          return items[index]
        }
      }
      return nil
    }
  }
  @discardableResult
  func getAndSubscribe(_ element: T.ValueToCompare) -> O<T?> {
    let pipe = O<T?>()
    if let a = array.at(element) {
      pipe.send(a)
    }
    output.compactMap {
      switch $0 {
      case let .insert(item), let .update(item):
        if item.value._valueToCompare == element {
          return item.value
        }
      case let .remove(item):
        if item.value._valueToCompare == element {
          return .some(.none)
        }
      case let .set(items):
        if let index = items.binarySearch(element, \._valueToCompare) {
          return items[index]
        }
      }
      return nil
    }.add(pipe)
    return pipe
  }
  @discardableResult
  func update(_ element: T.ValueToCompare, update: (inout T)->()) -> Bool {
    if var item = array.at(element) {
      update(&item)
      self.update(item)
      return true
    } else {
      return false
    }
  }
  @discardableResult
  func remove(_ element: T.ValueToCompare) -> Indexed<T>? {
    if let index = array.remove(element) {
      send(.remove(index))
      return index
    } else {
      return nil
    }
  }
}
public class ArrayPipe<T> {
  public private(set) var array: [T]
  public lazy var input: P<ArrayOperation<T>> = {
    let pipe = P<ArrayOperation<T>>()
    pipe.sink { [unowned self] in
      switch $0 {
      case let .insert(item, index):
        self.insert(item, at: index)
      case let .append(item):
        self.append(item)
      case let .remove(index):
        self.remove(at: index)
      case let .set(items):
        self.set(items)
      case let .replace(item, index):
        self.set(item, at: index)
      }
    }.store(in: bag)
    return pipe
  }()
  public lazy var output = P<ListOperation<T>>()
  public let bag = Bag()
  public init(_ set: [T]) {
    self.array = set
  }
  public init() {
    self.array = []
  }
  public func set(_ element: T, at index: Int) {
    array[index] = element
    output.send(.update(index.indexed(element)))
  }
  public func set(_ elements: [T]) {
    self.array = elements
    output.send(.set(elements))
  }
  public func append(_ element: T) {
    let index = array.count
    array.append(element)
    output.send(.insert(index.indexed(element)))
  }
  public func insert(_ element: T, at index: Int) {
    array.insert(element, at: index)
    output.send(.insert(index.indexed(element)))
  }
  public func remove(at index: Int) {
    let element = array.remove(at: index)
    output.send(.remove(index.indexed(element)))
  }
}
public enum ArrayOperation<T> {
  case insert(T, Int)
  case append(T)
  case remove(Int)
  case set([T])
  case replace(T, Int)
}
public enum SetOperation<T> {
  case insert(T)
  case remove(T)
  case update(T)
  case set([T])
  public func map<U>(_ transform: (T)->(U)) -> SetOperation<U> {
    switch self {
    case .insert(let element):
      return .insert(transform(element))
    case .remove(let element):
      return .remove(transform(element))
    case .set(let elements):
      return .set(elements.map(transform))
    case .update(let element):
      return .update(transform(element))
    }
  }
}
public enum ListOperation<T> {
  case insert(Indexed<T>)
  case remove(Indexed<T>)
  case set([T])
  case update(Indexed<T>)
  public func map<U>(_ transform: (T)->(U)) -> ListOperation<U> {
    switch self {
    case .insert(let element):
      return .insert(element.map(transform))
    case .remove(let element):
      return .remove(element.map(transform))
    case .set(let elements):
      return .set(elements.map(transform))
    case .update(let element):
      return .update(element.map(transform))
    }
  }
  public var setOperation: SetOperation<T> {
    switch self {
    case .insert(let element):
      return .insert(element.value)
    case .remove(let element):
      return .remove(element.value)
    case .set(let elements):
      return .set(elements)
    case .update(let element):
      return .update(element.value)
    }
  }
}
public protocol ListOperationStorage {
  associatedtype T
  var storage: [T] { get }
  var output: P<ListOperation<T>> { get }
}
extension ArrayPipe: ListOperationStorage {
  public var storage: [T] { array }
}
extension SortedArrayPipe: ListOperationStorage {
  public var storage: [T] { array.array }
}

// MARK: - Re-sorting
public extension SortedArrayPipe {
  var isSorted: Bool {
    guard count > 1 else { return true }
    for i in 1..<count {
      if array[i-1] > array[i] {
        return false
      }
    }
    return true
  }
  func resortIfNeeded() {
    guard !isSorted else { return }
    let a = array.enumerated().map { Indexed($0.offset, $0.element) }.sorted { $0.value < $1.value }
    a.forEach {
      array[$0.index] = $0.value
      send(.update($0))
    }
  }
}
