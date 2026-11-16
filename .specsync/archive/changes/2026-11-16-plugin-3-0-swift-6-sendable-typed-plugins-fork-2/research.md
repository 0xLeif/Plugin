---
change: plugin-3-0-swift-6-sendable-typed-plugins-fork-2
artifact: research
---

# Research

- Fork 2.0.1 (0xLeif/Fork, Dec 2025) declares swift-tools-version 6.0; Plugin 2.x pins Fork from 1.2.0, whose ForkedActor fails Swift 6 region checks.
- Plugin 2.x: `Pluginable: AnyObject` with `var plugins: [any Plugin] { get set }` and `handle(value: Any)`; `Any` is not Sendable, so the protocols must take a typed Sendable input.
- Scribe 3.0.0's `ScribePlugin: Sendable { func handle(value: Scribe.PluginPayload) async throws }` must stay source compatible when it refines Plugin's protocol.
