//
//  Response.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  // @discardableResult
  // public func send(constructor: @escaping (DataWriter)throws->()) -> Self {
  //   let operation = SomeSendOperation(constructor: constructor)
  //   add(operation)
  //   return self
  // }
}

private class SomeSendOperation: StreamOperation {
  override var cname: String { return "send(package:)" }
  let constructor: (DataWriter)throws->()
  init(constructor: @escaping (DataWriter)throws->()) {
    self.constructor = constructor
    super.init()
  }
  override func run() {
    do {
      let stream = self.stream as! SomeStream2
      let data = DataWriter()
      data.data.append(UInt32(0))
      data.append(UInt8(0))
      try constructor(data)
      printSendRead(prefix: "sending", data: data.data)
      stream.encrypt(data: data)
      stream.send(data: data.data) { response in
        Stream.debugSleep()
        switch response {
        case .success:
          self.completion(status: .success, action: .next)
        case .lostConnection:
          self.completion(status: .lostConnection, action: .restart)
        }
      }
    } catch {
      completion(status: .failed(error: error), action: .stop)
    }
  }
  enum Response {
    case success, lostConnection
  }
}
