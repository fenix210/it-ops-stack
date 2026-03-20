---
name: mdm-query
description: >
  Read-only MDM device queries across Kandji, Jamf Pro, and Microsoft Intune. Look up
  what machine a person has, what profiles are pushed, OS version, compliance status,
  hardware specs, and fleet-level inventory data. This skill is strictly read-only —
  no remote commands, no profile pushes, no device wipes, no lock commands. Use this
  skill whenever the user asks "what machine does this person have", "what laptop is
  assigned to", "what profiles are pushed", "is their device compliant", "what OS are
  they running", "show me the device inventory", "how many Macs do we have", "which
  devices are out of date", or any reference to endpoint management, device lookups,
  fleet inventory, or MDM status. Also activate when cross-referencing a user from
  Okta or Google Workspace with their device assignment.
---

# MDM Query

Read-only device intelligence across Kandji, Jamf Pro, and Microsoft Intune.
Answer the questions IT teams get every day: "What machine does this person have?"
"What profiles are on it?" "Is it compliant?"

**This skill is strictly read-only. It cannot and will not execute any device actions.**

## Prerequisites

Configure one or more MDM platform connections. You only need the platforms your
org uses — most shops run one, some run two (e.g. Kandji for Mac + Intune for Windows).

### Kandji

```json
{
  "mcpServers": {
    "kandji": {
      "type": "url",
      "url": "YOUR_KANDJI_MCP_SERVER_URL",
      "name": "kandji-mcp"
    }
  }
}
```

