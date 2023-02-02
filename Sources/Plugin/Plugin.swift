/// A protocol that defines a plugin that can be registered and handled by a `Pluginable` object.
public protocol Plugin {
    /// The source object that the plugin will modify.
    associatedtype Source: Pluginable

    /// The input value that the plugin will handle.
    associatedtype Input

    /// The value that the plugin will modify from the source object.
    associatedtype Output

    /// The key path to the property that the plugin will modify on the `Source` object.
    var keyPath: WritableKeyPath<Source, Output> { get set }

    /// Handles the input value and modifies the output value at the specified key path on the source object.
    ///
    /// - Parameters:
    ///   - value: The input value that the plugin will handle.
    ///   - output: The value that the plugin will modify from the source object. It is passed as an inout parameter so that it can be modified directly.
    /// - Throws: Any errors that occur during handling of the input value.
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
        if let plugin = self as? any ImmutablePlugin {
            return try await plugin.handle(value, source: &source)
        }

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
