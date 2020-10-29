//
//  Logger.swift
//  SomeFunctions
//
//  Created by Dmitry on 30/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import Foundation

#if os(macOS) || os(Linux)
extension FileHandle: TextOutputStream {
  public static var secondOutput: FileHandle?
  public func write(_ string: String) {
    write(string.data)
  }
}
public func _print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
  var out = FileHandle.standardOutput
  let output = items.map { "\($0)" }.joined(separator: separator)
  Swift.print(output, to: &out)
}
private let logFormat = DateFormatter().date(style: .none).time(style: .short)
private let logFormat2 = DateFormatter().date(style: .short).time(style: .medium)
public func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
  var out = FileHandle.standardOutput
  let output = items.map { "\($0)" }.joined(separator: separator)
  Swift.print("[\(logFormat.string(from: Date()))] " + output, to: &out)
  if var secondOutput = FileHandle.secondOutput {
    Swift.print("[\(logFormat2.string(from: Date()))] " + output, to: &secondOutput)
  }
}
#else
public func _print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
  let output = items.map { "\($0)" }.joined(separator: separator)
  Swift.print(Time.log, output, terminator: terminator)
}
#endif

public func testAssert(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
  #if debug
  assert(condition, message, file: file, line: line)
  #else
  if !condition {
    logger.critical("testAssert failed: \(message) at \(file):\(line)")
  }
  #endif
}

public let logger = Logger()
public class Logger {
  public var debug = LogContainer(level: 0, prefix: "debug: ", isPrivate: false)
  public var info = LogContainer(level: 100, prefix: "info: ", isPrivate: false)
  public var notice = LogContainer(level: 200, prefix: "notice: ", isPrivate: false)
  public var warning = LogContainer(level: 300, prefix: "warning: ", isPrivate: false)
  public var error = LogContainer(level: 400, prefix: "error: ", isPrivate: false)
  public var critical = LogContainer(level: 500, prefix: "critical: ", isPrivate: false)
  public var `private` = LogContainer(level: 600, prefix: "private: ", isPrivate: true)
  public func debug(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    debug.append(message, separator: separator, terminator: terminator)
  }
  public func info(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    info.append(message, separator: separator, terminator: terminator)
  }
  public func notice(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    notice.append(message, separator: separator, terminator: terminator)
  }
  public func warning(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    warning.append(message, separator: separator, terminator: terminator)
  }
  public func error(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    error.append(message, separator: separator, terminator: terminator)
  }
  public func critical(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    critical.append(message, separator: separator, terminator: terminator)
  }
  public func `private`(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    `private`.append(message, separator: separator, terminator: terminator)
  }
}

let allLogs = AllLogs()
public class AllLogs: CustomStringConvertible {
  public var logs = [String]()
  public func print() {
    _print(self)
  }
  public var description: String {
    return logs.joined(separator: "\n")
  }
}

public struct LogContainer: CustomStringConvertible {
  var level: Int
  var messages = [String]()
  var prefix: String
  var isEnabled = true
  var isPrivate: Bool
  var formattedPrefix: String {
    return "\(Time.now - .appStarted) " + prefix
  }
  init(level: Int, prefix: String, isPrivate: Bool) {
    self.level = level
    self.prefix = prefix
    self.isPrivate = isPrivate
  }
  mutating func append(_ message: Any..., separator: String = " ", terminator: String = "\n") {
    let message = formattedPrefix + message.map { "\($0)" }.joined(separator: separator) + terminator
    append(message)
  }
  mutating func append(_ message: String) {
    messages.append(message)
    #if debug
    guard !isPrivate else { return }
    #endif
    if isEnabled {
      _print(message)
    }
  }
  public var description: String {
    return messages.joined(separator: "\n")
  }
}
