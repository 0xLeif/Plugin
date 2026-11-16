---
module: Plugin
version: 3
status: active
files:
  - Sources/Plugin/Plugin.swift
  - Sources/Plugin/ImmutablePlugin.swift
  - Sources/Plugin/Plugins.swift
  - Sources/Plugin/Pluginable.swift

db_tables: []
depends_on: []
---

# Plugin

## Purpose

Plugin lets an object take on behavior through plugins. A plugin handles a typed, `Sendable` input and either returns an output (`Plugin`) or returns nothing (`ImmutablePlugin`). A `Plugins` list holds plugins that share an input and an output type behind a lock, registers and removes them from any task, and runs them all at once or one at a time in registration order. The module builds in the Swift 6 language mode with complete data-race checking and has no package dependencies (REQ-Plugin-1, REQ-Plugin-2).

The module owns the plugin protocols and the list. It does not own what a plugin does, where a host stores state, or how a host applies a plugin's output.

## Public API

| Export | Description |
|--------|-------------|
| `Plugin` | Protocol with primary associated types `Input` and `Output`, both `Sendable`; requires `func handle(value: Input) async throws -> Output`. The protocol is `Sendable`. |
| `ImmutablePlugin` | Protocol refining `Plugin` where `Output == Void`, with primary associated type `Input`. A conforming type writes only `func handle(value: Input) async throws`. |
| `Plugins` | `Sendable` final class `Plugins<Input, Output>` holding plugins behind an `OSAllocatedUnfairLock`. |
| `ImmutablePlugins` | Type alias for `Plugins<Input, Void>`. |
| `PluginToken` | `Hashable`, `Sendable` value returned by `register(_:)`; identifies one registration and is never reused by the list that issued it. |
| `Pluginable` | Protocol with primary associated types `PluginInput` and `PluginOutput` for a `Sendable` type exposing `var plugins: Plugins<PluginInput, PluginOutput> { get }`; forwards `register`, `register(contentsOf:)`, `remove`, `handle(value:)` and `handleInOrder(value:)` to the list. |
| `PluginInput` | `Pluginable`'s input type. |
| `PluginOutput` | `Pluginable`'s output type. |
| `Input` | The plugin's input type, `Sendable`. |
| `Output` | The plugin's output type, `Sendable`. |
| `plugins` | `Pluginable`'s list of plugins. |
| `init` | `Plugins.init(_ plugins: [any Plugin<Input, Output>] = [])` registers the given plugins in order. |
| `register` | `register(_ plugin: some Plugin<Input, Output>) -> PluginToken` appends one plugin; `register(contentsOf: [any Plugin<Input, Output>]) -> [PluginToken]` appends several together, with no other registration between them. Both are `@discardableResult`. |
| `remove` | `remove(_ token: PluginToken) -> (any Plugin<Input, Output>)?` removes that registration and returns the plugin, or `nil` if it was already removed. |
| `removeAll` | Removes every plugin. |
| `snapshot` | The registered plugins in registration order at the moment of the call. |
| `count` | The number of registered plugins. |
| `isEmpty` | Whether no plugin is registered. |
| `handle` | `Plugin.handle(value:)` is the plugin requirement. `Plugins.handle(value:) async throws -> [Output]` runs every plugin of a snapshot at the same time, each in its own child task, and returns the outputs in registration order; `handle()` does the same when `Input == Void`. |
| `handleInOrder` | `handleInOrder(value:) async throws -> [Output]` runs the plugins of a snapshot one at a time in registration order, each finishing before the next starts; `handleInOrder()` does the same when `Input == Void`. |

### Types

| Type | Kind | Description |
|------|------|-------------|
| `Plugins<Input, Output>` | final class | `Sendable` lock-protected plugin list. |
| `ImmutablePlugins<Input>` | type alias | `Plugins<Input, Void>`. |
| `PluginToken` | struct | `Hashable`, `Sendable` registration identifier. |

### Protocols

| Protocol | Description |
|----------|-------------|
| `Plugin<Input, Output>` | `Sendable` plugin returning an output. |
| `ImmutablePlugin<Input>` | `Plugin` whose output is `Void`; refinable with a fixed input, e.g. `ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload` (REQ-Plugin-3). |
| `Pluginable<PluginInput, PluginOutput>` | `Sendable` owner of a `Plugins` list, with forwarding methods. |

## Invariants

