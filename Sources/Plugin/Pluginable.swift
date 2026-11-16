/// A type that owns a ``Plugins`` list and runs it on its own values.
///
/// Conform by exposing the list; the protocol forwards registering, removing and running
/// to it, so callers can use the owning type directly:
///
/// ```swift
/// final class Logger: Pluginable {
///     let plugins = Plugins<String, Void>()
///
///     func log(_ message: String) async throws {
///         try await handleInOrder(value: message)
///     }
/// }
///
/// let logger = Logger()
/// logger.register(PrintPlugin())
/// ```
public protocol Pluginable<PluginInput, PluginOutput>: Sendable {
    /// The value the plugins handle.
    associatedtype PluginInput: Sendable

    /// The value the plugins return.
    associatedtype PluginOutput: Sendable

    /// The plugins this type runs.
    var plugins: Plugins<PluginInput, PluginOutput> { get }
}

extension Pluginable {
    /// Registers a plugin. See ``Plugins/register(_:)``.
    @discardableResult
    public func register(_ plugin: some Plugin<PluginInput, PluginOutput>) -> PluginToken {
        plugins.register(plugin)
    }

    /// Registers several plugins, in order. See ``Plugins/register(contentsOf:)``.
    @discardableResult
    public func register(contentsOf plugins: [any Plugin<PluginInput, PluginOutput>]) -> [PluginToken] {
        self.plugins.register(contentsOf: plugins)
    }

    /// Removes the plugin registered with a token. See ``Plugins/remove(_:)``.
    @discardableResult
    public func remove(_ token: PluginToken) -> (any Plugin<PluginInput, PluginOutput>)? {
        plugins.remove(token)
    }

    /// Runs every plugin at the same time. See ``Plugins/handle(value:)``.
    @discardableResult
    public func handle(value: PluginInput) async throws -> [PluginOutput] {
        try await plugins.handle(value: value)
    }

    /// Runs the plugins one at a time, in registration order. See ``Plugins/handleInOrder(value:)``.
    @discardableResult
    public func handleInOrder(value: PluginInput) async throws -> [PluginOutput] {
        try await plugins.handleInOrder(value: value)
    }
}
