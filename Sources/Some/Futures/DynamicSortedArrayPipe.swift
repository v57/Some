//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 25/11/2020.
//

#if canImport(Combine)
import Foundation

public class DynamicSortedArrayPipe<T: Comparable> {
  public var array: [T] {
    didSet {
      count = array.count
    }
  }
  @Published public var count: Int
  public lazy var input: P<SetOperation<T>> = {
    let pipe = P<SetOperation<T>>()
    pipe.forEach { [unowned self] in
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
  private var ignoreUpdates: Bool = false
  public var filter: (T)->Bool = { _ in true } {
    didSet {
      guard !ignoreUpdates else { return }
      if let parent = parent {
        set(parent.array.array)
      } else {
        guard !array.isEmpty else { return }
        array.enumerated().reversed().forEach {
          if filter($0.element) {
            remove(at: $0.offset)
          }
        }
      }
    }
  }
  public var sorter = Sorter<T>() {
    didSet {
      guard !ignoreUpdates else { return }
      guard !array.isEmpty else { return }
      let array = self.array.sorted(using: sorter)
      self.array = array
      output.send(.set(array))
    }
  }
  public var parent: SortedArrayPipe<T>?
  public init(parent: SortedArrayPipe<T>, sorter: Sorter<T>, filter: @escaping (T)->Bool) {
    self.parent = parent
    self.sorter = sorter
    self.filter = filter
    self.array = parent.array.array.filter(filter).sorted(using: sorter)
    self.count = array.count
    parent.output.map(\.setOperation).add(self.input)
  }
  public init(_ set: [T]) {
    self.array = set
    count = array.count
  }
  public init() {
    self.array = []
    count = array.count
  }
  public func set(sorter: Sorter<T>, filter: @escaping (T)->Bool) {
    ignoreUpdates = true
    self.sorter = sorter
    self.filter = filter
    ignoreUpdates = false
    set(parent?.array.array ?? array)
  }
  /// Update: Sends updates for exists elements
  public func set(_ unsorted: [T]) {
    array = unsorted.filter(filter).sorted(using: sorter)
    output.send(.set(array))
  }
  public func removeAll() {
    self.array.removeAll()
    output.send(.set([]))
  }
  /// Updates or inserts element
  public func update(_ element: T) {
    if let index = array.firstIndex(of: element) {
      array[index] = element
      output.send(.update(index.indexed(element)))
    } else {
      insert(element)
    }
  }
  public func insert(_ element: T) {
    insert(element, replace: true)
  }
  public func insert(_ element: T, replace: Bool) {
    guard filter(element) else { return }
    guard !array.contains(element) else { return }
    let index = array.binaryInsert(element, using: sorter, replace: replace)
    output.send(.insert(index.indexed(element)))
  }
  @discardableResult
  public func remove(_ element: T) -> Indexed<T>? {
    if let index = array.firstIndex(where: { $0 == element }) {
      let removed = Indexed(index, array.remove(at: index))
      output.send(.remove(removed))
      return removed
    } else {
      return nil
    }
  }
  @discardableResult
  public func remove(at index: Int) -> Indexed<T> {
    let removed = Indexed(index, array.remove(at: index))
    output.send(.remove(removed))
    return removed
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
public extension SortedArrayPipe {
  func dynamic(sorter: Sorter<T>, filter: @escaping (T)->(Bool) = { _ in true }) -> DynamicSortedArrayPipe<T> {
    DynamicSortedArrayPipe(parent: self, sorter: sorter, filter: filter)
  }
}
public extension DynamicSortedArrayPipe {
  var isSorted: Bool {
    guard count > 1 else { return true }
    for i in 1..<count {
      if sorter.compare(array[i-1], array[i]) == .greater {
        return false
      }
    }
    return true
  }
  func resortIfNeeded() {
    guard !isSorted else { return }
    let a = array.enumerated().map { Indexed($0.offset, $0.element) }.sorted { sorter.sort($0.value, $1.value) }
    a.forEach {
      array[$0.index] = $0.value
      output.send(.update($0))
    }
  }
}
#endif
