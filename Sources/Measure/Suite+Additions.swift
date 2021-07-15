import Foundation

public extension Suite where Destination == String {
  /// Transforms a ``Suite`` that renders `String` to a ``Suite`` that write this `String` into the standard output.
  func print() -> Suite<Input, Void> {
    .init(name: name, renderer: renderer.print(), studies: studies)
  }
}

// Table<String> -> String Suites
public extension Suite where Input == Table<String>, Destination == String {
  /// Instantiate a ``Suite`` that produces `String` from ``Table<String>`` using the default renderer
  /// - Parameters:
  ///   - name: The name of the suite.
  ///   - block: A block providing a configurable ``Suite`` as an argument.
  init(_ name: String, block: (inout Suite) -> Void) {
    var suite = Suite(name: name, renderer: .defaultTableOfStringsToString())
    block(&suite)
    self = suite
  }

  /// Adds a time benchmark ``Study`` to the ``Suite``, using the default converter of results with type `Measure<TimeInterval>`
  /// to `Table<String>`.
  mutating func addStudy(
    _ name: String,
    block: (inout Study<Void, Measure<TimeInterval>>) -> Void
  ) {
    var study = Study<Void, Measure<TimeInterval>>(label: name, cases: [])
    block(&study)
    studies.append(studyBlock(input: { () }, study: study, convert: .defaultConverter()))
  }
}
