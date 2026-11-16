import os

/// A token that identifies one registration in a ``Plugins`` list.
///
/// ``Plugins/register(_:)`` returns a token; pass it to ``Plugins/remove(_:)`` to take that
/// plugin out again. Tokens are unique within the list that issued them and are never reused.
public struct PluginToken: Hashable, Sendable {
    let id: UInt64
}

/// A list of plugins that share an input and an output type, safe to use from any task.
///
/// The list is held behind a lock, so plugins can be registered and removed from many tasks
/// at once. Running the plugins takes a snapshot first: a plugin registered or removed while
/// a run is in progress takes effect from the next run.
///
/// ```swift
/// let plugins = Plugins<String, Void>()
/// let token = plugins.register(PrintPlugin())
///
/// try await plugins.handle(value: "hello")        // every plugin at once
/// try await plugins.handleInOrder(value: "hello") // one at a time, in registration order
///
/// plugins.remove(token)
/// ```
///
/// Errors: both ways of running throw the first error a plugin throws. Running in order stops
/// at that plugin, so later plugins do not run. Running all at once cancels the plugins that
/// are still running (cancellation is cooperative) and throws once they have finished.
public final class Plugins<Input: Sendable, Output: Sendable>: Sendable {
    private struct Entry: Sendable {
        let token: PluginToken
        let plugin: any Plugin<Input, Output>
    }

    private struct State: Sendable {
        var nextID: UInt64 = 0
        var entries: [Entry] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Creates a list holding the given plugins, in order.
    ///
    /// - Parameter plugins: The plugins to register, in registration order.
    public init(_ plugins: [any Plugin<Input, Output>] = []) {
        register(contentsOf: plugins)
    }

    // MARK: Registering

    /// Registers a plugin after every plugin already in the list.
    ///
    /// The parameter is generic so that an existential of a refining protocol, such as
    /// `any ScribePlugin` where `ScribePlugin: ImmutablePlugin where Input == Payload`, can be
    /// passed directly: Swift opens it here, while converting it to `any Plugin<Input, Output>`
    /// by assignment is not supported.
    ///
    /// - Parameter plugin: The plugin to register.
    /// - Returns: A token that removes this registration.
    @discardableResult
    public func register(_ plugin: some Plugin<Input, Output>) -> PluginToken {
        state.withLock { state in
            let token = PluginToken(id: state.nextID)
            state.nextID += 1
            state.entries.append(Entry(token: token, plugin: plugin))
            return token
        }
    }

    /// Registers several plugins, in order, after every plugin already in the list.
    ///
    /// The plugins are added together: no other registration lands between them.
    ///
    /// - Parameter plugins: The plugins to register.
    /// - Returns: One token per plugin, in the same order.
    @discardableResult
    public func register(contentsOf plugins: [any Plugin<Input, Output>]) -> [PluginToken] {
        state.withLock { state in
            plugins.map { plugin in
                let token = PluginToken(id: state.nextID)
                state.nextID += 1
                state.entries.append(Entry(token: token, plugin: plugin))
                return token
            }
        }
    }

    /// Removes the plugin registered with a token.
    ///
    /// - Parameter token: The token ``register(_:)`` returned.
    /// - Returns: The removed plugin, or `nil` if the token was already removed.
    @discardableResult
    public func remove(_ token: PluginToken) -> (any Plugin<Input, Output>)? {
        state.withLock { state in
            guard let index = state.entries.firstIndex(where: { $0.token == token }) else {
                return nil
            }
            return state.entries.remove(at: index).plugin
        }
    }

    /// Removes every plugin.
    public func removeAll() {
        state.withLock { state in
            state.entries.removeAll()
        }
    }

    // MARK: Reading

    /// The registered plugins, in registration order, at the moment of the call.
    public var snapshot: [any Plugin<Input, Output>] {
        state.withLock { state in state.entries.map(\.plugin) }
    }

    /// The number of registered plugins.
    public var count: Int {
        state.withLock { state in state.entries.count }
    }

    /// Whether no plugin is registered.
    public var isEmpty: Bool {
        count == 0
    }

    // MARK: Running

    /// Runs every registered plugin at the same time, each in its own child task.
    ///
    /// - Parameter value: The value passed to every plugin.
    /// - Returns: Each plugin's output, in registration order.
    /// - Throws: The first error a plugin throws. The plugins still running are cancelled.
    @discardableResult
    public func handle(value: Input) async throws -> [Output] {
        let plugins = snapshot

        return try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            for (index, plugin) in plugins.enumerated() {
                group.addTask {
                    (index, try await plugin.handle(value: value))
                }
            }

            var outputs = [Output?](repeating: nil, count: plugins.count)
            for try await (index, output) in group {
                outputs[index] = output
            }
            return outputs.map { $0! }
        }
    }

    /// Runs the registered plugins one at a time, in registration order.
    ///
    /// Each plugin finishes before the next one starts.
    ///
    /// - Parameter value: The value passed to every plugin.
    /// - Returns: Each plugin's output, in registration order.
    /// - Throws: The first error a plugin throws. Later plugins do not run.
    @discardableResult
    public func handleInOrder(value: Input) async throws -> [Output] {
        var outputs: [Output] = []
        for plugin in snapshot {
            outputs.append(try await plugin.handle(value: value))
        }
        return outputs
    }
}

extension Plugins where Input == Void {
    /// Runs every registered plugin at the same time with `()`.
    @discardableResult
    public func handle() async throws -> [Output] {
        try await handle(value: ())
    }

    /// Runs the registered plugins one at a time, in registration order, with `()`.
    @discardableResult
    public func handleInOrder() async throws -> [Output] {
        try await handleInOrder(value: ())
    }
}

/// A list of ``ImmutablePlugin``s, which return nothing.
public typealias ImmutablePlugins<Input: Sendable> = Plugins<Input, Void>
