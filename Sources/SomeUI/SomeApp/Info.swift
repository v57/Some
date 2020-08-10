//
//  Info.swift
//  Some
//
//  Created by Димасик on 11/14/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit
import Some

open class SomeAppInfo {
  public static var `default`: ()->SomeAppInfo = { SomeAppInfo() }
  
  public let build: Int
  public let version: String
  
  public var buildUpdate: Update<Int>?
  public var versionUpdate: Update<String>?
  public var firstLaunchTime: Time?
  public var crashTime: Time?
  public var lastLaunch: Time?
  public var lastClose: Time?
  public let launchTime: Time = .now
  
  public var launches = 1
  public var crashes = 0
  public var averageSession: Time?
  
  public var isFirstLaunch: Bool { firstLaunchTime == nil }
  public var isCrashed: Bool { crashTime != nil }
  public var session: Time { return .now - launchTime }
  public var closes: Int { launches - 1 - crashes }
  
  public init() {
    let version = UIApplication.version
    let build = UIApplication.build
    self.version = version
    if let build = Int(build) {
      self.build = build
    } else {
      self.build = 0
    }
  }
  
  open func save(data: DataWriter, isLaunch: Bool) {
    data.append(UInt8(1)) // version
    
    data.append(build)
    data.append(version)
    
    data.append(launches)
    data.append(crashes)
    
    // firstLaunch
    if let time = firstLaunchTime {
      data.append(time)
    } else {
      data.append(launchTime)
    }
    
    data.append(launchTime)
    let closeTime = Time.now
    data.append(closeTime)
    
    // lastCrash
    if isLaunch {
      data.append(launchTime)
    } else {
      data.append(Time(0))
    }
    
    if let s = self.averageSession {
      var averageSession = Int64(s)
      let sessions = Int64(closes + 1)
      let currentSession = Int64(session)
      
      averageSession = (averageSession * sessions + currentSession) / sessions + 1
      data.append(Time(averageSession))
    } else {
      data.append(session)
    }
    
  }
  open func load(from data: DataReader) throws {
    let _: UInt8 = try data.next()
    let build: Int = try data.next()
    if build < self.build {
      buildUpdate = Update(old: build, new: self.build)
    }
    let version: String = try data.next()
    if version < self.version {
      versionUpdate = Update(old: version, new: self.version)
    }
    
    launches = try data.next()
    launches += 1
    crashes = try data.next()
    
    firstLaunchTime = try data.next()
    lastLaunch = try data.next()
    lastClose = try data.next()
    
    let crashTime: Time = try data.next()
    if crashTime > 0 {
      self.crashTime = crashTime
      crashes += 1
    }
    
    averageSession = try data.next()
  }
}

extension SomeAppInfo {
  var url: FileURL { "info.db".documentsURL }
  
  func open() {
    if let data = DataReader(url: url) {
      data.decrypt(password: 0x1488911228)
      do {
        try load(from: data)
      } catch {
        print("app info: load failed")
      }
    }
    let data = DataWriter()
    save(data: data, isLaunch: true)
    data.encrypt(password: 0x1488911228)
    try? data.write(to: url)
  }
  func close() {
    let data = DataWriter()
    save(data: data, isLaunch: false)
    data.encrypt(password: 0x1488911228)
    try? data.write(to: url)
  }
}

extension SomeAppInfo {
  public struct Update<T> {
    public let old: T
    public let new: T
  }
}
