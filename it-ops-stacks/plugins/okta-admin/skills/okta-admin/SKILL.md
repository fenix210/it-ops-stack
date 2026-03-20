---
name: okta-admin
description: >
  Okta identity and access management via natural language. Look up users, manage groups,
  check app assignments, troubleshoot SSO, and administer MFA factors. Onboarding and
  offboarding workflows are disabled by default. Use this skill whenever the user mentions
  Okta, SSO, single sign-on, MFA, multi-factor, identity, "can't log in", "reset their
  MFA", "what apps does this person have", "add them to the group", "check their Okta
  status", SCIM, provisioning, app assignments, factor enrollment, "locked out", or any
  reference to identity and access management. Also activate when troubleshooting
  authentication failures, SAML errors, or OIDC issues.
---

# Okta Admin

Natural language Okta administration for IT teams. Covers the daily operational tasks
that make up 90% of Okta admin work: user lookups, group management, app assignment
checks, factor resets, and SSO troubleshooting.

## Prerequisites

Configure Okta API access via one of:

**Option A — Okta MCP server** (recommended):
```json
{
  "mcpServers": {
    "okta": {
      "type": "url",
      "url": "YOUR_OKTA_MCP_SERVER_URL",
      "name": "okta-mcp"
    }
  }
}
```

