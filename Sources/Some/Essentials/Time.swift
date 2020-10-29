
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Dmitry Kozlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation

public typealias Time = Int

public extension DateFormatter {
  static let styled = DateFormatter()
  static let formatted = DateFormatter()
}

public func measure(_ text: String, _ code: ()throws->()) {
  let start = Time.mcs
  do {
    try code()
    let end = Time.mcs
    _print("\(text) \((end-start).string(unitDecimals: 6, decimals: 6))")
  } catch {
    _print("\(text) error: \(error)")
  }
}

public struct TimeMeasure: CustomStringConvertible {
  public var start: Time
  public var end: Time
  public var passed: Time { end - start }
  public var passedString: String {
    passed.string(unitDecimals: 6, decimals: 6) + "s"
  }
  public var framePercentage: Int {
    Int(Double(passed) / Double(16666) * 100)
  }
  public init() {
    start = .mcs
    end = start
  }
  public mutating func stop() {
    end = .mcs
  }
  public var description: String {
    "\(framePercentage)%"
  }
}

public extension Time {
  static let startup = Time.mcs
  var future: Time { self - .now }
  var past: Time { .now - self }
  func pad(_ length: Int) -> String {
    if self == 0 {
      return String(repeating: "0", count: length)
    } else {
      let string = description
      return String(repeating: "0", count: Swift.max(length - string.count, 0)) + string
    }
  }
  var hms: String {
    "\(hours.pad(2)):\((minutes % 60).pad(2)):\(seconds.pad(2))"
  }
  var ms: String {
    if minutes >= 60 {
      return "\(hours):\((minutes % 60).pad(2)):\(seconds.pad(2))"
    } else {
      return "\(minutes):\(seconds.pad(2))"
    }
  }
  static let appStarted = Time.now
  static var now: Time {
    var time:timeval = timeval(tv_sec: 0, tv_usec: 0)
    gettimeofday(&time, nil)
    return Time(time.tv_sec)
  }
  static var ms: UInt64 { UInt64(timeval.now.ms) }
  static var abs: Double { timeval.now.double }
  static var timezone: Time { Time(NSTimeZone.local.secondsFromGMT()) }
  var seconds: Time { self % .minute }
  var minutes: Time { self / .minute }
  var hours: Time { self / .hour }
  static let minute: Time = 60
  static func minutes(_ amount: Time) -> Time {
    amount * .minute
  }
  static func minutes(_ range: ClosedRange<Time>) -> Time {
    range.mapBounds { $0 * .minute }.random
  }
  static let hour: Time = 3600
  static func hours(_ amount: Time) -> Time {
    amount * .hour
  }
  static func hours(_ range: ClosedRange<Time>) -> Time {
    range.mapBounds { $0 * .hour }.random
  }
  static let day: Time = 86400
  static func days(_ amount: Time) -> Time {
    amount * .day
  }
  static func days(_ range: ClosedRange<Time>) -> Time {
    range.mapBounds { $0 * .day }.random
  }
  static let week: Time = 604800
  static func weeks(_ amount: Time) -> Time {
    amount * .week
  }
  static func weeks(_ range: ClosedRange<Time>) -> Time {
    range.mapBounds { $0 * .week }.random
  }
  static let month: Time = 2628000
  static func months(_ amount: Time) -> Time {
    amount * .month
  }
  static func months(_ range: ClosedRange<Time>) -> Time {
    range.mapBounds { $0 * .month }.random
  }
  static let year: Time = 31536000
  static func years(_ amount: Time) -> Time {
    amount * .year
  }
  static func years(_ range: ClosedRange<Time>) -> Time {
    range.mapBounds { $0 * .year }.random
  }
  
