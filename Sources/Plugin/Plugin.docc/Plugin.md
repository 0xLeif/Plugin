# ``Plugin``

Add behavior to an object through typed, `Sendable` plugins.

## Overview

A plugin takes a typed input and either returns an output (``Plugin/Plugin``) or returns
nothing (``ImmutablePlugin``). A ``Plugins`` list holds plugins safely across tasks and runs
them all at once or one at a time in registration order.

```swift
import Plugin

struct PrintPlugin: ImmutablePlugin {
    func handle(value: String) async throws {
        print(value)
    }
}

let plugins = ImmutablePlugins<String>()
let token = plugins.register(PrintPlugin())

try await plugins.handle(value: "hello")        // every plugin at once
try await plugins.handleInOrder(value: "hello") // one at a time, in order

plugins.remove(token)
```

Plugin 3.0 builds in the Swift 6 language mode with complete data-race checking, and every
public protocol and type is `Sendable`.

## Topics

### Essentials

- <doc:MovingFrom2x>

### Plugins

- ``Plugin/Plugin``
- ``ImmutablePlugin``

### Holding and running plugins

- ``Plugins``
- ``ImmutablePlugins``
- ``PluginToken``
- ``Pluginable``
