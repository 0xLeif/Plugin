# Plugin

*🔌 Plug and Play*

Plugin is a small Swift package for adding behavior to an object through plugins. A plugin takes a typed input and either returns an output (`Plugin`) or returns nothing (`ImmutablePlugin`). A `Plugins` list holds plugins safely across tasks and runs them all at once or one at a time in registration order.

Plugin 3.0 builds in the Swift 6 language mode with complete data-race checking. Every public protocol and type is `Sendable`, and the package has no dependencies.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/0xLeif/Plugin", from: "3.0.0")
]
```

Plugin 3.0 needs Swift 6 and macOS 13, iOS 16, tvOS 16, watchOS 9 or visionOS 1.

## Usage

### Writing a plugin

An `ImmutablePlugin` handles an input and returns nothing. The input type comes from the `handle(value:)` method you write, and it must be `Sendable`. The plugin itself must be `Sendable` too: use a struct, an actor, or a final class that protects its own state.

```swift
import Plugin

struct PrintPlugin: ImmutablePlugin {
    func handle(value: String) async throws {
        print(value)
    }
}

actor CountPlugin: ImmutablePlugin {
    private(set) var count = 0

    func handle(value: String) async throws {
        count += 1
    }
}
```

A `Plugin` returns an output:

```swift
struct AuthPlugin: Plugin {
    let token: String

    func handle(value: URLRequest) async throws -> URLRequest {
        var request = value
        request.setValue(token, forHTTPHeaderField: "auth")
        return request
    }
}
```

### Holding and running plugins

`Plugins<Input, Output>` is a lock-protected list of plugins that share an input and an output type. `ImmutablePlugins<Input>` is `Plugins<Input, Void>`.

```swift
let plugins = ImmutablePlugins<String>()

let token = plugins.register(PrintPlugin())
plugins.register(CountPlugin())

try await plugins.handle(value: "hello")        // every plugin at once
try await plugins.handleInOrder(value: "hello") // one at a time, in registration order

plugins.remove(token)
plugins.removeAll()
```

- `register(_:)` returns a `PluginToken`; `remove(_:)` takes it back out. `register(contentsOf:)` adds several at once.
- `snapshot`, `count` and `isEmpty` read the list at the moment of the call.
- `handle(value:)` runs every plugin in its own child task. `handleInOrder(value:)` waits for each plugin before starting the next. Both return the outputs in registration order.
- A run uses the plugins registered when it starts. Plugins registered or removed during a run take effect from the next run.
- Both runs throw the first error a plugin throws. `handleInOrder` stops there, so later plugins do not run. `handle` cancels the plugins still running and throws once they finish.
- Registering and removing is safe from any number of tasks at once.

When the input is `Void`, `handle()` and `handleInOrder()` take no argument.

### Making a type pluginable

A type that owns a `Plugins` list can conform to `Pluginable`, which forwards `register`, `remove`, `handle` and `handleInOrder` to it:

```swift
final class Logger: Pluginable {
    let plugins = Plugins<String, Void>()

    func log(_ message: String) async throws {
        try await handleInOrder(value: message)
    }
}

let logger = Logger()
logger.register(PrintPlugin())
try await logger.log("hello")
```

### Refining the plugin protocols

A library can give its plugins a fixed input by refining `ImmutablePlugin`. Types that only implement `handle(value:)` conform unchanged:

```swift
public protocol ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload {}

actor CountPlugin: ScribePlugin {
    func handle(value: Scribe.PluginPayload) async throws { /* ... */ }
}

let plugins = ImmutablePlugins<Scribe.PluginPayload>()
let plugin: any ScribePlugin = CountPlugin()
plugins.register(plugin)
```

Swift 6 does not convert `any ScribePlugin` to `any ImmutablePlugin<Scribe.PluginPayload>` by assignment, so `register(_:)` is generic and opens the existential for you. Register such plugins one at a time rather than through `register(contentsOf:)`.

## Moving from 2.x

Plugin 3.0 is a new major version. Its protocols take typed, `Sendable` inputs instead of `Any`, and plugins no longer write through a key path into their host.

| 2.x | 3.0 |
|-----|-----|
| `.package(url: "https://github.com/0xLeif/Plugin", from: "2.0.0")` | `from: "3.0.0"`, Swift 6, macOS 13 / iOS 16 / tvOS 16 / watchOS 9 |
| Depends on Fork 1.x | No dependencies |
| `Plugin` with `Source`, `keyPath` and `handle(value:output: inout Output)` | `Plugin<Input, Output>` with `handle(value: Input) async throws -> Output` |
| `ImmutablePlugin` with `handle(value:) async throws` | Unchanged requirement; `Input` must be `Sendable` and the plugin `Sendable` |
| `Pluginable: AnyObject` with `var plugins: [any Plugin] { get set }` | `Pluginable` with `var plugins: Plugins<PluginInput, PluginOutput> { get }` |
| `ImmutablePluginable` class | `ImmutablePlugins<Input>` (`Plugins<Input, Void>`) |
| `register(plugin:)`, `register(plugins:)` | `register(_:)` (returns a `PluginToken`), `register(contentsOf:)` |
| No removal | `remove(_:)` by token, `removeAll()` |
| `handle(value: Any)` (all at once) | `handle(value: Input)` |
| `syncHandle(value: Any)` (one at a time) | `handleInOrder(value: Input)` |
| `handle()`, `syncHandle()` | `handle()`, `handleInOrder()` when `Input == Void` |
| Plugins whose input type did not match were skipped at run time | A mismatched input does not compile |
| `pluginTypes`, `pluginInputTypes`, `pluginOutputTypes` | Removed: the list's type states its input and output |

A 2.x plugin that changed its host through a key path becomes a `Plugin` that returns the new value, and the host applies it:

```swift
// 2.x
struct AuthPlugin: Plugin {
    var keyPath: WritableKeyPath<PluginURLRequest, URLRequest>

    func handle(value: Void, output: inout URLRequest) async throws {
        output.allHTTPHeaderFields = ["auth": "token"]
    }
}

// 3.0
struct AuthPlugin: Plugin {
    func handle(value: URLRequest) async throws -> URLRequest {
        var request = value
        request.allHTTPHeaderFields = ["auth": "token"]
        return request
    }
}

let plugins = Plugins<URLRequest, URLRequest>()
plugins.register(AuthPlugin())

var request = URLRequest(url: url)
for plugin in plugins.snapshot {
    request = try await plugin.handle(value: request)
}
```

A 2.x host class becomes a type that owns a `Plugins` list, and it must be `Sendable`: a final class with only `let` properties of `Sendable` types, an actor, or a class that protects its own mutable state.

## Projects Using Plugins

- [Scribe](https://github.com/0xLeif/Scribe): Scribe is a flexible logging library for Swift, designed to make logging easy and efficient. It provides a centralized system for logging messages and events within your application, and supports multiple logging outputs and plugins to extend its capabilities to meet your needs. Scribe integrates with [swift-log](https://github.com/apple/swift-log) for console logging, making it a versatile solution for all your logging requirements.

- [PluginTask](https://github.com/0xLeif/PluginTask): PluginTask is a custom [Task](https://developer.apple.com/documentation/swift/task) that allows users to add plugins to modify its behavior. Plugins can be added to the PluginTask instance to perform additional functionality before or after the task's main operation. This makes it easy to modify the task's behavior without modifying its original implementation.
