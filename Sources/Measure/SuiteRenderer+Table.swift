import Foundation

extension SuiteRenderer where Source == Table<String>, Product == String {
  /// The default `SuiteRenderer` to merge  studies producing `Table<String>` as one `String`.
  public static func defaultTableOfStringsToString(tablesSeparator: Character = "-") -> Self {
    .init { title, titleAndTables in
      guard !titleAndTables.isEmpty else { return "" }

      let columnSeparator = " "
      let maxLength = titleAndTables.map { $0.1.requiredLength(separatorWidth: columnSeparator.count) }.max()!

      func alignment(column: Header) -> HorizontalAlignment {
        if column == .label { return .left }
        return .right
      }
      var lines = [String]()

      let groupedTitleAndTables = groupTableWithSameColumns(titleAndTables)
      for (offset, titleAndTables) in groupedTitleAndTables.enumerated() {
        let lengthForColumn = titleAndTables.map(\.1).reduce([Header: Int]()) {
          $0.merging($1.columnWidths(), uniquingKeysWith: max)
        }

        if offset == 0 {
          lines.append(Format.ruler(label: " " + title + " ", labelOffset: 2, repeating: "=", length: maxLength))
        }

        // Render column headers
        let headers = titleAndTables.first!.1.headers
        var headerLineComponents = [String]()
        for header in headers {
          let length = lengthForColumn[header]
          var headerLabel = header.label
          if header == .label || header == .best {
            headerLabel = ""
          }
          headerLineComponents.append(
            Format.align(string: headerLabel,
                         length: length,
                         alignment: .center)
          )
        }
        lines.append(headerLineComponents.joined(separator: columnSeparator))

        for (title, table) in titleAndTables {
          // Render table title
          if title.isEmpty {
            let formattedTitle = Format.ruler(repeating: tablesSeparator,
                                              length: maxLength)
            lines.append(formattedTitle)
          } else {
            let formattedTitle = Format.ruler(label: " " + title + " ",
                                              labelOffset: 2,
                                              repeating: tablesSeparator,
                                              length: maxLength)
            lines.append(formattedTitle)
          }
    

          // Render table content
          for line in table {
            var lineComponents = [String]()
            for column in table.headers {
              lineComponents.append(
                Format.align(
                  string: line[column, default: ""],
                  length: lengthForColumn[column],
                  alignment: alignment(column: column)
                )
              )
            }
            lines.append(lineComponents.joined(separator: columnSeparator))
          }
        }

        // Studies delimiters
        if offset < groupedTitleAndTables.count - 1 {
          lines.append(Format.ruler(repeating: "-", length: maxLength))
        } else {
          lines.append(Format.ruler(repeating: "=", length: maxLength))
        }
      }

      return lines.joined(separator: "\n")
    }
  }

  static func groupTableWithSameColumns(_ titleAndTables: [(String, Table<String>)]) -> [[(String, Table<String>)]] {
    var tablesWithSameColumns = [[(String, Table<String>)]]()
    var currentRun = [(String, Table<String>)]()
    for titleAndTable in titleAndTables {
      if currentRun.isEmpty {
        currentRun.append(titleAndTable)
        continue
      }
      if let headers = currentRun.last?.1.headers {
        if headers == titleAndTable.1.headers {
          currentRun.append(titleAndTable)
        } else {
          tablesWithSameColumns.append(currentRun)
          currentRun = [titleAndTable]
        }
      }
    }
    if !currentRun.isEmpty {
      tablesWithSameColumns.append(currentRun)
    }
    return tablesWithSameColumns
  }
}

extension Table where Element == String {
  func columnWidths(includingHeaders: Bool = true) -> [Header: Int] {
    var widths = [Header: Int]()
    for column in headers {
      var maxWidth = self[column, default: ""].map(\.count).max() ?? 0
      if includingHeaders {
        maxWidth = Swift.max(maxWidth, column.label.count)
      }
      widths[column] = maxWidth
    }
    return widths
  }

  func requiredLength(separatorWidth: Int = 1) -> Int {
    let widths = columnWidths(includingHeaders: true)
    return widths.values.reduce(0, +) + (widths.count - 1) * separatorWidth
  }
}
