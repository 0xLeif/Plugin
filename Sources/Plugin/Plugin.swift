public protocol Plugin {
    associatedtype Source
    associatedtype Input
    associatedtype Output

    var keyPath: WritableKeyPath<Source, Output> { get set }

    func handle(value: Input, output: inout Output) async throws
}

// MARK: Internal Implementation

internal extension Plugin {
    var inputType: String { "\(Input.self)" }
    var outputType: String { "\(Output.self)" }

    func isValid(value: Any) -> Bool {
        guard let _ = value as? Input else { return false }

        return true
    }

    func handle(_ value: Any, source: inout Any) async throws {
        guard
            let value = value as? Input,
            var source = source as? Source
        else { return }

        try await handle(
            value: value,
            output: &source[keyPath: keyPath]
        )
    }
}
