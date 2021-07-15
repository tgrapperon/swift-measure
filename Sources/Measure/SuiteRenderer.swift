import Foundation

/// A ``SuiteRenderer`` is responsible for producing the report of the execution of a ``Suite``.
public struct SuiteRenderer<Source, Product> {
  public init(render: @escaping (_ suiteLabel: String, _ studies: [(String, Source)]) -> Product) {
    self.render = render
  }

  let render: (_ suiteLabel: String, _ studies: [(String, Source)]) -> Product
}

public extension SuiteRenderer where Product == String {
  /// Transforms a ``SuiteRenderer`` that outputs `String` to a ``SuiteRenderer`` that write this `String` into the standard output.
  func print() -> SuiteRenderer<Source, Void> {
    .init {
      let string = render($0, $1)
      Swift.print(string)
    }
  }
}
