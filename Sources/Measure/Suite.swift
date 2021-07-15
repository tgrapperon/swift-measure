import Foundation

/// This top-level type hosts several ``Study``, each one of them hosting several cases.
///
/// Each ``Suite`` is defined with a
/// Each ``Study`` is installed with a converter from the
/// studies output to an common ``Input``. When executed, the ``Suite`` renders all the results in the form of ``Destination``.
public struct Suite<Input, Destination> {
  public let name: String
  public let renderer: SuiteRenderer<Input, Destination>

  /// An internal ``Block`` thats wraps any ``Study`` into something that produces the kind of `Input` expected by
  /// the ``SuiteRenderer`` when executed.
  typealias StudyBlock = Block<Void, Input>
  var studies: [StudyBlock] = []

  /// This helper erases parts for the type of the provided ``Study`` and
  func studyBlock<StudyInput, StudyOutput>(
    input: @escaping () -> StudyInput,
    study: Study<StudyInput, StudyOutput>,
    convert: StudyConverter<StudyOutput, Input>
  ) -> StudyBlock {
    .init(study.label, tag: study.tag) { _ in
      convert(try study.run(input()))
    }
  }

  init(name: String,
       renderer: SuiteRenderer<Input, Destination>,
       studies: [StudyBlock])
  {
    self.name = name
    self.renderer = renderer
    self.studies = studies
  }

  public init(name: String, renderer: SuiteRenderer<Input, Destination>) {
    self.name = name
    self.renderer = renderer
    studies = []
  }

  public init(
    _ name: String,
    renderer: SuiteRenderer<Input, Destination>,
    block: (inout Suite) -> Void
  ) {
    var suite = Suite(name: name, renderer: renderer)
    block(&suite)
    self = suite
  }

  public mutating func addStudy<StudyInput, StudyOutput>(
    _ name: String,
    convert: StudyConverter<StudyOutput, Input>,
    input: @escaping () -> StudyInput,
    block: (inout Study<StudyInput, StudyOutput>) -> Void
  ) {
    var study = Study<StudyInput, StudyOutput>(label: name, cases: [])
    block(&study)
    studies.append(studyBlock(input: input, study: study, convert: convert))
  }

  public func execute() throws -> Destination {
    var tables = [(String, Input)]()
    report("Executing \(name) suite…")
    for study in studies {
      report("Conducting \(study.label.isEmpty ? "" : "\(study.label + " ")")study…", level: 1)
      let rendered = try study(())
      tables.append((study.label, rendered))
    }
    return renderer.render(name, tables)
  }
}
