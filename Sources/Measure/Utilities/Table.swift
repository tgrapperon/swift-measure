import Foundation

/// This data type can be used to store tabulated results, with `headers` reprensenting the columns, and `content` holding the content
/// of each line in the form of a dictionary of `[Header: Element]`.
public struct Table<Element>: RandomAccessCollection, MutableCollection {
  public private(set) var headers: [Header]
  private var content: [[Header: Element]]

  public var startIndex: Int { content.startIndex }
  public var endIndex: Int { content.endIndex }

  public init(headers: [Header], content: [[Header: Element]] = []) {
    self.headers = headers
    self.content = content
  }

  public subscript(position: Int) -> [Header: Element] {
    get { content[position] }
    set { content[position] = newValue }
  }

  public subscript(position: Int, header: Header, default default: Element) -> Element {
    get { content[position][header, default: `default`] }
    set { content[position][header] = newValue }
  }

  public subscript(header: Header, default default: Element) -> [Element] { content.map { $0[header, default: `default`] } }

  public mutating func append(_ elements: [Header: Element]) {
    content.append(elements)
  }
}
