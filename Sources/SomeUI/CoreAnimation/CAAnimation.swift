//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 25/12/2020.
//

#if !os(Linux)
import QuartzCore

public extension CALayer {
  func pause() {
    let pausedTime: CFTimeInterval = convertTime(CACurrentMediaTime(), from: nil)
    speed = 0.0
    timeOffset = pausedTime
  }
  
  func resume() {
    let pausedTime = timeOffset
    speed = 1.0
    timeOffset = 0.0
    beginTime = 0.0
    let timeSincePause: CFTimeInterval = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
    beginTime = timeSincePause
  }
}

#endif
