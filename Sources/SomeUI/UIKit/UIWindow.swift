#if os(iOS)
//
//  UIWindow.swift
//  Some
//
//  Created by Dmitry on 13/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit

public extension UIWindow {
  static var main: UIWindow = UIApplication.shared.windows[0]
}
#endif
