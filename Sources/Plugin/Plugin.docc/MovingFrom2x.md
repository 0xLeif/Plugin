# Moving from 2.x

Update a Plugin 2.x integration to the typed, `Sendable` 3.0 API.

## Overview

Plugin 3.0 is a new major version. Its protocols take typed, `Sendable` inputs instead of
`Any`, plugins no longer write through a key path into their host, and the package has no
dependencies. It needs Swift 6 and macOS 13, iOS 16, tvOS 16, watchOS 9 or visionOS 1.

### Plugins

- ``ImmutablePlugin`` keeps its 2.x requirement, `func handle(value: Input) async throws`.
  The input and the plugin must now be `Sendable`.
- ``Plugin/Plugin`` drops `Source`, `keyPath` and `handle(value:output:)`. It now requires
  `func handle(value: Input) async throws -> Output`. A plugin that changed its host through a
  key path returns the new value instead, and the host applies it.

### Holding plugins

- `ImmutablePluginable` is replaced by ``ImmutablePlugins``, which is
  `Plugins<Input, Void>`.
- ``Pluginable`` no longer requires a settable `[any Plugin]`. A conforming type exposes a
  ``Plugins`` list with `var plugins: Plugins<PluginInput, PluginOutput> { get }`.
- `register(plugin:)` and `register(plugins:)` become ``Plugins/register(_:)``, which returns
  a ``PluginToken``, and ``Plugins/register(contentsOf:)``. ``Plugins/remove(_:)`` and
  ``Plugins/removeAll()`` are new.
- `pluginTypes`, `pluginInputTypes` and `pluginOutputTypes` are removed: the list's type
  states its input and output.

### Running plugins

- `handle(value: Any)` becomes ``Plugins/handle(value:)``, typed by the list's input.
- `syncHandle(value: Any)` becomes ``Plugins/handleInOrder(value:)``.
- A plugin whose input type did not match was skipped at run time in 2.x. In 3.0 a mismatched
  input does not compile.
- Both runs throw the first error a plugin throws, as 2.x did.
