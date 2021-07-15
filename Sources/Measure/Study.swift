import Foundation

/// This value can be used to mark baseline cases in studies.
public let baselineTag: AnyHashable = "Baseline"

/// A study holds and compare similar cases. They all accept the same input and produce the same output. One of the cases can be marked as
/// `baseline` and serves as a reference to compare with the other cases.
public struct Study<Input, Output> {
  public var label: String
  public var tag: AnyHashable?
  public var cases: [Block<Input, Output>] = []

  public func run(_ input: Input) throws -> [BlockResult<Output>] {
    try block(input)
  }

  /// Adds a generic case to a study.
  public mutating func addCase(
    _ block: Block<Input, Output>
  ) {
    cases.append(block)
  }

  /// Adds and set the baseline case of a study. This is the same as adding a generic case with the `baselineTag` tag.
  public mutating func setBaseline(
    _ block: Block<Input, Output>
  ) {
    cases.append(block.tag(baselineTag))
  }

  /// Returns a block that runs all the case of the study and produce `[BlockResult<Output>]`.
  public var block: Block<Input, [BlockResult<Output>]> {
    .init(label, tag: tag) {
      var results = [BlockResult<Output>]()
      for block in cases {
        report("Running \(block.label)…", level: 2, withoutNewLine: true)
        let timestamp = now()
        results.append(
          .init(
            label: block.label,
            tag: block.tag,
            result: try block($0)
          )
        )
        report(" Done! (\(Format.seconds(seconds(timestamp ..< now()), .s)))")
      }
      return results
    }
  }
}
