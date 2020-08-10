//
//  StreamOperation.swift
//  SomeNetwork
//
//  Created by Димасик on 2/2/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

import Foundation

open class StreamOperation {
  var stream: SomeStream!
  var _priority: Int { return 0 }
  var completed: ((StreamOperation, CompletionStatus, CompletionAction)->())?
  public var name: String = ""
  public weak var parent: StreamOperations?
  open var cname: String { return "" }
  var fullName: String {
    var string = ""
    if !name.isEmpty {
      string = "\(name)."
    }
    if cname.isEmpty {
      string += className(self)
    } else {
      string += cname
    }
    return string
  }
  
  public enum DebugMode {
    case full, mini, none
  }
  open var debugMode: DebugMode { return .full }
  
  public init() {}
  func run() {}
  func completion(status: CompletionStatus, action: CompletionAction) {
    completed!(self,status,action)
  }
  
  var parents: [StreamOperations] {
    var array = [StreamOperations]()
    if let parent = parent {
      array.insert(parent, at: 0)
      array.insert(contentsOf: parent.parents, at: 0)
    }
    return array
  }
}
