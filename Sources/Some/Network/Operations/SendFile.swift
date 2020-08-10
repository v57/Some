//
//  SendFileOperation.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

let uploadSpeed = SpeedManager<Int>(name: "upload speed")

extension StreamOperations {
  @discardableResult
  public func sendFile(construct: @escaping (_ offset: inout UInt64,inout ProgressProtocol?)->(URL)) -> Self {
    let operation = SendFileOperation(construct: construct)
    add(operation)
    return self
  }
}

private class SendFileOperation: StreamOperation {
  enum OperationError: Error {
    case failedToOpenFile
    case cancelled
  }
  override var cname: String { return "send(file:)" }
  var construct: (inout UInt64,inout ProgressProtocol?)->(URL)
  init(construct: @escaping (inout UInt64,inout ProgressProtocol?)->(URL)) {
    self.construct = construct
    super.init()
  }
  override func run() {
    var offset: UInt64 = 0
    var progress: ProgressProtocol?
    let url = construct(&offset, &progress)
    
    
    guard let file = try? FileHandle(forReadingFrom: url) else {
      completion(status: .failed(error: OperationError.failedToOpenFile), action: .stop)
      return
    }
    let chunk: UInt64 = UInt64(8).kb // 100kb
    let size: UInt64 = file.seekToEndOfFile()
    file.seek(toFileOffset: offset)
//    var cancelled = false
//    progress.cancellationHandler = { [weak stream] in
//      cancelled = true
//      stream?.disconnect()
//    }
//    progress.pausingHandler = progress.cancellationHandler
    stream.send(stream: {
      let cancelled = progress?.isCancelled ?? false
      guard !cancelled else {
        Swift.print("sendfile: cancelled")
        return nil }
      print("sendfile: sended \(progress!.completed)/\(progress!.total)")
      print("sendfile: offset: \(offset), size: \(size)")
      if offset >= size {
        return nil
      } else if offset + chunk >= size {
        let data = file.readDataToEndOfFile()
        progress?.completed += Int64(data.count)
        print("sendfile: sending \(offset)..<\(offset+UInt64(data.count))/\(progress!.total) (last) \(data[0..<4].hex(separateEvery: 4, separator: " "))")
        offset += UInt64(data.count)
        uploadSpeed.append(data.count)
        return data
      } else {
        offset += chunk
        progress?.completed += Int64(chunk)
        let data = file.readData(ofLength: Int(chunk))
        print("sendfile: sending \(offset-chunk)..<\(offset)/\(progress!.total) \(data[0..<4].hex(separateEvery: 4, separator: " "))")
        uploadSpeed.append(data.count)
        return data
      }
    }) { response in
      Stream.debugSleep()
      file.closeFile()
      let cancelled = progress?.isCancelled ?? false
      if cancelled {
        self.completion(status: .failed(error: OperationError.cancelled), action: .stop)
      } else {
        switch response {
        case .success:
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
#endif
