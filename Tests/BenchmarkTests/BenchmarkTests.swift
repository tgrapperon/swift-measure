import Benchmark
import XCTest
#if canImport(Accelerate)
  import Accelerate
#endif

final class BenchmarkTests: XCTestCase {
  func testTimeTimeIntervalBenchmark() {
    let array = [Double](repeating: 10.0, count: 100000)

    let suite = Suite("TimeInterval Measures") { suite in
      suite.addStudy("Sum of array's elements") { study in

        study.benchmarkReference("For loop") { measure in
          var sum: Double = 0.0
          for value in array {
            sum += value
          }
          measure(.stop)
          XCTAssertEqual(sum, 1000000, accuracy: 1)
        }

        study.benchmark("Reduce") { measure in
          let sum = array.reduce(0, +)
          measure(.stop)
          XCTAssertEqual(sum, 1000000, accuracy: 1)
        }

        #if canImport(Accelerate)
          if #available(iOS 13.0, *) {
            study.benchmark("Accelerate") { measure in
              let sum = vDSP.sum(array)
              measure(.stop)
              XCTAssertEqual(sum, 1000000, accuracy: 1)
            }
          }
        #endif
      }
    }

    XCTAssertNoThrow(try suite.print().execute())
  }

  func testCustomProperty() {
    // We will measure the number of times an ordering comparison is realized when sorting an array of integer,
    // using the Swift's standard `sort` algorithm and a bubble sort implementation. We also the measure the
    // time spent to sort an array of 10000 elements. This will produce a report in the form of

    // == Sorting algorithms ========================================================================================
    //                    Value      Difference    Variation  Performance  Error  Iterations
    // -- Time elapsed ----------------------------------------------------------------------------------------------
    // Swift sort  (*)   571.791 µs                                       ±0.11 %       8715
    // Bubble sort     93675.685 µs +93103.894 µs +16282.86 %       x0.01 ±0.31 %         54
    // --------------------------------------------------------------------------------------------------------------
    //                 Comparisons 10 100   250   500    1000   2500     5000    10000    12500     15000     20000
    // -- Number of comparisons -------------------------------------------------------------------------------------
    // Swift Sort  (*)      17.5×N 36 1419  4521  10123  20070   41262    88330   186401   259974    351550    392616
    // Bubble Sort        3038.6×N 45 4950 31125 124750 499500 3123750 12497500 49995000 78118750 112492500 199990000
    // ==============================================================================================================

    // We fefine a function that returns a block that counts the number of time a comparison was realized when
    // sorting an array provided as input.
    func countNumberOfComparisons(
      sortAlgorithm: @escaping ([Int], (Int, Int) -> Bool) -> [Int])
      -> Block<[Int], Int> {
      .init { input in
        var count = 0
        let sort: (Int, Int) -> Bool = {
          count += 1
          return $0 < $1
        }
        _ = sortAlgorithm(input, sort)

        return count
      }
    }

    // We will transform the `countNumberOfComparison` block into a block that counts them for
    // each array provided as input, and returns the result in the form of [(size, numberOfComparisons)]
    func numberOfComparisonsPerSize(_ block: Block<[Int], Int>) -> Block<[[Int]], [(Int, Int)]> {
      block // The take the block that counts comparisons for an array as argument
        .forEach() // We loop over a seq of inputs, producing a seq of results
        .map { $0.map { ($0.count, $1) } } // We convert the ouput type to keep only the size of the input as label
    }

    // We now build the function that will provide the input arrays:
    var rng = LCRNG(seed: 0)
    func generateRandomArrayOfInteger(count: Int) -> [Int] {
      (0 ..< count).map { _ in Int.random(in: 0 ... 1000000, using: &rng) }
    }

    // To process the results, we define a custom converter to build a Table<String> from
    // [BlockResult<[(size: Int, comparisons: Int)]>]
    let numberOfComparisonsToTable = StudyConverter<[(Int, Int)], Table<String>> { results in
      guard let firstRow = results.first else { return .init(headers: []) }

      // Define a custom column for each count
      let countColumns = firstRow.result.map { ($0.0, Header("\($0.0)")) }

      // Define a custom column for the mean relative number of comparisons
      let meanComparisons = Header("Comparisons")

      // Identify the best performer result. We take the one with the least total number of comparisons per size
      let bestPerformer: (String, Double)? = results.map { row in
        // Extract the relative number of comparisons
        let meanCountForRow = row.result.map { Double($1) / Double($0) }.measure!.value
        return (row.label, meanCountForRow)
      }
      .sorted { $0.1 < $1.1 } // Sort according to relative number of comparisons
      .first

      // Build the table
      var table = Table<String>(headers: [.label, .best, meanComparisons] + countColumns.map(\.1))

      for row in results {
        // Define an populate a line for each row
        var line = [Header: String]()

        line[.label] = row.label
        if row.label == bestPerformer?.0 {
          line[.best] = "(*)"
        }

        if let meanRelativeComparisons = row.result.map({ Double($1) / Double($0) }).measure?.value {
          line[meanComparisons] = String(format: "%.1f×N", meanRelativeComparisons)
        }

        for column in countColumns {
          if let resultForColumn = row.result.first(where: { $0.0 == column.0 })?.1 {
            line[column.1] = "\(resultForColumn)"
          }
        }

        table.append(line)
      }
      return table
    }

    // Wrap `Swift`'s standard sort as `([Int], (Int, Int) -> Bool) -> [Int]`
    let swiftSort: ([Int], (Int, Int) -> Bool) -> [Int] = { $0.sorted(by: $1) }

    // We can finally build a standard suite that will generate a `String` report:
    let suite = Suite("Sorting algorithms") { suite in
      
      let array = generateRandomArrayOfInteger(count: 10000)
      // Benchmark the time while we are at it:
      suite.addStudy("Time elapsed") { study in
        study.benchmarkReference("Swift sort") { measure in
          let sorted = array.sorted()
          measure(.stop)
          assert(sorted.count == array.count) // Prevents the optimizer to discard the code above if uneffectful
        }
        study.benchmark("Bubble sort") { measure in
          let sorted = self.bubbleSort(array, <)
          measure(.stop)
          assert(sorted.count == array.count) // Prevents the optimizer to discard the code above if uneffectful
        }
      }

      // Create a study for our custom metrics
      suite.addStudy(
        "Number of comparisons",
        convert: numberOfComparisonsToTable,
        input: {
          [10, 100, 250, 500, 1000, 2500, 5000, 10000, 12500, 15000, 20000].map(generateRandomArrayOfInteger)
        }
      ) { study in

        study.setBaseline(
          numberOfComparisonsPerSize(
            countNumberOfComparisons(
              sortAlgorithm: swiftSort
            )
          ).label("Swift Sort")
        )
        
        study.addCase(
          numberOfComparisonsPerSize(
            countNumberOfComparisons(
              sortAlgorithm: bubbleSort
            )
          ).label("Bubble Sort")
        )
      }
    }

    // Make the suite print to console and run it.
    XCTAssertNoThrow(try suite.print().execute())
  }

  // Bubble sort implementation.
  // Taken from https://github.com/raywenderlich/swift-algorithm-club
  func bubbleSort<T>(_ elements: [T], _ comparison: (T, T) -> Bool) -> [T] {
    var array = elements

    for i in 0 ..< array.count {
      for j in 1 ..< array.count - i {
        if comparison(array[j], array[j - 1]) {
          let tmp = array[j - 1]
          array[j - 1] = array[j]
          array[j] = tmp
        }
      }
    }
    return array
  }
}

// From https://github.com/pointfreeco/swift-gen, good enough for our needs
struct LCRNG: RandomNumberGenerator {
  var seed: UInt64

  init(seed: UInt64) {
    self.seed = seed
  }

  mutating func next() -> UInt64 {
    seed = 2862933555777941757 &* seed &+ 3037000493
    return seed
  }
}
