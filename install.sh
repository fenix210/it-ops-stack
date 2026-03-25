#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# IT Ops Stacks — One-Command Installer
# Sets up Claude Code with the IT Ops Skills marketplace and MCP connections
# ============================================================================

REPO="fenix210/it-ops-stack"
MARKETPLACE_NAME="it-ops-stacks"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_header() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          IT Ops Stacks — Installer              ║${NC}"
    echo -e "${BOLD}║   Claude Code skills for IT operations          ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "\n${BLUE}━━━ Step $1: $2 ━━━${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

ask_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -rp "$prompt [y/n]: " response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            [nN]|[nN][oO]) return 1 ;;
            *) echo "Please enter y or n." ;;
        esac
    done
}

# ============================================================================
# Pre-flight checks
# ============================================================================

print_header

echo -e "${BOLD}Checking prerequisites...${NC}"
echo ""

# Check for Claude Code
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
    print_success "Claude Code found ($CLAUDE_VERSION)"
else
    print_error "Claude Code not found"
    echo ""
    echo "  Install Claude Code first:"
    echo "    npm install -g @anthropic-ai/claude-code"
    echo ""
    echo "  Then re-run this installer."
    exit 1
fi

# Check for git
if command -v git &> /dev/null; then
    print_success "git found"
else
    print_error "git not found — required for marketplace installation"
    exit 1
fi

# Check for Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>/dev/null || echo "unknown")
    print_success "Python found ($PYTHON_VERSION)"
else
    print_error "Python 3 not found — required for MCP servers"
    echo "  Install Python 3.10+ and re-run this installer."
    exit 1
fi

# Check for uv (preferred) or pip, auto-install uv if neither found
if command -v uv &> /dev/null; then
    print_success "uv found (preferred Python package manager)"
    PKG_MANAGER="uv"
elif command -v pip &> /dev/null; then
    print_success "pip found"
    PKG_MANAGER="pip"
else
    echo ""
    print_warning "No Python package manager found — installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null
    # Source the updated PATH
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if command -v uv &> /dev/null; then
        print_success "uv installed successfully"
        PKG_MANAGER="uv"
    else
        print_error "Failed to install uv. Install manually:"
        echo "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "  Then re-run this installer."
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}Prerequisites met. Let's set up your IT Ops stack.${NC}"

# ============================================================================
# Step 1: Install the skills marketplace
# ============================================================================

print_step "1" "Installing IT Ops Skills Marketplace"

echo "  This installs 5 skills from github.com/$REPO:"
echo ""
echo "    • jsm-ticket-management  — Jira Service Management"
echo "    • google-workspace-admin — Google Workspace (replaces GAM)"
echo "    • okta-admin             — Okta identity management"
echo "    • mdm-query              — Device lookups (Kandji/Jamf/Intune)"
echo "    • slack-it-support       — Slack notifications & replies"
echo ""

if ask_yes_no "Install the marketplace?"; then
    echo ""
    echo "Adding marketplace..."
    claude plugin marketplace add "$REPO" 2>/dev/null && \
        print_success "Marketplace added" || \
        print_warning "Marketplace may already be added — continuing"

    echo ""
    echo "Installing plugins..."

    for plugin in jsm-ticket-management google-workspace-admin okta-admin mdm-query slack-it-support; do
        claude plugin install "${plugin}@${MARKETPLACE_NAME}" 2>/dev/null && \
            print_success "Installed $plugin" || \
            print_warning "$plugin may already be installed — continuing"
    done
else
    print_warning "Skipped marketplace installation"
fi

# ============================================================================
# Step 1b: Pre-install MCP server packages
# ============================================================================

echo ""
echo -e "${BLUE}  Installing MCP server packages...${NC}"
echo ""

IT_OS_DIR="$HOME/.it-os"
mkdir -p "$IT_OS_DIR"

# Google Workspace Admin MCP
if command -v gws-admin-mcp &> /dev/null; then
    print_success "gws-admin-mcp already installed"
else
    GWS_MCP_DIR="$IT_OS_DIR/gws-admin-mcp"
    if [[ ! -d "$GWS_MCP_DIR" ]]; then
        git clone https://github.com/fenix210/gws-admin-mcp.git "$GWS_MCP_DIR" && \
            print_success "gws-admin-mcp cloned" || \
            print_error "Failed to clone gws-admin-mcp"
    fi
    if [[ -d "$GWS_MCP_DIR" ]]; then
        if [[ "$PKG_MANAGER" == "uv" ]]; then
            uv pip install -e "$GWS_MCP_DIR" && \
                print_success "gws-admin-mcp installed" || \
                print_warning "gws-admin-mcp install failed"
        else
            pip install --user -e "$GWS_MCP_DIR" && \
                print_success "gws-admin-mcp installed" || \
                print_warning "gws-admin-mcp install failed"
        fi
    fi
