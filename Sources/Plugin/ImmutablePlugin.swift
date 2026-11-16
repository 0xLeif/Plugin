/// A plugin that handles a typed input and returns nothing.
///
/// `ImmutablePlugin` is a ``Plugin`` whose `Output` is `Void`. A conforming type only writes
/// `func handle(value: Input) async throws`; the input type is inferred from that method.
///
/// ```swift
/// actor CountPlugin: ImmutablePlugin {
///     private(set) var count = 0
///
///     func handle(value: String) async throws {
///         count += 1
///     }
/// }
/// ```
///
/// Another library can refine it with a fixed input, and types that only implement
/// `handle(value:)` conform unchanged:
///
/// ```swift
/// public protocol ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload {}
/// ```
public protocol ImmutablePlugin<Input>: Plugin where Output == Void {}
