---
change: plugin-3-0-swift-6-sendable-typed-plugins-fork-2
artifact: testing
---

# Testing

- `swift build` and `swift test` in Swift 6 mode, ThreadSanitizer clean.
- Tests named with REQ-Plugin IDs: typed input, all-at-once and in-order running, concurrent register and remove, a ScribePlugin-shaped refinement compiling and running.
- `specsync check --strict`.
