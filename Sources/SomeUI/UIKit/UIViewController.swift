//
//  UIViewController.swift
//  Some
//
//  Created by Димасик on 2/13/17.
//  Copyright © 2017 Dmitry Kozlov. All rights reserved.
//

import UIKit

public func notify<T>(_ type: T.Type, _ body: (T)->()) {
  UIViewController.root.forEach(as: type, body)
}

public extension UIViewController {
  func push(_ viewController: UIViewController?) {
    guard let viewController = viewController else { return }
    navigationController?.pushViewController(viewController, animated: true)
  }
  func replace(_ viewController: UIViewController?) {
    guard let viewController = viewController else { return }
    let navigation = self as? UINavigationController ?? navigationController
    navigation?.setViewControllers([viewController], animated: true)
  }
  func present(_ viewController: UIViewController?) {
    guard let viewController = viewController else { return }
    self.present(viewController, animated: true, completion: nil)
  }
  static var root: UIViewController {
    testAssert(UIWindow.main.rootViewController != nil)
    return UIWindow.main.rootViewController ?? UIViewController()
  }
  func forEach<T>(as type: T.Type, _ body: (T)->()) {
    presentedViewController?.forEach(as: type, body)
    if let vc = self as? UINavigationController {
      vc.viewControllers.forEach { $0.forEach(as: type, body) }
    } else if let vc = self as? UIPageViewController {
      vc.viewControllers?.forEach { $0.forEach(as: type, body) }
    } else if let vc = self as? UITabBarController {
      vc.viewControllers?.forEach { $0.forEach(as: type, body) }
    }
    if isViewLoaded, let converted = self as? T {
      body(converted)
    }
  }
  func present() {
    var vc: UIViewController = .root
    while let child = vc.presentedViewController {
      vc = child
    }
    vc.present(self)
  }
}
