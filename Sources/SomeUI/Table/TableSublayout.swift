#if os(iOS)
//
//  TableSublayout.swift
//  SomeTable
//
//  Created by Dmitry on 8/24/18.
//  Copyright © 2018 Дмитрий Козлов. All rights reserved.
//

//import UIKit

//class TableSublayout {
//  weak var table: TableControllerDelegate!
//  func update(cell: TableCell, frame: CGRect) {
//    cell.position = frame.origin
//    cell.size = frame.size
//  }
//  func commit() {
//
//  }
//  class Inverted: TableSublayout {
//    override func update(cell: TableCell, frame: CGRect) {
//      cell.position = CGPoint(frame.origin.x,-frame.origin.y-frame.size.height)
//      cell.size = frame.size
//    }
//  }
//  class XInverted: TableSublayout {
//    override func update(cell: TableCell, frame: CGRect) {
//      cell.position = CGPoint(table.cameraSize.width - frame.origin.x - frame.size.width, -frame.origin.y-frame.size.height)
//      cell.size = frame.size
//    }
//  }
//  class Mirrored: TableSublayout {
//    override func update(cell: TableCell, frame: CGRect) {
//      cell.position = CGPoint(table.cameraSize.width - frame.origin.x - frame.size.width, frame.origin.y)
//      cell.size = frame.size
//    }
//  }
//}
#endif