1. Package.swift declares swift-tools-version 6.0, so the module builds in the Swift 6 language mode with complete data-race checking, and it declares no package dependencies (REQ-Plugin-1).
2. Every public protocol and type is `Sendable`, and no public API takes or returns `Any`. `Plugins` is `Sendable` without `@unchecked` (REQ-Plugin-1, REQ-Plugin-2).
3. A plugin's input type is part of its type and of the list's type; a value of another type cannot be passed to it, and a plugin of another input type cannot be registered, at compile time (REQ-Plugin-2).
4. Every read and write of the plugin list happens under the list's lock, so concurrent `register`, `register(contentsOf:)`, `remove`, `removeAll`, `snapshot` and `count` calls lose no registration (REQ-Plugin-2).
5. Plugins are kept in registration order. `snapshot`, `handleInOrder` and the outputs of both runs follow that order (REQ-Plugin-2).
6. A run takes a snapshot when it starts and never holds the lock while a plugin runs. A plugin registered or removed during a run takes effect from the next run.
7. `handle(value:)` starts every plugin of its snapshot before any one of them must finish; `handleInOrder(value:)` starts a plugin only after the previous one has returned (REQ-Plugin-2).
8. A type that implements only `func handle(value: X) async throws` and is `Sendable` conforms to any protocol declared as `P: ImmutablePlugin where Input == X`, so Scribe 3.0 plugins compile unchanged when `ScribePlugin` refines `ImmutablePlugin` (REQ-Plugin-3).
9. A `PluginToken` is unique within the list that issued it and is never reused, so removing with a stale token removes nothing.
10. The README describes the 3.0 API and has a "Moving from 2.x" section; the DocC catalog has the same migration article (REQ-Plugin-4).

## Behavioral Examples

### Scenario: Run every plugin at once

- **Given** a `Plugins<String, Void>` with 50 plugins that each wait until all 50 are running
- **When** `handle(value: "go")` is called
- **Then** every plugin runs, the call returns 50 outputs, and it does not deadlock (REQ-Plugin-2)

### Scenario: Run plugins in registration order

- **Given** plugins 0 to 9 registered in order, where earlier plugins take longer
- **When** `handleInOrder(value:)` is called
- **Then** they run in the order 0 to 9 (REQ-Plugin-2)

### Scenario: Return outputs

- **Given** a `Plugins<String, Int>` holding a length plugin and a doubling plugin
- **When** `handle(value: "hello")` or `handleInOrder(value: "hello")` is called
- **Then** it returns `[5, 10]` (REQ-Plugin-2)

### Scenario: Register and remove from many tasks

- **Given** a list with 500 registered plugins
- **When** many tasks at once remove those 500 by token, register 500 others and read snapshots
- **Then** every removal succeeds, the list holds exactly the 500 new plugins, and running it calls each once (REQ-Plugin-2)

### Scenario: A Scribe-shaped refinement

- **Given** `protocol ScribePlugin: ImmutablePlugin where Input == Scribe.PluginPayload {}` and an actor that implements only `func handle(value: Scribe.PluginPayload) async throws`
- **When** the actor, held as `any ScribePlugin`, is registered in an `ImmutablePlugins<Scribe.PluginPayload>` and the list runs
- **Then** it compiles unchanged and the actor handles each payload (REQ-Plugin-3)

### Scenario: Remove with a token

- **Given** a plugin registered with token `t`
- **When** `remove(t)` is called twice
- **Then** the first call returns the plugin and the second returns `nil`

## Error Cases

| Condition | Behavior |
|-----------|----------|
| A plugin throws during `handleInOrder(value:)` | The call throws that error; later plugins do not run. |
| A plugin throws during `handle(value:)` | The call throws the first error thrown; the child tasks still running are cancelled (cooperatively) and the call returns once they finish. |
| `remove(_:)` with a token already removed, or after `removeAll()` | Returns `nil`; the list is unchanged. |
| Running an empty list | Returns `[]` without error. |
| Passing an input of the wrong type, or registering a plugin of another input or output type | Does not compile. |
| Converting `any P` (where `P: ImmutablePlugin where Input == X`) to `any ImmutablePlugin<X>` or `any Plugin<X, Void>` by assignment | Not supported by Swift 6.4; `register(_:)` is generic so such an existential is opened and registered directly. |

## Dependencies

### Consumes

| Module | What is used |
|--------|-------------|
| `os` (Apple SDK) | `OSAllocatedUnfairLock` guards the plugin list. |

### Consumed By

| Module | What is used |
|--------|-------------|
| Scribe (planned 3.1) | `ImmutablePlugin` as the base of `ScribePlugin`. |

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-11-16 | claude-code | Plugin 3.0: Swift 6 language mode; `Sendable` typed `Plugin<Input, Output>` and `ImmutablePlugin<Input>`; lock-protected `Plugins` list with tokens, removal, concurrent and in-order runs; `Pluginable` forwards to a `Plugins` list; Fork dependency removed; `ImmutablePluginable`, key paths and `Any` inputs removed (REQ-Plugin-1 to REQ-Plugin-4). |
| 2026-11-16 | SpecSync | plugin-3-0-swift-6-sendable-typed-plugins-fork-2: Plugin 3.0: Swift 6, Sendable typed plugins, Fork 2 |
