#if os(iOS)
//
//  TableDisplay.swift
//  SomeNotifications
//
//  Created by Дмитрий Козлов on 6/20/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

import UIKit

private extension Array {
  func safe(_ index: Int) -> Element? {
    guard index >= 0 && index < count else { return nil }
    return self[index]
  }
}

public protocol CellExtensions {
  var tableInfo: TableInfo? { get set }
}

public extension CellExtensions {
  var table: TableController? { tableInfo?.table }
  var index: Int { tableInfo?.index ?? 0 }
  var previous: TableCell? { table?.cells.safe(index-1) }
  var next: TableCell? { table?.cells.safe(index+1) }
}
#endif
