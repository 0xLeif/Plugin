# Plugin

*🔌 Plug and Play*

Plugin is a Swift SPM project that provides a flexible and modular approach to enhancing object functionality through the use of plugins. By conforming to the `Plugin` protocol, custom plugins can be created and added to objects that conform to the `Pluginable` protocol, without having to modify their original implementation. This allows developers the ability to add custom behaviors to their objects in a plug-and-play manner, making it easy to maintain and extend code over time.

## Usage

### Creating a plugin

To create a plugin, create a struct or class that conforms to the Plugin protocol and implement its requirements.

Here's an example of a simple plugin that adds an `auth` header to a `URLRequest` object:

```swift
struct AuthPlugin: Plugin {
    var keyPath: WritableKeyPath<PluginURLRequest, URLRequest>

    func handle(value: Void, output: inout URLRequest) async throws {
        output.allHTTPHeaderFields = ["auth": "token"]
    }
}
```

### Making an object pluginable

To use plugins with an object, make it conform to the `Pluginable` protocol. Here's an example of a `PluginURLRequest` class that can have plugins added to it:

```swift
class PluginURLRequest: Pluginable {
    var plugins: [any Plugin] = []

    var request: URLRequest

    init(url: URL) {
        self.request = URLRequest(url: url)
    }
}
```

### Registering and handling plugins

Plugins can be registered to a `Pluginable` object using the `register(plugin: any Plugin)` method. Once registered, the `handle(value: Any)` method can be called on the object to apply the registered plugins to it.

```swift
let urlRequest = PluginURLRequest(url: URL(string: "https://example.com")!)

urlRequest.register(plugin: AuthPlugin(keyPath: \.request))

try await urlRequest.handle()
print(urlRequest.request.allHTTPHeaderFields) // ["auth": "token"]
```

### Additional Features

You can also access the `inputType` and `outputType` properties of any plugin and get the list of plugins with their `inputType` and `outputType` properties.

```swift
let authPlugin = AuthPlugin(keyPath: \.request)
print(authPlugin.inputType) // Void
print(authPlugin.outputType) // URLRequest

let pluginTypes = urlRequest.pluginTypes
print(pluginTypes) // [(input: Void, output: URLRequest)]
```

## Projects Using Plugins

- [Scribe](https://github.com/0xLeif/Scribe): Scribe is a flexible logging library for Swift, designed to make logging easy and efficient. It provides a centralized system for logging messages and events within your application, and supports multiple logging outputs and plugins to extend its capabilities to meet your needs. Scribe integrates with [swift-log](https://github.com/apple/swift-log) for console logging, making it a versatile solution for all your logging requirements.

- [PluginTask](https://github.com/0xLeif/PluginTask): PluginTask is a custom [`Task`](https://developer.apple.com/documentation/swift/task) that allows users to add plugins to modify its behavior. Plugins can be added to the PluginTask instance to perform additional functionality before or after the task's main operation. This makes it easy to modify the task's behavior without modifying its original implementation.
