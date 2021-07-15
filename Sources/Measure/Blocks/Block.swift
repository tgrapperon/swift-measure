import Foundation

/// This is the fundamental execution unit of the app.
public struct Block<Input, Output> {
  public init(
    _ label: String = "",
    tag: AnyHashable? = nil,
    run: @escaping (Input) throws -> Output
  ) {
    self.label = label
    self.tag = tag
    self.run = run
  }

  /// The name of the block. This value can be used to present the results
  public let label: String
  /// An optional tag that can be used to identify a block.
  /// This can be used to mark the baseline case in a benchmark for example
  public let tag: AnyHashable?

  private let run: (Input) throws -> Output
  @discardableResult
  public func callAsFunction(_ input: Input) throws -> Output {
    try run(input)
  }
}

/// This labels the result of a block execution.
public struct BlockResult<Element> {
  /// The block's `label`
  public var label: String
  /// The block's `tag`
  public var tag: AnyHashable?
  /// The block's returned value when it ran.
  public var result: Element
}

public extension Block {
  /// This higher order block wraps the source's `Output` in a `BlockResult<Output>`
  func labelAndTagResult() -> Block<Input, BlockResult<Output>> {
    .init(label, tag: tag) {
      .init(label: label, tag: tag, result: try run($0))
    }
  }
}

public extension Block {
  /// Returns a new block with the provided `label`
  func label(_ label: String) -> Self {
    Block(label, tag: tag, run: run)
  }

  /// Returns a new block with the provided `tag`
  func tag(_ tag: AnyHashable?) -> Self {
    Block(label, tag: tag, run: run)
  }
}

public extension Block {
  /// Returns a new block with its output casted to `Optional<Output>`
  func optional() -> Block<Input, Output?> {
    .init(label, tag: tag) { try run($0) }
  }

  /// Returns a block that produces `Output` from a block that procudes `Optional<Output>`, defaulting to the
  /// provided value if the result is `nil`.
  func unwrap<Wrapped>(default: @escaping @autoclosure () -> Wrapped) -> Block<Input, Wrapped>
    where Output == Wrapped?
  {
    .init(label, tag: tag) { try run($0) ?? `default`() }
  }
}

public extension Block {
  /// Maps the output of a block according to its `OutPut` result. `KeyPath<Output, T>` can be used as argument to
  /// access innert `Output` properties.
  func map<T>(_ apply: @escaping (Output) throws -> T) -> Block<Input, T> {
    .init(label, tag: tag) {
      try apply(run($0))
    }
  }

  /// Maps the output of a block according to its `Input` and `OutPut`. This allows to normalize the output according to some
  /// property of the input for example.
  func map<T>(_ apply: @escaping (Input, Output) throws -> T) -> Block<Input, T> {
    .init(label, tag: tag) {
      try apply($0, run($0))
    }
  }
}

public extension Block {
  /// Returns a block which repeats the same source block and return an array of the results. The block excutes until, and as long as, both
  /// `iteration` and `duration` are satisfied. It other words, the `lowerBounds` of the ranges are guaranteed to be reached
  /// if the block doesn't throws.
  func `repeat`(
    iterations: Range<Int> = 1 ..< 1_000_000,
    duration: Range<TimeInterval> = 0 ..< 5
  ) -> Block<Input, [Output]> {
    .init(label, tag: tag) {
      var outputs = [Output]()
      let start = now()
      var iteration = 0

      func shouldContinue() -> Bool {
        if iteration < iterations.lowerBound { return true }
        let timeInterval = seconds(start ..< now())
        if timeInterval < duration.lowerBound { return true }
        if iteration >= iterations.upperBound { return false }
        if timeInterval >= duration.upperBound { return false }
        return true
      }

      while shouldContinue() {
        outputs.append(try run($0))
        iteration += 1
      }

      return outputs
    }
  }

  /// A shorthand version of `repeat` where you only set the maximum number of iterations.
  func `repeat`(_ count: Int) -> Block<Input, [Output]> {
    self.repeat(iterations: 1 ..< count)
  }
}

public extension Block {
  /// Returns a block which executes a source block for each value of the input and return the result in the form
  /// of an array of `(Input, Ouput)` tuples.
  func forEach() -> Block<[Input], [(Input, Output)]> {
    .init(label, tag: tag) { inputs in
      var results = [(Input, Output)]()
      for input in inputs {
        results.append((input, try run(input)))
      }
      return results
    }
  }
}
