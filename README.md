# Plugin

*Plug and Play*

This package provides a way to extend the functionality of objects through the use of plugins.

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

urlRequest.register(plugin: AuthPlugin())

try await urlRequest.handle()
print(urlRequest.request.allHTTPHeaderFields) // ["auth": "token"]
```

### Additional Features

You can also access the `inputType` and `outputType` properties of any plugin and get the list of plugins with their `inputType` and `outputType` properties.

```swift
let authPlugin = AuthPlugin()
print(authPlugin.inputType) // Void
print(authPlugin.outputType) // URLRequest

let pluginTypes = urlRequest.pluginTypes
print(pluginTypes) // [(input: Void, output: URLRequest)]
```