# Onboarding Workflow (Disabled by Default)

This document describes the onboarding capability that can optionally be enabled
for the `okta-admin` and `google-workspace-admin` skills.

## Why It's Disabled

Account creation is a multi-step, multi-system process that should follow a defined
runbook — not an ad-hoc chat interaction. Getting it wrong means someone starts Day 1
without access, or worse, with access to the wrong things.

## Enabling Onboarding (Future)

When the onboarding workflow is available as an opt-in module, it will:

1. Require a structured input (name, email, department, role, start date, manager)
2. Present a full provisioning plan across all connected systems before executing anything
3. Execute each step with individual confirmations
4. Generate a completion report with everything that was created
5. Support a rollback if any step fails

This is on the roadmap but not yet implemented. If you need this capability now,
consider building a custom skill using the `skill-creator` tool with your org's
specific onboarding checklist.

## Current Recommendation

Use your existing onboarding process (Okta workflows, Tines, Workato, or manual
runbook) and use the read-only capabilities of these skills to verify everything
was provisioned correctly after the fact:

- "Is sarah@company.com in Okta?"
- "What groups is she in?"
- "Does she have access to Salesforce?"
- "What device is assigned to her?"
