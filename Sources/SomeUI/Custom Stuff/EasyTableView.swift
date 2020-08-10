#if os(iOS)
//
//  File.swift
//  
//
//  Created by Dmitry Kozlov on 8/10/20.
//

import UIKit
import Some

class EasyTableArray: NSObject, UITableViewDataSource {
  var sections = [EasyTableSection]()
  var lastSection: EasyTableSection {
    if sections.isEmpty {
      sections.append(EasyTableSection())
    }
    return sections.last!
  }
  func cell(at indexPath: IndexPath) -> EasyTableCell {
    return sections[indexPath.section].cells[indexPath.row]
  }
  func append(section name: String?) {
    let section = EasyTableSection()
    section.name = name
    sections.append(section)
  }
  func append(cell: EasyTableCell) {
    let section = lastSection
    section.cells.append(cell)
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sections[section].cells.count
  }
  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    return sections[section].footer
  }
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sections[section].header
  }
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return cell(at: indexPath).isEditable
  }
  func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
    return cell(at: indexPath).isMovable
  }
  func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
    let cell = self.cell(at: sourceIndexPath)
    sections[sourceIndexPath.section].cells.remove(at: sourceIndexPath.row)
    sections[destinationIndexPath.section].cells.insert(cell, at: destinationIndexPath.row)
  }
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    cell(at: indexPath).commit(editingStyle: editingStyle)
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    if sections.isEmpty {
      sections.append(EasyTableSection())
    }
    return sections.count
  }
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return cell(at: indexPath).cell(for: tableView, indexPath: indexPath)
  }
}
class EasyTableSection {
  var name: String?
  var header: String?
  var footer: String?
  var cells = [EasyTableCell]()
  init() {}
}
class EasyTableCell {
  var isEditable: Bool { false }
  var isMovable: Bool { false }
  var cellId: String { "someCell" }
  init() {}
  func cell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    return tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
  }
  func commit(editingStyle: UITableViewCell.EditingStyle) {
    
  }
}
#endif
