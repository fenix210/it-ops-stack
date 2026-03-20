---
name: gws-admin
description: >
  Google Workspace administration via natural language. Replaces common GAM CLI commands
  with conversational queries that include confirmation prompts before any write action.
  Use this skill whenever the user mentions Google Workspace, Google Admin, GAM, user
  accounts, Google groups, organizational units, OUs, Google devices, Chrome devices,
  mobile devices, email routing, aliases, suspended users, license management, admin
  audit logs, Google directory, "add someone to a group", "suspend a user", "check their
  Google account", "what groups is this person in", "reset their password", or any
  reference to Google Workspace administration. Also activate for questions about Google
  Workspace settings, delegation, or organizational structure.
---

# Google Workspace Admin

Natural language Google Workspace administration with mandatory confirmation prompts
for all write operations. Think of this as GAM but conversational and safe.

## Prerequisites

This skill requires the `gws-admin-mcp` server connected to Claude Code.
Each admin authenticates with their own Google account via OAuth — all actions
appear in Google audit logs under the actual admin's identity.

```bash
# Install the MCP server
claude mcp add-json "gws-admin" '{
  "command": "gws-admin-mcp",
  "env": {
    "GWS_OAUTH_CLIENT_FILE": "/path/to/client_secret.json",
    "GOOGLE_WORKSPACE_DOMAIN": "yourcompany.com"
  }
}'
```

On first use, your browser opens to authenticate. Your Google admin role
(Super Admin, User Management Admin, Help Desk Admin, etc.) determines
what operations you can perform — if your role doesn't allow an action,
Google returns a 403 and the tool reports it clearly.

