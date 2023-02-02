public protocol ImmutablePlugin: Plugin where Output == Void {
    /// Handles the input value.
    ///
    /// - Parameters:
    ///   - value: The input value that the plugin will handle.
    /// - Throws: Any errors that occur during handling of the input value.
    func handle(value: Input) async throws
}

extension ImmutablePlugin {
    /// A keypath that provides access to the `immutable` property of the `Source`.
    public var keyPath: WritableKeyPath<Source, ()> {
        get { \.immutable }
        set { }
    }

    public func handle(value: Input, output: inout ()) async throws {
        try await handle(value: value)
    }
}

