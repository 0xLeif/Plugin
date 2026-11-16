---
kind: evidence
id: 2026-11-16-the-readme-links-https-0xleif-github-io-plugin-documentation
aliases: []
claim: The README links https://0xleif.github.io/Plugin/documentation/plugin and its movingfrom2x article; both return 200, and the DocC data JSON for both loads
result: passed
evidence_kind: product-test
method: curl -L of each link and the DocC data JSON
revision: c262ff1985764dcf24883526fad0b8bc4824b3d7
content: 95434d85b1d0203a355bd5939546e38ace9cc350364b9d4d69e0d134aabdc183
environment: local-macos-arm64
criteria: [PLUGIN3-1]
requirements: []
contracts: []
limitations: [Link check only]
observed: 2026-11-16T03:24:31Z
actor:
  - agent: claude-code
    terminal: t28
---
**The README links https://0xleif.github.io/Plugin/documentation/plugin and its movingfrom2x article; both return 200, and the DocC data JSON for both loads.**

Recorded as passed in local-macos-arm64 at revision c262ff198576, observed 2026-11-16T03:24:31Z.
