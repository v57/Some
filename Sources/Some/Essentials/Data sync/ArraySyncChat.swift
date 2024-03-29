//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 9/2/20.
//

import Foundation

public protocol ArraySyncChatMessageContent {
  static var empty: Self { get }
}
public struct ArraySyncChatMessage<Content: ArraySyncChatMessageContent>: ArraySyncHashedItem {
  public var from: Int
  public var time: Time
  public var hash: UInt64
  public var content: Content
  public init(from: Int, time: Time, hash: UInt64, content: Content) {
    self.from = from
    self.time = time
    self.hash = hash
    self.content = content
  }
}
extension ArraySyncChatMessage: DataRepresentable where Content: DataRepresentable {
  public init(data: DataReader) throws {
    from = try data.next()
    time = try data.next()
    hash = try data.next()
    content = try data.next()
  }
  public func save(data: DataWriter) {
    data.append(from)
    data.append(time)
    data.append(hash)
    data.append(content)
  }
}
public protocol ArraySyncChat: ArraySyncQueuedClient where Item == ArraySyncChatMessage<Content> {
  associatedtype Content: ArraySyncChatMessageContent
  var senderId: Int { get }
}
public extension ArraySyncChat {
  typealias Message = ArraySyncChatMessage<Content>
  func send(messages: [Content]) {
    let from = senderId
    let time = Time.now
    var hash = UInt64.random()
    let items = messages.map {
      ArraySyncChatMessage<Content>.init(from: from, time: time, hash: hash.increment(), content: $0)
    }
    self.queuedAppend(items: items)
  }
  func update(message indexed: Indexed<Content>) -> P<Error?>? {
    if let message = items[indexed.index]?[nonRelative: indexed.index] {
      return update(items: Indexed(indexed.index, [message]))
    } else {
      return nil
    }
  }
  func update(message: Indexed<Message>, with content: Content) -> P<Error?> {
    var message = message
    message.value.content = content
    return update(items: Indexed(message.index, [message.value]))
  }
}

public protocol ArraySyncChatUser: ComparsionValue where ValueToCompare == Int {
  var id: Int { get }
  var lastRead: Int { get set }
}
public extension ArraySyncChatUser {
  var _valueToCompare: Int { id }
}
