# Security boundaries

This repository is a disposable training lab, not a hardened production baseline. Only deploy to networks and machines you own or are authorized to administer. Use isolated virtual networking and synthetic users. Do not connect a lab DHCP server to a production broadcast domain.

No credentials, private keys, ISO images, raw event logs, or real user inventories are included. User creation produces disabled accounts with no CSV passwords. Privileged operations support WhatIf; read the script and review targets first. Existing-user skips and partial failures require operator attention. The account disable guard does not terminate every live session and is not a complete offboarding system.

Keep Windows Firewall on. Do not add blanket Everyone permissions or disable security software to make exercises pass. The model ACLs are stateless; guest peer isolation, DHCP snooping, dynamic ARP inspection, endpoint hardening, and production AD port restrictions are not provided. The simulated public segment is not safe to replace with an actual internet uplink without a firewall design.

Local reports may contain usernames, IPs, hostnames, and event metadata. Use evidence/local (ignored by Git), redact before sharing, and verify `git diff --cached` before every commit. The .gitignore is a convenience, not a secret scanner. Do not export network device secrets into public .pkt or config files.

Report code problems with a minimal synthetic reproducer. Never include a real credential or live customer log in an issue.
