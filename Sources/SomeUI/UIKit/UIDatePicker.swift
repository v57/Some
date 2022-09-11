#if os(iOS)
//
//  UIDatePicker.swift
//  
//
//  Created by Dmitry Kozlov on 23.12.2021.
//

import UIKit

public extension UIDatePicker {
  @discardableResult
  func date(_ date: Date? = nil, minimum: Date? = nil, maximum: Date? = nil) -> Self {
    if let date = date {
      self.date = date
    }
    if let minimumDate = minimum {
      self.minimumDate = minimumDate
    }
    if let maximumDate = maximum {
      self.maximumDate = maximumDate
    }
    return self
  }
  @discardableResult
  func compact() -> Self {
    if #available(iOS 13.4, *) {
      preferredDatePickerStyle = .compact
    }
    return self
  }
}

#endif
