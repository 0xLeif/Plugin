/// A protocol that defines a plugin that can be registered and handled by a `Pluginable` object.
public protocol ImmutablePlugin: Plugin where Output == Void, Source == ImmutablePluginable {
    /// The input value that the plugin will handle.
    associatedtype Input = Input

    /// Handles the input value.
    ///
    /// - Parameters:
    ///   - value: The input value that the plugin will handle.
    /// - Throws: Any errors that occur during handling of the input value.
    func handle(value: Input) async throws
}

// MARK: Public Implementation

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

// MARK: Internal Implementation

internal extension ImmutablePlugin {
    func handle(_ value: Any) async throws {
        guard let value = value as? Input else { return }

        var output: Void = ()

        try await handle(
            value: value,
            output: &output
        )
    }
}
