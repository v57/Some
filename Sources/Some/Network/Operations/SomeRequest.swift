//
//  Request.swift
//  Network
//
//  Created by Димасик on 9/20/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

extension StreamOperations {
  @discardableResult
  public func request(constructor: @escaping (DataWriter)throws->()) -> Self {
    let operation = SomeRequestOperation(constructor: constructor)
    add(operation)
    return self
  }
}

public class SomeRequestOperation: StreamOperation {
  override public var cname: String { return "request(package:)" }
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
      try constructor(data)
      printSendRead(prefix: "sending", data: data.data)
      stream.encrypt(data: data)
      printSendRead(prefix: "encrypted", data: data.data)
      stream.send(data: data.data) { [unowned self] response in
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
