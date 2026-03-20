---
name: slack-it-support
description: >
  Slack communication for IT support workflows. Reply to users after resolving
  their tickets, post status updates to IT channels, and read Slack threads for
  context during ticket triage. Designed to work alongside the JSM, Okta, GWS,
  and MDM skills as the communication layer in the IT support workflow. Use this
  skill whenever the user mentions Slack, "reply in Slack", "let them know in
  Slack", "message them", "post an update", "notify the team", "DM them",
  "check the Slack thread", or any reference to communicating with end users
  or IT team members through Slack. Also activate when a ticket was created
  from Slack and the workflow reaches the notification step, or when the user
  asks to read a Slack conversation for context.
---

# Slack IT Support

The communication layer for IT support workflows. Handles the "let the user know"
step after a ticket is resolved, posts status updates during outages, and reads
Slack threads for context when triaging tickets.

This skill is NOT a Slack admin tool. It doesn't manage channels, permissions,
or workspace settings. It's focused on the IT support communication loop:
user asks for help → IT resolves it → user gets notified.

## Prerequisites

Requires Slack's official MCP server connected to Claude Code:

```bash
claude mcp add-json "slack" '{
  "type": "http",
  "url": "https://mcp.slack.com/mcp",
  "oauth": {
    "clientId": "1601185624273.8899143856786",
    "callbackPort": 3118
  }
}'
```

Each admin authenticates with their own Slack identity. Messages sent through
this skill appear as coming from the authenticated admin, not a bot.

## Core Capabilities

### 1. Resolution Replies

The primary use case. After resolving a ticket, notify the user in Slack.

**When to activate:** Claude has just completed a ticket workflow (Okta reset,
password change, access grant, etc.) and the admin says "let them know" or
"reply in Slack" or the ticket originated from Slack.

**How to compose the message:**

- **Match the user's tone.** If they wrote casually ("hey my okta is broken lol"),
  reply casually. If they wrote formally, keep it professional.
- **Keep it short.** 2-4 sentences max. The user doesn't need a technical play-by-play.
- **Lead with the outcome.** "Your MFA has been reset" not "I investigated your
  ticket and after checking your Okta account status..."
- **Include what they need to do next** (if anything). "You'll be prompted to
  re-enroll Okta Verify on your next login."
- **Close with an offer to help.** "Let me know if you run into anything else."
- **Never include internal details.** No ticket IDs, no tool names, no system
  references. "Your MFA has been reset" not "I reset your Okta Verify factor
  via the Admin Console per ITSD-5827."

**Message template:**

```
Hey [name]! [Outcome in plain language]. [Next step if any].
Let me know if you need anything else!
```

**Examples by ticket type:**

MFA Reset:
> Hey Sarah! Your Okta Verify has been reset — you'll be prompted to set it
> up again next time you log in. Let me know if you run into any issues!

Access Grant:
> Hey Marcus! You should now have access to Salesforce. Give it a try and
> let me know if it's working for you.

Password Reset:
> Hey Alex! I've reset your password. Check your email for the temporary
> one — you'll need to set a new password when you log in. Let me know
> if you have any trouble!

Laptop Issue:
> Hey Jordan! I've pushed an updated configuration to your MacBook. Give
> it a restart when you get a chance and it should be sorted. Ping me if
> it's still acting up!

### 2. Thread Replies vs Channel Messages

**Thread reply** (default): When the ticket originated from a Slack thread or the
admin says "reply in the thread," post the message as a reply to the original thread.
This keeps the conversation contained and doesn't spam the channel.

**Channel message**: Only when the admin specifically asks to "post in the channel"
or when posting a status update (see below). Never default to channel-level messages
for individual ticket resolutions.

**DMs**: When the admin says "DM them" or when the original request came via DM.
Use with caution — DMs can feel more intrusive than thread replies.

When replying in a thread, @mention the specific person whose issue was resolved
if the thread has multiple participants. Don't @mention if they're the only person
in the thread.

### 3. Status Updates

