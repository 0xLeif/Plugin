# Lesson bundle: plugin-s-readme-links-its-docc-documentation-and-the-moving-from-2-x-article

Material for folding this change's lessons into each affected module's lesson file.
Synthesise from what actually happened below; do not restate the change description.

## What this change was

- **Title**: Plugin's README links its DocC documentation and the Moving from 2.x article
- **Kind**: Documentation
- **Paths**: README.md, .chough/sessions
- **Acceptance**: The README links the DocC site and the Moving from 2.x article, and both load.

## Evidence

- Verification commit: `2ea5a7d5130696cd27ecaad11acebecf57f1ec0e`
- Base commit: `bd66202a737bc1557ba55bb757837db83e240909`
- Verified by: `specsync check (no spec in scope)`

## From the change's context.md

# Context

Leif, 2026-11-16: "make sure the scribe and plugin github pages are loading and all docs swift docc". The Plugin DocC site loads at https://0xleif.github.io/Plugin/documentation/plugin (and the Moving from 2.x article), but the README never links it.

## From the change's testing.md

# Testing

- curl each new link and get 200.

## Where these lessons go

This change declared no affected specs, so there is no module context to fold into.
