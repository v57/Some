//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 22.09.2021.
//

import Foundation

public extension DateFormatter {
  static let js: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.formatOptions = [
        .withFullDate,
        .withFullTime,
        .withDashSeparatorInDate,
        .withFractionalSeconds]
    return formatter
  }()
}
public extension Date {
  var js: String { DateFormatter.js.string(from: self) }
}
public extension String {
  var jsDate: Date? { DateFormatter.js.date(from: self) }
}