  var year: Int {
    return Calendar.current.component(.year, from: date)
  }
  var date: Date {
    return Date(timeIntervalSince1970: TimeInterval(self))
  }
  func dateFormat(date: DateFormatter.Style = .none, time: DateFormatter.Style = .none) -> String {
    let df = DateFormatter.styled
    df.dateStyle = date
    df.timeStyle = time
    return df.string(from: self.date)
  }
  func dateFormat(_ format: String) -> String {
    let df = DateFormatter.formatted
    df.dateFormat = format
    return df.string(from: self.date)
  }
  var timeFormat: String {
    let df = DateFormatter.styled
    df.dateStyle = .none
    df.timeStyle = .short
    return df.string(from: date)
  }
  var singleChar: String {
    if self < .minute {
      return "\(self)s"
    } else if self < .hour {
      return "\(self / .minute)m"
    } else if self < .day {
      return "\(self / .hour)h"
    } else if self < .week {
      return "\(self / .day)d"
    } else if self < .year {
      return "\(self / .week)w"
    } else {
      return "\(self / .year)y"
    }
  }
  var uniFormat: String {
    let current = Time.now
    var result = ""
    var timeDifference = Swift.max(current,self)
    timeDifference -= Swift.min(current,self)
    if timeDifference > 82800 {
      result.append(dateFormat("MMM dd "))
    }
    if current.year != year {
      result.append("2k")
      result.append(dateFormat("YY "))
    }
    if !result.isEmpty {
      result.append(" ")
    }
    result.append(dateFormat(time: .short))
    return result
  }
  static func ping(_ start: Double) -> Int {
    return Int((Time.abs - start) * 1000)
  }
}
public extension Double {
  mutating func measureTime(_ message: String) {
    let now = Time.abs
    let time = now - self
    //    if time > 0.1 {
    print(message,time)
    //    }
    self = now
  }
}

public extension timeval {
  static var now: timeval {
    var time:timeval = timeval(tv_sec: 0, tv_usec: 0)
    gettimeofday(&time, nil)
    return time
  }
  var usecFromNow: Int64 {
    var now:timeval = timeval(tv_sec: 0, tv_usec: 0)
    gettimeofday(&now, nil)
    let sec = Int64(now.tv_sec - self.tv_sec)
    let usec = Int64(now.tv_usec - self.tv_usec)
    return sec * 1000000 + usec
  }
  #if os(iOS)
  var usecs: Int64 {
    return Int64(tv_sec) * 1000000 + Int64(tv_usec)
  }
  #else
  var usecs: Int {
    return Int(tv_sec) * 1000000 + Int(tv_usec)
  }
  #endif
  var sec: Int {
    return self.tv_sec
  }
  var double: Double {
    Double(tv_sec) + Double(tv_usec) / 1000000
  }
  var ms: Int64 {
    return Int64(tv_sec) * 1000 + Int64(tv_usec) / 1000
  }
  mutating func update() {
    gettimeofday(&self, nil)
  }
  static func -= (l: inout timeval, r: timeval) {
    l.tv_sec -= r.tv_sec
    l.tv_usec -= r.tv_usec
    while l.tv_usec < 0 {
      l.tv_usec += 1_000_000
      l.tv_sec -= 1
    }
  }
}

public extension Date {
  static var now: Date { return Date() }
  var time: Time {
    return Time(timeIntervalSince1970)
  }
  func string(_ format: DateFormatter) -> String {
    return format.string(from: self)
  }
}
public extension DateFormatter {
  static let medium = DateFormatter().set(style: .medium)
  static let full = DateFormatter().set(style: .full)
  static let long = DateFormatter().set(style: .long)
  static let short = DateFormatter().set(style: .short)
  static func format(_ string: String) -> DateFormatter {
    return DateFormatter().set(format: string)
  }
  func set(style: Style) -> Self {
    dateStyle = style
    return self
  }
  func date(style: Style) -> Self {
    dateStyle = style
    return self
  }
  func time(style: Style) -> Self {
    timeStyle = style
    return self
  }
  func set(format: String) -> Self {
    dateFormat = format
    return self
  }
}

public extension DispatchTime {
  static var seconds: DispatchTime {
    DispatchTime(uptimeNanoseconds: DispatchTime.now().rawValue / 1000000000 * 1000000000)
  }
}