fi

# MDM MCP (Kandji / Jamf / Intune)
if command -v mdm-mcp &> /dev/null; then
    print_success "mdm-mcp already installed"
else
    MDM_MCP_DIR="$IT_OS_DIR/mdm-mcp"
    if [[ ! -d "$MDM_MCP_DIR" ]]; then
        git clone https://github.com/fenix210/mdm-mcp.git "$MDM_MCP_DIR" && \
            print_success "mdm-mcp cloned" || \
            print_error "Failed to clone mdm-mcp"
    fi
    if [[ -d "$MDM_MCP_DIR" ]]; then
        if [[ "$PKG_MANAGER" == "uv" ]]; then
            uv pip install -e "${MDM_MCP_DIR}[intune]" && \
                print_success "mdm-mcp installed (with Intune support)" || \
                print_warning "mdm-mcp install failed"
        else
            pip install --user -e "${MDM_MCP_DIR}[intune]" && \
                print_success "mdm-mcp installed (with Intune support)" || \
                print_warning "mdm-mcp install failed"
        fi
    fi
fi

# Okta MCP (official — just clone, uv runs it directly)
OKTA_MCP_DIR="$IT_OS_DIR/okta-mcp-server"
if [[ ! -d "$OKTA_MCP_DIR" ]]; then
    git clone https://github.com/okta/okta-mcp-server.git "$OKTA_MCP_DIR" && \
        print_success "Okta MCP server cloned" || \
        print_error "Failed to clone Okta MCP server"
else
    print_success "Okta MCP server already cloned"
fi

echo ""
print_success "MCP server packages ready"

# ============================================================================
# Step 2: Connect Jira / JSM
# ============================================================================

print_step "2" "Connect Jira Service Management"

echo "  This connects Claude Code to your Atlassian instance"
echo "  so you can manage JSM tickets through natural language."
echo ""
echo "  You'll need:"
echo "    • An Atlassian Cloud instance"
echo "    • You'll authenticate via browser when prompted"
echo ""

if ask_yes_no "Connect Jira/JSM now?"; then
    echo ""
    echo "Adding Atlassian MCP server..."
    claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse --scope user 2>/dev/null && \
        print_success "Atlassian MCP added" || \
        print_warning "Atlassian MCP may already be configured"
    echo ""
    print_info "On your next Claude Code session, you'll be prompted to"
    print_info "authenticate in your browser."
else
    print_warning "Skipped Jira — you can add it later with:"
    print_info "claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse"
fi

# ============================================================================
# Step 3: Connect Okta
# ============================================================================

print_step "3" "Connect Okta"

echo "  This connects Claude Code to your Okta org for"
echo "  user lookups, group management, MFA resets, and SSO diagnostics."
echo ""
echo "  You'll need:"
echo "    • Your Okta org URL (e.g. https://yourcompany.okta.com)"
echo "    • Python 3.10+ and uv (for the official Okta MCP server)"
echo ""

if ask_yes_no "Connect Okta now?"; then
    echo ""
    read -rp "  Enter your Okta org URL (e.g. https://yourcompany.okta.com): " OKTA_ORG_URL

    if [[ -z "$OKTA_ORG_URL" ]]; then
        print_warning "No URL provided — skipping Okta"
    else
        OKTA_MCP_DIR="$HOME/.it-os/okta-mcp-server"

        if command -v uv &> /dev/null && [[ -d "$OKTA_MCP_DIR" ]]; then
            echo ""
            echo "  You'll need to create an API Services app in Okta:"
            echo "    1. Go to Okta Admin > Applications > Create App Integration"
            echo "    2. Select 'API Services'"
            echo "    3. Note the Client ID"
            echo "    4. Grant the necessary API scopes under the Okta API tab"
            echo ""
            read -rp "  Enter your Okta Client ID (or press Enter to configure later): " OKTA_CLIENT_ID

            if [[ -n "$OKTA_CLIENT_ID" ]]; then
                claude mcp add-json "okta" "{
                    \"command\": \"uv\",
                    \"args\": [\"run\", \"--directory\", \"$OKTA_MCP_DIR\", \"okta-mcp-server\"],
                    \"env\": {
                        \"OKTA_ORG_URL\": \"$OKTA_ORG_URL\",
                        \"OKTA_CLIENT_ID\": \"$OKTA_CLIENT_ID\",
                        \"OKTA_SCOPES\": \"okta.users.read okta.users.manage okta.groups.read okta.groups.manage okta.apps.read okta.factors.read okta.factors.manage okta.logs.read\"
                    }
                }" --scope user 2>/dev/null && \
                    print_success "Okta MCP configured" || \
                    print_error "Failed to configure Okta MCP"
            else
                print_warning "Skipped Okta Client ID — configure later"
            fi
        else
            print_warning "Okta MCP server not ready — ensure uv is installed and re-run"
            print_info "Install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
        fi
    fi
