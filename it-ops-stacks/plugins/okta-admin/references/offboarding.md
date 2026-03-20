# Offboarding Workflow (Disabled by Default)

This document describes the offboarding capability that can optionally be enabled
for the `okta-admin` and `google-workspace-admin` skills.

## Why It's Disabled

Offboarding is the highest-stakes IT operation. Doing it wrong means either:
- **Too aggressive**: Data loss, disrupted handoffs, locked-out contractors who still need access
- **Too slow**: Former employees retaining access to sensitive systems

Neither should happen because someone typed the wrong thing in a chat window.

## Enabling Offboarding (Future)

When the offboarding workflow is available as an opt-in module, it will:

1. Require a ticket or approval reference (e.g. "per ITSD-4567" or "approved by [manager]")
2. Present the full deprovisioning plan across all connected systems
3. Execute in a specific, safe order:
   a. Revoke active sessions (Okta, Google)
   b. Reset password and MFA
   c. Suspend account (not delete)
   d. Remove from groups (with SCIM impact preview)
   e. Transfer Drive/data ownership
   f. Update distribution lists
   g. Set email forwarding/auto-reply
   h. Archive (after retention period)
4. Each step gets individual confirmation
5. Generate a compliance-ready offboarding report

## Current Recommendation

Use the skills for offboarding *verification*, not execution:

- "Is john@company.com still active in Okta?"
- "Does john still have any group memberships?"
- "Is john's Google account suspended?"
- "Are any devices still assigned to john?"

This is actually one of the most valuable use cases — auditing that offboarding
was completed correctly across all systems.
