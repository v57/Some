//
//  States.swift
//  Some
//
//  Created by Димасик on 11/14/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import Foundation

public class SomeAppStates {
  public static var `default`: ()->SomeAppStates = { SomeAppStates() }
  public init() {}
  
  open func launch() {}
  open func toBackground() {}
  open func fromBackground() {}
  open func inactive() {}
  open func quit() {}
}
