//
//  ProgressView.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit
import SomeFunctions

open class ProgressView: UIProgressView {
  open weak var currentProgress: Progress?
  open var followInterval: Double = 0.5
  private var followHandler: (()->())?
  
  open func follow(progress: Progress, handler: (()->())?) {
    followHandler = handler
    currentProgress = progress
    progressTick()
  }
  
  open func progressTick() {
    guard let progress = currentProgress else {
      stopFollowing()
      return
    }
    self.setProgress(progress.value(), animated: true)
    if progress.isCancelled {
      stopFollowing()
    } else {
      wait(followInterval) { [weak self] in
        self?.progressTick()
      }
    }
  }
  
  open func stopFollowing() {
    followHandler?()
    currentProgress = nil
    destroy()
  }
}
