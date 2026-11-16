/// A plugin that handles a typed input and returns an output.
///
/// The input and the output are both `Sendable`, so a plugin can be handed to any task.
/// Conforming types are `Sendable` too: use a struct of `Sendable` values, an actor,
/// or a final class that protects its own state.
///
/// ```swift
/// struct UppercasePlugin: Plugin {
///     func handle(value: String) async throws -> String {
///         value.uppercased()
///     }
/// }
/// ```
///
/// Because `Input` and `Output` are primary associated types, a list of different plugins
/// with the same input and output can be stored as `[any Plugin<String, String>]`.
public protocol Plugin<Input, Output>: Sendable {
    /// The value the plugin handles.
    associatedtype Input: Sendable

    /// The value the plugin returns.
    associatedtype Output: Sendable

    /// Handles one input value.
    ///
    /// - Parameter value: The input value to handle.
    /// - Returns: The plugin's output for this value.
    /// - Throws: Any error the plugin raises while handling the value.
    func handle(value: Input) async throws -> Output
}
