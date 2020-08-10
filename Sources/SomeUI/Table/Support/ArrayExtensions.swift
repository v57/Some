#if os(iOS)
//
//  ArrayExtensions.swift
//  SomeTable
//
//  Created by Dmitry on 7/31/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import Foundation

extension Array where Element: Comparable {
  mutating func binaryInsert(_ element: Element) {
    guard count > 0 else {
      append(element)
      return
    }
    var size = count / 2
    var position = size
    while size > 1 {
      size /= 2
      if self[position] > element {
        position -= size
      } else {
        position += size
      }
    }
    insert(element, at: position)
  }
}
#endif
