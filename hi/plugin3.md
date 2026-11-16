---
hi: 1
families: [PLUGIN3]
---

# Plugin3

## Intent

Leif, 2026-11-16, in Claude Code chat, after Scribe 3.0.0 dropped this package: "could we update plugin to be swift 6 and kept it in scribe?", then "yes do Plugin 3.0 and Scribe 3.1".

<!-- What is this for, and what should it feel like? Write it as a person. -->

## Criteria

- **PLUGIN3-1**  Plugin builds in the Swift 6 language mode with complete data-race checking, and its public types are safe to share across threads
- **PLUGIN3-2**  Plugins take a typed, Sendable input instead of Any, and an object can hold plugins and run them all at once or one at a time
- **PLUGIN3-3**  Scribe can build its plugin protocol on Plugin again, without breaking anyone who wrote a Scribe 3.0 plugin
