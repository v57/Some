//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 19.02.2020.
//

import Foundation

open class TimeWatch: E {
  public static let shared = TimeWatch()
  
  open override var isEmpty: Bool {
    didSet {
      if isEmpty {
        version += 1
      } else {
        time = DispatchTime.seconds
        run()
      }
    }
  }
  open var time = DispatchTime.now()
  open var version = 0
  
  open override func add(child: S) {
    super.add(child: child)
    (child as? P<Void>)?.send()
  }
  open override func request(from child: S) {
    (child as? P<Void>)?.send()
  }
  open func run() {
    send()
    let version = self.version
    let t = Time.now
    DispatchQueue.main.asyncAfter(deadline: time) { [weak self] in
      guard let self = self else { return }
      guard version == self.version else { return }
      guard !self.isEmpty else { return }
      if Time.now > t {
        self.time = self.time + 1
        self.run()
      } else {
        self.recover(time: t)
      }
    }
  }
  func recover(time: Time) {
    wait(0.1) {
      if time == Time.now {
        self.recover(time: time)
      } else {
        self.run()
      }
    }
  }
}

