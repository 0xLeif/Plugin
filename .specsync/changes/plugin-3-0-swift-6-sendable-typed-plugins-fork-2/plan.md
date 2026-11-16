---
change: plugin-3-0-swift-6-sendable-typed-plugins-fork-2
artifact: plan
---

# Plan

## Approach

swift-tools-version 6.0 and Fork 2.x (or no dependency if Fork is no longer needed). `ImmutablePlugin<Input: Sendable>: Sendable` with `handle(value:) async throws` and `Plugin` with an output, using associated types. A `final class` plugin container (or an actor) holding plugins behind a lock with register, remove, run-all-at-once and run-in-order. Swift Testing suite including a ScribePlugin-shaped refinement. README, DocC and the spec.

## Out of scope

Scribe 3.1 (a separate change in Scribe after this releases).

## Steps

1. Package and protocols.
2. Container and running.
3. Tests, README, DocC, spec.

## Risks

A breaking major version; associated-type protocols change how heterogeneous plugin lists are stored (existentials with primary associated types).

## Constraints consulted

Swift 6 strict concurrency; compatibility with Scribe 3.0 plugins.
