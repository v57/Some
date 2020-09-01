//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/1/20.
//

import Foundation

public struct ArraySyncQueue<Item: HashedItem> {
  public var appendSending = [Item]()
  public var appendQueued = [Item]()
  public var appendWaiting = [UInt64]()
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
public protocol HashedItem {
  var hash: UInt64 { get set }
}
public protocol ArraySyncQueuedClient: ArraySyncClient where Item: HashedItem {
  var queue: ArraySyncQueue<Item> { get set }
  func timeout(_ completion: @escaping ()->())
  /// - Returns: `true` if operation should repeat
  func process(error: Error) -> Bool
  func newAdded(items: Indexed<[Item]>)
  func newUpdated(items: Indexed<[Item]>, oldValue: Indexed<[Item]>)
  func sentAppend(items: Indexed<[Item]>)
  func sentUpdates(items: Indexed<[Item]>, oldValue: Indexed<[Item]>)
}
public extension ArraySyncQueuedClient {
  func added(items: Indexed<[Item]>) {
    items.enumerate { item, stop in
      if queue.remove(waiting: item.value) {
        sentAppend(items: Indexed(item.index, [item.value]))
      } else {
        newAdded(items: Indexed(item.index, [item.value]))
      }
    }
  }
  func timeout(_ completion: @escaping ()->()) {
    wait(3) {
      completion()
    }
  }
  func queuedAdd(items: [Item]) {
    queue.appendQueued.append(contentsOf: items)
    sendAppending()
  }
  private func sendAppending() {
    guard queue.appendSending.isEmpty else { return }
    guard !queue.appendQueued.isEmpty else { return }
    queue.appendSending = queue.appendQueued
    add(items: queue.appendSending).next { error in
      self.added(error: error)
    }.storeSingle()
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
