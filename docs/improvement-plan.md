# Improvement plan — 15 November 2026

Inspected all six repositories, complete commit logs, source, configurations, workflows and existing tests before editing. Preserve main and original history; changes belong on portfolio-review-2026-11-15.

1. Keep the four-VLAN baseline. Add an isolated six-department configuration variant with its own inventory, DHCP pools and build instructions. No unverified replacement of existing working assumptions.
2. Check interface-specific gateway/mask/tag/relay/ACL bindings and DHCP values, not only text presence. Add negative mutation tests so broken configurations cause failures.
3. Add network fault exercises, packet-path explanation, backup/restore procedure and a blank acceptance record. Keep runtime results explicitly pending.
4. Fix reproducible application edge cases with regression tests: help-desk pagination query collisions, sensitive parser-error text, and blank retail identities.
5. Put the infrastructure lab first on the profile and hub. Preserve legacy snapshots and distinguish browser demonstrations from Python apps.
6. Run available suites, inspect diffs, submit separate PRs, and build a study guide from inspected implementation and actual verification results.

Highest remaining priority: personal Packet Tracer and Windows VM acceptance runs. More documentation cannot replace those results.
