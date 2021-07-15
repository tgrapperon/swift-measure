@_exported import Measure

public var defaultBenchmarkSuite = Suite(name: "Default Suite", renderer: .defaultTableOfStringsToString())

public enum Benchmark {
  public static var suites: [Suite<Table<String>, String>] = [defaultBenchmarkSuite]
  public static func main(_ suites: [Suite<Table<String>, String>] = Self.suites) {
    var reports = String()
    for suite in suites {
      do {
        reports.append("\n")
        let report = try suite.execute()
        reports.append(report)
        reports.append("\n")
      } catch {
        print("Suite executed with error:", "\(error.localizedDescription)")
      }
    }
    print(reports)
  }
}

@discardableResult
public func benchmarkSuite(_ name: String, block: (inout Suite<Table<String>, String>) -> Void) -> Suite<Table<String>, String> {
  let suite = Suite(name, renderer: .defaultTableOfStringsToString(), block: block)
  Benchmark.suites.append(suite)
  return suite
}

public typealias BenchmarkSuite = Suite<Table<String>, String>

public extension Suite where Input == Table<String>, Destination == String {
  // `Measure`'s variant has an unlabelled `name` argument.
  init(name: String, block: (inout Suite) -> Void) {
    var suite = Suite(name: name, renderer: .defaultTableOfStringsToString())
    block(&suite)
    self = suite
  }
  
  mutating func benchmark(_ label: String, block: @escaping () -> Void) {
    addStudy("") {
      $0.benchmark(label, block: block)
    }
  }
  
  mutating func register(benchmark: AnyBenchmark) {
    addStudy(benchmark.name) { study in
      study.benchmark(benchmark.name) { measure in
        benchmark.setUp()
        var state = BenchmarkState()
        measure(.start)
        try! benchmark.run(&state)
        measure(.stop)
        benchmark.tearDown()
      }
    }
  }
}

public struct BenchmarkSetting {}
public struct BenchmarkState {}
public protocol AnyBenchmark {
  var name: String { get }
  var settings: [BenchmarkSetting] { get }
  func setUp()
  func run(_ state: inout BenchmarkState) throws
  func tearDown()
}
