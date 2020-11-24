//
//  StreamConnection.swift
//  Network
//
//  Created by Димасик on 9/19/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

public enum StreamStatus {
  case disconnected, connecting, connected
}

private var streams = 0
class StreamConnection: NSObject, StreamDelegate {
  static var id = 0
  var id: Int
  private(set) var _input: InputStream?
  private(set) var _output: OutputStream?
  private var input: InputStream  { return _input! }
  private var output: OutputStream  { return _output! }
  var queue = DispatchQueue(label: "some.network.stream.\(Int.unique)")
  var onDisconnect: (()->())?
  var onConnect: (()->())?
  
  var response: Response?
  var streamStatus: Stream.Status {
    return _input?.streamStatus ?? .notOpen
  }
  var status = StreamStatus.disconnected
  var streamOptions: Stream.Event = []
  
  var ip: String
  var port: Int
  
  var options = 0
  
  init(ip: String, port: Int) {
    self.ip = ip
    self.port = port
    
    StreamConnection.id += 1
    id = StreamConnection.id
    
    super.init()
    
    streams += 1
    Swift.print("streams: \(streams)")
  }
  
  deinit {
    streams -= 1
    Swift.print("streams: \(streams)")
  }
  
  func process(_ path: KeyPath<Response, Bool>, _ value: Bool) {
    guard let response = response else { return }
    guard response[keyPath: path] else { return }
    self.response = nil
    response.completion(value)
  }
  func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    if eventCode.contains(.hasBytesAvailable) {
      print("(sync) hasBytesAvailable \(input.hasBytesAvailable)")
    }
    queue.async {
      self._stream(aStream, handle: eventCode)
    }
  }
  func _stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    print("\(eventCode.rawValue)")
    streamOptions = eventCode
    if eventCode.contains(.openCompleted) {
      print("connected")
      status = .connected
      onConnect?()
      process(\Response.onConnect, true)
    }
    if eventCode.contains(.hasSpaceAvailable), output.hasSpaceAvailable {
      if let response = response, response.onSend {
        print("ready to send (sending)")
        self.response = nil
        response.completion(true)
      } else {
        print("ready to send (waiting)")
      }
//      process(\Response.onSend, true)
    }
    if eventCode.contains(.hasBytesAvailable), input.hasBytesAvailable {
      print("ready to read \(input.hasBytesAvailable)")
      if response == nil {
        print("error: response == nil")
      }
      process(\Response.onRead, true)
    }
    if eventCode.contains(.errorOccurred) {
      print("disconnected by error")
      if status != .disconnected {
        status = .disconnected
        onDisconnect?()
      }
      process(\Response.onDisconnect, false)
    }
    if eventCode.contains(.endEncountered) {
      print("disconnected")
      if status != .disconnected {
        status = .disconnected
        onDisconnect?()
      }
      process(\Response.onDisconnect, false)
    }
  }
  
  func connect(completion: @escaping (Bool)->()) {
    switch status {
    case .connected:
      completion(true)
    case .connecting:
      response = Connect(completion: completion)
    case .disconnected:
      print("connecting to \(ip)")
      status = .connecting
      response = Connect(completion: completion)
      
      Stream.getStreamsToHost(withName: ip, port: port, inputStream: &_input, outputStream: &_output)
      
      self.input.delegate = self
      self.output.delegate = self
      self.input.schedule(in: .main, forMode: .default)
      self.output.schedule(in: .main, forMode: .default)
      self.input.open()
      self.output.open()
    }
  }
  
  func disconnect() {
    guard _input != nil && _output != nil else { return }
    input.close()
    output.close()
    onDisconnect?()
    status = .disconnected
  }
  
  func onSpaceAvailable(completion: @escaping (Bool)->()) {
    if output.hasSpaceAvailable {
      completion(true)
    } else {
      print("waiting for available space to send")
      response = Send(completion: completion)
    }
  }
  
  func onBytesAvailable(completion: @escaping (Bool)->()) {
    if input.hasBytesAvailable {
      completion(true)
    } else {
      print("waiting for read")
      response = Read(completion: completion)
    }
  }
  
  func send(stream: @escaping ()->(Data?), completion: @escaping (StreamResponse)->()) {
    onSpaceAvailable { [unowned self] success in
      guard success else {
        completion(.lostConnection)
        return
      }
      guard let data = stream() else {
        completion(.success)
        return
      }
      let count = data.count
      let sended = self.output.write(data: data, id: self.id)
      if sended == count {
        self.send(stream: stream, completion: completion)
      } else {
        self.disconnect()
        completion(.lostConnection)
      }
    }
  }
  
  func read(id: UInt16, stream: @escaping (Data)->(Bool), completion: @escaping (StreamResponse)->()) {
    onBytesAvailable { [unowned self] success in
      guard success else {
        completion(.lostConnection)
        return
      }
      
//      var data = Data(size: 8.kb)
//      let readed = self.input.read(data: &data)
      if let data = self.input.read(id: self.id) {
        switch SomeSettings.stream.debugSendRead {
        case .full:
          self.print("received \(data.count.bytesString(.short)): \(data.hex(separateEvery: 4, separator: " "))")
        case .short:
          self.print("received \(data.count.bytesString(.short)) bytes")
        case .none: break
        }
        let shouldContinue = stream(data)
        if shouldContinue {
          self.print("read(stream:) shouldContinue")
          self.read(id: id, stream: stream, completion: completion)
        } else {
          self.print("read(stream:) success")
          completion(.success)
        }
      } else {
        self.print("read(stream:) lostConnection")
        self.disconnect()
        completion(.lostConnection)
      }
    }
  }
  
  func send(data: Data, completion: @escaping (StreamResponse)->()) {
    onSpaceAvailable { [unowned self] success in
      guard success else {
        completion(.lostConnection)
        self.print("lost connection on send")
        return
      }
      let count = data.count
      self.print("sending \(count) bytes")
      let sended = self.output.write(data: data, id: self.id)
      if sended == count {
        completion(.success)
      } else {
        self.disconnect()
        completion(.lostConnection)
      }
    }
  }
  
  func print(_ string: String) {
    guard SomeSettings.stream.debugStream else { return }
    Swift.print("stream \(id): \(string)")
  }
  
  func read(completion: @escaping (StreamDataResponse)->()) {
    onBytesAvailable { [unowned self] success in
      guard success else {
        completion(.lostConnection)
        return
      }
      if let data = self.input.read(id: self.id) {
        self.print("received \(data.count) bytes: \(data.hex(separateEvery: 4, separator: " "))")
        completion(.success(data))
      } else {
        self.disconnect()
        completion(.lostConnection)
      }
    }
  }
}

