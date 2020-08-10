//
//  stream.swift
//  Network
//
//  Created by Димасик on 9/19/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

public enum StreamError: Error {
  case lostConnection
}

open class SomeStream {
  var someDescription: String?
  public var queue: DispatchQueue {
    get { return stream.queue }
    set { stream.queue = newValue }
  }
  var stream: StreamConnection
  public var isConnected: Bool { status == .connected }
  public var streamOptions: Stream.Event { stream.streamOptions }
  public var streamStatus: Stream.Status { stream.streamStatus }
  public var status: StreamStatus { stream.status }
  public var ip: String {
    set {
      stream.ip = newValue
    } get {
      return stream.ip
    }
  }
  public var port: Int {
    set {
      stream.port = newValue
    } get {
      return stream.port
    }
  }
  
  public init(ip: String, port: Int) {
    stream = StreamConnection(ip: ip, port: port)
    stream.onDisconnect = { [weak self] in
      self?.disconnected()
    }
    stream.onConnect = { [weak self] in
      self?.connected()
    }
  }
  
  func connect(completion: @escaping (Bool)->()) {
    stream.connect(completion: completion)
  }
  public func disconnect() {
    stream.disconnect()
  }
  func send(data: Data, completion: @escaping (StreamResponse)->()) {
    stream.queue.async {
      self.stream.send(data: data, completion: completion)
    }
  }
  func read(completion: @escaping (StreamDataResponse)->()) {
    stream.queue.async {
      self.stream.read(completion: completion)
    }
  }
  func send(stream: @escaping ()->(Data?), completion: @escaping (StreamResponse)->()) {
    self.stream.queue.async {
      self.stream.send(stream: stream, completion: completion)
    }
  }
  func read(id: UInt16, stream: @escaping (Data)->(Bool), completion: @escaping (StreamResponse)->()) {
    self.stream.queue.async {
      self.stream.read(id: id, stream: stream, completion: completion)
    }
  }
  open func connected() {
    
  }
  open func disconnected() {
    
  }
  open func writeDescription(to string: inout String) {
    string.addLine("stream \(stream.id) ")
    if stream._input != nil {
      switch streamStatus {
      case .writing: string += "writing"
      case .notOpen: string += "notOpen"
      case .opening: string += "opening"
      case .open: string += "open"
      case .reading: string += "reading"
      case .atEnd: string += "atEnd"
      case .closed: string += "closed"
      case .error: string += "error"
      @unknown default:
        fatalError()
      }
    } else {
      string += "created"
    }
    let options = streamOptions
    if options.contains(.openCompleted) {
      string += " openCompleted"
    }
    if options.contains(.hasSpaceAvailable) {
      string += " hasSpaceAvailable"
    }
    if options.contains(.hasBytesAvailable) {
      string += " hasBytesAvailable"
    }
    if options.contains(.errorOccurred) {
      string += " errorOccurred"
    }
    if options.contains(.endEncountered) {
      string += " endEncountered"
    }
    if let response = stream.response {
      var array = [String]()
      if response.onConnect {
        array.append("connect")
      }
      if response.onDisconnect {
        array.append("disconnect")
      }
      if response.onRead {
        array.append("read")
      }
      if response.onSend {
        array.append("send")
      }
      string.addLine("trigger on: \(array.joined(separator: ", "))")
    }
  }
}


enum StreamDataResponse {
  case success(Data), lostConnection
}

enum StreamResponse {
  case success, lostConnection
}

extension SomeStream: Equatable {
  public static func ==(lhs: SomeStream, rhs: SomeStream) -> Bool {
    return lhs === rhs
  }
}

extension SomeStream: Hashable {
  public func hash(into hasher: inout Hasher) {
    ObjectIdentifier(self).hash(into: &hasher)
  }
}
#endif