**Option B — Okta API token**:
- `OKTA_ORG_URL` — Your Okta org (e.g. https://yourorg.okta.com)
- `OKTA_API_TOKEN` — API token with appropriate scopes

**Recommended scopes**: `okta.users.read`, `okta.users.manage`, `okta.groups.read`,
`okta.groups.manage`, `okta.apps.read`, `okta.factors.read`, `okta.factors.manage`,
`okta.logs.read`

## Core Capabilities

### 1. User Lookups (Read)

| User says | What to do |
|---|---|
| "Look up sarah@company.com" | Full profile: name, email, status, last login, groups, enrolled factors, assigned apps |
| "Is john's account active?" | Check status (ACTIVE, STAGED, PROVISIONED, SUSPENDED, DEPROVISIONED, LOCKED_OUT, RECOVERY, PASSWORD_EXPIRED) |
| "Who's locked out?" | Query users with status=LOCKED_OUT |
| "Show me all suspended users" | Query users with status=SUSPENDED |
| "When did marcus last log in?" | Check lastLogin timestamp |
| "What factors does sarah have enrolled?" | List enrolled factors with type and status |

For user lookups, always include: **Name**, **Email**, **Status**, **Last login**,
**MFA factors enrolled** (list types), **Group count**, **App count**.

If a user is LOCKED_OUT, proactively mention: "This user is currently locked out.
Would you like me to unlock their account?"

### 2. Group Management

**Read operations (no confirmation needed):**
- "What groups is sarah in?"
- "Who's in the Engineering group?"
- "How many people are in the AWS-Admins group?"
- "What apps are assigned to the Marketing group?"

**Write operations (confirmation required):**

- **Add user to group**:
  ```
  Here's what I'm about to do:

    Action:    Add user to Okta group
    Target:    sarah@company.com
    Group:     Engineering
    Effect:    Sarah will gain access to all applications assigned to the
               Engineering group. Currently assigned apps: [list apps].
               If SCIM provisioning is enabled for any of these apps,
               accounts may be automatically created.

    Do you approve? (yes/no)
  ```

- **Remove user from group**:
  ```
  Here's what I'm about to do:

    Action:    Remove user from Okta group
    Target:    sarah@company.com
    Group:     Engineering
    Effect:    Sarah will lose access to applications assigned exclusively
               through this group. Apps also assigned via other groups or
               direct assignment will be unaffected.
               SCIM-provisioned accounts may be deactivated.

    Do you approve? (yes/no)
  ```

**Critical**: When adding or removing from groups, ALWAYS check what apps are assigned
to that group and include them in the confirmation. This is the most common source of
accidental access changes.

### 3. Application Checks (Read)

- "What apps does sarah have?"
- "Who has access to Salesforce?"
- "Is john assigned to the AWS console app?"
- "What apps are assigned to the Engineering group?"
- "Show me all apps with SCIM provisioning enabled"

For app queries, show: **App name**, **Assignment type** (direct vs group-based),
**Sign-on mode** (SAML, OIDC, SWA), **Status** (ACTIVE/INACTIVE),
**Provisioning** (SCIM enabled yes/no).

### 4. Factor / MFA Management

**Read operations (no confirmation needed):**
- "What MFA factors does sarah have?"
- "Is john enrolled in Okta Verify?"
- "Who doesn't have MFA set up?"

**Write operations (confirmation required):**

- **Reset MFA factor**: Remove a specific enrolled factor so user can re-enroll.
  ```
  Here's what I'm about to do:

    Action:    Reset MFA factor
    Target:    sarah@company.com
    Factor:    Okta Verify (Push)
    Effect:    Sarah's Okta Verify enrollment will be removed. She will
               need to re-enroll on her next login. If this is her only
               factor, she may be prompted to enroll during her next
               sign-in based on your org's MFA policy.

    Do you approve? (yes/no)
  ```

- **Unlock account**: Clear LOCKED_OUT status.
  ```
  Here's what I'm about to do:

    Action:    Unlock user account
    Target:    john@company.com
    Effect:    John's account will be set back to ACTIVE. He will be
               able to sign in on his next attempt. The failed login
               counter will be reset.

    Do you approve? (yes/no)
  ```

### 5. SSO Troubleshooting (Read)

When a user reports "I can't log in to [app]" or "SSO isn't working", follow this
diagnostic workflow:

1. **Check user status**: Is the account ACTIVE? LOCKED_OUT? SUSPENDED?
2. **Check app assignment**: Is the user assigned to the app (directly or via group)?
3. **Check factor enrollment**: Does the user have the required MFA factors?
4. **Check system log**: Pull recent auth events for this user:
   - `eventType eq "user.authentication.sso"` — SSO attempts
   - `eventType eq "user.session.start"` — Login attempts
   - `eventType eq "policy.evaluate_sign_on"` — Sign-on policy evaluations
5. **Report findings**: Present a clear summary of what's working and what's not.

Format the troubleshooting output as:

```
SSO Diagnostic for sarah@company.com -> Salesforce

  Account status:    ACTIVE
  App assigned:      Yes (via Engineering group)
  MFA enrolled:      Okta Verify (Push), SMS
  Last successful SSO: 2025-03-18 14:22 UTC
  Recent failures:   1 failed attempt at 2025-03-19 09:01 UTC
                     Reason: INVALID_CREDENTIALS

  Likely issue: Password may need to be reset. The user's last
  successful login was yesterday — credentials may have expired.

  Suggested action: Reset password or check if password policy
  recently changed.
```

### 6. System Log Queries (Read)

- "Show me login activity for sarah in the last 24 hours"
- "What failed logins happened today?"
- "Show me admin actions from this week"
- "Who made changes to the Engineering group?"

Present log entries with: **Timestamp**, **Actor**, **Event type**, **Target**,
**Outcome** (SUCCESS/FAILURE), **Client IP**.

## Blocked Operations

The following are **disabled by default**:

- **User creation / activation** — Onboarding workflow. See `references/onboarding.md`.
- **User deactivation / deprovisioning** — Offboarding workflow. See `references/offboarding.md`.
- **Password resets** — Disabled separately from MFA resets for safety. Can be enabled
  in the skill configuration. When enabled, follows the same confirmation pattern.
- **App assignment changes** — Adding or removing direct app assignments (not group-based).
  Group-based access changes are allowed since they go through group management.
- **Admin role assignment** — Privilege escalation must go through the Okta admin console.

If the user asks for a blocked operation, explain: "That operation is currently disabled
in this skill for safety. [Brief reason]. You can perform this in the Okta admin console
at {OKTA_ORG_URL}/admin, or this capability can be enabled in the skill configuration."

## Safety Rules

1. **Confirmation required for all write operations.** Include downstream effects.
2. **Always show app impact when modifying groups.** Group changes = access changes.
3. **SCIM awareness.** When group changes could trigger SCIM provisioning/deprovisioning,
   call this out explicitly in the confirmation. Users often don't realize that removing
   someone from a group can deactivate their account in a downstream app.
4. **No onboarding/offboarding by default.** These are multi-step workflows that require
   coordination across systems. They should be purpose-built, not ad-hoc.
5. **Factor resets are sensitive.** Always confirm which specific factor is being reset.
   Never reset all factors at once without individual confirmation for each.
6. **Log all write operations:**
   `[OKTA-ADMIN] {timestamp} | {action} | {target} | {actor} | {result}`
