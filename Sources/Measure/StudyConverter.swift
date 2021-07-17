import Foundation

/// This adapter is used to convert some `Study`'s `Output` to the `Input` of its parent `Suite`.
/// This allows hosting heterogenous studies inside the same `Suite`.
public struct StudyConverter<StudyOutput, SuiteInput> {
  let convert: (_ results: [BlockResult<StudyOutput>]) -> SuiteInput
  public init(convert: @escaping ([BlockResult<StudyOutput>]) -> SuiteInput) {
    self.convert = convert
  }

  func callAsFunction(_ results: [BlockResult<StudyOutput>]) -> SuiteInput {
    convert(results)
  }
}

extension StudyConverter where StudyOutput == Measure<TimeInterval>, SuiteInput == Table<String> {
  /// The default converter for tabular time measures.
  static func defaultConverter() -> StudyConverter<Measure<TimeInterval>, Table<String>> {
    .init { results in
      let columns: [Header] =
        [.label, .best, .mean, .delta, .variation, .performance, .standardError, .iterations]

      var table = Table<String>(headers: columns)
      let minValue = results.map(\.result.value).min() ?? 0
      let timeUnit = TimeUnit.preferredUnit(minValue)
      let baselineResult = results.first { $0.tag == baselineTag }?.result

      func columnContent(_ block: BlockResult<Measure<TimeInterval>>) -> [Header: String] {
        var content = [Header: String]()

        content[.label] = block.label
        content[.best] = (block.result.value == minValue && results.count > 1) ? "(*)" : ""
        content[.mean] = Format.seconds(block.result.value, timeUnit)

        if block.tag != baselineTag, let baselineResult = baselineResult {
          let delta = block.result.value - baselineResult.value
          content[.delta] = Format.seconds(delta, withSign: true, timeUnit)

          let variation = delta / baselineResult.value
          content[.variation] = Format.percent(variation)

          let performance = baselineResult.value / block.result.value
          content[.performance] = Format.factor(performance)
        }

        content[.standardError] = Format.errorPercent(block.result.error / block.result.value)
        content[.iterations] = Format.integer(block.result.count)

        return content
      }

      for result in results {
        table.append(columnContent(result))
      }

      return table
    }
  }
}