else
    print_warning "Skipped Okta — you can configure it later"
fi

# ============================================================================
# Step 4: Connect Google Workspace
# ============================================================================

print_step "4" "Connect Google Workspace Admin"

echo "  This connects Claude Code to Google Workspace for"
echo "  user/group management, device inventory, and audit logs."
echo ""
echo "  You'll need:"
echo "    • A GCP project with Admin SDK API enabled"
echo "    • An OAuth 2.0 Desktop client (client_secret.json)"
echo "    • Your Google Workspace domain"
echo ""
echo "  Setup guide: https://github.com/fenix210/gws-admin-mcp#setup"
echo ""

if ask_yes_no "Connect Google Workspace now?"; then
    echo ""

    read -rp "  Path to your OAuth client_secret JSON file (or Enter to skip): " GWS_CLIENT_FILE
    read -rp "  Your Google Workspace domain (e.g. company.com, or Enter to skip): " GWS_DOMAIN

    if [[ -n "$GWS_CLIENT_FILE" && -n "$GWS_DOMAIN" ]]; then
        # Expand tilde
        GWS_CLIENT_FILE="${GWS_CLIENT_FILE/#\~/$HOME}"

        claude mcp add-json "gws-admin" "{
            \"command\": \"gws-admin-mcp\",
            \"env\": {
                \"GWS_OAUTH_CLIENT_FILE\": \"$GWS_CLIENT_FILE\",
                \"GOOGLE_WORKSPACE_DOMAIN\": \"$GWS_DOMAIN\"
            }
        }" --scope user 2>/dev/null && \
            print_success "Google Workspace MCP configured" || \
            print_error "Failed to configure GWS MCP"
        echo ""
        print_info "On first use, your browser will open to authenticate."
        print_info "Sign in with your Google admin account."
    else
        print_warning "Skipped Google Workspace credentials — configure later with:"
        print_info "claude mcp add-json \"gws-admin\" '{\"command\": \"gws-admin-mcp\", \"env\": {\"GWS_OAUTH_CLIENT_FILE\": \"/path/to/client_secret.json\", \"GOOGLE_WORKSPACE_DOMAIN\": \"yourdomain.com\"}}'"
    fi
else
    print_warning "Skipped Google Workspace — see setup guide at:"
    print_info "https://github.com/fenix210/gws-admin-mcp#setup"
fi

# ============================================================================
# Step 5: Connect Slack
# ============================================================================

print_step "5" "Connect Slack"

echo "  This connects Claude Code to your Slack workspace"
echo "  for replying to users and posting status updates."
echo ""

if ask_yes_no "Connect Slack now?"; then
    echo ""
    claude mcp add-json "slack" '{
        "type": "http",
        "url": "https://mcp.slack.com/mcp",
        "oauth": {
            "clientId": "1601185624273.8899143856786",
            "callbackPort": 3118
        }
    }' --scope user 2>/dev/null && \
        print_success "Slack MCP configured" || \
        print_warning "Slack MCP may already be configured"
    echo ""
    print_info "You'll be prompted to authenticate in your browser"
    print_info "on your next Claude Code session."
else
    print_warning "Skipped Slack — you can add it later"
fi

# ============================================================================
# Step 6: Connect MDM (Multi-select)
# ============================================================================

print_step "6" "Connect MDM — Device Management"

echo "  This connects Claude Code to your MDM for read-only"
echo "  device queries: assigned devices, profiles, compliance, fleet inventory."
echo ""
printf "  ${BOLD}You can select multiple platforms${NC} (e.g. Kandji for Mac + Intune for Windows).\n"
echo ""
echo "  Select all MDM platforms you use:"
echo "    1. Kandji (now Iru)"
echo "    2. Jamf Pro"
echo "    3. Microsoft Intune"
echo "    4. Skip MDM for now"
echo ""
read -rp "  Enter your choices (comma-separated, e.g. 1,3): " MDM_CHOICES

# Track which platforms were configured
MDM_ENV_VARS=""
MDM_CONFIGURED=false

