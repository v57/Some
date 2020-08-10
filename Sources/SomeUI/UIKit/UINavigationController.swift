#if os(iOS)
//
//  UINavigationController.swift
//  Some
//
//  Created by Dmitry on 30/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit

public extension UINavigationController {
  convenience init(_ vc: UIViewController) {
    self.init(rootViewController: vc)
  }
}
#endif