See the [gws-admin-mcp README](https://github.com/YOURHANDLE/gws-admin-mcp)
for full setup instructions.

## The Confirmation Pattern

**This is the most important part of this skill.**

Every write operation MUST follow this exact pattern:

```
Here's what I'm about to do:

  Action:    Add user to group
  Target:    sarah@company.com
  Group:     engineering-all@company.com
  Effect:    Sarah will receive all emails sent to engineering-all
             and gain access to any resources shared with this group.

  Do you approve? (yes/no)
```

The confirmation block must always include:
1. **Action** — What operation will be performed
2. **Target** — Who or what is affected
3. **Detail** — The specific parameters (group name, OU path, etc.)
4. **Effect** — Plain-language explanation of what will actually happen as a result

Never combine multiple write operations into a single confirmation. Each action gets
its own approval. If the user requests "add Sarah to eng-all and devops-team", present
two separate confirmations sequentially.

## Core Capabilities

### 1. User Lookups (Read — No confirmation needed)

| User says | What to do |
|---|---|
| "Look up sarah@company.com" | Retrieve full user profile: name, email, aliases, OU, status, last login, 2FA status, creation date |
| "Is John's account active?" | Check suspended/archived status, last login date |
| "Who hasn't logged in for 90 days?" | Query users by lastLoginTime, return list sorted by staleness |
| "Show me all suspended users" | List users where suspended=true |
| "What groups is Marcus in?" | List all group memberships for user |
| "Who are the admins?" | List users with admin privileges (isAdmin=true or isDelegatedAdmin=true) |
| "What aliases does sarah have?" | Show all email aliases for user |

For user lookups, always include: **Name**, **Primary email**, **OU**, **Status** (active/suspended/archived),
**Last login**, **2FA enrolled** (yes/no), **Creation date**.

### 2. User Management (Write — Confirmation required)

**Supported operations:**

- **Suspend user**: Blocks sign-in, retains data. Does NOT remove from groups or transfer data.
  ```
  Action:    Suspend user account
  Target:    john@company.com
  Effect:    John will be immediately signed out of all sessions and
             unable to sign in. Email will continue to be delivered.
             Group memberships and Drive files are unchanged.
  ```

- **Unsuspend user**: Restores sign-in access.

- **Reset password**: Generate a temporary password. Always set changePasswordAtNextLogin=true.
  ```
  Action:    Reset password
  Target:    sarah@company.com
  Effect:    A temporary password will be generated. Sarah will be
             required to set a new password on next sign-in.
             Current sessions will NOT be invalidated.
  Temp password: [generated]
  ```

- **Update user info**: Name, phone, title, department, manager, etc.

- **Manage aliases**: Add or remove email aliases.

- **Move to OU**: Change organizational unit.
  ```
  Action:    Move user to new Organizational Unit
  Target:    marcus@company.com
  Current OU: /Staff/Engineering
  New OU:     /Staff/Marketing
  Effect:    Marcus will inherit all policies applied to /Staff/Marketing.
             This may change his Chrome policies, mobile device policies,
             and available applications.
  ```

### 3. Group Management (Write — Confirmation required)

- **List groups**: "Show me all groups" or "What groups match 'engineering'?"
- **Group members**: "Who's in eng-all@company.com?"
- **Add to group**: Requires confirmation with role specified (MEMBER, MANAGER, OWNER)
- **Remove from group**: Requires confirmation
- **Create group**: Requires confirmation with settings preview (who can post, who can view, etc.)

### 4. Device Management (Read — No confirmation needed)

- **Chrome devices**: "Show me Chrome devices for sarah" or "How many Chrome devices do we have?"
- **Mobile devices**: "What mobile devices does john have enrolled?"
- **Device details**: Serial number, OS version, last sync, enrollment status

Note: For deeper MDM queries (profiles, compliance, app inventory), use the **mdm-query** skill instead.
This skill covers only Google-native device info from the Admin Directory API.

### 5. Audit Logs (Read — No confirmation needed)

- **Login activity**: "Show login attempts for sarah in the last 24 hours"
- **Admin activity**: "What admin changes were made this week?"
- **Drive activity**: "Who accessed the HR folder today?"
- **Failed logins**: "Show failed login attempts in the last hour"

Present audit results in reverse chronological order with: **Timestamp**, **Actor**, **Action**,
**Target**, **IP address** (if available).

## Blocked Operations

The following operations are **NOT available** through this skill:

- **Account creation** — Onboarding actions are disabled by default. See `references/onboarding.md`
  for instructions on enabling this capability if your organization opts in.
- **Account deletion** — Too destructive for conversational execution. Use Google Admin console.
- **Data transfer/migration** — Requires careful planning beyond a chat interaction.
- **Domain-level settings** — DNS, SMTP routing, and domain verification are admin console only.
- **Super admin role assignment** — Privilege escalation must go through the admin console.

If the user asks for any blocked operation, explain clearly why it's blocked and where
they should perform the action instead.

## Safety Rules

1. **Every write operation gets a confirmation prompt.** No exceptions.
2. **One action per confirmation.** Never batch writes into a single approval.
3. **Show the downstream effect.** Don't just say what changes — say what the user will experience.
4. **No account creation or deletion.** These are blocked by default.
5. **Password resets always require change on next login.** Never generate a permanent password.
6. **Suspensions are not offboarding.** Always clarify that suspend != offboard. Group memberships,
   Drive files, and email delivery are unchanged. If the user seems to want a full offboard, explain
   that this requires additional steps and point them to the offboarding reference doc.
7. **Log all write operations.** After each confirmed action, output a structured log line:
   `[GWS-ADMIN] {timestamp} | {action} | {target} | {actor} | {result}`

## GAM Command Reference

For users familiar with GAM, here are common translations:

| GAM command | Natural language equivalent |
|---|---|
| `gam info user sarah@co.com` | "Look up sarah@company.com" |
| `gam print users query "isSuspended=true"` | "Show me all suspended users" |
| `gam update user john suspended on` | "Suspend john's account" |
| `gam user sarah add group eng-all` | "Add sarah to eng-all" |
| `gam print group-members eng-all` | "Who's in eng-all?" |
| `gam report login user sarah` | "Show sarah's login activity" |
| `gam print cros query "user:sarah"` | "What Chrome devices does sarah have?" |

If the user references a GAM command directly, parse it and execute the equivalent
operation through this skill's normal flow (including confirmations for writes).