# Parse choices
if [[ "$MDM_CHOICES" == *"1"* ]]; then
    echo ""
    echo -e "  ${BLUE}── Kandji Setup ──${NC}"
    echo "  Find your API URL and token in Kandji > Settings > Access"
    echo ""
    read -rp "  Kandji API URL (e.g. https://yourorg.api.kandji.io): " KANDJI_URL
    read -rp "  Kandji API Token: " KANDJI_TOKEN

    if [[ -n "$KANDJI_URL" && -n "$KANDJI_TOKEN" ]]; then
        MDM_ENV_VARS="${MDM_ENV_VARS}\"KANDJI_API_URL\": \"$KANDJI_URL\", \"KANDJI_API_TOKEN\": \"$KANDJI_TOKEN\", "
        MDM_CONFIGURED=true
        print_success "Kandji credentials captured"
    else
        print_warning "Incomplete Kandji credentials — skipped"
    fi
fi

if [[ "$MDM_CHOICES" == *"2"* ]]; then
    echo ""
    echo -e "  ${BLUE}── Jamf Pro Setup ──${NC}"
    echo "  Create API credentials in Jamf Pro > Settings > API Roles and Clients"
    echo ""
    read -rp "  Jamf Pro URL (e.g. https://yourorg.jamfcloud.com): " JAMF_URL
    read -rp "  Jamf Client ID: " JAMF_CLIENT_ID
    read -rp "  Jamf Client Secret: " JAMF_CLIENT_SECRET

    if [[ -n "$JAMF_URL" && -n "$JAMF_CLIENT_ID" && -n "$JAMF_CLIENT_SECRET" ]]; then
        MDM_ENV_VARS="${MDM_ENV_VARS}\"JAMF_URL\": \"$JAMF_URL\", \"JAMF_CLIENT_ID\": \"$JAMF_CLIENT_ID\", \"JAMF_CLIENT_SECRET\": \"$JAMF_CLIENT_SECRET\", "
        MDM_CONFIGURED=true
        print_success "Jamf Pro credentials captured"
    else
        print_warning "Incomplete Jamf credentials — skipped"
    fi
fi

if [[ "$MDM_CHOICES" == *"3"* ]]; then
    echo ""
    echo -e "  ${BLUE}── Microsoft Intune Setup ──${NC}"
    echo "  Create an Azure AD App Registration with"
    echo "  DeviceManagementManagedDevices.Read.All permission"
    echo ""
    read -rp "  Azure Tenant ID: " INTUNE_TENANT
    read -rp "  App Client ID: " INTUNE_CLIENT
    read -rp "  Client Secret: " INTUNE_SECRET

    if [[ -n "$INTUNE_TENANT" && -n "$INTUNE_CLIENT" && -n "$INTUNE_SECRET" ]]; then
        MDM_ENV_VARS="${MDM_ENV_VARS}\"INTUNE_TENANT_ID\": \"$INTUNE_TENANT\", \"INTUNE_CLIENT_ID\": \"$INTUNE_CLIENT\", \"INTUNE_CLIENT_SECRET\": \"$INTUNE_SECRET\", "
        MDM_CONFIGURED=true
        print_success "Intune credentials captured"
    else
        print_warning "Incomplete Intune credentials — skipped"
    fi
fi

if [[ "$MDM_CONFIGURED" == true ]]; then
    echo ""

    # Remove trailing comma and space from env vars
    MDM_ENV_VARS="${MDM_ENV_VARS%, }"

    # Register the MCP server with all collected credentials
    claude mcp add-json "mdm" "{
        \"command\": \"mdm-mcp\",
        \"env\": { $MDM_ENV_VARS }
    }" --scope user 2>/dev/null && \
        print_success "MDM MCP configured with all selected platforms" || \
        print_error "Failed to configure MDM MCP"
else
    if [[ "$MDM_CHOICES" != *"4"* ]]; then
        print_warning "No MDM platforms configured"
    else
        print_warning "Skipped MDM — you can configure it later"
    fi
fi

# ============================================================================
# Summary
# ============================================================================

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║              Setup Complete!                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}What's installed:${NC}"
echo "    Skills marketplace with 5 IT Ops plugins"
echo "    MCP connections for your selected platforms"
echo ""
echo -e "  ${BOLD}To get started:${NC}"
echo "    1. Open Claude Code:  claude"
echo "    2. Try a command:     \"Show me my open tickets\""
echo ""
echo -e "  ${BOLD}Useful commands to try:${NC}"
echo "    \"Pull my assigned tickets and rank by priority\""
echo "    \"Look up sarah@company.com in Okta\""
echo "    \"What devices does sarah have?\""
echo "    \"Show me the fleet summary\""
echo "    \"Show me failed logins in the last 24 hours\""
echo "    \"Who hasn't logged in for 90 days?\""
echo "    \"Which devices are non-compliant?\""
echo ""
echo -e "  ${BOLD}Documentation:${NC}"
echo "    https://github.com/$REPO"
echo ""
echo -e "  ${GREEN}Happy ticket crushing.${NC}"
echo ""