Or via API:
- `KANDJI_API_URL` — Your Kandji tenant (e.g. https://yourorg.api.kandji.io)
- `KANDJI_API_TOKEN` — API token (Bearer token from Settings > Access)

### Jamf Pro

- `JAMF_URL` — Your Jamf Pro instance (e.g. https://yourorg.jamfcloud.com)
- `JAMF_CLIENT_ID` — API client ID
- `JAMF_CLIENT_SECRET` — API client secret

### Microsoft Intune

- `INTUNE_TENANT_ID` — Azure AD tenant ID
- `INTUNE_CLIENT_ID` — App registration client ID
- `INTUNE_CLIENT_SECRET` — App registration client secret

Required Graph API permissions (Application): `DeviceManagementManagedDevices.Read.All`,
`DeviceManagementConfiguration.Read.All`

## Platform Detection

When the user asks a device question, determine which MDM platform to query:

1. If only one platform is configured, use it.
2. If multiple platforms are configured and the user specifies (e.g. "check Kandji"), use that.
3. If multiple platforms and no specification, query all configured platforms and merge results.
   Deduplicate by serial number if the same device appears in multiple systems.

## Core Capabilities

### 1. User Device Lookup

The most common query. "What machine does Sarah have?"

Query by user email or name. Return a device card for each assigned device:

```
Devices for sarah@company.com:

  MacBook Pro 16" (2023)
    Serial:       C02X1234ABCD
    MDM:          Kandji
    OS:           macOS 15.3.1
    Last check-in: 2 hours ago
    Compliance:   Compliant
    Storage:      412 GB / 512 GB used
    Profiles:     12 installed

  iPhone 15 Pro
    Serial:       F4GX7890EFGH
    MDM:          Kandji
    OS:           iOS 18.3
    Last check-in: 35 minutes ago
    Compliance:   Compliant
    Supervised:   Yes
```

Always include: **Device model**, **Serial number**, **MDM platform**, **OS version**,
**Last check-in**, **Compliance status**.

### 2. Profile Queries

"What profiles are pushed to Sarah's MacBook?" or "What profiles are on serial C02X1234?"

List all installed configuration profiles:

```
Profiles on C02X1234ABCD (sarah@company.com - MacBook Pro 16"):

  Name                          Type              Status
  -----------------------------------------------------------
  FileVault Encryption          Security          Installed
  Wi-Fi - Corporate             Network           Installed
  Okta Verify Config            App Config        Installed
  Chrome Browser Managed        App Managed       Installed
  Firewall Settings             Security          Installed
  Software Update Policy        OS Update         Installed
  Screensaver Lock (5 min)      Restrictions      Installed
  CrowdStrike Sensor Config     Security          Installed
  ...

  12 profiles installed | 0 pending | 0 failed
```

If any profiles are in a **failed** or **pending** state, highlight them prominently.
These are usually the reason someone is asking.

### 3. Compliance Status

"Is John's laptop compliant?" or "Show me non-compliant devices"

For individual device compliance, show what's passing and what's not:

```
Compliance check for C02X1234ABCD:

  Overall:             NON-COMPLIANT

  FileVault:           Enabled
  OS Version:          macOS 15.3.1 (required: 15.3+)     PASS
  Firewall:            Enabled                              PASS
  Gatekeeper:          Enabled                              PASS
  SIP:                 Enabled                              PASS
  Auto-update:         Disabled                             FAIL
  Last check-in:       Within 24h                           PASS
  Storage encryption:  Enabled                              PASS

  Failing: Auto-update is disabled. This may require user action
  or a profile re-push from the admin console.
```

For fleet-level compliance: "How many devices are non-compliant?"
Return summary counts with the ability to drill into specific failure reasons.

### 4. Fleet Inventory

"How many Macs do we have?" or "Show me the device breakdown"

```
Fleet summary (as of 2025-03-19):

  Platform     Count    Compliant    Non-Compliant    Stale (>7d)
  ----------------------------------------------------------------
  macOS         87        82             3                2
  iOS           45        44             0                1
  Windows       23        21             1                1
  Android        4         4             0                0
  ----------------------------------------------------------------
  Total        159       151             4                4

  OS version breakdown (macOS):
    15.3.1    — 64 devices
    15.3      — 18 devices
    15.2.1    —  3 devices (outdated)
    14.7.2    —  2 devices (outdated)
```

### 5. OS Version Queries

"Which devices are running outdated macOS?" or "Who still hasn't updated?"

Return devices below the current minimum OS requirement, sorted by staleness:

```
Devices below minimum macOS (15.3):

  User                Device              Current    Last Check-in
  ----------------------------------------------------------------
  john@company.com    MacBook Air M2      14.7.2     3 days ago
  alex@company.com    MacBook Pro 14"     14.7.2     1 day ago
  pat@company.com     MacBook Pro 16"     15.2.1     6 hours ago
```

### 6. Cross-Reference with Other Skills

This skill works well alongside the **okta-admin** and **gws-admin** skills.
Common cross-reference patterns:

- "Look up sarah in Okta and show me her devices" — Okta profile + MDM device card
- "Is john's laptop compliant? He's having SSO issues" — MDM compliance + Okta SSO diagnostic
- "Show me all of marketing team's devices" — Pull group membership from Okta/Google, then query MDM

When the user's query spans multiple skills, coordinate the lookups and present
a unified view. Don't make the user ask separately.

## Blocked Operations

This skill **cannot** perform any of the following. These are intentionally excluded:

- **Lock device** — Use the MDM admin console
- **Wipe / erase device** — Use the MDM admin console with appropriate approval
- **Push profiles** — Use the MDM admin console or blueprints/smart groups
- **Install apps** — Use the MDM admin console
- **Send remote commands** (restart, shutdown, etc.) — Use the MDM admin console
- **Remove device from MDM** — Use the MDM admin console
- **Change blueprint / smart group assignment** — Use the MDM admin console

If the user asks for any device action, respond: "This skill is read-only for safety.
Device actions like [action] should be performed directly in [Kandji/Jamf/Intune]
admin console at [URL if known]."

## Safety Rules

1. **Strictly read-only.** No device commands, no profile pushes, no wipes. Ever.
2. **Serial numbers are sensitive.** Don't include them in logs that might be shared
   outside IT. When the user asks to "share" or "export" results, omit serial numbers
   unless explicitly requested.
3. **Stale data awareness.** If a device hasn't checked in for >24 hours, flag it:
   "Note: This device last checked in [X days] ago. Information may not reflect
   current state."
4. **Multi-platform deduplication.** If querying multiple MDMs, match by serial number
   to avoid showing the same device twice.

## Response Format

Keep device cards compact and scannable. Use tables for fleet-level data.
For individual lookups, use the structured card format shown above.

When a user is clearly doing IT support (looking up a person, checking their device,
checking compliance), anticipate the follow-up: "Sarah's MacBook is non-compliant
due to auto-update being disabled. Would you like me to check her Okta status or
look at her recent login activity?"