extension InputStream {
  func read(id: Int) -> Data? {
    var data = Data()
    var buffer = Data(count: 8.kb)
    while hasBytesAvailable {
      let count = read(data: &buffer)
      guard count > 0 else { return nil }
      data.append(buffer.subdata(in: 0..<count))
      if count == 0 {
        return nil
      } else {}
    }
    return data.isEmpty ? nil : data
  }
  private func read(data: inout Data) -> Int {
    let count = data.count
    return data.withUnsafeMutableBytes { read($0.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: count) }
  }
}

extension OutputStream {
  func write(data: Data, id: Int) -> Int {
    var c = _write(data: data)
    if SomeSettings.stream.debugStream {
      _print("stream \(id): sended \(c)/\(data.count) bytes")
    }
    guard c > 0 else { return c }
    while c < data.count {
      let s = _write(data: data.subdata(in: c..<data.count))
      
      guard s > 0 else { return s }
      c += s
      if SomeSettings.stream.debugStream {
        _print("stream \(id): sended \(c)/\(data.count) bytes")
      }
    }
    return c
  }
  private func _write(data: Data) -> Int {
    return data.withUnsafeBytes { write($0.baseAddress!.assumingMemoryBound(to: UInt8.self), maxLength: data.count) }
  }
}


extension StreamConnection {
  class Response {
    var completion: (Bool)->()
    var onRead: Bool { return false }
    var onSend: Bool { return false }
    var onConnect: Bool { return false }
    var onDisconnect: Bool { return false }
    init(completion: @escaping (Bool)->()) {
      self.completion = completion
    }
  }
  
  class Read: Response {
    override var onRead: Bool { return true }
    override var onDisconnect: Bool { return true }
  }
  class Send: Response {
    override var onSend: Bool { return true }
    override var onDisconnect: Bool { return true }
  }
  class Connect: Response {
    override var onConnect: Bool { return true }
    override var onDisconnect: Bool { return true }
  }
}
#endif
