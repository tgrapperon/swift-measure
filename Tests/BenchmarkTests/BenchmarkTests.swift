import Benchmark
import XCTest
#if canImport(Accelerate)
  import Accelerate
#endif

final class BenchmarkTests: XCTestCase {
  func testTimeTimeIntervalBenchmark() {
    let array = [Double](repeating: 10.0, count: 100_000)

    let suite = Suite("TimeInterval Measures") { suite in
      suite.addStudy("Sum of array's elements") { study in

        study.benchmarkReference("For loop") { measure in
          var sum: Double = 0.0
          for value in array {
            sum += value
          }
          measure(.stop)
          XCTAssertEqual(sum, 1_000_000, accuracy: 1)
        }

        study.benchmark("Reduce") { measure in
          let sum = array.reduce(0, +)
          measure(.stop)
          XCTAssertEqual(sum, 1_000_000, accuracy: 1)
        }

        #if canImport(Accelerate)
          if #available(iOS 13.0, *) {
            study.benchmark("Accelerate") { measure in
              let sum = vDSP.sum(array)
              measure(.stop)
              XCTAssertEqual(sum, 1_000_000, accuracy: 1)
            }
          }
        #endif
      }
    }

    XCTAssertNoThrow(try suite.print().execute())
  }

  func testCustomProperty() {
    let array = [71, 67, 47, 80, 37, 11, 95, 7, 48, 69, 67, 61, 97, 94, 70, 54, 1, 6, 23, 55, 79, 10,
                 89, 21, 31, 61, 2, 81, 43, 4, 37, 11, 22, 58, 3, 92, 58, 20, 8, 46, 5, 7, 12, 99, 82,
                 88, 75, 56, 58, 48, 44, 89, 71, 85, 73, 65, 80, 20, 20, 72, 30, 43, 75, 66, 76, 2, 36,
                 74, 37, 60, 28, 77, 20, 77, 23, 61, 18, 15, 63, 35, 89, 72, 12, 3, 96, 36, 55, 8, 65,
                 67, 91, 10, 32, 100, 95, 49, 73, 74, 75, 73]

    // Define a function that returns a block that counts the number of time a comparison was realized when
    // sorting an array provided as input
    func countNumberOfComparison(sortAlgorithm: @escaping ([Int], (Int, Int) -> Bool) -> [Int]) -> Block<[Int], Int> {
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

    // Define a custom converter to build a Table<String> from [BlockResult<Int>]
    let numberOfComparisonsToTable = StudyConverter<Int, Table<String>> { results in
      // Define a custom column for the count
      let count = Header("Count")
      // Identify the best performer result
      let bestCount = results.map(\.result).min()!
      // Prepare the table
      var table = Table<String>(headers: [.label, count, .best])

      for result in results {
        // Define an populate a line for each result
        var line = [Header: String]()

        line[.label] = result.label
        line[count] = "\(result.result)"
        if result.result == bestCount {
          line[.best] = "⭐"
        }

        table.append(line)
      }
      return table
    }

    // Wrap `Swift` standard sort
    let swiftSort: ([Int], (Int, Int) -> Bool) -> [Int] = { $0.sorted(by: $1) }

    // Create a standard suite
    let suite = Suite("Sorting algorithms") { suite in

      // Benchmark the time while we are at it
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
      suite.addStudy("Number of comparisons", convert: numberOfComparisonsToTable, input: { array }) { study in
        study.setBaseline(countNumberOfComparison(sortAlgorithm: swiftSort).label("Swift Sort"))
        study.addCase(countNumberOfComparison(sortAlgorithm: bubbleSort).label("Bubble Sort"))
      }
    }

    // Make the suite print to console and run it.
    XCTAssertNoThrow(try suite.print().execute())
  }

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
