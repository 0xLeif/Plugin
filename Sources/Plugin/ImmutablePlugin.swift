public protocol ImmutablePlugin: Plugin where Output == Void {
    /// The input value that the plugin will handle.
    associatedtype Value

    /// Handles the input value.
    ///
    /// - Parameters:
    ///   - value: The input value that the plugin will handle.
    /// - Throws: Any errors that occur during handling of the input value.
    func handle(value: Value) async throws
}

extension ImmutablePlugin where Value == Input {
    /// A keypath that provides access to the `immutable` property of the `Source`.
    public var keyPath: WritableKeyPath<Source, ()> {
        get { \.immutable }
        set { }
    }

    public func handle(value: Value, output: inout ()) async throws {
        try await handle(value: value)
    }
}

