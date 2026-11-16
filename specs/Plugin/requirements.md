---
spec: Plugin.spec.md
---

# Plugin requirements

### REQ-Plugin-1

Plugin SHALL build in the Swift 6 language mode with complete data-race checking (swift-tools-version 6.0), its public protocols and types SHALL be `Sendable`, and it SHALL depend on Fork 2.x or nothing (PLUGIN3-1).

Acceptance Criteria:
- `swift build` and `swift test` pass with swift-tools-version 6.0 and no data-race diagnostics.
- Package.swift depends on Fork 2.x (from 2.0.1) or on no package.

### REQ-Plugin-2

A plugin SHALL declare its input type, which SHALL be `Sendable` (no `Any`): `ImmutablePlugin` handles an input and returns nothing, `Plugin` returns an output; a pluginable object SHALL hold its plugins in a lock-protected list, register and remove them, and run them all at once or one at a time in registration order (PLUGIN3-2).

Acceptance Criteria:
- A plugin of one input type cannot be called with another type at compile time.
- Running all at once calls every plugin; running one at a time calls them in registration order.
- Registering and removing plugins from several tasks at once loses no plugin.

### REQ-Plugin-3

Plugin 3.0 SHALL let Scribe make `ScribePlugin` a refinement of its immutable plugin protocol with Scribe 3.0's exact requirement, `func handle(value: Scribe.PluginPayload) async throws`, so existing Scribe 3.0 plugins compile unchanged (PLUGIN3-3).

Acceptance Criteria:
- A test protocol shaped like ScribePlugin refines Plugin's immutable protocol, and a conforming type written only against `handle(value:)` compiles.

### REQ-Plugin-4

Plugin 3.0 SHALL be released as a new major version, with the README and DocC describing the 3.0 API and how to move from 2.x (PLUGIN3-1, PLUGIN3-2).

Acceptance Criteria:
- The README has usage for 3.0 and a "Moving from 2.x" section.
