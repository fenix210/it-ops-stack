---
name: jsm-tickets
description: >
  Jira Service Management ticket operations via natural language. Search, view, update,
  comment, transition, and triage JSM tickets. Use this skill whenever the user mentions
  tickets, JSM, Jira, service desk, IT requests, incidents, queues, SLAs, support tickets,
  "check on a ticket", "update the ticket", "what's open", "assign this to", or any
  reference to IT service management workflows. Also activate when the user pastes a
  ticket key (e.g. ITSD-1234, INC-567) or asks about ticket status, priority, or history.
---

# JSM Ticket Management

Natural language interface for Jira Service Management. Designed for IT support teams
who want to manage tickets without leaving their terminal.

## Prerequisites

This skill requires a Jira/JSM MCP server connection. Configure in `.mcp.json`:

```json
{
  "mcpServers": {
    "jira": {
      "type": "url",
      "url": "YOUR_JIRA_MCP_SERVER_URL",
      "name": "jira-mcp"
    }
  }
}
```

Alternatively, this skill can operate via the Jira REST API using environment variables:

- `JIRA_BASE_URL` — Your Atlassian instance (e.g. https://yourorg.atlassian.net)
- `JIRA_API_TOKEN` — API token for authentication
- `JIRA_USER_EMAIL` — Email associated with the API token

## Core Capabilities

### 1. Ticket Search and Lookup

Translate natural language queries into JQL. Common patterns:

| User says | JQL equivalent |
|---|---|
| "What's open in the IT queue?" | `project = ITSD AND status != Done ORDER BY created DESC` |
| "Show me P1 incidents" | `project = INC AND priority = Highest AND status != Done` |
| "What tickets does Sarah have?" | `assignee = "sarah@company.com" AND status != Done` |
| "Anything breaching SLA?" | `project = ITSD AND "Time to resolution" = breached()` |
| "Tickets from this week" | `project = ITSD AND created >= startOfWeek()` |

When displaying results, always show: **Key**, **Summary**, **Status**, **Priority**, **Assignee**, **Created date**.

For single ticket lookups (user provides a key like ITSD-1234), show the full detail view:
summary, description, status, priority, assignee, reporter, created, updated, comments (last 3),
linked issues, SLA status if available.

### 2. Ticket Updates

Supported update operations:

- **Assign**: Change assignee. "Assign ITSD-1234 to me" or "Assign this to sarah@company.com"
- **Priority**: Change priority level. "Escalate ITSD-1234 to P1" or "Lower priority to P3"
- **Status transition**: Move ticket through workflow. "Move ITSD-1234 to In Progress" or "Resolve this ticket"
- **Labels/Components**: Add or remove labels. "Tag ITSD-1234 as hardware"
- **Custom fields**: Update if field name is provided. "Set the location field to Alameda office"

**Before executing any update**, confirm with the user:

```
I'm about to make the following change to ITSD-1234:
  Field: Assignee
  Current value: unassigned
  New value: sarah@company.com

Proceed? (yes/no)
```

### 3. Comments

- **Add comment**: "Comment on ITSD-1234: Reached out to the user, waiting on response"
- **Internal note**: "Add an internal note to ITSD-1234: Escalating to vendor support"
  - Default to internal/private comments unless the user specifies "public" or "customer-visible"
- **View comments**: "Show me the comments on ITSD-1234"

When adding comments, always default to **internal notes** (not customer-visible) unless
explicitly told otherwise. This prevents accidental customer-facing communication.

### 4. Triage Assistance

When the user asks to triage or review a queue, follow this workflow:

1. Pull unassigned tickets ordered by priority then created date
2. For each ticket, present a summary and suggest:
   - Recommended priority (based on keywords, affected users, service impact)
   - Recommended assignee (if team member patterns are known)
   - Recommended category/label
3. Wait for user approval before making any changes
4. Batch the approved changes and execute them

### 5. Bulk Operations

Support batch updates when explicitly requested:

- "Close all resolved tickets older than 30 days"
- "Assign all unassigned hardware tickets to Marcus"
- "Add the Q1-audit label to all tickets from January"

**Bulk operations always require a preview first:**

```
This will affect 12 tickets:
  ITSD-1001, ITSD-1003, ITSD-1015, ITSD-1022...

  Action: Set status to "Closed"

  Type CONFIRM to proceed, or CANCEL to abort.
```

### 6. Action Plan Templates

For common ticket types, consult `references/ticket-templates.md` for pre-built
diagnostic and action plans. Templates exist for:

- MFA / Okta Verify reset
- Password reset
- Access request (add to app)
- Access removal
- Laptop replacement
- Software installation
- Account suspension
- Google group management

When a ticket matches one of these templates, use it as the starting point for
the action plan. The admin can always modify or override the suggested steps.

## Safety Rules

1. **Never auto-execute updates.** Always preview the change and get confirmation.
2. **Default comments to internal.** Only post customer-visible comments when explicitly asked.
3. **Bulk operations require explicit CONFIRM.** Show the full list of affected tickets.
4. **No ticket deletion.** This skill does not support deleting tickets. If asked, explain
   that ticket deletion should be done through the Jira admin UI.
5. **No project or workflow configuration.** This skill manages tickets, not JSM settings.
   Redirect configuration questions to Jira admin documentation.

## Response Format

Keep responses concise and scannable. Use tables for multi-ticket results.
For single tickets, use a structured summary block. Avoid walls of text.

When the user is clearly working through a queue (multiple sequential ticket actions),
maintain context of the current queue and offer to continue: "Want to look at the next
ticket in the queue?"
