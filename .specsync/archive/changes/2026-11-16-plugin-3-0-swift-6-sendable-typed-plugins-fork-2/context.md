---
change: plugin-3-0-swift-6-sendable-typed-plugins-fork-2
artifact: context
---

# Context

Scribe 3.0.0 (released 2026-11-16) dropped this package because Plugin 2.x was not Swift 6 safe: `Pluginable: AnyObject` with a settable `plugins` array, `handle(value: Any)`, and a dependency on Fork 1.x, which fails Swift 6 checks. Fork 2.0.1 is a Swift 6 package. Leif asked for Plugin 3.0 for Swift 6 and Scribe 3.1 adopting it ("yes do Plugin 3.0 and Scribe 3.1"). Scribe 3.0's `ScribePlugin: Sendable { func handle(value: Scribe.PluginPayload) async throws }` is the shape to stay compatible with.
