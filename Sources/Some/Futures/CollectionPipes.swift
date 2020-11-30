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
    pipe.next { [unowned self] in
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
  @V public var count: Int
  public lazy var input: P<SetOperation<T>> = {
    let pipe = P<SetOperation<T>>()
    pipe.next { [unowned self] in
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
  public lazy var output = P<ListOperation<T>>()
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
  public func set(_ array: [T]) {
    let sorted = SortedArray(array)
    let (added, removed) = self.array.merge(to: sorted)
    if removed.count == self.array.count {
      output.send(.set(array))
    } else {
      removed.enumerated().reversed().forEach {
        output.send(.remove($0.offset))
      }
      added.enumerated().forEach {
        output.send(.insert($0.element, $0.offset))
      }
    }
  }
  public func update(_ value: T) {
    if let index = array.index(of: value) {
      array.array[index] = value
      output.send(.update(value, index))
    }
  }
  public func insert(_ element: T) {
    guard !array.contains(element) else { return }
    let index = array.insert(element, replace: replace)
    output.send(.insert(index.indexed(element)))
  }
  @discardableResult
  public func remove(_ element: T) -> Int? {
    if let index = array.remove(element) {
      output.send(.remove(index))
      return index
    } else {
      return nil
    }
  }
}
extension SortedArrayPipe where T: ComparsionValue {
  @discardableResult
  public func remove(_ element: T.ValueToCompare) -> Int? {
    if let index = array.remove(element) {
      output.send(.remove(index))
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
    pipe.next { [unowned self] in
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

