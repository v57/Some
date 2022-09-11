//
//  RequestManager.swift
//  Events
//
//  Created by Димасик on 4/16/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

import Foundation

/*
private var _streamId = 0
private var streamId: Int {
  _streamId += 1
  return _streamId
}
private var streams = 0

enum TCPOptions: UInt8 {
  case isConnected
  case isConnecting
  case isSending
  case isReading
  case isReadyToRead
  case isReadyToSend
  case isSync
}

public class TCPStreamDebug: TCPStream {
  public override init(ip: String, port: Int) {
    super.init(ip: ip, port: port)
    streams += 1
    Swift.print("streams: \(streams)")
  }
  deinit {
    streams -= 1
    Swift.print("streams: \(streams)")
  }
  override func connected() {
    print("connected")
    super.connected()
  }
  override func readyToSend() {
    print("ready to send")
    super.readyToSend()
  }
  override func readyToRead() {
    print("ready to read")
    super.readyToRead()
  }
  override func disconnected() {
    print("disconnected by error")
    super.disconnected()
  }
  
  func print(_ string: String) {
    guard SomeSettings.stream.debugStream else { return }
    Swift.print("stream \(id): \(string)")
  }
}

public class TCPStreamSyncable: TCPStreamDebug {
  lazy var queue = DispatchQueue(label: "some.network.tcp.\(Int.unique)")
  lazy var semaphore = DispatchSemaphore(value: 0)
  override func connect() {
    super.connect()
    if isSync {
      semaphore.wait()
    }
  }
  override func connected() {
    if isSync {
      semaphore.signal()
    }
    super.connected()
  }
  
  override func readyToSend() {
    if isSync {
      send(data: sendBuffer)
    } else {
      
    }
  }
  
  override func lostConnection() {
    if isSync {
      semaphore.signal()
    }
    super.lostConnection()
  }
  override func disconnected() {
    if isSync {
      semaphore.signal()
    }
    super.disconnected()
  }
}

private extension TCPStream {
  var isConnecting: Bool {
    return options.contains(.isConnecting)
  }
  var isDisconnected: Bool {
    return !options.contains(.isConnected) && !options.contains(.isConnecting)
  }
  var isReading: Bool {
    return options.contains(.isReading)
  }
  var isSending: Bool {
    return options.contains(.isSending)
  }
  var isReadyToRead: Bool {
    return options.contains(.isReadyToRead)
  }
  var isReadyToSend: Bool {
    return options.contains(.isReadyToSend)
  }
  
}

public extension TCPStream {
  var isSync: Bool {
    get {
      return options.contains(.isSync)
    } set {
      options[.isSync] = newValue
    }
  }
  var isConnected: Bool {
    return options.contains(.isConnected)
  }
  var status: StreamStatus {
    get {
      if options.contains(.isConnecting) {
        return .connecting
      } else if options.contains(.isConnected) {
        return .connected
      } else {
        return .disconnected
      }
    } set {
      switch newValue {
      case .connecting:
        options.insert(.isConnecting)
        options.remove(.isConnected)
      case .connected:
        options.insert(.isConnected)
        options.remove(.isConnecting)
      case .disconnected:
        options.remove(.isConnected)
        options.remove(.isConnecting)
      }
    }
  }
}

public class TCPStream: NSObject, StreamDelegate, TCPConnection {
  var delegate: TCPDelegate?
  var sendBuffer = Data()
  
  var id: Int = streamId
  private var _input: InputStream?
  private var _output: OutputStream?
  private var input: InputStream  { return _input! }
  private var output: OutputStream  { return _output! }
  var options = TCPOptions.Set()
  
  public var ip: String
  public var port: Int
  
  public init(ip: String, port: Int) {
    self.ip = ip
    self.port = port
    id = streamId
    super.init()
  }
  
  public func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
    if eventCode.contains(.openCompleted) {
      if status != .connected {
        connected()
      }
    }
    if eventCode.contains(.hasSpaceAvailable) {
      readyToSend()
    }
    if eventCode.contains(.hasBytesAvailable) {
      readyToRead()
    }
    if eventCode.contains(.errorOccurred) {
      if status != .disconnected {
        disconnected()
      }
    }
    if eventCode.contains(.endEncountered) {
      if status != .disconnected {
        disconnected()
      }
    }
  }
  
  func readyToSend() {
    
  }
  func readyToRead() {
    
  }
  
  
  func connect() {
    status = .connecting
    Stream.getStreamsToHost(withName: ip, port: port, inputStream: &_input, outputStream: &_output)
    input.delegate = self
    output.delegate = self
    input.schedule(in: .main, forMode: .defaultRunLoopMode)
    output.schedule(in: .main, forMode: .defaultRunLoopMode)
    input.open()
    output.open()
  }
  func disconnect() {
    guard status != .disconnected else { return }
    guard _input != nil && _output != nil else { return }
    input.close()
    output.close()
    disconnected()
  }
  
  func send(data: Data) {
    guard !data.isEmpty else { return }
    let count = data.count
    let sended = self.output.write(data: data, id: self.id)
    if sended == count {
      delegate?.sended()
    } else {
      disconnect()
      lostConnection()
    }
  }
  
  func read() -> Data {
    var data = Data(size: 8192)
    let readed = self.input.read(data: &data)
    if readed > 0 {
      return data.subdata(in: 0..<readed)
    } else {
      disconnect()
      lostConnection()
      return Data()
    }
  }
  
  func connected() {
    status = .connected
    delegate?.connected()
  }
  
  func disconnected() {
    status = .disconnected
    delegate?.disconnected()
  }
  
  func lostConnection() {
    delegate?.lostConnection()
  }
}

protocol TCPConnection: AnyObject {
  var delegate: TCPDelegate? { get set }
  
  func connect()
  func disconnect()
  
  func connected()
  func disconnected()
  func lostConnection()
  func readyToSend()
  func readyToRead()
}

protocol TCPDelegate: AnyObject {
  var connection: TCPConnection? { get set }
  func connected()
  func disconnected()
  func lostConnection()
  func sended()
  func received(data: Data)
}

class DataSnapshot {
  var key: UInt64 = 0
  var data = DataWriter()
}

class SomeRequest {
  var isPackable: Bool { return true }
  var shouldRepeat: Bool { return false }
  var staticData: Bool { return true }
  
  var privateData: DataWriter?
  func send(data: DataWriter) {
    
  }
  func read(data: DataReader) throws {
    
  }
  func corrupted() {
    
  }
}

class RequestManager {
  var sendingCount = 0
  var queue = [SomeRequest]()
  var maxRequests: Int {
    return 100
  }
  var maxRequestSize: Int {
    return 100.kb
  }
  var sending = [SomeRequest]()
  var isConnected = false
  var isSending = false
  
  // open
  func prefix(package: inout [SomeRequest]) {
    
  }
  
  // public
  func append(request: SomeRequest) {
    queue.append(request)
    if !isSending {
      next()
    }
  }
  
  // private
  func next() {
    prefix(package: &sending)
    let data = DataWriter()
    for request in sending {
      data.append(request.data)
    }
    for request in queue {
      sending.append(request)
      sendingCount += 1
      data.append(request.data)
      if sending.count >= maxRequests || !request.isPackable || data.count >= maxRequestSize {
        break
      }
    }
    send(data: data)
  }
  func send(data: DataWriter) {
    
  }
  func sended() {
    
  }
  func response(data: DataReader) {
    do {
      let responses: [DataReader] = try data.next()
      for (i,response) in responses.enumerated() {
        let request = sending[i]
        do {
          try request.read(data: response)
        } catch DataError.corrupted {
          request.corrupted()
        } catch {
          
        }
      }
    } catch {}
  }
  func notification(type: UInt8, data: DataReader) {
    
  }
  
  func resetSending(clear: Bool) {
    if clear {
      queue.removeFirst(sendingCount)
    }
    sendingCount = 0
    sending.removeAll(keepingCapacity: true)
  }
}

class SomeDataProcessor {
  enum State {
    case idle
    case processing(packages: Int, size: Int)
  }
  var buffer = DataReader()
  var packages = 0
  var size = 0
  var offset = 0
  var key: UInt64 = 0
  weak var delegate: RequestManager?
  
  func received(data: Data, from manager: RequestManager) {
    buffer.data.append(data)
  }
  func send(data: DataWriter, from manager: RequestManager) {
    encrypt(data: data)
  }
  func append(buffer data: Data) throws {
    buffer.data.append(contentsOf: data)
    do {
      while let package = try buffer.package() {
        decrypt(data: package)
        let type: UInt8 = try! package.next()
        if type == 0 {
          delegate?.response(data: package)
        } else {
          delegate?.notification(type: type, data: package)
        }
      }
    } catch {
      throw error
    }
  }
  
  
  func encrypt(data: DataWriter) {
    data.encrypt(password: key)
    data.replace(at: 0, with: Data(UInt32(data.count)))
  }
  func decrypt(data: DataReader) {
    data.decrypt(password: key, offset: 4)
  }
}

protocol DataProcessor {
  var buffer: DataReader { get set }
  func received(data: Data)
  func send(data: DataWriter)
}

protocol DataProcessorDelegate {
  func response(data: DataReader) throws
}



private extension SomeRequest {
  var data: DataWriter {
    if staticData, let data = privateData {
      return data
    } else {
      let data = DataWriter()
      send(data: data)
      if staticData {
        privateData = data
      }
      return data
    }
  }
}
*/
