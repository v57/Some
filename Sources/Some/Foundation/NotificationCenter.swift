//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 07.02.2022.
//

#if os(iOS)
import Foundation

class NotificationSelectorPipe<T>: P<T> {
  var selector: Selector { #selector(receive) }
  @objc func receive(_ event: Notification) {
    if let event = event.object as? T {
      send(event)
    }
  }
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
public extension NotificationCenter {
  func on<T>(_ name: NSNotification.Name) -> P<T> {
    let pipe = NotificationSelectorPipe<T>()
    addObserver(pipe, selector: pipe.selector, name: name, object: nil)
    return pipe
  }
}
#endif
