#if os(iOS)
//
//  UITableView.swift
//  Some
//
//  Created by Dmitry on 30/08/2019.
//  Copyright © 2019 Дмитрий Козлов. All rights reserved.
//

import UIKit

public extension UITableView {
  func register(_ id: String) {
    register(UINib(nibName: id, bundle: nil), forCellReuseIdentifier: id)
  }
}
#endif
