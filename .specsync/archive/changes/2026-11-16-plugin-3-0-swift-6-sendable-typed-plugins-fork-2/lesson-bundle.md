# Lesson bundle: plugin-3-0-swift-6-sendable-typed-plugins-fork-2

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Plugin 3.0: Swift 6, Sendable typed plugins, Fork 2
- **Kind**: Feature
- **Specs**: Plugin
- **Paths**: Sources/Plugin, Tests/PluginTests, Package.swift, README.md, specs/Plugin, .github/workflows, .chough/sessions
- **Acceptance**: Plugin 3.0 builds in Swift 6 with Sendable, typed plugins and a safe container on Fork 2.x, and Scribe's ScribePlugin can refine it without breaking Scribe 3.0 plugins.

## Evidence

- Verification commit: `fc8a0513b96b76549e9d07f7dca6c77a763bab40`
- Base commit: `7e77f9e539daf9161ea65804f176581255a958c2`
- Verified by: `specsync check --spec Plugin`

## From the change's context.md

# Context

Scribe 3.0.0 (released 2026-11-16) dropped this package because Plugin 2.x was not Swift 6 safe: `Pluginable: AnyObject` with a settable `plugins` array, `handle(value: Any)`, and a dependency on Fork 1.x, which fails Swift 6 checks. Fork 2.0.1 is a Swift 6 package. Leif asked for Plugin 3.0 for Swift 6 and Scribe 3.1 adopting it ("yes do Plugin 3.0 and Scribe 3.1"). Scribe 3.0's `ScribePlugin: Sendable { func handle(value: Scribe.PluginPayload) async throws }` is the shape to stay compatible with.

## From the change's design.md

# design

No visual design: a library API. Fork 2.0.1 declares swift-tools-version 6.0. Scribe 3.0.0's ScribePlugin (Sendable, async throws handle(value:)) is the compatibility target.

## From the change's testing.md

# Testing

- `swift build` and `swift test` in Swift 6 mode, ThreadSanitizer clean.
- Tests named with REQ-Plugin IDs: typed input, all-at-once and in-order running, concurrent register and remove, a ScribePlugin-shaped refinement compiling and running.
- `specsync check --strict`.

## Where these lessons go

- `specs/Plugin/context.md`
