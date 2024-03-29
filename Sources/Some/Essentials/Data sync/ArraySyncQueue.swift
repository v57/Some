//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/1/20.
//

import Foundation

// MARK: - ArraySyncQueue
public struct ArraySyncQueue<Item: ArraySyncHashedItem> {
  public var appendSending = [Item]()
  public var appendQueued = [Item]()
  public var appendWaiting = [UInt64]()
  public init() {}
}

extension ArraySyncQueue: DataRepresentable where Item: DataRepresentable {
  // TODO: Fix problem when data saved, messages sent and app crashed. So on next load messages will send again
  public init(data: DataReader) throws {
    appendSending = try data.next()
    appendQueued = try data.next()
    appendWaiting = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(appendSending)
    data.append(appendQueued)
    data.append(appendWaiting)
  }
}

private extension ArraySyncQueue {
  mutating func insert(waiting: Item) {
    if !contains(waiting: waiting) {
      appendWaiting.binaryInsert(waiting.hash)
    }
  }
  mutating func remove(waiting: Item) -> Bool {
    if let index = appendWaiting.binarySearch(waiting.hash) {
      appendWaiting.remove(at: index)
      return true
    } else {
      return false
    }
  }
  func contains(waiting: Item) -> Bool {
    appendWaiting.binarySearch(waiting.hash) != nil
  }
}

public protocol ArraySyncHashedItem {
  var hash: UInt64 { get set }
}

// MARK: - ArraySyncQueuedClient
public protocol ArraySyncQueuedClient: ArraySyncClient where Item: ArraySyncHashedItem {
  var queue: ArraySyncQueue<Item> { get set }
  func timeout(_ completion: @escaping ()->())
  /// - Returns: `true` if operation should repeat
  func process(error: Error) -> Bool
  func newAdded(items: Indexed<[Item]>)
  func newUpdated(items: Indexed<[Item]>, oldValue: Indexed<[Item]>)
  func appendSent(items: Indexed<[Item]>)
  func updatesSent(items: Indexed<[Item]>, oldValue: Indexed<[Item]>)
}
public extension ArraySyncQueuedClient {
  // MARK: - Added
  func added(items: Indexed<[Item]>) {
    guard !items.value.isEmpty else { return }
    var range = 0..<0
    var sent = false
    items.enumerate { index, item, stop in
      if queue.remove(waiting: item.value) {
        if !sent {
          addItems(index: index, items: items, range: &range, using: newAdded)
          sent = true
        }
      } else {
        if sent {
          addItems(index: index, items: items, range: &range, using: appendSent)
          sent = false
        }
      }
    }
    if sent {
      addItems(index: items.count, items: items, range: &range, using: appendSent)
    } else {
      addItems(index: items.count, items: items, range: &range, using: newAdded)
    }
  }
  private func addItems(index: Int, items: Indexed<[Item]>, range: inout Range<Int>, using: (Indexed<[Item]>)->()) {
    range.end = index
    if !range.isEmpty {
      let array = Array(items.value[range])
      newAdded(items: Indexed(items.index + range.lowerBound, array))
      range = index..<index
    }
  }
  
  // MARK: - Default timeout
  func timeout(_ completion: @escaping ()->()) {
    wait(3) {
      completion()
    }
  }
  
  // MARK: - Queued append
  func queuedAppend(items: [Item]) {
    queue.appendQueued.append(contentsOf: items)
    sendAppending()
  }
  private func sendAppending() {
    guard queue.appendSending.isEmpty else { return }
    guard !queue.appendQueued.isEmpty else { return }
    queue.appendSending = queue.appendQueued
    add(items: queue.appendSending).first().sink { error in
      self.added(error: error)
    }.store()
  }
  private func added(error: Error?) {
    if let error = error {
      if !process(error: error) {
        queue.appendSending.removeAll()
      }
      timeout {
        self.sendAppending()
      }
    } else {
      queue.appendSending.removeAll()
      sendAppending()
    }
  }
}
