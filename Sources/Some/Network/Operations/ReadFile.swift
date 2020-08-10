//
//  ReadFileOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation
import Foundation

class SpeedManager<T: BinaryInteger> {
  var name: String
  init(name: String) {
    self.name = name
  }
  var current: T = 0
  var total: T = 0
  var isRunning: Bool = false
  func append(_ value: T) {
    thread.lock {
      current += value
      resume()
    }
  }
  func resume() {
    guard !isRunning else { return }
    isRunning = true
    wait(1.0, completed)
  }
  func completed() {
    thread.lock {
      isRunning = false
      Swift.print("\(name) \(current.bytesString(.short))/s")
      total += current
      current = 0
    }
  }
}

let downloadSpeed = SpeedManager<Int>(name: "download speed")

public class SomeDownload: ProgressProtocol {
  public var data: Data?
  public var url: URL?
  public var completed: Int64 = 0
  public var total: Int64 = 0
  public var listeners = 0
  public var isDownloaded: Bool {
    return completed + 1 >= total
  }
  
  public var isCancelled = false
  public var storeData = false {
    didSet {
      guard storeData != oldValue else { return }
      if storeData {
        if completed > 0, let url = url {
          print("loading \(completed) bytes")
          thread.lock {
            do {
              data = try Data(contentsOf: url)
            } catch {
              print("cannot load data from \(url)")
              data = Data()
            }
          }
        } else {
          data = Data()
        }
      } else {
        data = nil
      }
    }
  }
  public func cancel() {
    isCancelled = true
  }
  
  public var dataReceived = P<SomeDownload>()
  public init() {}
  public func append(data: Data) {
    downloadSpeed.append(data.count)
    completed += Int64(data.count)
    self.data?.append(data)
    dataReceived.send(self)
  }
}

extension StreamOperations {
  @discardableResult
  public func readFile(construct: @escaping ()->(SomeDownload)) -> Self {
    let operation = ReadFileOperation(construct: construct)
    add(operation)
    return self
  }
}

/*
class Timeout {
  var time: Double = 1.0
  var action: ((inout Bool)->())?
  var version = 0
  func stop() {
    version += 1
  }
  func reset() {
    version += 1
    let v = version
    wait(time) { [weak self] in
      guard let sel = self else { return }
      if sel.version == v {
        var stop = false
        sel.action?(&stop)
        if !stop {
          sel.reset()
        }
      }
    }
  }
}
 */

private class ReadFileOperation: StreamOperation {
  enum OperationError: Error {
    case cancelled
  }
  override var cname: String { return "read(file:)" }
  var construct: ()->(SomeDownload)
  init(construct: @escaping ()->(SomeDownload)) {
    self.construct = construct
    super.init()
  }
  override func run() {
    let download = construct()
    let file: FileHandle?
    if let url = download.url {
      file = try? FileHandle(forWritingTo: url)
    } else {
      file = nil
    }
    
    file?.seek(toFileOffset: UInt64(download.completed))
//    var cancelled = false
//    progress.cancellationHandler = { [weak stream] in
//      cancelled = true
//      stream?.disconnect()
//    }
//    progress.pausingHandler = progress.cancellationHandler
    
    let id = UInt16.random()
    stream.read(id: id, stream: { [unowned self] data in
      file?.write(data)
      download.append(data: data)
      self.stream.someDescription = "download \(download.completed)/\(download.total)"
      return !download.isDownloaded && !download.isCancelled
    }) { [unowned self] response in
      Stream.debugSleep()
      file?.closeFile()
      if download.isCancelled {
        self.completion(status: .failed(error: OperationError.cancelled), action: .stop)
      } else {
        switch response {
        case .success:
          self.stream = nil
          self.completion(status: .success, action: .next)
        case .lostConnection:
          self.completion(status: .lostConnection, action: .restart)
        }
      }
    }
  }
  enum Response {
    case success, lostConnection
  }
}

private func print(_ text: String) {
  guard SomeSettings.stream.debugFileProgress else { return }
  Swift.print(text)
}
