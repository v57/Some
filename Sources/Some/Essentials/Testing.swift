//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 7/26/20.
//

import Foundation

public var isTesting = false
public func overrideRequired(file: String = #file, function: String = #function, line: Int = #line) -> Never {
  fatalError("""
    Class override required.
    file: \(file)
    line: \(line)
    function: \(function)
    """)
}
public struct UniqueData<T: Hashable> {
  private var set = Set<T>()
  public init() {}
  public mutating func insert(_ value: T) {
    assert(set.insert(value).inserted, "UniqueData received a duplicated value \(value)")
  }
}

public enum SomeTest {
  
}
public extension SomeTest {
  static func ops(_ name: String, _ code: @escaping ()->()) {
      var ops: Double = 0
      let queue = OperationQueue()
      let lock = NSLock()
      for _ in 0..<5 {
          queue.addOperation {
              var _ops = 0
              var time = 0.0
              while time < 0.5 {
                  let t = Time.abs
                  code()
                  _ops += 1
                  time += Time.abs - t
              }
              lock.lock()
              ops += Double(_ops) / time
              lock.unlock()
          }
      }
      queue.waitUntilAllOperationsAreFinished()
      let result = ops
      let opsString: String
      if result > 100.0 {
          opsString = Int(result).description
      } else {
          opsString = result.string(precision: 2)
      }
      print("\(name): \(opsString) operations per second")
  }
  @discardableResult
  static func measure(_ text: String, _ code: ()throws->()) -> Double {
    let start = Time.abs
    do {
      try code()
      let end = Time.abs
      print("\(text) \(end-start) seconds")
      return end-start
    } catch {
      print("\(text) error: \(error)")
      return 0
    }
  }
  static func measure(_ text: String, _ count: Int, _ code: ()throws->()) {
    print(text)
    for _ in 0..<count {
      let start = Time.abs
      do {
        try code()
        let end = Time.abs
        print("\(end-start) seconds")
      } catch {
        print("error: \(error)")
      }
    }
  }
  static func dataMeasure(_ text: String, _ size: Int, _ count: Int, _ code: ()throws->()) {
    print(text)
    for _ in 0..<count {
      let start = Time.abs
      do {
        try code()
        let time = Time.abs - start
        print("\(Int(Double(size) / time).bytesString()) / sec")
      } catch {
        print("error: \(error)")
      }
    }
  }
}

// MARK: MacOS
#if os(macOS)
public extension Process {
  static var memoryUsage: Int {
    var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
    let rev1Count = mach_msg_type_number_t(MemoryLayout.offset(of: \task_vm_info_data_t.min_address)! / MemoryLayout<integer_t>.size)
    var info = task_vm_info_data_t()
    let kr = withUnsafeMutablePointer(to: &info) { infoPtr in
      infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
        task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
      }
    }
    guard kr == KERN_SUCCESS, count >= rev1Count
      else { return 0 }
    return Int(info.phys_footprint)
  }
}
extension SomeTest {
  static func memoryUsage(_ execute: (()->())->()) {
    let memory = Process.memoryUsage
    let completion = {
      print("Memory usage: \((Process.memoryUsage - memory).bytesString())")
    }
    execute(completion)
  }
  static func memoryUsage(operations: Int, _ execute: (()->())->()) {
    var memory = Process.memoryUsage
    let completion = {
      memory = Process.memoryUsage - memory
    }
    execute(completion)
    print("Memory usage: \((memory).bytesString()) \(memory/operations) bytes/operation")
  }
}
#endif