For outages, maintenance windows, or widespread issues. Posted to IT-related
channels (e.g. #it-help, #it-status, #engineering).

**When to activate:** Admin says "post a status update," "let the team know,"
or "announce the outage."

**Status update format:**

For an active issue:
```
🔴 [Service] is currently experiencing issues

We're aware that [brief description of impact]. Our team is investigating.

We'll post updates here as we have them. If you're affected, you don't
need to file a separate ticket — we're tracking this centrally.
```

For a resolution:
```
🟢 [Service] is back to normal

The [brief description] issue has been resolved. [One sentence about
what happened, if appropriate]. Everything should be working normally now.

Thanks for your patience! Let us know if you're still seeing issues.
```

### 4. Reading Slack Context

When triaging a ticket that originated from Slack, read the original thread
for context before suggesting actions.

**When to activate:** The admin says "check the Slack thread," "what did they
say in Slack," or a JSM ticket has a Slack link in it.

**What to extract:**
- The original problem description
- Any additional context from follow-up messages
- Whether the user already tried any troubleshooting steps
- Whether other users reported the same issue in the thread
- The user's tone and urgency level

**How to present it:**

```
Slack thread context (from #it-help, 2 hours ago):

  Sarah reported: Can't get past Okta login, Verify push
  isn't coming through on her phone.

  She mentioned she got a new phone last week but Okta Verify
  was "working fine until today."

  No other users reporting similar issues in the channel.

  Tone: Frustrated but polite. Marked as urgent by her.

Likely issue: Okta Verify needs to be re-enrolled on new device.
```

### 5. Ticket Creation from Slack (Future)

NOT in v1 scope. When this is implemented, it will:
- Read a Slack message and extract the issue details
- Create a JSM ticket with proper fields
- Reply in the Slack thread with the ticket number
- Kick off the standard triage workflow

For now, rely on JSM's native Slack integration for ticket creation.

## Confirmation Pattern

**All Slack messages require confirmation before sending.** Follow the same
pattern as other skills:

```
Here's what I'm about to send:

  Channel:   #it-help (thread reply to Sarah's message)
  Message:   Hey Sarah! Your Okta Verify has been reset — you'll be
             prompted to set it up again next time you log in. Let me
             know if you run into any issues!

  Do you approve? (yes/no)
```

In queue mode, the Slack reply is bundled into the per-ticket confirmation
along with the system action and ticket update. It's not a separate approval.

## Safety Rules

1. **Confirmation before every message.** No auto-sending, even for "simple" replies.
2. **Never include internal details in user-facing messages.** No ticket IDs, no
   system names (Okta, Kandji, etc.), no technical actions. Speak in outcomes.
3. **Never include PII in channel messages.** If the resolution involves sensitive
   info (temp passwords, personal devices), use a DM instead.
4. **Thread replies by default.** Only post to the channel when explicitly asked
   or for status updates.
5. **Don't send duplicate notifications.** If the JSM ticket already sent an email
   notification AND the admin wants to Slack them, that's fine — but flag it:
   "Note: the ticket resolution will also send an email notification. Want to
   send the Slack message too, or skip it?"
6. **Respect working hours.** If it's outside typical working hours and the issue
   isn't urgent, suggest: "It's 10 PM — want to send this now or queue it for
   morning?" (This is advisory, not enforced.)

## Integration with Other Skills

This skill works as the communication endpoint in the IT support workflow:

```
JSM skill (ticket) → Okta/GWS/MDM skills (action) → Slack skill (notify)
```

When another skill's workflow reaches the "notify the user" step, this skill
takes over for the Slack communication. The handoff is seamless — Claude
knows to activate this skill when the conversation moves to user notification.

Cross-skill patterns:
- "Resolve the ticket and let Sarah know in Slack" → JSM resolves, Slack replies
- "Post an outage update for the Okta issue" → Reads Okta context, posts to channel
- "Check what they said in Slack before we work this ticket" → Reads thread, feeds
  context into the JSM/Okta diagnostic workflow
