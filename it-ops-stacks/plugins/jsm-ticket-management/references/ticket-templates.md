# Ticket Templates — Common IT Support Action Plans

Pre-built action plans for the most common ticket types. Claude uses these as
suggested playbooks during the Queue Mode workflow. The admin can always override,
modify, or skip steps.

These templates assume the IT Ops Stacks are connected (JSM, Okta, GWS, MDM, Slack).
If a connector isn't available, skip the steps that require it.

---

## MFA / Okta Verify Reset

**Triggers:** "can't log in," "MFA not working," "push notification not coming,"
"new phone," "Okta Verify," "locked out"

**Diagnostic:**
1. Look up user in Okta → check status (ACTIVE/LOCKED_OUT)
2. Check enrolled factors → is Okta Verify present?
3. Pull recent login activity → any failed attempts?
4. If locked out, check if it's a lockout or a factor issue

**Action plan:**
1. Unlock account (if LOCKED_OUT)
2. Reset Okta Verify (Push) factor
3. Internal comment: "Reset Okta Verify push factor. User will re-enroll on next login. Account status: [status]."
4. Category: Access Management > MFA Reset
5. Slack reply: "Your Okta Verify has been reset — you'll be prompted to set it up again next time you log in."
6. Resolve ticket

---

## Password Reset

**Triggers:** "forgot password," "password expired," "can't log in," "reset my password"

**Diagnostic:**
1. Look up user in Okta → check status
2. Check if password is expired (changePasswordAtNextLogin flag)
3. Verify identity if policy requires it (skip in this tool — note in ticket)

**Action plan:**
1. Reset password in Okta with temp password (changePasswordAtNextLogin = true)
2. Optionally reset in Google Workspace if the user has a separate GWS password
3. Internal comment: "Password reset. Temp password provided via [DM/secure channel]. User must change on next login."
4. Category: Access Management > Password Reset
5. DM the user with the temp password (never in a channel or thread)
6. Resolve ticket

⚠️ **Never put temporary passwords in ticket comments, Slack channels, or email.**
Use a Slack DM or your org's secure password delivery method.

---

## Access Request — Add to Application

**Triggers:** "need access to [app]," "can't get into Salesforce," "requesting access"

**Diagnostic:**
1. Look up user in Okta → check current app assignments
2. Check if the app is assigned via a group → which group?
3. Verify the request is approved (check ticket for manager approval or linked approval)

**Action plan:**
1. Add user to the appropriate Okta group (which grants app access via group assignment)
2. Confirm SCIM provisioning status if applicable
3. Internal comment: "Added [user] to [group] granting access to [app]. SCIM provisioning [triggered/not applicable]."
4. Category: Access Management > App Access
5. Slack reply: "You should now have access to [app]. Give it a try and let me know if it's working!"
6. Resolve ticket

⚠️ **Always verify approval before granting access.** If no approval is attached
to the ticket, ask the admin: "I don't see manager approval on this ticket. Want
to proceed or wait for approval?"

---

## Access Removal

**Triggers:** "remove access to [app]," "revoke," "no longer needs [app]"

**Diagnostic:**
1. Look up user in Okta → how is the app assigned? (direct vs group)
2. If group-based: which group? What else does that group grant?
3. Confirm the removal scope — just this app, or broader offboarding?

**Action plan:**
1. Remove user from group (if group-based) or remove direct assignment
2. Confirm SCIM deprovisioning if applicable
3. Internal comment: "Removed [user] from [group]. Access to [app] revoked. SCIM deprovisioning [triggered/not applicable]. Other group memberships unchanged."
4. Category: Access Management > Access Removal
5. Resolve ticket (no Slack reply needed unless requested)

⚠️ **Always show the SCIM impact.** Removing someone from a group can deactivate
their account in downstream apps. Make sure the admin sees exactly what will happen.

---

## New Laptop Setup / Laptop Replacement

**Triggers:** "new laptop," "laptop replacement," "need a new machine," "broken laptop"

**Diagnostic:**
1. Check MDM → what device is currently assigned?
2. Check if the current device has any compliance issues
3. Check inventory (if tracked) for available replacement devices

**Action plan:**
1. Internal comment documenting current device details (serial, model, condition)
2. If replacement is in inventory: note the serial number and assignment
3. If procurement needed: update ticket with procurement status, set to "Waiting"
4. Category: Hardware > Laptop Replacement
5. Slack reply: "We're working on getting you a replacement. [Expected timeline if known]. I'll keep you posted!"
6. Set ticket status appropriately (In Progress or Waiting for Procurement)

Note: Actual MDM enrollment and device wipe are done in the MDM console,
not through this tool. The skill handles the ticket workflow, not the device setup.

---

## Software Installation Request

**Triggers:** "install [app]," "need [software]," "requesting [tool]"

**Diagnostic:**
1. Check MDM → is the app already deployed via MDM profile?
2. Check if the app requires a license (Okta app assignment or separate license)
3. Check if the app is in the approved software catalog

**Action plan:**
1. If MDM-managed: verify the profile is assigned to the user's device
2. If license needed: check Okta group assignment or license pool
3. Internal comment: "Verified [app] deployment via [MDM/manual]. License status: [status]."
4. Category: Software > Installation
5. Slack reply: "[App] should be available on your machine now. If you don't see it, try restarting. Let me know!"
6. Resolve ticket

---

## Account Suspension (Admin-Initiated)

**Triggers:** "suspend [user]," "disable account," "block access" (NOT offboarding)

**Diagnostic:**
1. Look up user in Okta → current status
2. Look up user in Google Workspace → current status
3. Verify the request has appropriate authorization

**Action plan:**
1. Suspend in Okta (blocks all SSO)
2. Suspend in Google Workspace (blocks Google sign-in, retains data)
3. Internal comment: "Suspended [user] in Okta and Google Workspace per [ticket/request]. Group memberships and data retained. This is NOT a full offboard."
4. Category: Access Management > Account Suspension
5. Resolve ticket

⚠️ **Suspension ≠ offboarding.** Always clarify this. Suspension blocks sign-in
but retains all data, group memberships, and email delivery. If the admin actually
wants a full offboard, redirect to the offboarding process.

---

## Google Group Management

**Triggers:** "add to group," "remove from group," "create group," "distribution list"

**Diagnostic:**
1. Look up the group in Google Workspace → members, settings
2. If adding: check if the user is already a member
3. If removing: check what the group is used for (email, access, etc.)

**Action plan:**
1. Add or remove the user from the Google group
2. Internal comment: "[Added/Removed] [user] [to/from] [group]. Group is used for: [email distribution / shared drive access / etc.]."
3. Category: Access Management > Group Management
4. Slack reply (if adding): "You've been added to [group name]. You should start receiving emails and have access to shared resources."
5. Resolve ticket

---

## General Template Structure

For ticket types not covered above, follow this general pattern:

1. **Diagnose**: Look up the user across relevant systems. Understand the current state.
2. **Identify**: Determine the root cause and the right fix.
3. **Propose**: Present the action plan to the admin with confirmation.
4. **Execute**: System action first, then ticket update, then notification.
5. **Document**: Internal comment with what was done, what changed, what to watch for.
6. **Categorize**: Set the right category and sub-category.
7. **Notify**: Slack reply if appropriate (user-facing, outcome-focused).
8. **Close**: Transition to Resolved.

Always follow the execution order: **system action → verify success → ticket update → user notification → close.** Never notify the user before confirming the action succeeded.
