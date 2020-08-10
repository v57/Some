//
//  TimeoutManager.swift
//  SomeNetwork
//
//  Created by Димасик on 2/2/18.
//  Copyright © 2018 Dmitry Kozlov. All rights reserved.
//

/*
 2 февраля 2018, димас(нахуя я пишу тут своё имя, я же один):
 нигде не используется
 потом добавлю хуйню
 
 по идее эта хуйня должна быть нетворк менежером, который запускает и останавливает очереди запросов
 плюс он же будет отображать уведомление Connecting
 еше будет хуйня для загрузки видео через вайфай онли
 
 кстати руский шрифт тут вобше охуевный, заебись. прям "у вити всё нормально"
 */

#if !os(Linux)
import Foundation
import SystemConfiguration

class StreamQueues: Manager {
  var autoPause = true
  var isPaused = false
  var queues = [Queue]()
  var isTimeout = false
  var timeoutDuration = 5.0
  let lock = NSLock()
  func append(_ queue: Queue) {
    queues.append(queue)
  }
  func start() {
    
  }
  func pause() {
    guard autoPause else { return }
    lock.lock()
    defer { lock.unlock() }
    isPaused = true
    pauseQueues()
  }
  func resume() {
    lock.lock()
    defer { lock.unlock() }
    isPaused = false
    resumeQueues()
  }
  
  func pauseQueues() {
    queues.forEach { $0.pause() }
  }
  func resumeQueues() {
    guard !isTimeout else { return }
    guard !isPaused else { return }
    queues.forEach { $0.resume() }
  }
  
  
  func connecting() {
    
  }
  func connected() {
    
  }
  func timeout() {
    lock.lock()
    defer { lock.unlock() }
    guard !isTimeout else { return }
    isTimeout = true
    pauseQueues()
    wait(timeoutDuration) {
      self.timeoutEnded()
    }
  }
  func timeoutEnded() {
    lock.lock()
    defer { lock.unlock() }
    guard isTimeout else { return }
    isTimeout = false
    resumeQueues()
  }
}

enum NetworkStatus {
  case disconnected, cellular, wifi
}

func callback(reachability:SCNetworkReachability, flags: SCNetworkReachabilityFlags, info: UnsafeMutableRawPointer?) {
  guard let info = info else { return }
  let reachability = Unmanaged<Reachability>.fromOpaque(info).takeUnretainedValue()
  reachability.statusChanged?(reachability)
}

class Reachability {
  var status: NetworkStatus {
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(_reachabilityRef, &flags) else { return .disconnected }
    return status(for: flags)
  }
  var connectionRequired: Bool {
    var flags = SCNetworkReachabilityFlags()
    guard SCNetworkReachabilityGetFlags(_reachabilityRef, &flags) else { return false }
    return flags.contains(.connectionRequired)
  }
  var statusChanged: ((Reachability)->())?
  private var _reachabilityRef: SCNetworkReachability
  init?(hostName: String) {
    guard let reachability = SCNetworkReachabilityCreateWithName(nil, hostName) else { return nil }
    _reachabilityRef = reachability
  }
  init() {
    var zeroAddress = sockaddr()
    bzero(&zeroAddress, MemoryLayout<sockaddr_in>.size)
    zeroAddress.sa_len = __uint8_t(MemoryLayout<sockaddr_in>.size)
    zeroAddress.sa_family = sa_family_t(AF_INET)
    
    let reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, &zeroAddress)!
    _reachabilityRef = reachability
  }
  func start() -> Bool {
    var context = SCNetworkReachabilityContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
    context.info = UnsafeMutableRawPointer(Unmanaged<Reachability>.passUnretained(self).toOpaque())
    guard SCNetworkReachabilitySetCallback(_reachabilityRef, callback, &context) else { return false }
    guard SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue) else { return false }
    return true
  }
  func stop() {
    SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
  }
  func status(for flags: SCNetworkReachabilityFlags) -> NetworkStatus {
    guard flags.contains(.reachable) else { return .disconnected }
    #if !os(macOS) && !os(Linux)
    guard !flags.contains(.isWWAN) else { return .cellular }
    #endif
    guard flags.contains(.connectionRequired) else { return .wifi }
    guard flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic) && !flags.contains(.interventionRequired) else { return .disconnected }
    return .wifi
  }
  deinit {
    stop()
  }
}
#endif
