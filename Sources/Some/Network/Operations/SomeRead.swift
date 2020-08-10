//
//  OnResponse.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

#if !os(Linux)
import Foundation

extension StreamOperations {
  @discardableResult
  public func read(success: @escaping (DataReader)throws->()) -> Self {
    let operation = SomeReadOperation(success: success)
    add(operation)
    return self
  }
}

class SomeReadOperation: StreamOperation {
  override var cname: String { return "read(package:)" }
  let success: (DataReader)throws->()
  init(success: @escaping (DataReader)throws->()) {
    self.success = success
    super.init()
  }
  override func run() {
    let stream = self.stream as! SomeStream2
    stream.readPackage { [unowned self] response in
      Stream.debugSleep()
      switch response {
      case .success(let data):
        do {
          try mainThreadSync {
            try self.success(data)
          }
          self.completion(status: .success, action: .next)
        } catch {
          self.completion(status: .failed(error: error), action: .stop)
        }
      case .lostConnection:
        self.completion(status: .lostConnection, action: .restart)
      }
    }
  }
  enum Response {
    case success(DataReader), lostConnection
  }
}
#endif
