---
kind: evidence
id: 2026-11-16-at-46c3b31-swift-test-swift-6-mode-11-tests-in-4-suites-pass
aliases: []
claim: "At 46c3b31: swift test (Swift 6 mode) 11 tests in 4 suites pass with no data-race diagnostics, including a 50-plugin barrier proving concurrent runs, in-order runs, 500+500 concurrent register/remove with no losses, and a ScribePlugin-shaped refinement whose types written only against handle(value:) conform unchanged; specsync check --strict passes; no package dependencies; the builder's ThreadSanitizer, release build, compile-time type checks and DocC analysis pass"
result: passed
evidence_kind: product-test
method: swift test and specsync (orchestrator re-run); builder's sanitizer, release, swiftc -typecheck and docc runs
revision: 46c3b31c39e6baa10793deabd923d55e6a56d543
content: 738adcd5acbaa36bd4a1b769962fb808bc9d31c79f67d4c9daad286e8c464b67
environment: local-macos-arm64
criteria: [PLUGIN3-1, PLUGIN3-2, PLUGIN3-3]
requirements: [REQ-Plugin-1, REQ-Plugin-2, REQ-Plugin-3, REQ-Plugin-4]
contracts: []
limitations:
  - Apple platforms only (macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1); register(contentsOf:) can't take [any ScribePlugin] because of a Swift 6.4 type-checker crash, so Scribe registers one at a time; first error is thrown, not collected
observed: 2026-11-16T03:18:17Z
actor:
  - agent: claude-code
    terminal: t28
---
**At 46c3b31: swift test (Swift 6 mode) 11 tests in 4 suites pass with no data-race diagnostics, including a 50-plugin barrier proving concurrent runs, in-order runs, 500+500 concurrent register/remove with no losses, and a ScribePlugin-shaped refinement whose types written only against handle(value:) conform unchanged; specsync check --strict passes; no package dependencies; the builder's ThreadSanitizer, release build, compile-time type checks and DocC analysis pass.**

Recorded as passed in local-macos-arm64 at revision 46c3b31c39e6, observed 2026-11-16T03:18:17Z.
