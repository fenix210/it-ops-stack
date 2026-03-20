# IT Ops Stacks for Claude Code

Curated Claude Code skills for IT operations professionals. Built by an IT Director
with 10+ years in remote-first SaaS environments managing Okta, Google Workspace,
Kandji, Jamf, Intune, and Jira Service Management.

## What This Is

Pre-built skill bundles that turn Claude Code into an IT operations co-pilot. Instead
of clicking through four different admin consoles to answer "what machine does Sarah
have and is her Okta account active?", you type it in plain English.

**Safety-first design:** All write operations require explicit confirmation with
plain-language impact descriptions. Onboarding and offboarding actions are disabled
by default. MDM queries are strictly read-only.

## The IT Support Stack (v0.1)

| Plugin | What it does | Write access |
|---|---|---|
| **jsm-ticket-management** | Search, update, comment, transition JSM tickets | Yes, with confirmation |
| **google-workspace-admin** | User lookups, group management, audit logs (replaces GAM) | Yes, with confirmation |
| **okta-admin** | User lookups, group/app management, MFA resets, SSO troubleshooting | Yes, with confirmation |
| **mdm-query** | Device lookups across Kandji, Jamf, and Intune | Read-only |
| **slack-it-support** | Reply to users, post status updates, read thread context | Yes, with confirmation |

## Quick Start

```bash
# 1. Install Claude Code (if you haven't)
npm install -g @anthropic-ai/claude-code

# 2. Add this marketplace
/plugin marketplace add YOURHANDLE/it-ops-stacks

# 3. Install the plugins you need
/plugin install jsm-ticket-management@it-ops-stacks
/plugin install google-workspace-admin@it-ops-stacks
/plugin install okta-admin@it-ops-stacks
/plugin install mdm-query@it-ops-stacks
/plugin install slack-it-support@it-ops-stacks

# 4. Configure your API connections (see each plugin's SKILL.md for details)

# 5. Start using it
claude
> "What machine does sarah@company.com have?"
> "Is her Okta account active?"
> "Show me her open tickets"
```

## How It Works

Skills activate automatically based on what you ask. You don't need to select which
plugin to use — Claude figures it out from context.

- Ask about a ticket → JSM skill activates
- Ask about a user's Google account → GWS Admin skill activates
- Ask about someone's device → MDM Query skill activates
- Ask about SSO or MFA → Okta Admin skill activates
- Ask a cross-cutting question → Multiple skills coordinate

## The Confirmation Pattern

Every write operation follows the same pattern:

```
Here's what I'm about to do:

  Action:    [What will happen]
  Target:    [Who/what is affected]
  Detail:    [Specific parameters]
  Effect:    [What the user will actually experience]

  Do you approve? (yes/no)
```

This isn't optional or configurable. It's baked into every skill. The "Effect" line
is the key — it translates the technical action into real-world impact so you always
know what you're approving.

## What's Blocked by Default

These operations are intentionally excluded for safety:

- **Account creation** (onboarding) — in Okta and Google Workspace
- **Account deletion/deprovisioning** (offboarding) — in Okta and Google Workspace
- **Device actions** — lock, wipe, restart, profile push in MDM
- **Ticket deletion** — in JSM
- **Admin role/privilege changes** — in Okta and Google Workspace
- **Domain and org-level settings** — in Google Workspace

These exist because a chat interface should not be where you accidentally deprovision
someone's account or wipe a device. For these actions, use the native admin console.

## Requirements

- Claude Code (with a Claude subscription or Anthropic Console account)
- API access to the platforms you want to manage (see each plugin's SKILL.md)
- MCP server connections OR API tokens for each service

## Roadmap

- [ ] PagerDuty / OpsGenie alerting integration
- [ ] IT budget tracking skill (vendor spend, license counts)
- [ ] Meeting prep skill (pull relevant tickets + context before 1:1s)
- [ ] ITSM reporting skill (ticket volume trends, SLA compliance, MTTR)
- [ ] Optional onboarding/offboarding workflows (opt-in, multi-step with checkpoints)

## Contributing

Found a bug? Want to add support for another platform? PRs welcome.

## License

MIT

---

*Built by an IT professional, for IT professionals. Not by developers guessing what
IT teams need.*
